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

    /// @notice Returns the token URI corresponding to a certain badge UID, or the default
    ///         badge token URI if the pass UID is 0x0.
    /// @param uid The badge UID, or 0x0.
    /// @return The badge token URI (same format as ERC721).
    function badgeTokenURI(bytes32 uid) external view returns (string memory);

    /// @notice Returns true if the user has one or more of this badge.
    /// @param user The user's wallet address.
    /// @return True if the user has one or more of this badge.
    function hasBadge(address user) external view returns (bool);
}
