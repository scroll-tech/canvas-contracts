// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { ScrollBadgeAccessControl } from "../extensions/ScrollBadgeAccessControl.sol";
import { ScrollBadgeSBT } from "../extensions/ScrollBadgeSBT.sol";
import { ScrollBadge } from "../ScrollBadge.sol";

/// @title ScrollBadgeSimple
/// @notice A simple SBT badge that has the same static metadata for each token.
contract ScrollBadgeSimple is ScrollBadgeAccessControl, ScrollBadgeSBT {
    string public sharedTokenURI;

    constructor(address resolver_, string memory name_, string memory symbol_, string memory tokenUri_) ScrollBadge(resolver_) ScrollBadgeSBT(name_, symbol_, true) {
        sharedTokenURI = tokenUri_;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal override(ScrollBadgeAccessControl, ScrollBadgeSBT) returns (bool) {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal override(ScrollBadgeAccessControl, ScrollBadgeSBT) returns (bool) {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 /*tokenId*/) public view virtual override(ERC721) returns (string memory) {
        return sharedTokenURI;
    }
}
