// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { ScrollBadgeSBT } from "../extensions/ScrollBadgeSBT.sol";
import { ScrollBadge } from "../ScrollBadge.sol";
import { InvalidBadge } from "../../Errors.sol";

/// @title ScrollBadgePermissionless
/// @notice A simple SBT badge that anyone can mint in a permissionless manner.
contract ScrollBadgePermissionless is ScrollBadgeSBT {
    constructor(address resolver_, string memory name_, string memory symbol_, string memory tokenUri_) ScrollBadge(resolver_) ScrollBadgeSBT(name_, symbol_, true) {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal override(ScrollBadgeSBT) returns (bool) {
        if (attestation.recipient != attestation.attester) {
            revert InvalidBadge(attestation.uid);
        }

        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal override(ScrollBadgeSBT) returns (bool) {
        return super.onIssueBadge(attestation);
    }
}
