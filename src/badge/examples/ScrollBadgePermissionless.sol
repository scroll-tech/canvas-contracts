// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {ScrollBadgeSelfAttest} from "../extensions/ScrollBadgeSelfAttest.sol";
import {ScrollBadgeSingleton} from "../extensions/ScrollBadgeSingleton.sol";

/// @title ScrollBadgePermissionless
/// @notice A simple badge that anyone can mint in a permissionless manner.
contract ScrollBadgePermissionless is ScrollBadgeSelfAttest, ScrollBadgeSingleton {
    constructor(address resolver_) ScrollBadge(resolver_) {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        virtual
        override (ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        virtual
        override (ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return "";
    }
}
