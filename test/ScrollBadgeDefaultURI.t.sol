// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {ScrollBadgeDefaultURI} from "../src/badge/extensions/ScrollBadgeDefaultURI.sol";

contract TestContract is ScrollBadgeDefaultURI {
    constructor(address resolver_) ScrollBadge(resolver_) ScrollBadgeDefaultURI("default") {}

    function getBadgeTokenURI(bytes32 /*uid*/ ) internal pure override returns (string memory) {
        return "not-default";
    }
}

contract ScrollBadgeDefaultURITest is ScrollBadgeTestBase {
    TestContract internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContract(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testGetBadgeTokenURI() external {
        bytes32 uid = _attest(address(badge), "", alice);

        string memory uri = badge.badgeTokenURI(uid);
        assertEq(uri, "not-default");

        uri = badge.badgeTokenURI(bytes32(0));
        assertEq(uri, "default");
    }
}
