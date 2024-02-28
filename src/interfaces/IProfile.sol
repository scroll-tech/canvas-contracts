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
}
