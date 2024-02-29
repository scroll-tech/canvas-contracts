// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {RevocationDisabled} from "../../Errors.sol";

/// @title ScrollBadgeNonRevocable
/// @notice This contract disables revocation for this badge.
abstract contract ScrollBadgeNonRevocable is ScrollBadge {
    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        if (attestation.revocable) {
            revert RevocationDisabled();
        }

        return true;
    }
}
