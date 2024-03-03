// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadge} from "../ScrollBadge.sol";

/// @title ScrollBadgeOnChainEligibility
/// @notice This contract adds a standard on-chain eligibility check API.
abstract contract ScrollBadgeOnChainEligibility is ScrollBadge {
    /// @notice Check if user is eligible to mint this badge.
    /// @param recipient The user's wallet address.
    /// @return Whether the user is eligible to mint.
    function isEligible(address recipient) external virtual returns (bool) {
        return !hasBadge(recipient);
    }
}
