// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {ScrollBadgePermissionless} from "./ScrollBadgePermissionless.sol";
import {ScrollBadgeEligibilityCheck} from "../extensions/ScrollBadgeEligibilityCheck.sol";
import {Unauthorized} from "../../Errors.sol";

/// @title ScrollBadgeWhale
/// @notice A badge that shows that the user had 1000 ETH or more at the time of minting.
contract ScrollBadgeWhale is ScrollBadgePermissionless {
    constructor(address resolver_, string memory _defaultBadgeURI)
        ScrollBadgePermissionless(resolver_, _defaultBadgeURI)
    {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal override returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        if (attestation.recipient.balance < 1000 ether) {
            revert Unauthorized();
        }

        return true;
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal override returns (bool) {
        if (!super.onRevokeBadge(attestation)) {
            return false;
        }

        return true;
    }

    /// @inheritdoc ScrollBadgeEligibilityCheck
    function isEligible(address recipient) external view override returns (bool) {
        return !hasBadge(recipient) && recipient.balance >= 1000 ether;
    }
}
