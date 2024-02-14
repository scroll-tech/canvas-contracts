// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { ScrollBadgeTestBase } from "./ScrollBadgeTestBase.sol";

import { ScrollBadgeAccessControl } from "../src/badge/extensions/ScrollBadgeAccessControl.sol";
import { ScrollBadge } from "../src/badge/ScrollBadge.sol";
import { Unauthorized } from "../src/Errors.sol";

contract TestContract is ScrollBadgeAccessControl {
    constructor(address resolver_) ScrollBadge(resolver_) {}
}

contract ScrollBadgeAccessControlTest is ScrollBadgeTestBase {
    TestContract internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContract(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAuthorized() external {
        badge.toggleAttester(address(this), true);
        bytes32 uid = _attest(address(badge), "", alice);
        _revoke(uid);
    }

    function testUnauthorizedAttest() external {
        hevm.expectRevert(Unauthorized.selector);
        _attest(address(badge), "", alice);
    }

    function testUnauthorizedRevoke() external {
        badge.toggleAttester(address(this), true);
        bytes32 uid = _attest(address(badge), "", alice);

        badge.toggleAttester(address(this), false);
        hevm.expectRevert(Unauthorized.selector);
        _revoke(uid);
    }
}
