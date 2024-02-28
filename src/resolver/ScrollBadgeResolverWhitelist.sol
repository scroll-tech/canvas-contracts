// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ScrollBadgeResolverWhitelist is Ownable {
    // If false, all badges are allowed.
    bool public whitelistEnabled = true;

    // Authorized badge contracts.
    mapping(address => bool) public whitelist;

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
