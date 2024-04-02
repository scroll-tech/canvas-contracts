// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {ScrollBadgeCustomPayload} from "../extensions/ScrollBadgeCustomPayload.sol";
import {ScrollBadgeNoExpiry} from "../extensions/ScrollBadgeNoExpiry.sol";
import {ScrollBadgeNonRevocable} from "../extensions/ScrollBadgeNonRevocable.sol";
import {ScrollBadgeSelfAttest} from "../extensions/ScrollBadgeSelfAttest.sol";
import {ScrollBadgeSingleton} from "../extensions/ScrollBadgeSingleton.sol";
import {Unauthorized} from "../../Errors.sol";

string constant ETHEREUM_YEAR_BADGE_SCHEMA = "uint256 year, bytes signature";

function decodePayloadData(bytes memory data) pure returns (uint256, bytes memory) {
    return abi.decode(data, (uint256, bytes));
}

/// @title EthereumYearBadge
/// @notice A badge that represents the year of the user's first transaction on Ethereum.
contract EthereumYearBadge is
    Ownable,
    EIP712,
    ScrollBadgeSelfAttest,
    ScrollBadgeCustomPayload,
    ScrollBadgeNoExpiry,
    ScrollBadgeNonRevocable,
    ScrollBadgeSingleton
{
    /// @dev Thrown when the signature is invalid.
    error ErrorInvalidSignature();

    /// @notice Emitted when the offchain signer is updated.
    /// @param oldSigner The address of previous offchain signer.
    /// @param newSigner The address of current offchain signer.
    event UpdateOffchainSigner(address indexed oldSigner, address indexed newSigner);

    /// @dev The type hash for issue badge.
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _ISSUE_BADGE_TYPEHASH = keccak256("IssueBadge(address recipient,uint256 year)");

    /// @notice The address of badge offchain signer.
    address public offchainSigner;

    /// @notice The base token URI.
    string public baseTokenURI;

    // badge UID => current year
    mapping(bytes32 => uint256) public badgeYear;

    constructor(address resolver_, address offchainSigner_, string memory baseTokenURI_) ScrollBadge(resolver_) EIP712("Ethereum Year Badge", "1") {
        _updateOffchainSigner(offchainSigner_);

        baseTokenURI = baseTokenURI_;
    }

    /// @notice Update the offchain signer.
    /// @param newSigner The new offchain signer address.
    function updateOffchainSigner(address newSigner) external onlyOwner {
        _updateOffchainSigner(newSigner);
    }

    /// @notice Update the base token URI.
    /// @param baseTokenURI_ The new base token URI.
    function updateBaseTokenURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        override (
            ScrollBadgeSelfAttest,
            ScrollBadgeCustomPayload,
            ScrollBadgeNoExpiry,
            ScrollBadgeNonRevocable,
            ScrollBadgeSingleton
        )
        returns (bool)
    {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        // check signature
        bytes memory payload = getPayload(attestation);
        (uint256 year, bytes memory signature) = decodePayloadData(payload);
        bytes32 structHash = keccak256(abi.encode(_ISSUE_BADGE_TYPEHASH, attestation.recipient, year));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        if (signer != offchainSigner) revert ErrorInvalidSignature();

        badgeYear[attestation.uid] = year;

        return true;
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        override (ScrollBadge, ScrollBadgeSelfAttest, ScrollBadgeCustomPayload, ScrollBadgeNoExpiry, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 uid) public view override returns (string memory) {
        uint256 year = badgeYear[uid];
        return string(abi.encodePacked(baseTokenURI, Strings.toString(year)));
    }

    /// @inheritdoc ScrollBadgeCustomPayload
    function getSchema() public pure override returns (string memory) {
        return ETHEREUM_YEAR_BADGE_SCHEMA;
    }

    /// @dev Internal function to update offchain signer.
    /// @param newSigner The new offchain signer address.
    function _updateOffchainSigner(address newSigner) internal {
        address oldSigner = offchainSigner;
        offchainSigner = newSigner;

        emit UpdateOffchainSigner(oldSigner, newSigner);
    }
}
