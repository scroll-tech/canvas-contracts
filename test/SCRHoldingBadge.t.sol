// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";

import {EAS} from "@eas/contracts/EAS.sol";
import {EMPTY_UID, NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";
import {SchemaRegistry, ISchemaRegistry} from "@eas/contracts/SchemaRegistry.sol";
import {IEAS, Attestation, AttestationRequest, AttestationRequestData, RevocationRequest, RevocationRequestData} from "@eas/contracts/IEAS.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {ITransparentUpgradeableProxy, TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {EmptyContract} from "../src/misc/EmptyContract.sol";
import {Profile} from "../src/profile/Profile.sol";
import {ProfileRegistry} from "../src/profile/ProfileRegistry.sol";
import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {ScrollBadgeResolver} from "../src/resolver/ScrollBadgeResolver.sol";
import {SCRHoldingBadge} from "../src/badge/examples/SCRHoldingBadge.sol";

import {encodeBadgeData} from "../src/Common.sol";
import {AttestationNotFound} from "../src/Errors.sol";

contract Token is MockERC20 {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract SCRHoldingBadgeTest is Test {
    address private constant TREASURY_ADDRESS = 0x1000000000000000000000000000000000000000;

    address private constant PROXY_ADMIN_ADDRESS = 0x2000000000000000000000000000000000000000;

    ISchemaRegistry private schemaRegistry;
    IEAS private eas;
    ScrollBadgeResolver private resolver;
    SCRHoldingBadge private badge;
    Token private token;

    Profile private profileImpl;
    ProfileRegistry private profileRegistry;
    Profile private profile;

    receive() external payable {}

    function setUp() public {
        schemaRegistry = new SchemaRegistry();
        eas = new EAS(schemaRegistry);
        address profileRegistryProxy = address(
            new TransparentUpgradeableProxy(address(new EmptyContract()), PROXY_ADMIN_ADDRESS, "")
        );

        address resolverImpl = address(new ScrollBadgeResolver(address(eas), profileRegistryProxy));
        address resolverProxy = address(new TransparentUpgradeableProxy(resolverImpl, PROXY_ADMIN_ADDRESS, ""));
        resolver = ScrollBadgeResolver(payable(resolverProxy));
        resolver.initialize();

        token = new Token();
        badge = new SCRHoldingBadge(address(resolver), "xx", address(token));
        resolver.updateSelfAttestedBadge(0, address(badge));

        profileImpl = new Profile(address(resolver));
        ProfileRegistry profileRegistryImpl = new ProfileRegistry();
        vm.prank(PROXY_ADMIN_ADDRESS);
        ITransparentUpgradeableProxy(profileRegistryProxy).upgradeTo(address(profileRegistryImpl));
        profileRegistry = ProfileRegistry(profileRegistryProxy);
        profileRegistry.initialize(TREASURY_ADDRESS, TREASURY_ADDRESS, address(profileImpl));
        profile = Profile(profileRegistry.mint{value: 0.001 ether}("xxxxx", new bytes(0)));
    }

    function testInitialize() external view {
        // from ScrollBadge
        assertEq(badge.resolver(), address(resolver));

        // from ScrollBadgeCustomPayload
        assertEq(badge.getSchema(), "uint256 level");

        // from ScrollBadgeDefaultURI
        assertEq(badge.defaultBadgeURI(), "xx");
        assertEq(badge.badgeTokenURI(0), "xx");

        // from SCRHoldingBadge
        assertEq(badge.scr(), address(token));
        assertEq(badge.getBadgeId(), 0);

        // in ScrollBadgeResolver
        assertEq(resolver.selfAttestedBadges(0), address(badge));
    }

    function testIssueBadge(Attestation calldata attestation) external {
        vm.prank(address(resolver));
        assertEq(false, badge.issueBadge(attestation));
    }

    function testRevokeBadge(Attestation calldata attestation) external {
        vm.prank(address(resolver));
        assertEq(false, badge.revokeBadge(attestation));
    }

    function testGetAndValidateBadge() external {
        bytes32 uid;
        // badge id nonzero
        assembly {
            uid := 0
            uid := or(uid, shl(1, 160))
        }
        vm.expectRevert(abi.encodePacked(AttestationNotFound.selector, uid));
        badge.getAndValidateBadge(uid);

        // customized data nonzero
        assembly {
            uid := 0
            uid := or(uid, shl(1, 192))
        }
        vm.expectRevert(abi.encodePacked(AttestationNotFound.selector, uid));
        badge.getAndValidateBadge(uid);

        // no scr
        assembly {
            uid := address()
        }
        token.mint(address(this), 1 ether - 1);
        vm.expectRevert(abi.encodePacked(AttestationNotFound.selector, uid));
        badge.getAndValidateBadge(uid);

        // succeed
        assembly {
            uid := address()
        }
        token.mint(address(this), 1 ether);
        Attestation memory attestation = badge.getAndValidateBadge(uid);
        assertEq(attestation.uid, uid);
        assertEq(attestation.schema, resolver.schema());
        assertEq(attestation.time, block.timestamp);
        assertEq(attestation.expirationTime, 0);
        assertEq(attestation.refUID, bytes32(0));
        assertEq(attestation.recipient, address(this));
        assertEq(attestation.attester, address(badge));
        assertEq(attestation.revocable, false);
        assertEq(attestation.data, encodeBadgeData(address(badge), abi.encode(uint256(1))));
    }

    function testBadgeTokenURI(address user, uint256 amount) external {
        vm.assume(amount >= 1 ether);
        vm.assume(user != address(0));

        uint256 level;
        if (amount >= 1 ether) level = 1;
        if (amount >= 10 ether) level = 2;
        if (amount >= 100 ether) level = 3;
        if (amount >= 1000 ether) level = 4;
        if (amount >= 10000 ether) level = 5;
        if (amount >= 100000 ether) level = 6;

        token.mint(user, amount);
        bytes32 uid;
        assembly {
            uid := user
        }
        assertEq(badge.badgeTokenURI(uid), string(abi.encodePacked("xx", Strings.toString(level), ".json")));
    }

    function testHasBadge(address user, uint256 amount) external {
        vm.assume(user != address(0));

        token.mint(user, amount);
        assertEq(badge.hasBadge(user), amount >= 1 ether);
    }

    function testGetAttestationInvalidUID(address user, uint96 base) external view {
        vm.assume(base > 0);
        bytes32 uid;
        assembly {
            uid := or(user, shl(160, base))
        }
        Attestation memory attestation = badge.getAttestation(uid);
        assertEq(attestation.uid, bytes32(0));
        assertEq(attestation.schema, "");
        assertEq(attestation.time, 0);
        assertEq(attestation.expirationTime, 0);
        assertEq(attestation.refUID, bytes32(0));
        assertEq(attestation.recipient, address(0));
        assertEq(attestation.attester, address(0));
        assertEq(attestation.revocable, false);
        assertEq(attestation.data, "");
    }

    function testGetAttestationNoSCR(address user, uint256 amount) external {
        amount = bound(amount, 0, 1 ether - 1);
        token.mint(user, amount);
        bytes32 uid;
        assembly {
            uid := user
        }
        Attestation memory attestation = badge.getAttestation(uid);
        _validateAttestation(attestation, user);
    }

    function testGetAttestation(address user, uint256 amount, uint256 amount2) external {
        vm.assume(amount >= 1 ether);
        vm.assume(user != address(0));
        amount2 = bound(amount2, 0, amount);

        uint256 level;
        if (amount >= 1 ether) level = 1;
        if (amount >= 10 ether) level = 2;
        if (amount >= 100 ether) level = 3;
        if (amount >= 1000 ether) level = 4;
        if (amount >= 10000 ether) level = 5;
        if (amount >= 100000 ether) level = 6;

        token.mint(user, amount);
        bytes32 uid;
        assembly {
            uid := user
        }
        Attestation memory attestation = badge.getAttestation(uid);
        _validateAttestation(attestation, user);

        // transfer
        vm.prank(user);
        token.transfer(address(this), amount2);
        attestation = badge.getAttestation(uid);
        _validateAttestation(attestation, user);
    }

    function _validateAttestation(Attestation memory attestation, address user) internal view {
        uint256 amount = token.balanceOf(user);
        if (amount < 1 ether) {
            assertEq(attestation.uid, bytes32(0));
            assertEq(attestation.schema, "");
            assertEq(attestation.time, 0);
            assertEq(attestation.expirationTime, 0);
            assertEq(attestation.refUID, bytes32(0));
            assertEq(attestation.recipient, address(0));
            assertEq(attestation.attester, address(0));
            assertEq(attestation.revocable, false);
            assertEq(attestation.data, "");
        } else {
            bytes32 uid;
            assembly {
                uid := user
            }
            uint256 level;
            if (amount >= 1 ether) level = 1;
            if (amount >= 10 ether) level = 2;
            if (amount >= 100 ether) level = 3;
            if (amount >= 1000 ether) level = 4;
            if (amount >= 10000 ether) level = 5;
            if (amount >= 100000 ether) level = 6;
            assertEq(attestation.uid, uid);
            assertEq(attestation.schema, resolver.schema());
            assertEq(attestation.time, block.timestamp);
            assertEq(attestation.expirationTime, 0);
            assertEq(attestation.refUID, bytes32(0));
            assertEq(attestation.recipient, user);
            assertEq(attestation.attester, address(badge));
            assertEq(attestation.revocable, false);
            assertEq(attestation.data, encodeBadgeData(address(badge), abi.encode(level)));
        }
    }
}
