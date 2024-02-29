// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {EMPTY_UID, NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";
import {
    IEAS,
    Attestation,
    AttestationRequest,
    AttestationRequestData,
    RevocationRequest,
    RevocationRequestData
} from "@eas/contracts/IEAS.sol";
import {EAS} from "@eas/contracts/EAS.sol";
import {ISchemaResolver} from "@eas/contracts/resolver/ISchemaResolver.sol";

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {IScrollBadge} from "../src/interfaces/IScrollBadge.sol";
import {
    AttestationExpired,
    AttestationNotFound,
    AttestationRevoked,
    AttestationBadgeMismatch,
    AttestationSchemaMismatch,
    BadgeNotFound,
    BadgeNotAllowed,
    Unauthorized
} from "../src/Errors.sol";

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

    function testAttestRevoke(address recipient) external {
        bytes32 uid = _attest(address(badge), "", recipient);

        bool isValid = eas.isAttestationValid(uid);
        assertTrue(isValid);

        bool hasBadge = badge.hasBadge(recipient);
        assertTrue(hasBadge);

        _revoke(uid);
        bool isValid2 = eas.isAttestationValid(uid);
        assertTrue(isValid2);

        Attestation memory attestation = eas.getAttestation(uid);
        assertGe(attestation.revocationTime, 0);

        bool hasBadge2 = badge.hasBadge(recipient);
        assertFalse(hasBadge2);
    }

    function testAttestMultiple(address recipient, uint8 times) external {
        hevm.assume(times < 10);

        bytes32[] memory uids = new bytes32[](times);

        for (uint256 i = 0; i < times; i++) {
            bytes32 uid = _attest(address(badge), "", recipient);
            uids[i] = uid;
        }

        for (uint256 i = 0; i < times; i++) {
            bool hasBadge = badge.hasBadge(recipient);
            assertTrue(hasBadge);

            _revoke(uids[i]);
        }

        bool hasBadge2 = badge.hasBadge(recipient);
        assertFalse(hasBadge2);
    }

    function testIssueBadgeOnlyResolver(address notResolver, Attestation memory attestation) external {
        hevm.assume(notResolver != address(resolver));
        hevm.prank(notResolver);
        hevm.expectRevert(Unauthorized.selector);
        badge.issueBadge(attestation);
    }

    function testRevokeBadgeOnlyResolver(address notResolver, Attestation memory attestation) external {
        hevm.assume(notResolver != address(resolver));
        hevm.prank(notResolver);
        hevm.expectRevert(Unauthorized.selector);
        badge.revokeBadge(attestation);
    }

    function testGetBadge() external {
        bytes32 uid = _attest(address(badge), "", alice);
        Attestation memory attestation = badge.getAndValidateBadge(uid);
        assertEq(attestation.uid, uid);
    }

    function testGetWrongBadgeFails() external {
        ScrollBadge otherBadge = new TestContract(address(resolver));
        resolver.toggleBadge(address(otherBadge), true);
        bytes memory data = abi.encode(otherBadge, "");

        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: alice,
            expirationTime: NO_EXPIRATION_TIME,
            revocable: true,
            refUID: EMPTY_UID,
            data: data,
            value: 0
        });

        AttestationRequest memory _req = AttestationRequest({schema: schema, data: _attData});

        bytes32 uid = eas.attest(_req);

        hevm.expectRevert(abi.encodeWithSelector(AttestationBadgeMismatch.selector, uid));
        badge.getAndValidateBadge(uid);
    }
}
