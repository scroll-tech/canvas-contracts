// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {Attestation, AttestationRequest, AttestationRequestData} from "@eas/contracts/IEAS.sol";
import {EAS} from "@eas/contracts/EAS.sol";
import {EMPTY_UID, NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";

import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {ScrollBadgeAccessControl} from "../src/badge/extensions/ScrollBadgeAccessControl.sol";
import {ScrollBadgeCustomPayload} from "../src/badge/extensions/ScrollBadgeCustomPayload.sol";
import {ScrollBadgeNoExpiry} from "../src/badge/extensions/ScrollBadgeNoExpiry.sol";
import {ScrollBadgeNonRevocable} from "../src/badge/extensions/ScrollBadgeNonRevocable.sol";
import {ScrollBadgeSBT} from "../src/badge/extensions/ScrollBadgeSBT.sol";
import {ScrollBadgeSelfAttest} from "../src/badge/extensions/ScrollBadgeSelfAttest.sol";
import {ScrollBadgeSingleton} from "../src/badge/extensions/ScrollBadgeSingleton.sol";

contract TestContractBase is ScrollBadge {
    bool succeed = true;

    constructor(address resolver_) ScrollBadge(resolver_) {}

    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return "";
    }

    function onIssueBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        return super.onIssueBadge(attestation) && succeed;
    }

    function onRevokeBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        return super.onRevokeBadge(attestation) && succeed;
    }

    function baseFail() external {
        succeed = false;
    }
}

contract TestContractAccessControl is TestContractBase, ScrollBadgeAccessControl {
    constructor(address resolver_) TestContractBase(resolver_) {}

    function onIssueBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeAccessControl)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    function onRevokeBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeAccessControl)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }
}

contract ScrollBadgeAccessControlInheritanceChainTest is ScrollBadgeTestBase {
    TestContractAccessControl internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContractAccessControl(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestFails() external {
        badge.baseFail();
        vm.expectRevert(EAS.InvalidAttestation.selector);
        _attest(address(badge), "", alice);
    }

    function testRevokeFails() external {
        badge.toggleAttester(address(this), true);
        bytes32 uid = _attest(address(badge), "", alice);
        badge.baseFail();
        vm.expectRevert(EAS.InvalidRevocation.selector);
        _revoke(uid);
    }
}

contract TestContractCustomPayload is TestContractBase, ScrollBadgeCustomPayload {
    constructor(address resolver_) TestContractBase(resolver_) {}

    function onIssueBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeCustomPayload)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    function onRevokeBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeCustomPayload)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }

    function getSchema() public pure override returns (string memory) {
        return "string abc";
    }
}

contract ScrollBadgeCustomPayloadInheritanceChainTest is ScrollBadgeTestBase {
    TestContractCustomPayload internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContractCustomPayload(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestFails() external {
        badge.baseFail();
        vm.expectRevert(EAS.InvalidAttestation.selector);
        _attest(address(badge), "abc", alice);
    }

    function testRevokeFails() external {
        bytes32 uid = _attest(address(badge), "abc", alice);
        badge.baseFail();
        vm.expectRevert(EAS.InvalidRevocation.selector);
        _revoke(uid);
    }
}

contract TestContractNoExpiry is TestContractBase, ScrollBadgeNoExpiry {
    constructor(address resolver_) TestContractBase(resolver_) {}

    function onIssueBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeNoExpiry)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    function onRevokeBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeNoExpiry)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }
}

contract ScrollBadgeNoExpiryInheritanceChainTest is ScrollBadgeTestBase {
    TestContractNoExpiry internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContractNoExpiry(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestFails() external {
        badge.baseFail();
        vm.expectRevert(EAS.InvalidAttestation.selector);
        _attest(address(badge), "", alice);
    }

    function testRevokeFails() external {
        bytes32 uid = _attest(address(badge), "", alice);
        badge.baseFail();
        vm.expectRevert(EAS.InvalidRevocation.selector);
        _revoke(uid);
    }
}

contract TestContractNonRevocable is TestContractBase, ScrollBadgeNonRevocable {
    constructor(address resolver_) TestContractBase(resolver_) {}

    function onIssueBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeNonRevocable)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    function onRevokeBadge(Attestation calldata attestation)
        internal
        virtual
        override (ScrollBadge, TestContractBase)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }
}

contract ScrollBadgeNonRevocableInheritanceChainTest is ScrollBadgeTestBase {
    TestContractNonRevocable internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContractNonRevocable(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestFails() external {
        bytes memory attestationData = abi.encode(badge, "");

        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: alice,
            expirationTime: NO_EXPIRATION_TIME,
            revocable: false,
            refUID: EMPTY_UID,
            data: attestationData,
            value: 0
        });

        AttestationRequest memory _req = AttestationRequest({schema: schema, data: _attData});

        badge.baseFail();
        vm.expectRevert(EAS.InvalidAttestation.selector);
        eas.attest(_req);
    }
}

contract TestContractSBT is TestContractBase, ScrollBadgeSBT {
    constructor(address resolver_) TestContractBase(resolver_) ScrollBadgeSBT("name", "symbol") {}

    function onIssueBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeSBT)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    function onRevokeBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeSBT)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }
}

contract ScrollBadgeSBTInheritanceChainTest is ScrollBadgeTestBase {
    TestContractSBT internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContractSBT(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestFails() external {
        badge.baseFail();
        vm.expectRevert(EAS.InvalidAttestation.selector);
        _attest(address(badge), "", alice);
    }

    function testRevokeFails() external {
        bytes32 uid = _attest(address(badge), "", alice);
        badge.baseFail();
        vm.expectRevert(EAS.InvalidRevocation.selector);
        _revoke(uid);
    }
}

contract TestContractSelfAttest is TestContractBase, ScrollBadgeSelfAttest {
    constructor(address resolver_) TestContractBase(resolver_) {}

    function onIssueBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeSelfAttest)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    function onRevokeBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeSelfAttest)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }
}

contract ScrollBadgeSelfAttestInheritanceChainTest is ScrollBadgeTestBase {
    TestContractSelfAttest internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContractSelfAttest(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestFails() external {
        badge.baseFail();
        vm.expectRevert(EAS.InvalidAttestation.selector);
        _attest(address(badge), "", address(this));
    }

    function testRevokeFails() external {
        bytes32 uid = _attest(address(badge), "", address(this));
        badge.baseFail();
        vm.expectRevert(EAS.InvalidRevocation.selector);
        _revoke(uid);
    }
}

contract TestContractSingleton is TestContractBase, ScrollBadgeSingleton {
    constructor(address resolver_) TestContractBase(resolver_) {}

    function onIssueBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    function onRevokeBadge(Attestation calldata attestation)
        internal
        virtual
        override (TestContractBase, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }
}

contract ScrollBadgeSingletonInheritanceChainTest is ScrollBadgeTestBase {
    TestContractSingleton internal badge;

    function setUp() public virtual override {
        super.setUp();

        badge = new TestContractSingleton(address(resolver));
        resolver.toggleBadge(address(badge), true);
    }

    function testAttestFails() external {
        badge.baseFail();
        vm.expectRevert(EAS.InvalidAttestation.selector);
        _attest(address(badge), "", alice);
    }

    function testRevokeFails() external {
        bytes32 uid = _attest(address(badge), "", alice);
        badge.baseFail();
        vm.expectRevert(EAS.InvalidRevocation.selector);
        _revoke(uid);
    }
}
