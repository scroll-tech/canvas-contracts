// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";
import {NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {ExpirationDisabled} from "../../Errors.sol";

/// @title ScrollBadgeNoExpiry
/// @notice This contract disables expiration for this badge.
abstract contract ScrollBadgeNoExpiry is ScrollBadge {
    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        if (attestation.expirationTime != NO_EXPIRATION_TIME) {
            revert ExpirationDisabled();
        }

        return true;
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        return super.onRevokeBadge(attestation);
    }
}
