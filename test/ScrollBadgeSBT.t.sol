// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {SBT} from "../src/misc/SBT.sol";
import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {ScrollBadgeSBT} from "../src/badge/extensions/ScrollBadgeSBT.sol";

contract TestContract is ScrollBadgeSBT {
    constructor(address resolver_) ScrollBadge(resolver_) ScrollBadgeSBT("name", "symbol") {}

    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return "";
    }
}

contract ScrollBadgeSBTTest is ScrollBadgeTestBase {
    TestContract internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContract(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttest() external {
        // mint single token
        bytes32 uid = _attest(address(badge), "", alice);

        bool isValid = eas.isAttestationValid(uid);
        assertTrue(isValid);

        uint256 balance = badge.balanceOf(alice);
        assertEq(balance, 1);

        uint256 tokenId = uint256(uid);
        address owner = badge.ownerOf(uint256(uid));
        assertEq(owner, alice);

        // cannot transfer token
        hevm.prank(alice);
        hevm.expectRevert(SBT.TransfersDisabled.selector);
        badge.transferFrom(alice, bob, tokenId);

        // revoke
        _revoke(uid);

        balance = badge.balanceOf(alice);
        assertEq(balance, 0);

        hevm.expectRevert("ERC721: invalid token ID");
        badge.ownerOf(uint256(uid));
    }
}
