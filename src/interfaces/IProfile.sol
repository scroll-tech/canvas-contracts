// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IProfile {
    /**
     *
     * Public Mutating Functions *
     *
     */

    /// @notice Attach a list of badges to this profile.
    /// @param _uids The list of badge uids to attach.
    function attach(bytes32[] memory _uids) external;

    /// @notice Auto-attach a badge to this profile.
    /// @dev Only callable by the badge resolver contract.
    /// @param _uid The badge uid to attach.
    function autoAttach(bytes32 _uid) external;
}
