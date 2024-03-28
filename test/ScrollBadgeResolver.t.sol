// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {EMPTY_UID, NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";
import {EAS} from "@eas/contracts/EAS.sol";
import {ISchemaResolver} from "@eas/contracts/resolver/ISchemaResolver.sol";

import {
    Attestation,
    AttestationRequest,
    AttestationRequestData,
    RevocationRequest,
    RevocationRequestData
} from "@eas/contracts/IEAS.sol";

import {IScrollBadge, ScrollBadge} from "../src/badge/ScrollBadge.sol";

import {
    AttestationExpired,
    AttestationNotFound,
    AttestationRevoked,
    AttestationSchemaMismatch,
    BadgeNotAllowed,
    BadgeNotFound,
    UnknownSchema
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

    function testResolverToggleBadgeOnlyOwner(address notOwner, address anyBadge, bool enable) external {
        vm.assume(notOwner != address(this));
        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        resolver.toggleBadge(anyBadge, enable);
    }

    function testResolverToggleWhitelistOnlyOwner(address notOwner, bool enable) external {
        vm.assume(notOwner != address(this));
        vm.prank(notOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        resolver.toggleWhitelist(enable);
    }

    function testGetBadge() external {
        bytes32 uid = _attest(address(badge), "", alice);
        Attestation memory attestation = resolver.getAndValidateBadge(uid);
        assertEq(attestation.uid, uid);
    }

    function testGetNonExistentBadgeFails(bytes32 uid) external {
        vm.expectRevert(abi.encodeWithSelector(AttestationNotFound.selector, uid));
        resolver.getAndValidateBadge(uid);
    }

    function testGetWrongSchemaBadgeFails() external {
        bytes32 otherSchema = registry.register("address badge", ISchemaResolver(address(0)), true);

        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: alice,
            expirationTime: NO_EXPIRATION_TIME,
            revocable: true,
            refUID: EMPTY_UID,
            data: abi.encode(badge, ""),
            value: 0
        });

        AttestationRequest memory _req = AttestationRequest({schema: otherSchema, data: _attData});
        bytes32 uid = eas.attest(_req);

        vm.expectRevert(abi.encodeWithSelector(AttestationSchemaMismatch.selector, uid));
        resolver.getAndValidateBadge(uid);
    }

    function testGetExpiredBadgenFails() external {
        uint64 expirationTime = uint64(block.timestamp) + 1;

        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: alice,
            expirationTime: expirationTime,
            revocable: true,
            refUID: EMPTY_UID,
            data: abi.encode(badge, ""),
            value: 0
        });

        AttestationRequest memory _req = AttestationRequest({schema: schema, data: _attData});
        bytes32 uid = eas.attest(_req);

        vm.warp(expirationTime);

        vm.expectRevert(abi.encodeWithSelector(AttestationExpired.selector, uid));
        resolver.getAndValidateBadge(uid);
    }

    function testGetRevokedBadgeFails() external {
        bytes32 uid = _attest(address(badge), "", alice);
        _revoke(uid);

        vm.expectRevert(abi.encodeWithSelector(AttestationRevoked.selector, uid));
        resolver.getAndValidateBadge(uid);
    }

    // test only EAS can call

    function testAttestRejectPayment(uint256 value) external {
        vm.assume(value > 0);
        vm.deal(address(this), value);

        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: alice,
            expirationTime: NO_EXPIRATION_TIME,
            revocable: true,
            refUID: EMPTY_UID,
            data: abi.encode(badge, ""),
            value: value
        });

        AttestationRequest memory _req = AttestationRequest({schema: schema, data: _attData});

        vm.expectRevert(EAS.NotPayable.selector);
        eas.attest{value: value}(_req);
    }

    function testAttestRejectOtherSchema() external {
        // register other schema with the same resolver
        bytes32 otherSchema = registry.register("address badge", resolver, true);

        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: alice,
            expirationTime: NO_EXPIRATION_TIME,
            revocable: true,
            refUID: EMPTY_UID,
            data: abi.encode(badge, ""),
            value: 0
        });

        AttestationRequest memory _req = AttestationRequest({schema: otherSchema, data: _attData});

        vm.expectRevert(UnknownSchema.selector);
        eas.attest(_req);
    }

    function testAttestRejectInvalidPayload(bytes memory randomPayload) external {
        // note: randomPayload != abi.encode(badge, _)

        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: alice,
            expirationTime: NO_EXPIRATION_TIME,
            revocable: true,
            refUID: EMPTY_UID,
            data: randomPayload,
            value: 0
        });

        AttestationRequest memory _req = AttestationRequest({schema: schema, data: _attData});

        // fail on abi.decode, no error
        vm.expectRevert(bytes(""));
        eas.attest(_req);
    }

    function testAttestRejectNonContractBadge(address otherBadge) external {
        vm.assume(otherBadge != address(badge));
        vm.assume(otherBadge.code.length == 0);

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

        vm.expectRevert(abi.encodeWithSelector(BadgeNotFound.selector, otherBadge));
        eas.attest(_req);
    }

    function testAttestRejectUnknownBadge() external {
        ScrollBadge otherBadge = new TestContract(address(resolver));
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

        vm.expectRevert(abi.encodeWithSelector(BadgeNotAllowed.selector, otherBadge));
        eas.attest(_req);
    }

    function testAttestRejectIncorrectBadgeContract() external {
        address otherBadge = address(this); // this is not a badge
        resolver.toggleBadge(otherBadge, true);
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

        // fail on issueBadge call, no error
        vm.expectRevert(bytes(""));
        eas.attest(_req);
    }

    function testRevokeRejectPayment(uint256 value) external {
        vm.assume(value > 0);
        vm.deal(address(this), value);

        bytes32 uid = _attest(address(badge), "", alice);

        RevocationRequestData memory _data = RevocationRequestData({uid: uid, value: value});

        RevocationRequest memory _req = RevocationRequest({schema: schema, data: _data});

        vm.expectRevert(EAS.NotPayable.selector);
        eas.revoke{value: value}(_req);
    }
}
