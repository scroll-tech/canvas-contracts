// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

uint256 constant MAX_ATTACHED_BADGE_NUM = 48;

string constant SCROLL_BADGE_SCHEMA = "address badge, bytes payload";

function decodeBadgeData(bytes memory data) pure returns (address, bytes memory) {
    return abi.decode(data, (address, bytes));
}

function encodeBadgeData(address badge, bytes memory payload) pure returns (bytes memory) {
    return abi.encode(badge, payload);
}