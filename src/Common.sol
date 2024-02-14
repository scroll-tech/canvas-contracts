// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

uint256 constant MAX_ATTACHED_BADGE_NUM = 48;

string constant SCROLL_BADGE_SCHEMA = "address badge, bytes payload";

function decodeBadgeData(bytes memory data) pure returns (address, bytes memory) {
    return abi.decode(data, (address, bytes));
}

function isContract(address addr) view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
}
