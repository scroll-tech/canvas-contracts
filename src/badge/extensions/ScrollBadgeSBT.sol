// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { ScrollBadge } from "../ScrollBadge.sol";
import { SBT } from "../../misc/SBT.sol";

/// @title ScrollBadgeSBT
/// @notice This contract attaches an SBT token to each badge.
abstract contract ScrollBadgeSBT is SBT, ScrollBadge {
    error MultipleActiveAttestationsDisabled();

    // Whether it is allowed to mint multiple tokens per address.
    bool public immutable singleton;

    /// @dev Creates a new ScrollBadgeSBT instance.
    /// @param name_ The ERC721 token name.
    /// @param symbol_ The ERC721 token symbol.
    /// @param singleton_ If true, each user can only have one badge.
    constructor(string memory name_, string memory symbol_, bool singleton_) SBT(name_, symbol_) {
        singleton = singleton_;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        if (singleton && balanceOf(attestation.recipient) > 0) {
            revert MultipleActiveAttestationsDisabled();
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
}
