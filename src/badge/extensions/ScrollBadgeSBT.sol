// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {SBT} from "../../misc/SBT.sol";
import {ScrollBadge} from "../ScrollBadge.sol";
import {ScrollBadgeNoExpiry} from "./ScrollBadgeNoExpiry.sol";

/// @title ScrollBadgeSBT
/// @notice This contract attaches an SBT token to each badge.
abstract contract ScrollBadgeSBT is SBT, ScrollBadgeNoExpiry {
    /// @dev Creates a new ScrollBadgeSBT instance.
    /// @param name_ The ERC721 token name.
    /// @param symbol_ The ERC721 token symbol.
    constructor(string memory name_, string memory symbol_) SBT(name_, symbol_) {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        uint256 tokenId = uid2TokenId(attestation.uid);
        _safeMint(attestation.recipient, tokenId);

        return true;
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        if (!super.onRevokeBadge(attestation)) {
            return false;
        }

        uint256 tokenId = uid2TokenId(attestation.uid);
        _burn(tokenId);

        return true;
    }

    /// @notice Converts an ERC721 token ID into a badge attestation UID.
    /// @param tokenId The ERC721 token id.
    /// @return The badge attestation UID.
    function tokenId2Uid(uint256 tokenId) public pure returns (bytes32) {
        return bytes32(tokenId);
    }

    /// @notice Converts a badge attestation UID into an ERC721 token ID.
    /// @param uri The badge attestation UID.
    /// @return The ERC721 token id.
    function uid2TokenId(bytes32 uri) public pure returns (uint256) {
        return uint256(uri);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view virtual override (ERC721) returns (string memory) {
        bytes32 uid = bytes32(tokenId);
        return badgeTokenURI(uid);
    }
}
