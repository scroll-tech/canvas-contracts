// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {IScrollBadge} from "./IScrollBadge.sol";

interface IScrollSelfAttestationBadge is IScrollBadge {
    /// @notice Return the unique id of this badge.
    function getBadgeId() external view returns (uint256);

    /// @notice Returns an existing attestation by UID.
    /// @param uid The UID of the attestation to retrieve.
    /// @return The attestation data members.
    function getAttestation(bytes32 uid) external view returns (Attestation memory);
}
