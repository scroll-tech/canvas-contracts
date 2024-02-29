// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {decodeBadgeData} from "../../Common.sol";
import {MissingPayload} from "../../Errors.sol";

/// @title ScrollBadgeCustomPayload
/// @notice This contract adds custom payload to ScrollBadge.
abstract contract ScrollBadgeCustomPayload is ScrollBadge {
    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        bytes memory payload = getPayload(attestation);

        if (payload.length == 0) {
            revert MissingPayload();
        }

        return true;
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        return super.onRevokeBadge(attestation);
    }

    /// @notice Return the badge payload.
    /// @param badge The Scroll badge attestation.
    /// @return The abi encoded badge payload.
    function getPayload(Attestation memory badge) public pure returns (bytes memory) {
        (, bytes memory payload) = decodeBadgeData(badge.data);
        return payload;
    }

    /// @notice Return the badge custom payload schema.
    /// @return The custom abi encoding schema used for the payload.
    /// @dev This schema serves as a decoding hint for clients.
    function getSchema() public virtual returns (string memory);
}
