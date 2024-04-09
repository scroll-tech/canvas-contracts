// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {ScrollBadgeAccessControl} from "../extensions/ScrollBadgeAccessControl.sol";
import {ScrollBadgeCustomPayload} from "../extensions/ScrollBadgeCustomPayload.sol";
import {ScrollBadgeNoExpiry} from "../extensions/ScrollBadgeNoExpiry.sol";
import {ScrollBadgeNonRevocable} from "../extensions/ScrollBadgeNonRevocable.sol";
import {ScrollBadgeSingleton} from "../extensions/ScrollBadgeSingleton.sol";

string constant ETHEREUM_YEAR_BADGE_SCHEMA = "uint256 year";

function decodePayloadData(bytes memory data) pure returns (uint256) {
    return abi.decode(data, (uint256));
}

/// @title EthereumYearBadge
/// @notice A badge that represents the year of the user's first transaction on Ethereum.
contract EthereumYearBadge is
    ScrollBadgeAccessControl,
    ScrollBadgeCustomPayload,
    ScrollBadgeNoExpiry,
    ScrollBadgeNonRevocable,
    ScrollBadgeSingleton
{
    /// @notice The base token URI.
    string public baseTokenURI;

    constructor(address resolver_, string memory baseTokenURI_) ScrollBadge(resolver_) {
        baseTokenURI = baseTokenURI_;
    }

    /// @notice Update the base token URI.
    /// @param baseTokenURI_ The new base token URI.
    function updateBaseTokenURI(string memory baseTokenURI_) external onlyOwner {
        baseTokenURI = baseTokenURI_;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        override (
            ScrollBadgeAccessControl,
            ScrollBadgeCustomPayload,
            ScrollBadgeNoExpiry,
            ScrollBadgeNonRevocable,
            ScrollBadgeSingleton
        )
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        override (
            ScrollBadge, ScrollBadgeAccessControl, ScrollBadgeCustomPayload, ScrollBadgeNoExpiry, ScrollBadgeSingleton
        )
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 uid) public view override returns (string memory) {
        Attestation memory attestation = getAndValidateBadge(uid);
        bytes memory payload = getPayload(attestation);
        uint256 year = decodePayloadData(payload);

        return string(abi.encodePacked(baseTokenURI, Strings.toString(year), ".json"));
    }

    /// @inheritdoc ScrollBadgeCustomPayload
    function getSchema() public pure override returns (string memory) {
        return ETHEREUM_YEAR_BADGE_SCHEMA;
    }
}
