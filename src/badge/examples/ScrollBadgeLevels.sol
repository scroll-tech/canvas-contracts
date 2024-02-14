// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ScrollBadgeAccessControl } from "../extensions/ScrollBadgeAccessControl.sol";
import { ScrollBadgeCustomPayload } from "../extensions/ScrollBadgeCustomPayload.sol";
import { ScrollBadgeSBT } from "../extensions/ScrollBadgeSBT.sol";
import { ScrollBadge } from "../ScrollBadge.sol";

string constant SCROLL_BADGE_LEVELS_SCHEMA = "uint8 scrollLevel";

function decodePayloadData(bytes memory data) pure returns (uint8) {
    return abi.decode(data, (uint8));
}

contract ScrollBadgeLevels is ScrollBadgeAccessControl, ScrollBadgeCustomPayload, ScrollBadgeSBT {
    constructor(address resolver_, bytes32 schema_, string memory name_, string memory symbol_) ScrollBadge(resolver_) ScrollBadgeSBT(name_, symbol_, true) {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal override(ScrollBadgeAccessControl, ScrollBadgeCustomPayload, ScrollBadgeSBT) returns (bool) {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal override(ScrollBadgeAccessControl, ScrollBadgeCustomPayload, ScrollBadgeSBT) returns (bool) {
        return super.onRevokeBadge(attestation);
    }

    function getSchema() public pure override returns (string memory) {
        return SCROLL_BADGE_LEVELS_SCHEMA;
    }

    function getCurrentLevel(uint256 tokenId) public view returns (uint8) {
        bytes32 uid = bytes32(tokenId);
        Attestation memory badge = getAndValidateBadge(uid);
        bytes memory payload = getPayload(badge);
        (uint8 level) = decodePayloadData(payload);
        return level;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory) {
        uint8 level = getCurrentLevel(tokenId);
        string memory name = string(abi.encode("Scroll Level #", Strings.toString(level)));
        string memory description = "Scroll Level Badge";
        string memory image = ""; // IPFS, HTTP, or data URL
        string memory tokenUriJson = Base64.encode(abi.encodePacked('{"name":"', name, '", "description":"', description, ', "image": "', image, '"}'));
        return string(abi.encodePacked("data:application/json;base64,", tokenUriJson));
    }
}
