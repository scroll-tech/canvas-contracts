// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadgeAccessControl} from "../extensions/ScrollBadgeAccessControl.sol";
import {ScrollBadgeSingleton} from "../extensions/ScrollBadgeSingleton.sol";
import {ScrollBadge} from "../ScrollBadge.sol";

/// @title ScrollBadgeSimple
/// @notice A simple badge that has the same static metadata for each token.
contract ScrollBadgeSimple is ScrollBadgeAccessControl, ScrollBadgeSingleton {
    string public sharedTokenURI;

    constructor(address resolver_, string memory tokenUri_) ScrollBadge(resolver_) {
        sharedTokenURI = tokenUri_;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        override (ScrollBadgeAccessControl, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        override (ScrollBadgeAccessControl, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 /*uid*/ ) public view override returns (string memory) {
        return sharedTokenURI;
    }
}
