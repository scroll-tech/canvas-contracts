// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {VmSafe} from "forge-std/Vm.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import {EAS} from "@eas/contracts/EAS.sol";
import {IEAS} from "@eas/contracts/IEAS.sol";
import {ISchemaResolver} from "@eas/contracts/resolver/ISchemaResolver.sol";
import {SchemaRegistry, ISchemaRegistry} from "@eas/contracts/SchemaRegistry.sol";

import {ITransparentUpgradeableProxy, TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {IProfileRegistry} from "../src/interfaces/IProfileRegistry.sol";
import {EmptyContract} from "../src/misc/EmptyContract.sol";
import {Profile} from "../src/profile/Profile.sol";
import {ProfileRegistry} from "../src/profile/ProfileRegistry.sol";
import {ScrollBadgeResolver} from "../src/resolver/ScrollBadgeResolver.sol";

contract ProfileRegistryTest is Test {
    error MsgValueMismatchWithMintFee();
    error DuplicatedUsername();
    error InvalidUsername();
    error ExpiredSignature();
    error InvalidSignature();
    error InvalidReferrer();
    error CallerIsNotUserProfile();
    error ImplementationNotContract();
    error ProfileAlreadyMinted();

    address private constant TREASURY_ADDRESS =
        0x1000000000000000000000000000000000000000;

    address private constant PROXY_ADMIN_ADDRESS =
        0x2000000000000000000000000000000000000000;

    ISchemaRegistry internal schemaRegistry;
    IEAS internal eas;
    ScrollBadgeResolver internal resolver;

    VmSafe.Wallet private signer;

    Profile private profileImpl;
    ProfileRegistry private profileRegistry;

    receive() external payable {}

    function setUp() public {
        schemaRegistry = new SchemaRegistry();
        eas = new EAS(schemaRegistry);
        address profileRegistryProxy = address(new TransparentUpgradeableProxy(address(new EmptyContract()), PROXY_ADMIN_ADDRESS, ""));
        resolver = new ScrollBadgeResolver(address(eas), profileRegistryProxy);

        signer = vm.createWallet(10001);

        profileImpl = new Profile(address(resolver));
        ProfileRegistry profileRegistryImpl = new ProfileRegistry();
        vm.prank(PROXY_ADMIN_ADDRESS);
        ITransparentUpgradeableProxy(profileRegistryProxy).upgradeTo(address(profileRegistryImpl));
        profileRegistry = ProfileRegistry(profileRegistryProxy);
        profileRegistry.initialize(TREASURY_ADDRESS, signer.addr, address(profileImpl));
        vm.warp(1000000);
    }

    function testInitialize() external {
        vm.expectRevert("Initializable: contract is already initialized");
        profileRegistry.initialize(address(0), address(0), address(0));
    }

    function testMint() external {
        // MsgValueMismatchWithMintFee
        vm.expectRevert(MsgValueMismatchWithMintFee.selector);
        profileRegistry.mint("x", new bytes(0));
        // should revert when invalid username: length < 4
        vm.expectRevert(InvalidUsername.selector);
        profileRegistry.mint{value: 0.001 ether}("x", new bytes(0));
        // should revert when invalid username: length > 15
        vm.expectRevert(InvalidUsername.selector);
        profileRegistry.mint{value: 0.001 ether}(
            "xxxxxyyyyyzzzzza",
            new bytes(0)
        );
        // should revert when invalid username: has characters other than a-z, A-Z, 0-9, _
        vm.expectRevert(InvalidUsername.selector);
        profileRegistry.mint{value: 0.001 ether}("xxxxx.xxxxx", new bytes(0));

        // should revert when ExpiredSignature
        uint256 deadline = block.timestamp - 1;
        bytes memory signature = _signReferralData(
            signer.privateKey,
            address(this),
            address(this),
            deadline
        );
        vm.expectRevert(ExpiredSignature.selector);
        profileRegistry.mint(
            "xxxxx",
            abi.encode(address(this), deadline, signature)
        );

        // should mint without referral and fee goes to treasury
        uint256 balanceBefore = TREASURY_ADDRESS.balance;
        assertEq(
            profileRegistry.isProfileMinted(
                profileRegistry.getProfile(address(this))
            ),
            false
        );
        assertEq(profileRegistry.isUsernameUsed("xxxxx"), false);
        profileRegistry.mint{value: 0.001 ether}("xxxxx", new bytes(0));
        assertEq(profileRegistry.isUsernameUsed("xxxxx"), true);
        assertEq(
            profileRegistry.isProfileMinted(
                profileRegistry.getProfile(address(this))
            ),
            true
        );
        uint256 balanceAfter = TREASURY_ADDRESS.balance;
        assertEq(balanceAfter - balanceBefore, 0.001 ether);

        // should revert when mint with same sender
        vm.expectRevert(ProfileAlreadyMinted.selector);
        profileRegistry.mint{value: 0.001 ether}("yyyyy", new bytes(0));

        // should revert when InvalidReferrer
        deadline = block.timestamp + 1;
        signature = _signReferralData(
            signer.privateKey + 1,
            address(1),
            address(this),
            deadline
        );
        vm.expectRevert(InvalidReferrer.selector);
        profileRegistry.mint(
            "xxxxx",
            abi.encode(address(1), deadline, signature)
        );

        // should revert when InvalidSignature
        deadline = block.timestamp + 1;
        signature = _signReferralData(
            signer.privateKey + 1,
            address(this),
            address(this),
            deadline
        );
        vm.expectRevert(InvalidSignature.selector);
        profileRegistry.mint(
            "xxxxx",
            abi.encode(address(this), deadline, signature)
        );

        // should mint with referral and fee goes to referral
        deadline = block.timestamp + 1;
        signature = _signReferralData(
            signer.privateKey,
            address(this),
            address(2),
            deadline
        );
        payable(address(2)).transfer(1 ether);
        vm.prank(address(2));
        balanceBefore = address(this).balance;
        profileRegistry.mint{value: 0.0005 ether}(
            "yyyyy",
            abi.encode(address(this), deadline, signature)
        );
        balanceAfter = address(this).balance;
        assertEq(balanceAfter - balanceBefore, 0.0005 ether);
        vm.stopPrank();

        // should revert when mint with same name
        payable(address(3)).transfer(1 ether);
        vm.prank(address(3));
        vm.expectRevert(DuplicatedUsername.selector);
        profileRegistry.mint{value: 0.001 ether}("yyyyy", new bytes(0));
        vm.stopPrank();
    }

    function testRegisterUsername() external {
        vm.expectRevert(CallerIsNotUserProfile.selector);
        profileRegistry.registerUsername("xxxx");
    }

    function testUnregisterUsername() external {
        vm.expectRevert(CallerIsNotUserProfile.selector);
        profileRegistry.unregisterUsername("xxxx");
    }

    function testBlacklistUsername() external {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(1));
        profileRegistry.blacklistUsername(new bytes32[](0));
        vm.stopPrank();

        bytes32[] memory v = new bytes32[](1);
        v[0] = keccak256("xxxxx");
        assertEq(profileRegistry.isUsernameUsed("xxxxx"), false);
        profileRegistry.blacklistUsername(v);
        assertEq(profileRegistry.isUsernameUsed("xxxxx"), true);
    }

    function testUpdateDefaultProfileAvatar(string memory newAvatar) external {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(1));
        profileRegistry.updateDefaultProfileAvatar(newAvatar);
        vm.stopPrank();

        assertEq(profileRegistry.getDefaultProfileAvatar(), "");
        profileRegistry.updateDefaultProfileAvatar(newAvatar);
        assertEq(profileRegistry.getDefaultProfileAvatar(), newAvatar);
    }

    function testUpdateProfileImplementation() external {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(1));
        profileRegistry.updateProfileImplementation(address(0));
        vm.stopPrank();

        vm.expectRevert(ImplementationNotContract.selector);
        profileRegistry.updateProfileImplementation(address(0));

        Profile newProfileImpl = new Profile(address(resolver));
        assertEq(profileRegistry.implementation(), address(profileImpl));
        profileRegistry.updateProfileImplementation(address(newProfileImpl));
        assertEq(profileRegistry.implementation(), address(newProfileImpl));
    }

    function testUpdateSigner(address newSigner) external {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(1));
        profileRegistry.updateSigner(newSigner);
        vm.stopPrank();

        assertEq(profileRegistry.signer(), signer.addr);
        profileRegistry.updateSigner(newSigner);
        assertEq(profileRegistry.signer(), newSigner);
    }

    function testUpdateTreasury(address newTreasury) external {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(address(1));
        profileRegistry.updateTreasury(newTreasury);
        vm.stopPrank();

        assertEq(profileRegistry.treasury(), TREASURY_ADDRESS);
        profileRegistry.updateTreasury(newTreasury);
        assertEq(profileRegistry.treasury(), newTreasury);
    }

    function _signReferralData(
        uint256 privateKey,
        address referrer,
        address owner,
        uint256 deadline
    ) private view returns (bytes memory) {
        bytes32 TYPE_HASH = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                TYPE_HASH,
                keccak256("ProfileRegistry"),
                keccak256("1"),
                block.chainid,
                address(profileRegistry)
            )
        );
        bytes32 REFERRAL_TYPEHASH = keccak256(
            "Referral(address referrer,address owner,uint256 deadline)"
        );
        bytes32 structHash = keccak256(
            abi.encode(REFERRAL_TYPEHASH, referrer, owner, deadline)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }
}
