// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

abstract contract ScrollBadgeResolverWhitelist is OwnableUpgradeable {
    /**
     *
     * Variables *
     *
     */

    // If false, all badges are allowed.
    bool public whitelistEnabled;

    // Authorized badge contracts.
    mapping(address => bool) public whitelist;

    // Storage slots reserved for future upgrades.
    uint256[48] private __gap;

    /**
     *
     * Constructor *
     *
     */
    constructor() {
        _disableInitializers();
    }

    function __Whitelist_init() internal onlyInitializing {
        __Ownable_init();
        whitelistEnabled = true;
    }

    /**
     *
     * Restricted Functions *
     *
     */

    /// @notice Enables or disables a given badge contract.
    /// @param badge The badge address.
    /// @param enable True if enable, false if disable.
    function toggleBadge(address badge, bool enable) external onlyOwner {
        whitelist[badge] = enable;
    }

    /// @notice Enables or disables the badge whitelist.
    /// @param enable True if enable, false if disable.
    function toggleWhitelist(bool enable) external onlyOwner {
        whitelistEnabled = enable;
    }
}
