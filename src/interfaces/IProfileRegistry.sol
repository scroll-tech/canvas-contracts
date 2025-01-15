// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IProfileRegistry {
    /**
     *
     * Events *
     *
     */

    /// @notice Emitted when a new profile is minted.
    /// @param account The address of account who minted the profile.
    /// @param profile The address of profile minted.
    /// @param referrer The address of referrer.
    event MintProfile(address indexed account, address indexed profile, address indexed referrer);

    /// @notice Emitted when profile register username.
    /// @param profile The address of profile.
    /// @param username The username registered.
    event RegisterUsername(address indexed profile, string username);

    /// @notice Emitted when profile unregister username.
    /// @param profile The address of profile.
    /// @param username The username unregistered.
    event UnregisterUsername(address indexed profile, string username);

    /// @notice Emitted when the default profile avatar is updated.
    /// @param oldAvatar The token URI of the previous avatar.
    /// @param newAvatar The token URI of the current avatar.
    event UpdateDefaultProfileAvatar(string oldAvatar, string newAvatar);

    /// @dev Emitted when the profile implementation is updated.
    /// @param oldImplementation The address of previous profile implementation.
    /// @param newImplementation The address of current profile implementation.
    event UpdateProfileImplementation(address indexed oldImplementation, address indexed newImplementation);

    /// @dev Emitted when the referral signer is updated.
    /// @param oldSigner The address of previous signer.
    /// @param newSigner The address of current signer.
    event UpdateSigner(address indexed oldSigner, address indexed newSigner);

    /// @dev Emitted when the mint fee treasury is updated.
    /// @param oldTreasury The address of previous treasury.
    /// @param newTreasury The address of current treasury.
    event UpdateTreasury(address indexed oldTreasury, address indexed newTreasury);

    /**
     *
     * Public View Functions *
     *
     */

    /// @notice Check whether the profile is minted in this contract.
    /// @param profile The address of profile to check.
    function isProfileMinted(address profile) external view returns (bool);

    /// @notice Check whether the username is used by other profile.
    /// @param username The username to query.
    function isUsernameUsed(string calldata username) external view returns (bool);

    /// @notice Calculate the address of profile with given account address.
    /// @param account The address of account to query.
    function getProfile(address account) external view returns (address);

    /// @notice Return the tokenURI for default profile avatar.
    function getDefaultProfileAvatar() external view returns (string memory);

    /**
     *
     * Public Mutating Functions *
     *
     */

    /// @notice Register an username.
    /// @param username The username to register.
    function registerUsername(string memory username) external;

    /// @notice Unregister an username.
    /// @param username The username to unregister.
    function unregisterUsername(string memory username) external;
}
