// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { ScrollBadge } from "../ScrollBadge.sol";
import { SingletonBadge }from "../../Errors.sol";

/// @title ScrollBadgeSingleton
/// @notice This contract only allows one active badge per wallet.
abstract contract ScrollBadgeSingleton is ScrollBadge {
    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal override virtual returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        if (hasBadge(attestation.recipient)) {
            revert SingletonBadge(attestation.uid);
        }

        return true;
    }
}
