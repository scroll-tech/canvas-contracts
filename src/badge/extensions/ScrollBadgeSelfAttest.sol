// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {Unauthorized} from "../../Errors.sol";

/// @title ScrollBadgeSelfAttest
/// @notice This contract ensures that only the badge recipient can attest.
abstract contract ScrollBadgeSelfAttest is ScrollBadge {
    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        if (attestation.attester != attestation.recipient) {
            revert Unauthorized();
        }

        return true;
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        return super.onRevokeBadge(attestation);
    }
}
