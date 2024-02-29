// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {ScrollBadgeCustomPayload} from "../src/badge/extensions/ScrollBadgeCustomPayload.sol";
import {MissingPayload} from "../src/Errors.sol";

contract TestContract is ScrollBadgeCustomPayload {
    constructor(address resolver_) ScrollBadge(resolver_) {}

    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return "";
    }

    function getSchema() public pure override returns (string memory) {
        return "string abc";
    }
}

contract ScrollBadgeCustomPayloadTest is ScrollBadgeTestBase {
    TestContract internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContract(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestWithPayload(string memory message) external {
        bytes memory payload = abi.encode(message);
        bytes32 uid = _attest(address(badge), payload, alice);

        Attestation memory attestation = badge.getAndValidateBadge(uid);
        bytes memory payload2 = badge.getPayload(attestation);
        string memory message2 = abi.decode(payload2, (string));

        assertEq(message2, message);
    }

    function testAttestWithEmptyPayloadFails() external {
        vm.expectRevert(MissingPayload.selector);
        _attest(address(badge), "", alice);
    }
}
