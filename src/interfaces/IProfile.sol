// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IProfile {
    /**
     *
     * Events *
     *
     */

    /// @notice Emitted when a badge is attached.
    /// @param uid The id of the badge.
    event AttachBadge(bytes32 indexed uid);

    /// @notice Emitted when a badge is detached.
    /// @param uid The id of the badge.
    event DetachBadge(bytes32 indexed uid);

    /// @notice Emitted when the username is updated.
    event ChangeUsername(string oldUsername, string newUsername);

    /// @notice Emitted when the avatar is updated.
    event ChangeAvatar(address oldToken, uint256 oldTokenId, address newToken, uint256 newTokenId);

    /// @notice Emitted when the badge order is updated.
    event ReorderBadges(uint256 oldOrder, uint256 newOrder);

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
