// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ScrollBadgeCustomPayload} from "../extensions/ScrollBadgeCustomPayload.sol";
import {ScrollBadgeSelfAttest} from "../extensions/ScrollBadgeSelfAttest.sol";
import {ScrollBadgeSingleton} from "../extensions/ScrollBadgeSingleton.sol";
import {ScrollBadge} from "../ScrollBadge.sol";
import {Unauthorized} from "../../Errors.sol";

string constant SCROLL_BADGE_NFT_OWNER_SCHEMA = "address tokenAddress, uint256 tokenId";

function decodePayloadData(bytes memory data) pure returns (address, uint256) {
    return abi.decode(data, (address, uint256));
}

/// @title ScrollNFTOwnerBadge
/// @notice A simple badge that attests that the user owns a specific NFT.
contract ScrollNFTOwnerBadge is ScrollBadgeCustomPayload, ScrollBadgeSelfAttest, ScrollBadgeSingleton {
    error IncorrectBadgeOwner();

    mapping(address => bool) public isTokenAllowed;

    constructor(address resolver_, address[] memory tokens_) ScrollBadge(resolver_) {
        for (uint256 i = 0; i < tokens_.length; ++i) {
            isTokenAllowed[tokens_[i]] = true;
        }
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        override (ScrollBadgeCustomPayload, ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        // do not allow minting for other users
        if (attestation.attester != attestation.recipient) {
            revert Unauthorized();
        }

        // check that badge payload attestation is correct
        bytes memory payload = getPayload(attestation);
        (address tokenAddress, uint256 tokenId) = decodePayloadData(payload);

        if (!isTokenAllowed[tokenAddress]) {
            revert Unauthorized();
        }

        if (IERC721(tokenAddress).ownerOf(tokenId) != attestation.recipient) {
            revert IncorrectBadgeOwner();
        }

        return true;
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        override (ScrollBadgeCustomPayload, ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 uid) public view override returns (string memory) {
        Attestation memory attestation = getAndValidateBadge(uid);
        bytes memory payload = getPayload(attestation);
        (address tokenAddress, uint256 tokenId) = decodePayloadData(payload);
        return IERC721Metadata(tokenAddress).tokenURI(tokenId);
    }

    /// @inheritdoc ScrollBadgeCustomPayload
    function getSchema() public pure override returns (string memory) {
        return SCROLL_BADGE_NFT_OWNER_SCHEMA;
    }
}
