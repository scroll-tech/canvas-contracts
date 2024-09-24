// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {ScrollBadgeDefaultURI} from "../extensions/ScrollBadgeDefaultURI.sol";
import {ScrollBadgeEligibilityCheck} from "../extensions/ScrollBadgeEligibilityCheck.sol";
import {ScrollBadgeSelfAttest} from "../extensions/ScrollBadgeSelfAttest.sol";
import {ScrollBadgeSingleton} from "../extensions/ScrollBadgeSingleton.sol";

/// @title ScrollBadgePermissionless
/// @notice A simple badge that anyone can mint in a permissionless manner.
contract ScrollBadgePermissionless is
    ScrollBadgeDefaultURI,
    ScrollBadgeEligibilityCheck,
    ScrollBadgeSelfAttest,
    ScrollBadgeSingleton
{
    constructor(address resolver_, string memory _defaultBadgeURI)
        ScrollBadge(resolver_)
        ScrollBadgeDefaultURI(_defaultBadgeURI)
    {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        virtual
        override (ScrollBadge, ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        virtual
        override (ScrollBadge, ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }
}
