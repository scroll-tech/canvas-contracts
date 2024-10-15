// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {ScrollBadgeAccessControl} from "../extensions/ScrollBadgeAccessControl.sol";
import {ScrollBadgeDefaultURI} from "../extensions/ScrollBadgeDefaultURI.sol";
import {ScrollBadgeSingleton} from "../extensions/ScrollBadgeSingleton.sol";

/// @title ScrollBadgeSimple
/// @notice A simple badge that has the same static metadata for each token.
contract ScrollBadgeSimple is ScrollBadgeAccessControl, ScrollBadgeDefaultURI, ScrollBadgeSingleton {
    constructor(address resolver_, string memory tokenUri_) ScrollBadge(resolver_) ScrollBadgeDefaultURI(tokenUri_) {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        override (ScrollBadge, ScrollBadgeAccessControl, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        override (ScrollBadge, ScrollBadgeAccessControl, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }
}
