// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

import {IProfileRegistry} from "../interfaces/IProfileRegistry.sol";
import {CallerIsNotUserProfile, DuplicatedUsername} from "../Errors.sol";
import {Profile} from "./Profile.sol";

contract ClonableBeaconProxy is BeaconProxy {
    constructor() BeaconProxy(msg.sender, "") {}
}

/// @title ProfileRegistry
/// @notice Profile registry keeps track of minted profiles and manages their implementation.
contract ProfileRegistry is UpgradeableBeacon, IProfileRegistry {
    /*************
     * Constants *
     *************/

    /// @notice The codehash for `ClonableBeaconProxy` contract.
    bytes32 public constant cloneableProxyHash = keccak256(type(ClonableBeaconProxy).creationCode);

    /*************
     * Variables *
     *************/

    /// @inheritdoc IProfileRegistry
    mapping(address => bool) public isProfileMinted;

    /// @notice Mapping from username hash to the status.
    mapping(bytes32 => bool) private isUsernameHashUsed;

    /*************
     * Modifiers *
     *************/

    modifier onlyProfile() {
        if (!isProfileMinted[_msgSender()]) revert CallerIsNotUserProfile();
        _;
    }

    /***************
     * Constructor *
     ***************/

    /// @param profileImpl_ The address of profile implementation contract.
    constructor(address profileImpl_) UpgradeableBeacon(profileImpl_) {
        // empty
    }

    /*************************
     * Public View Functions *
     *************************/

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

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @inheritdoc IProfileRegistry
    function mintProfile(string calldata username) external override returns (address) {
        return _mintProfile(_msgSender(), username);
    }

    /// @inheritdoc IProfileRegistry
    function registerUsername(string memory username) external override onlyProfile {
        bytes32 hash = keccak256(bytes(username));
        if (isUsernameHashUsed[hash]) revert DuplicatedUsername();
        isUsernameHashUsed[hash] = true;

        emit RegisterProfile(_msgSender(), username);
    }

    /// @inheritdoc IProfileRegistry
    function unregisterUsername(string memory username) external override onlyProfile {
        bytes32 hash = keccak256(bytes(username));
        isUsernameHashUsed[hash] = false;

        emit UnregisterProfile(_msgSender(), username);
    }

    /************************
     * Restricted Functions *
     ************************/

    /// @notice Blacklist a list of usernames by given username hashes.
    /// @param hashes The list of username hashes to blacklist.
    function blacklistUsername(bytes32[] memory hashes) external onlyOwner {
        for (uint256 i = 0; i < hashes.length; i++) {
            isUsernameHashUsed[hashes[i]] = true;
        }
    }

    /**********************
     * Internal Functions *
     **********************/
    
    /// @dev Internal function to mint a profile with given account address and username.
    /// @param account The address of user to mint profile.
    /// @param username The username of the profile.
    function _mintProfile(address account, string calldata username) private returns (address) {
        // deployment will fail and this function will revert if contract `salt` is not unique
        bytes32 salt = keccak256(abi.encode(account));
        address profile = address(new ClonableBeaconProxy{salt: salt}());

        // mark the profile is minted
        isProfileMinted[profile] = true;

        Profile(profile).initialize(account, username);

        emit MintProfile(account, profile);

        return profile;
    }
}
