// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {IScrollBadge} from "../src/interfaces/IScrollBadge.sol";

contract TestContract is ScrollBadge {
    constructor(address resolver_) ScrollBadge(resolver_) {}

    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return "";
    }
}

contract ScrollBadgeTest is ScrollBadgeTestBase {
    ScrollBadge internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContract(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestRevoke() external {
        bytes32 uid = _attest(address(badge), "", alice);

        bool isValid = eas.isAttestationValid(uid);
        assertTrue(isValid);

        _revoke(uid);
        bool isValid2 = eas.isAttestationValid(uid);
        assertTrue(isValid2);

        Attestation memory attestation = eas.getAttestation(uid);
        assertGe(attestation.revocationTime, 0);
    }
}
