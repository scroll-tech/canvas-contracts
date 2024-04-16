// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadge} from "../ScrollBadge.sol";

/// @title ScrollBadgeDefaultURI
/// @notice This contract sets a default badge URI.
abstract contract ScrollBadgeDefaultURI is ScrollBadge {
    string public defaultBadgeURI;

    constructor(string memory _defaultBadgeURI) {
        defaultBadgeURI = _defaultBadgeURI;
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 uid) public view override returns (string memory) {
        if (uid == bytes32(0)) {
            return defaultBadgeURI;
        }

        return getBadgeTokenURI(uid);
    }

    /// @notice Returns the token URI corresponding to a certain badge UID.
    /// @param uid The badge UID.
    /// @return The badge token URI (same format as ERC721).
    function getBadgeTokenURI(bytes32 uid) internal view virtual returns (string memory);
}
