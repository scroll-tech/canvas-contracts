// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {InvalidBadge} from "../../Errors.sol";
import {ScrollBadge} from "../ScrollBadge.sol";
import {ScrollBadgeSingleton} from "../extensions/ScrollBadgeSingleton.sol";

/// @title ScrollBadgePermissionless
/// @notice A simple badge that anyone can mint in a permissionless manner.
contract ScrollBadgePermissionless is ScrollBadgeSingleton {
    constructor(address resolver_, string memory name_, string memory symbol_) ScrollBadge(resolver_) {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal override returns (bool) {
        if (attestation.recipient != attestation.attester) {
            revert InvalidBadge(attestation.uid);
        }

        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal override returns (bool) {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return "";
    }
}
