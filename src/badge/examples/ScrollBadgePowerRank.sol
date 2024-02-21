// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ScrollBadge } from "../ScrollBadge.sol";
import { ScrollBadgeAccessControl } from "../extensions/ScrollBadgeAccessControl.sol";
import { ScrollBadgeCustomPayload } from "../extensions/ScrollBadgeCustomPayload.sol";
import { ScrollBadgeNoExpiry } from "../extensions/ScrollBadgeNoExpiry.sol";
import { ScrollBadgeNonRevocable } from "../extensions/ScrollBadgeNonRevocable.sol";
import { ScrollBadgeSingleton } from "../extensions/ScrollBadgeSingleton.sol";
import { Unauthorized } from "../../Errors.sol";

string constant SCROLL_BADGE_POWER_RANK_SCHEMA = "uint256 firstTxTimestamp";

function decodePayloadData(bytes memory data) pure returns (uint256) {
    return abi.decode(data, (uint256));
}

/// @title ScrollBadgePowerRank
/// @notice A badge that represents the user's power rank.
contract ScrollBadgePowerRank is ScrollBadgeAccessControl, ScrollBadgeCustomPayload, ScrollBadgeNoExpiry, ScrollBadgeNonRevocable, ScrollBadgeSingleton {
    error CannotUpgrade();
    event Upgrade(uint256 oldRank, uint256 newRank);

    // badge UID => current rank
    mapping (bytes32 => uint256) public badgeRank;

    constructor(address resolver_) ScrollBadge(resolver_) {
        // empty
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal override(ScrollBadgeAccessControl, ScrollBadgeCustomPayload, ScrollBadgeNoExpiry, ScrollBadgeNonRevocable, ScrollBadgeSingleton) returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        bytes memory payload = getPayload(attestation);
        (uint256 firstTxTimestamp) = decodePayloadData(payload);
        badgeRank[attestation.uid] = timestampToRank(firstTxTimestamp);

        return true;
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation) internal override(ScrollBadge, ScrollBadgeAccessControl, ScrollBadgeCustomPayload) returns (bool) {
        return super.onRevokeBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 uid) public override view returns (string memory) {
        uint256 rank = badgeRank[uid];
        string memory name = string(abi.encode("Scroll Power Rank #", Strings.toString(rank)));
        string memory description = "Scroll Power Rank Badge";
        string memory image = ""; // IPFS, HTTP, or data URL
        string memory tokenUriJson = Base64.encode(abi.encodePacked('{"name":"', name, '", "description":"', description, ', "image": "', image, '"}'));
        return string(abi.encodePacked("data:application/json;base64,", tokenUriJson));
    }

    /// @inheritdoc ScrollBadgeCustomPayload
    function getSchema() public pure override returns (string memory) {
        return SCROLL_BADGE_POWER_RANK_SCHEMA;
    }

    function upgrade(bytes32 uid) external {
        Attestation memory badge = getAndValidateBadge(uid);

        if (msg.sender != badge.recipient) {
            revert Unauthorized();
        }

        bytes memory payload = getPayload(badge);
        (uint256 firstTxTimestamp) = decodePayloadData(payload);
        uint256 newRank = timestampToRank(firstTxTimestamp);

        uint256 oldRank = badgeRank[uid];
        if (newRank <= oldRank) {
            revert CannotUpgrade();
        }

        badgeRank[uid] = newRank;
        emit Upgrade(oldRank, newRank);
    }

    function timestampToRank(uint256 timestamp) public view returns (uint256) {
        return (block.timestamp - timestamp) / 2592000 + 1; // level up every 30 days
    }
}
