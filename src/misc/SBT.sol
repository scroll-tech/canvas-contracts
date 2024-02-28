// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SBT is ERC721 {
    error TransfersDisabled();

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        // empty
    }

    function _beforeTokenTransfer(address from, address to, uint256, /*firstTokenId*/ uint256 /*batchSize*/ )
        internal
        pure
        override
    {
        if (from != address(0) && to != address(0)) {
            revert TransfersDisabled();
        }
    }
}
