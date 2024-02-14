// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { ScrollBadgeCustomPayload } from "../extensions/ScrollBadgeCustomPayload.sol";
import { ScrollBadgeSBT } from "../extensions/ScrollBadgeSBT.sol";
import { ScrollBadge } from "../ScrollBadge.sol";

string constant SCROLL_BADGE_ORIGINS_SCHEMA = "address originsTokenAddress, uint256 originsTokenId";

function decodePayloadData(bytes memory data) pure returns (address, uint256) {
    return abi.decode(data, (address, uint256));
}

/// @title ScrollBadgeOrigins
/// @notice A simple SBT badge that is attached to a Scroll Origins NFT.
contract ScrollBadgeOrigins is ScrollBadgeCustomPayload, ScrollBadgeSBT {
    error IncorrectBadgeOwner();

    constructor(address resolver_, string memory name_, string memory symbol_) ScrollBadge(resolver_) ScrollBadgeSBT(name_, symbol_, true) {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal override(ScrollBadgeCustomPayload, ScrollBadgeSBT) returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
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
    function onRevokeBadge(Attestation calldata attestation) internal override(ScrollBadgeCustomPayload, ScrollBadgeSBT) returns (bool) {
        return super.onRevokeBadge(attestation);
    }

    function getSchema() public pure override returns (string memory) {
        return SCROLL_BADGE_ORIGINS_SCHEMA;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        bytes32 uid = tokenId2Uid(tokenId);
        Attestation memory attestation = getAndValidateBadge(uid);
        bytes memory payload = getPayload(attestation);
        (address originsTokenAddress, uint256 originsTokenId) = decodePayloadData(payload);
        return IERC721Metadata(originsTokenAddress).tokenURI(originsTokenId);
    }
}
