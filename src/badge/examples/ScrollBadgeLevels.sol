// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ScrollBadgeAccessControl } from "../extensions/ScrollBadgeAccessControl.sol";
import { ScrollBadgeCustomPayload } from "../extensions/ScrollBadgeCustomPayload.sol";
import { ScrollBadge } from "../ScrollBadge.sol";

string constant SCROLL_BADGE_LEVELS_SCHEMA = "uint8 scrollLevel";

function decodePayloadData(bytes memory data) pure returns (uint8) {
    return abi.decode(data, (uint8));
}

/// @title ScrollBadgeLevels
/// @notice A simple badge that represents the user's level.
contract ScrollBadgeLevels is ScrollBadgeAccessControl, ScrollBadgeCustomPayload {
    constructor(address resolver_) ScrollBadge(resolver_) {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal override(ScrollBadgeAccessControl, ScrollBadgeCustomPayload) returns (bool) {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal override(ScrollBadgeAccessControl, ScrollBadgeCustomPayload) returns (bool) {
        return super.onRevokeBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 uid) public override view returns (string memory) {
        uint8 level = getCurrentLevel(uid);
        string memory name = string(abi.encode("Scroll Level #", Strings.toString(level)));
        string memory description = "Scroll Level Badge";
        string memory image = ""; // IPFS, HTTP, or data URL
        string memory tokenUriJson = Base64.encode(abi.encodePacked('{"name":"', name, '", "description":"', description, ', "image": "', image, '"}'));
        return string(abi.encodePacked("data:application/json;base64,", tokenUriJson));
    }

    /// @inheritdoc ScrollBadgeCustomPayload
    function getSchema() public pure override returns (string memory) {
        return SCROLL_BADGE_LEVELS_SCHEMA;
    }

    function getCurrentLevel(bytes32 uid) public view returns (uint8) {
        Attestation memory badge = getAndValidateBadge(uid);
        bytes memory payload = getPayload(badge);
        (uint8 level) = decodePayloadData(payload);
        return level;
    }
}
