// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {Unauthorized} from "../../Errors.sol";

/// @title ScrollBadgeAccessControl
/// @notice This contract adds access control to ScrollBadge.
/// @dev In EAS, only the original attester can revoke an attestation. If the original
//       attester was removed and a new was added in this contract, it will not be able
//       to revoke previous attestations.
abstract contract ScrollBadgeAccessControl is Ownable, ScrollBadge {
    // Authorized badge issuer and revoker accounts.
    mapping(address => bool) public isAttester;

    /// @notice Enables or disables a given attester.
    /// @param attester The attester address.
    /// @param enable True if enable, false if disable.
    function toggleAttester(address attester, bool enable) external onlyOwner {
        isAttester[attester] = enable;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        // only allow authorized issuers
        if (!isAttester[attestation.attester]) {
            revert Unauthorized();
        }

        return true;
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        if (!super.onRevokeBadge(attestation)) {
            return false;
        }

        // only allow authorized revokers
        if (!isAttester[attestation.attester]) {
            revert Unauthorized();
        }

        return true;
    }
}
