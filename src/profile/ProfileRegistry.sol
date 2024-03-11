// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IBeacon} from "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

import {IProfileRegistry} from "../interfaces/IProfileRegistry.sol";
import {Profile} from "./Profile.sol";

import {
    CallerIsNotUserProfile,
    DuplicatedUsername,
    ExpiredSignature,
    ImplementationNotContract,
    InvalidReferrer,
    InvalidSignature,
    InvalidUsername,
    MsgValueMismatchWithMintFee,
    ProfileAlreadyMinted
} from "../Errors.sol";

contract ClonableBeaconProxy is BeaconProxy {
    constructor() BeaconProxy(msg.sender, "") {}
}

/// @title ProfileRegistry
/// @notice Profile registry keeps track of minted profiles and manages their implementation.
contract ProfileRegistry is OwnableUpgradeable, EIP712Upgradeable, IBeacon, IProfileRegistry {
    /**
     *
     * Constants *
     *
     */

    /// @notice The mint fee for each profile without referral.
    uint256 public constant MINT_FEE = 0.001 ether;

    /// @notice The codehash for `ClonableBeaconProxy` contract.
    bytes32 public constant cloneableProxyHash = keccak256(type(ClonableBeaconProxy).creationCode);

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _REFERRAL_TYPEHASH = keccak256("Referral(address referrer,address owner,uint256 deadline)");

    /**
     *
     * Structs *
     *
     */

    /// @param referred The number of profiles minted through this referrer.
    /// @param earned The amount of ETH earned by referral.
    struct ReferrerData {
        uint128 referred;
        uint128 earned;
    }

    /**
     *
     * Variables *
     *
     */

    /// @notice The address of fee treasury.
    address public treasury;

    /// @notice The address of referral data signer.
    address public signer;

    /// @inheritdoc IBeacon
    /// @dev The address of profile implementation contract.
    address public implementation;

    /// @inheritdoc IProfileRegistry
    mapping(address => bool) public isProfileMinted;

    /// @notice Mapping from username hash to the status.
    mapping(bytes32 => bool) private isUsernameHashUsed;

    /// @notice The token URI for default profile avatar.
    /// @dev It should follow the Metadata Standards by opensea: https://docs.opensea.io/docs/metadata-standards.
    string private defaultProfileAvatar;

    /// @notice Mapping from referrer address to referrer statistics.
    mapping(address => ReferrerData) public referrerData;

    /**
     *
     * Modifiers *
     *
     */
    modifier onlyProfile() {
        if (!isProfileMinted[_msgSender()]) revert CallerIsNotUserProfile();
        _;
    }

    /**
     *
     * Constructor *
     *
     */
    constructor() {
        _disableInitializers();
    }

    /// @param treasury_ The address of mint fee treasury.
    /// @param signer_ The address of referral data signer.
    /// @param profileImpl_ The address of profile implementation contract.
    function initialize(address treasury_, address signer_, address profileImpl_) external initializer {
        __Context_init();
        __Ownable_init();
        __EIP712_init("ProfileRegistry", "1");

        _updateTreasury(treasury_);
        _updateSigner(signer_);
        _updateProfileImplementation(profileImpl_);
    }

    /**
     *
     * Public View Functions *
     *
     */

    /// @inheritdoc IProfileRegistry
    function getProfile(address account) public view override returns (address) {
        bytes32 salt = keccak256(abi.encode(account));
        return Create2.computeAddress(salt, cloneableProxyHash, address(this));
    }

    /// @inheritdoc IProfileRegistry
    function isUsernameUsed(string calldata username) external view override returns (bool) {
        bytes32 hash = keccak256(bytes(username));
        return isUsernameHashUsed[hash];
    }

    /// @inheritdoc IProfileRegistry
    function getDefaultProfileAvatar() external view override returns (string memory) {
        return defaultProfileAvatar;
    }

    /**
     *
     * Public Mutating Functions *
     *
     */

    /// @inheritdoc IProfileRegistry
    function mint(string calldata username, bytes memory referral) external payable override returns (address) {
        address receiver = treasury;
        address referrer;
        uint256 mintFee = MINT_FEE;
        if (referral.length > 0) {
            uint256 deadline;
            bytes memory signature;
            (receiver, deadline, signature) = abi.decode(referral, (address, uint256, bytes));
            if (deadline < block.timestamp) revert ExpiredSignature();
            if (!isProfileMinted[getProfile(receiver)]) {
                revert InvalidReferrer();
            }

            bytes32 structHash = keccak256(abi.encode(_REFERRAL_TYPEHASH, receiver, _msgSender(), deadline));
            bytes32 hash = _hashTypedDataV4(structHash);
            address recovered = ECDSAUpgradeable.recover(hash, signature);
            if (signer != recovered) revert InvalidSignature();

            // half mint fee and fee goes to referral
            mintFee = MINT_FEE / 2;
            referrer = receiver;
        }
        if (msg.value != mintFee) revert MsgValueMismatchWithMintFee();
        Address.sendValue(payable(receiver), mintFee);

        if (isProfileMinted[getProfile(_msgSender())]) {
            revert ProfileAlreadyMinted();
        }

        if (referrer != address(0)) {
            ReferrerData memory cached = referrerData[referrer];
            cached.referred += 1;
            cached.earned += uint128(mintFee);
            referrerData[referrer] = cached;
        }

        return _mintProfile(_msgSender(), username, referrer);
    }

    /// @inheritdoc IProfileRegistry
    function registerUsername(string memory username) external override onlyProfile {
        _validateUsername(username);

        bytes32 hash = keccak256(bytes(username));
        if (isUsernameHashUsed[hash]) revert DuplicatedUsername();
        isUsernameHashUsed[hash] = true;

        emit RegisterUsername(_msgSender(), username);
    }

    /// @inheritdoc IProfileRegistry
    function unregisterUsername(string memory username) external override onlyProfile {
        bytes32 hash = keccak256(bytes(username));
        isUsernameHashUsed[hash] = false;

        emit UnregisterUsername(_msgSender(), username);
    }

    /**
     *
     * Restricted Functions *
     *
     */

    /// @notice Blacklist a list of usernames by given username hashes.
    /// @param hashes The list of username hashes to blacklist.
    function blacklistUsername(bytes32[] memory hashes) external onlyOwner {
        for (uint256 i = 0; i < hashes.length; i++) {
            isUsernameHashUsed[hashes[i]] = true;
        }
    }

    /// @notice Update the default profile avatar.
    /// @param newAvatar The new default profile avatar.
    function updateDefaultProfileAvatar(string memory newAvatar) external onlyOwner {
        string memory oldAvatar = defaultProfileAvatar;
        defaultProfileAvatar = newAvatar;

        emit UpdateDefaultProfileAvatar(oldAvatar, newAvatar);
    }

    /// @notice Update the profile implementation contract.
    /// @param newImplementation The address of new implementation.
    function updateProfileImplementation(address newImplementation) external onlyOwner {
        _updateProfileImplementation(newImplementation);
    }

    /// @notice Update referral data signer.
    /// @param newSigner The address of new signer.
    function updateSigner(address newSigner) external onlyOwner {
        _updateSigner(newSigner);
    }

    /// @notice Update mint fee treasury.
    /// @param newTreasury The address of new treasury.
    function updateTreasury(address newTreasury) external onlyOwner {
        _updateTreasury(newTreasury);
    }

    /**
     *
     * Internal Functions *
     *
     */

    /// @dev Internal function to mint a profile with given account address and username.
    /// @param account The address of user to mint profile.
    /// @param username The username of the profile.
    function _mintProfile(address account, string calldata username, address referrer) private returns (address) {
        // deployment will fail and this function will revert if contract `salt` is not unique
        bytes32 salt = keccak256(abi.encode(account));
        address profile = address(new ClonableBeaconProxy{salt: salt}());

        // mark the profile is minted
        isProfileMinted[profile] = true;

        Profile(profile).initialize(account, username);

        emit MintProfile(account, profile, referrer);

        return profile;
    }

    /// @dev Internal function to update the profile implementation contract.
    /// @param newImplementation The address of new implementation.
    function _updateProfileImplementation(address newImplementation) private {
        if (!Address.isContract(newImplementation)) revert ImplementationNotContract();

        address oldImplementation = implementation;
        implementation = newImplementation;

        emit UpdateProfileImplementation(oldImplementation, newImplementation);
    }

    /// @dev Internal function to update referral data signer.
    /// @param newSigner The address of new signer.
    function _updateSigner(address newSigner) private {
        address oldSigner = signer;
        signer = newSigner;

        emit UpdateSigner(oldSigner, newSigner);
    }

    /// @dev Internal function to update mint fee treasury.
    /// @param newTreasury The address of new treasury.
    function _updateTreasury(address newTreasury) private {
        address oldTreasury = treasury;
        treasury = newTreasury;

        emit UpdateTreasury(oldTreasury, newTreasury);
    }

    /// @dev Internal function to validate the username. We only accept username consisting of
    /// lowercase and uppercase English letter (`a-z, A-Z`), digits (`0-9`) and underscore (`_`).
    ///
    /// @param username_ The username to validate.
    function _validateUsername(string memory username_) private pure {
        bytes memory s = bytes(username_);
        uint256 length = s.length;
        if (length < 4 || length > 15) revert InvalidUsername();
        for (uint256 i = 0; i < length; i++) {
            if (
                !(
                    (bytes1(0x61) <= s[i] && s[i] <= bytes1(0x7a)) || (bytes1(0x41) <= s[i] && s[i] <= bytes1(0x5a))
                        || (bytes1(0x30) <= s[i] && s[i] <= bytes1(0x39)) || s[i] == bytes1(0x5f)
                )
            ) revert InvalidUsername();
        }
    }
}
