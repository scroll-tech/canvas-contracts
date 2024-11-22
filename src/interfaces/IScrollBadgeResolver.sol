// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

interface IScrollBadgeResolver {
    /**
     *
     * Events *
     *
     */

    /// @dev Emitted when a new badge is issued.
    /// @param uid The UID of the new badge attestation.
    event IssueBadge(bytes32 indexed uid);

    /// @dev Emitted when a badge is revoked.
    /// @param uid The UID of the revoked badge attestation.
    event RevokeBadge(bytes32 indexed uid);

    /// @dev Emitted when the auto-attach status of a badge is updated.
    /// @param badge The address of the badge contract.
    /// @param enable Auto-attach was enabled if true, disabled if false.
    event UpdateAutoAttachWhitelist(address indexed badge, bool indexed enable);

    /**
     *
     * Public View Functions *
     *
     */

    /// @notice Return the Scroll badge attestation schema.
    /// @return The GUID of the Scroll badge attestation schema.
    function schema() external view returns (bytes32);

    /// @notice The profile registry contract.
    /// @return The address of the profile registry.
    function registry() external view returns (address);

    /// @notice The global EAS contract.
    /// @return The address of the global EAS contract.
    function eas() external view returns (address);

    /// @notice Validate and return a Scroll badge attestation.
    /// @param uid The attestation UID.
    /// @return The attestation.
    function getAndValidateBadge(bytes32 uid) external view returns (Attestation memory);
}
