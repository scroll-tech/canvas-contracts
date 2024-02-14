// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

interface IScrollBadgeResolver {
    event IssueBadge(bytes32 indexed uid);
    event RevokeBadge(bytes32 indexed uid);

    /// @notice Return the Scroll badge attestation schema.
    /// @return The GUID of the Scroll badge attestation schema.
    function schema() external returns (bytes32);

    /// @notice The global EAS contract.
    /// @return The address of the global EAS contract.
    function eas() external returns (address);

    /// @notice Validate and return a Scroll badge attestation.
    /// @param uid The attestation UID.
    /// @return The attestation.
    function getAndValidateBadge(bytes32 uid) external view returns (Attestation memory);
}
