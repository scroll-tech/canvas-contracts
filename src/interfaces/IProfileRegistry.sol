// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IProfileRegistry {
    /**********
     * Events *
     **********/

    /// @notice Emitted when a new profile is minted.
    /// @param account The address of account who minted the profile.
    /// @param profile The address of profile minted.
    event MintProfile(address indexed account, address indexed profile);

    /// @notice Emitted when profile register username.
    /// @param profile The address of profile.
    /// @param username The username registered.
    event RegisterProfile(address indexed profile, string username);

    /// @notice Emitted when profile unregister username.
    /// @param profile The address of profile.
    /// @param username The username unregistered.
    event UnregisterProfile(address indexed profile, string username);

    /*************************
     * Public View Functions *
     *************************/

    /// @notice Check whether the profile is minted in this contract.
    /// @param profile The address of profile to check.
    function isProfileMinted(address profile) external view returns (bool);

    /// @notice Check whether the username is used by other profile.
    /// @param username The username to query.
    function isUsernameUsed(string calldata username) external view returns (bool);

    /// @notice Calculate the address of profile with given account address.
    /// @param account The address of account to query.
    function getProfile(address account) external view returns (address);

    /*****************************
     * Public Mutating Functions *
     *****************************/

    /// @notice Mint a profile for caller with given username.
    /// @param username The username of the profile.
    /// @return The address of minted profile.
    function mintProfile(string calldata username) external returns (address);

    /// @notice Register an username.
    /// @param username The username to register.
    function registerUsername(string memory username) external;

    /// @notice Unregister an username.
    /// @param username The username to unregister.
    function unregisterUsername(string memory username) external;
}
