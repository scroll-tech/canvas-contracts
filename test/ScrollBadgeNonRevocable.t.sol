// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {EMPTY_UID, NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";
import {Attestation, AttestationRequest, AttestationRequestData} from "@eas/contracts/IEAS.sol";

import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {ScrollBadgeNonRevocable} from "../src/badge/extensions/ScrollBadgeNonRevocable.sol";
import {RevocationDisabled} from "../src/Errors.sol";

contract TestContract is ScrollBadgeNonRevocable {
    constructor(address resolver_) ScrollBadge(resolver_) {}

    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return "";
    }
}

contract ScrollBadgeNonRevocableTest is ScrollBadgeTestBase {
    TestContract internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContract(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestNonRevocable() external {
        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: alice,
            expirationTime: NO_EXPIRATION_TIME,
            revocable: false,
            refUID: EMPTY_UID,
            data: abi.encode(badge, ""),
            value: 0
        });

        AttestationRequest memory _req = AttestationRequest({schema: schema, data: _attData});

        eas.attest(_req);
    }

    function testAttestRevocableFails() external {
        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: alice,
            expirationTime: NO_EXPIRATION_TIME,
            revocable: true,
            refUID: EMPTY_UID,
            data: abi.encode(badge, ""),
            value: 0
        });

        AttestationRequest memory _req = AttestationRequest({schema: schema, data: _attData});

        vm.expectRevert(RevocationDisabled.selector);
        eas.attest(_req);
    }
}
