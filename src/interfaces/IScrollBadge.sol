// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

interface IScrollBadge {
    event IssueBadge(bytes32 indexed uid);
    event RevokeBadge(bytes32 indexed uid);

    /// @notice A resolver callback invoked in the `issueBadge` function in the parent contract.
    /// @param attestation The new attestation.
    /// @return Whether the attestation is valid.
    function issueBadge(Attestation calldata attestation) external returns (bool);

    /// @notice A resolver callback invoked in the `revokeBadge` function in the parent contract.
    /// @param attestation The new attestation.
    /// @return Whether the attestation can be revoked.
    function revokeBadge(Attestation calldata attestation) external returns (bool);

    /// @notice Validate and return a Scroll badge attestation.
    /// @param uid The attestation UID.
    /// @return The attestation.
    function getAndValidateBadge(bytes32 uid) external view returns (Attestation memory);
}
