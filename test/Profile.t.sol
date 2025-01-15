// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";

import {EAS} from "@eas/contracts/EAS.sol";
import {EMPTY_UID, NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";
import {SchemaRegistry, ISchemaRegistry} from "@eas/contracts/SchemaRegistry.sol";

import {
    IEAS,
    AttestationRequest,
    AttestationRequestData,
    RevocationRequest,
    RevocationRequestData
} from "@eas/contracts/IEAS.sol";

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {EmptyContract} from "../src/misc/EmptyContract.sol";
import {Profile} from "../src/profile/Profile.sol";
import {ProfileRegistryMintable} from "../src/profile/ProfileRegistry.sol";
import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {ScrollBadgeResolver} from "../src/resolver/ScrollBadgeResolver.sol";

contract TestBadge is ScrollBadge {
    constructor(address resolver_) ScrollBadge(resolver_) {}

    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return "";
    }
}

contract TestERC721 is ERC721 {
    constructor() ERC721("xx", "yy") {}

    function mint(address to, uint256 id) external {
        _mint(to, id);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "testBaseURI/";
    }
}

contract ProfileRegistryTest is Test {
    error AttestationOwnerMismatch(bytes32 uid);
    error BadgeCountReached();
    error DuplicatedUsername();
    error InvalidUsername();
    error TokenNotOwnedByUser(address token, uint256 tokenId);
    error Unauthorized();

    event AttachBadge(bytes32 indexed uid);
    event DetachBadge(bytes32 indexed uid);
    event ChangeUsername(string oldUsername, string newUsername);
    event ChangeAvatar(address oldToken, uint256 oldTokenId, address newToken, uint256 newTokenId);
    event ReorderBadges(uint256 oldOrder, uint256 newOrder);

    address internal constant attester = address(1);

    address private constant TREASURY_ADDRESS = 0x1000000000000000000000000000000000000000;

    address private constant PROXY_ADMIN_ADDRESS = 0x2000000000000000000000000000000000000000;

    ISchemaRegistry private schemaRegistry;
    IEAS private eas;
    ScrollBadgeResolver private resolver;
    ScrollBadge private badge;

    Profile private profileImpl;
    ProfileRegistryMintable private profileRegistry;
    Profile private profile;

    receive() external payable {}

    function setUp() public {
        schemaRegistry = new SchemaRegistry();
        eas = new EAS(schemaRegistry);
        address profileRegistryProxy =
            address(new TransparentUpgradeableProxy(address(new EmptyContract()), PROXY_ADMIN_ADDRESS, ""));

        address resolverImpl = address(new ScrollBadgeResolver(address(eas), profileRegistryProxy));
        address resolverProxy = address(new TransparentUpgradeableProxy(resolverImpl, PROXY_ADMIN_ADDRESS, ""));
        resolver = ScrollBadgeResolver(payable(resolverProxy));
        resolver.initialize();

        badge = new TestBadge(address(resolver));
        resolver.toggleBadge(address(badge), true);

        profileImpl = new Profile(address(resolver));
        ProfileRegistryMintable profileRegistryImpl = new ProfileRegistryMintable();
        vm.prank(PROXY_ADMIN_ADDRESS);
        ITransparentUpgradeableProxy(profileRegistryProxy).upgradeTo(address(profileRegistryImpl));
        profileRegistry = ProfileRegistryMintable(profileRegistryProxy);
        profileRegistry.initialize(TREASURY_ADDRESS, TREASURY_ADDRESS, address(profileImpl));
        profile = Profile(profileRegistry.mint{value: 0.001 ether}("xxxxx", new bytes(0)));
    }

    function testInitialize() external {
        vm.expectRevert("Initializable: contract is already initialized");
        profile.initialize(address(0), "");
    }

    function testAttach() external {
        vm.prank(address(1));
        vm.expectRevert(Unauthorized.selector);
        profile.attach(new bytes32[](0));
        vm.stopPrank();

        // attach two badges
        bytes32 uid0 = _attest(address(badge), "1", address(this));
        bytes32 uid1 = _attest(address(badge), "2", address(this));
        bytes32[] memory uids = new bytes32[](2);
        uids[0] = uid0;
        uids[1] = uid1;
        vm.expectEmit(false, false, false, true, address(profile));
        emit AttachBadge(uid0);
        vm.expectEmit(false, false, false, true, address(profile));
        emit AttachBadge(uid1);
        profile.attach(uids);
        bytes32[] memory badges = profile.getAttachedBadges();
        assertEq(badges.length, 2);
        assertEq(badges[0], uid0);
        assertEq(badges[1], uid1);
        badges = profile.getValidBadges();
        assertEq(badges.length, 2);
        assertEq(badges[0], uid0);
        assertEq(badges[1], uid1);
        uint256[] memory orders = profile.getBadgeOrder();
        assertEq(orders.length, 2);
        assertEq(orders[0], 1);
        assertEq(orders[1], 2);

        // attach again, no op
        vm.expectEmit(false, false, false, true, address(profile));
        emit AttachBadge(uid0);
        vm.expectEmit(false, false, false, true, address(profile));
        emit AttachBadge(uid1);
        profile.attach(uids);
        badges = profile.getAttachedBadges();
        assertEq(badges.length, 2);
        assertEq(badges[0], uid0);
        assertEq(badges[1], uid1);
        badges = profile.getValidBadges();
        assertEq(badges.length, 2);
        assertEq(badges[0], uid0);
        assertEq(badges[1], uid1);

        // revoke one
        _revoke(uid0);
        badges = profile.getValidBadges();
        assertEq(badges.length, 1);
        assertEq(badges[0], uid1);
    }

    function testAttachOne() external {
        // revert when not owner
        vm.prank(address(1));
        vm.expectRevert(Unauthorized.selector);
        _attachOne(bytes32(0));

        // revert when invalid badge
        bytes32 invalidUID = _attest(address(badge), "invalidUID", address(badge));
        vm.expectRevert(abi.encodeWithSelector(AttestationOwnerMismatch.selector, invalidUID));
        _attachOne(invalidUID);

        vm.startPrank(attester);
        bytes32 uid0 = _attest(address(badge), "1", address(this));
        bytes32 uid1 = _attest(address(badge), "2", address(this));
        vm.stopPrank();
        // attach one badge
        _attachOne(uid0);
        bytes32[] memory badges = profile.getAttachedBadges();
        assertEq(badges.length, 1);
        assertEq(badges[0], uid0);
        badges = profile.getValidBadges();
        assertEq(badges.length, 1);
        assertEq(badges[0], uid0);
        uint256[] memory orders = profile.getBadgeOrder();
        assertEq(orders.length, 1);
        assertEq(orders[0], 1);

        // attach another badge
        _attachOne(uid1);
        badges = profile.getAttachedBadges();
        assertEq(badges.length, 2);
        assertEq(badges[0], uid0);
        assertEq(badges[1], uid1);
        badges = profile.getValidBadges();
        assertEq(badges.length, 2);
        assertEq(badges[0], uid0);
        assertEq(badges[1], uid1);
        orders = profile.getBadgeOrder();
        assertEq(orders.length, 2);
        assertEq(orders[0], 1);
        assertEq(orders[1], 2);

        // attach 46 badges
        for (uint256 i = 1; i <= 46; ++i) {
            vm.startPrank(attester);
            bytes32 uid = _attest(address(badge), abi.encodePacked(i), address(this));
            vm.stopPrank();
            _attachOne(uid);
        }
        badges = profile.getAttachedBadges();
        assertEq(badges.length, 48);
        badges = profile.getValidBadges();
        assertEq(badges.length, 48);
        orders = profile.getBadgeOrder();
        assertEq(orders.length, 48);
        for (uint256 j = 0; j < orders.length; ++j) {
            assertEq(orders[j], j + 1);
        }

        // revert exceed maximum
        bytes32 badgeCountReachedUID = _attest(address(badge), "BadgeCountReached", address(this));
        vm.expectRevert(BadgeCountReached.selector);
        _attachOne(badgeCountReachedUID);
    }

    function testDetach() external {
        // revert when not owner
        vm.prank(address(1));
        vm.expectRevert(Unauthorized.selector);
        profile.detach(new bytes32[](0));
        vm.stopPrank();

        // attach 10 badges
        for (uint256 i = 1; i <= 10; ++i) {
            bytes32 uid = _attest(address(badge), abi.encodePacked(i), address(this));
            bytes32[] memory uids = new bytes32[](1);
            uids[0] = uid;
            profile.attach(uids);
        }

        // current order is: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
        bytes32[] memory originalBadges = profile.getAttachedBadges();
        // detach 6, order would be: 1, 2, 3, 4, 5, 9, 6, 7, 8
        bytes32[] memory detachBadges = new bytes32[](1);
        detachBadges[0] = originalBadges[5];
        vm.expectEmit(false, false, false, true, address(profile));
        emit DetachBadge(originalBadges[5]);
        profile.detach(detachBadges);
        bytes32[] memory badges = profile.getAttachedBadges();
        assertEq(badges.length, 9);
        uint256[] memory orders = profile.getBadgeOrder();
        assertEq(orders.length, 9);
        assertEq(orders[0], 1);
        assertEq(orders[1], 2);
        assertEq(orders[2], 3);
        assertEq(orders[3], 4);
        assertEq(orders[4], 5);
        assertEq(orders[5], 9);
        assertEq(orders[6], 6);
        assertEq(orders[7], 7);
        assertEq(orders[8], 8);

        // detach 1 2 3 4, order would be: 4, 3, 2, 5, 1
        detachBadges = new bytes32[](4);
        detachBadges[0] = badges[0];
        detachBadges[1] = badges[1];
        detachBadges[2] = badges[2];
        detachBadges[3] = badges[3];
        vm.expectEmit(false, false, false, true, address(profile));
        emit DetachBadge(badges[0]);
        vm.expectEmit(false, false, false, true, address(profile));
        emit DetachBadge(badges[1]);
        vm.expectEmit(false, false, false, true, address(profile));
        emit DetachBadge(badges[2]);
        vm.expectEmit(false, false, false, true, address(profile));
        emit DetachBadge(badges[3]);
        profile.detach(detachBadges);
        badges = profile.getAttachedBadges();
        assertEq(badges.length, 5);
        orders = profile.getBadgeOrder();
        assertEq(orders.length, 5);
        assertEq(orders[0], 4);
        assertEq(orders[1], 3);
        assertEq(orders[2], 2);
        assertEq(orders[3], 5);
        assertEq(orders[4], 1);

        // detach all
        profile.detach(badges);
        badges = profile.getAttachedBadges();
        assertEq(badges.length, 0);
        orders = profile.getBadgeOrder();
        assertEq(orders.length, 0);
    }

    function testReorderBadges(uint256 count, uint256 encoding) external {
        count = bound(count, 1, 42);
        // revert when not owner
        vm.prank(address(1));
        vm.expectRevert(Unauthorized.selector);
        profile.reorderBadges(new uint256[](0));
        vm.stopPrank();

        // attach count badges
        for (uint256 i = 1; i <= count; ++i) {
            bytes32 uid = _attest(address(badge), abi.encodePacked(i), address(this));
            bytes32[] memory uids = new bytes32[](1);
            uids[0] = uid;
            profile.attach(uids);
        }

        uint256[] memory orders = new uint256[](count);
        for (uint256 i = 0; i < count; ++i) {
            orders[i] = encoding % 64;
            encoding >>= 6;
        }
        uint256 mask;
        for (uint256 i = 0; i < count; ++i) {
            uint256 index = type(uint256).max;
            for (uint256 j = 0; j < count; ++j) {
                if ((mask >> j) & 1 > 0) continue;
                if (index == type(uint256).max || orders[j] < orders[index]) {
                    index = j;
                }
            }
            orders[index] = i + 1;
            mask |= 1 << index;
        }

        profile.reorderBadges(orders);
        uint256[] memory badgeOrders = profile.getBadgeOrder();
        assertEq(badgeOrders.length, count);
        for (uint256 i = 0; i < count; ++i) {
            assertEq(badgeOrders[i], orders[i]);
        }

        // attach one more badge
        bytes32 newUid = _attest(address(badge), "", address(this));
        bytes32[] memory newUids = new bytes32[](1);
        newUids[0] = newUid;
        profile.attach(newUids);

        badgeOrders = profile.getBadgeOrder();
        assertEq(badgeOrders.length, count + 1);
        for (uint256 i = 0; i < count; ++i) {
            // the order of the previous badges did not change
            assertEq(badgeOrders[i], orders[i]);
        }
        assertEq(badgeOrders[count], count + 1);
    }

    function testChangeUsername() external {
        // revert when not owner
        vm.prank(address(1));
        vm.expectRevert(Unauthorized.selector);
        profile.changeUsername("");
        vm.stopPrank();

        // should revert when invalid username: length < 4
        vm.expectRevert(InvalidUsername.selector);
        profile.changeUsername("x");
        // should revert when invalid username: length > 15
        vm.expectRevert(InvalidUsername.selector);
        profile.changeUsername("xxxxxyyyyyzzzzza");
        // should revert when invalid username: has characters other than a-z, A-Z, 0-9, _
        vm.expectRevert(InvalidUsername.selector);
        profile.changeUsername("xxxxx.xxxxx");

        // should revert when DuplicatedUsername
        bytes32[] memory hashes = new bytes32[](1);
        hashes[0] = keccak256("yyyyy");
        profileRegistry.blacklistUsername(hashes);
        vm.expectRevert(DuplicatedUsername.selector);
        profile.changeUsername("yyyyy");

        // succeed
        assertEq(profile.username(), "xxxxx");
        vm.expectEmit(false, false, false, true, address(profile));
        emit ChangeUsername("xxxxx", "zzzzz");
        profile.changeUsername("zzzzz");
        assertEq(profile.username(), "zzzzz");
    }

    function testChangeAvatar() external {
        // revert when not owner
        vm.prank(address(1));
        vm.expectRevert(Unauthorized.selector);
        profile.changeAvatar(address(0), 0);
        vm.stopPrank();

        TestERC721 token = new TestERC721();
        token.mint(address(this), 1);
        token.mint(address(badge), 2);
        profileRegistry.updateDefaultProfileAvatar("123");

        // revert, token not owned
        vm.expectRevert(abi.encodeWithSelector(TokenNotOwnedByUser.selector, address(token), 2));
        profile.changeAvatar(address(token), 2);

        // succeed
        assertEq(profile.getAvatar(), "123");
        vm.expectEmit(false, false, false, true, address(profile));
        emit ChangeAvatar(address(0), 0, address(token), 1);
        profile.changeAvatar(address(token), 1);
        assertEq(profile.getAvatar(), "testBaseURI/1");

        // transfer token
        token.transferFrom(address(this), address(badge), 1);
        assertEq(profile.getAvatar(), "123");
    }

    function testAutoAttach() external {
        bytes32[] memory badges = profile.getAttachedBadges();
        assertEq(badges.length, 0);

        vm.prank(address(this));
        _attest(address(badge), "1", address(this));

        badges = profile.getAttachedBadges();
        assertEq(badges.length, 1);
    }

    function _attachOne(bytes32 uid) private {
        bytes32[] memory uids = new bytes32[](1);
        uids[0] = uid;
        profile.attach(uids);
    }

    function _attest(address _badge, bytes memory payload, address recipient) internal returns (bytes32) {
        bytes memory attestationData = abi.encode(_badge, payload);
        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: recipient,
            expirationTime: NO_EXPIRATION_TIME,
            revocable: true,
            refUID: EMPTY_UID,
            data: attestationData,
            value: 0
        });
        AttestationRequest memory _req = AttestationRequest({schema: resolver.schema(), data: _attData});
        return eas.attest(_req);
    }

    function _revoke(bytes32 uid) internal {
        RevocationRequestData memory _data = RevocationRequestData({uid: uid, value: 0});
        RevocationRequest memory _req = RevocationRequest({schema: resolver.schema(), data: _data});
        eas.revoke(_req);
    }
}
