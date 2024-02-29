// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {ScrollBadgeSelfAttest} from "../src/badge/extensions/ScrollBadgeSelfAttest.sol";
import {Unauthorized} from "../src/Errors.sol";

contract TestContract is ScrollBadgeSelfAttest {
    constructor(address resolver_) ScrollBadge(resolver_) {}

    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return "";
    }
}

contract ScrollBadgeSelfAttestTest is ScrollBadgeTestBase {
    TestContract internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContract(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestToSelf() external {
        _attest(address(badge), "", address(this));
    }

    function testAttestToOtherFails(address notSelf) external {
        vm.assume(notSelf != address(this));
        vm.expectRevert(Unauthorized.selector);
        _attest(address(badge), "", notSelf);
    }
}
