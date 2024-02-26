// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { ScrollBadgeCustomPayload } from "../extensions/ScrollBadgeCustomPayload.sol";
import { ScrollBadgeSingleton } from "../extensions/ScrollBadgeSingleton.sol";
import { ScrollBadge } from "../ScrollBadge.sol";
import { Unauthorized } from "../../Errors.sol";

string constant SCROLL_BADGE_ORIGINS_SCHEMA = "address originsTokenAddress, uint256 originsTokenId";

function decodePayloadData(bytes memory data) pure returns (address, uint256) {
    return abi.decode(data, (address, uint256));
}

/// @title ScrollBadgeOrigins
/// @notice A simple badge that is attached to a Scroll Origins NFT.
contract ScrollBadgeOrigins is ScrollBadgeCustomPayload, ScrollBadgeSingleton {
    error IncorrectBadgeOwner();

    constructor(address resolver_) ScrollBadge(resolver_) {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal override(ScrollBadgeCustomPayload, ScrollBadgeSingleton) returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        // do not allow minting for other users
        if (msg.sender != attestation.recipient) {
            revert Unauthorized();
        }

        // check that badge payload attestation is correct
        bytes memory payload = getPayload(attestation);
        (address originsTokenAddress, uint256 originsTokenId) = decodePayloadData(payload);

        if (IERC721(originsTokenAddress).ownerOf(originsTokenId) != attestation.recipient) {
            revert IncorrectBadgeOwner();
        }

        return true;
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal override(ScrollBadge, ScrollBadgeCustomPayload) returns (bool) {
        return super.onRevokeBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 uid) public override view returns (string memory) {
        Attestation memory attestation = getAndValidateBadge(uid);
        bytes memory payload = getPayload(attestation);
        (address originsTokenAddress, uint256 originsTokenId) = decodePayloadData(payload);
        return IERC721Metadata(originsTokenAddress).tokenURI(originsTokenId);
    }

    /// @inheritdoc ScrollBadgeCustomPayload
    function getSchema() public pure override returns (string memory) {
        return SCROLL_BADGE_ORIGINS_SCHEMA;
    }
}
