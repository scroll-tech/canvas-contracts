// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { ScrollBadgeTestBase } from "./ScrollBadgeTestBase.sol";

import { ScrollBadge } from "../src/badge/ScrollBadge.sol";
import { ScrollBadgeNFT } from "../src/badge/extensions/ScrollBadgeNFT.sol";

contract TestContract is ScrollBadgeNFT {
    constructor(address resolver_) ScrollBadge(resolver_) ScrollBadgeNFT("name", "symbol", false) {}

    function mint(address to, uint256 tokenId) external override {
        _safeMint(to, tokenId);
    }

    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
}

contract ScrollBadgeNFTTest is ScrollBadgeTestBase {
    TestContract internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContract(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttest() external {
        badge.mint(alice, 1);
        bytes32 uid1 = badge.token2uid(1);

        bool isValid = eas.isAttestationValid(uid1);
        assertTrue(isValid);

        badge.mint(alice, 2);
        bytes32 uid2 = badge.token2uid(2);

        isValid = eas.isAttestationValid(uid2);
        assertTrue(isValid);

        uint256 balance = badge.balanceOf(alice);
        assertEq(balance, 2);

        hevm.prank(alice);
        badge.transferFrom(alice, bob, 2);
        bytes32 uid3 = badge.token2uid(2);

        Attestation memory attestation = eas.getAttestation(uid2);
        assertLe(attestation.revocationTime, block.timestamp);

        isValid = eas.isAttestationValid(uid3);
        assertTrue(isValid);

        assertNotEq(uid2, uid3);

        balance = badge.balanceOf(alice);
        assertEq(balance, 1);

        balance = badge.balanceOf(bob);
        assertEq(balance, 1);

        hevm.prank(bob);
        badge.burn(2);

        attestation = eas.getAttestation(uid3);
        assertLe(attestation.revocationTime, block.timestamp);

        balance = badge.balanceOf(alice);
        assertEq(balance, 1);

        balance = badge.balanceOf(bob);
        assertEq(balance, 0);
    }
}
