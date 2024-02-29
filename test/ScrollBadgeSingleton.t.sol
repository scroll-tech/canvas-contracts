// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {EMPTY_UID, NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";
import {
    IEAS,
    Attestation,
    AttestationRequest,
    AttestationRequestData,
    RevocationRequest,
    RevocationRequestData
} from "@eas/contracts/IEAS.sol";

import {ScrollBadgeSingleton} from "../src/badge/extensions/ScrollBadgeSingleton.sol";
import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {SingletonBadge, InvalidPayload, RevocationDisabled} from "../src/Errors.sol";

contract TestContract is ScrollBadgeSingleton {
    constructor(address resolver_) ScrollBadge(resolver_) {}

    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return "";
    }
}

contract ScrollBadgeSingletonTest is ScrollBadgeTestBase {
    TestContract internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContract(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestOnce(address recipient) external {
        _attest(address(badge), "", recipient);
    }

    function testAttestRevokeAttest(address recipient) external {
        bytes32 uid = _attest(address(badge), "", recipient);
        _revoke(uid);
        _attest(address(badge), "", recipient);
    }

    function testAttestTwiceFails(address recipient) external {
        _attest(address(badge), "", recipient);

        hevm.expectRevert(SingletonBadge.selector);
        _attest(address(badge), "", recipient);
    }
}
