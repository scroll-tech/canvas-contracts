// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title IScrollBadgeUpgradeable
/// @notice This interface defines functions to facilitate badge upgrades.
interface IScrollBadgeUpgradeable {
    /// @notice Checks if a badge can be upgraded.
    /// @param uid The unique identifier of the badge.
    /// @return True if the badge can be upgraded, false otherwise.
    function canUpgrade(bytes32 uid) external view returns (bool);

    /// @notice Upgrades a badge.
    /// @param uid The unique identifier of the badge.
    /// @dev Should revert with CannotUpgrade (from Errors.sol) if the badge cannot be upgraded.
    /// @dev Should emit an Upgrade event (custom defined) if the upgrade is successful.
    function upgrade(bytes32 uid) external;
}
