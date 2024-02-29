// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {Attestation, AttestationRequest, AttestationRequestData} from "@eas/contracts/IEAS.sol";
import {EMPTY_UID} from "@eas/contracts/Common.sol";

import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {ScrollBadgeNoExpiry} from "../src/badge/extensions/ScrollBadgeNoExpiry.sol";
import {ExpirationDisabled} from "../src/Errors.sol";

contract TestContract is ScrollBadgeNoExpiry {
    constructor(address resolver_) ScrollBadge(resolver_) {}

    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return "";
    }
}

contract ScrollBadgeNoExpiryTest is ScrollBadgeTestBase {
    TestContract internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContract(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestWithoutExpiration() external {
        _attest(address(badge), "", alice);
    }

    function testAttestWithExpiryFails(uint64 expirationTime) external {
        vm.assume(expirationTime > uint64(block.timestamp));

        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: alice,
            expirationTime: expirationTime,
            revocable: true,
            refUID: EMPTY_UID,
            data: abi.encode(badge, ""),
            value: 0
        });

        AttestationRequest memory _req = AttestationRequest({schema: schema, data: _attData});

        vm.expectRevert(ExpirationDisabled.selector);
        eas.attest(_req);
    }
}
