// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {EAS} from "@eas/contracts/EAS.sol";

import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {EmptyContract} from "../src/misc/EmptyContract.sol";
import {Profile} from "../src/profile/Profile.sol";
import {ProfileRegistry} from "../src/profile/ProfileRegistry.sol";
import {ScrollBadgeResolver} from "../src/resolver/ScrollBadgeResolver.sol";

contract DeployCanvasContracts is Script {
    uint256 DEPLOYER_PRIVATE_KEY = vm.envUint("DEPLOYER_PRIVATE_KEY");

    address SIGNER_ADDRESS = vm.envAddress("SIGNER_ADDRESS");
    address TREASURY_ADDRESS = vm.envAddress("TREASURY_ADDRESS");

    address EAS_ADDRESS = vm.envAddress("EAS_ADDRESS");

    function run() external {
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);

        // deploy proxy admin
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        // deploy profile registry placeholder
        address placeholder = address(new EmptyContract());
        address profileRegistryProxy = address(new TransparentUpgradeableProxy(placeholder, address(proxyAdmin), ""));

        // deploy Scroll badge resolver
        address resolverImpl = address(new ScrollBadgeResolver(EAS_ADDRESS, profileRegistryProxy));
        address resolverProxy = address(new TransparentUpgradeableProxy(resolverImpl, address(proxyAdmin), ""));
        ScrollBadgeResolver resolver = ScrollBadgeResolver(payable(resolverProxy));
        resolver.initialize();

        bytes32 schema = resolver.schema();

        // deploy profile implementation and upgrade registry
        Profile profileImpl = new Profile(address(resolver));
        ProfileRegistry profileRegistryImpl = new ProfileRegistry();
        proxyAdmin.upgrade(ITransparentUpgradeableProxy(profileRegistryProxy), address(profileRegistryImpl));
        ProfileRegistry(profileRegistryProxy).initialize(TREASURY_ADDRESS, SIGNER_ADDRESS, address(profileImpl));

        // misc
        bytes32[] memory blacklist = new bytes32[](1);
        blacklist[0] = keccak256(bytes("vpn"));
        ProfileRegistry(profileRegistryProxy).blacklistUsername(blacklist);

        // log addresses
        logAddress("DEPLOYER_ADDRESS", vm.addr(DEPLOYER_PRIVATE_KEY));
        logAddress("SIGNER_ADDRESS", SIGNER_ADDRESS);
        logAddress("TREASURY_ADDRESS", TREASURY_ADDRESS);
        logAddress("EAS_ADDRESS", EAS_ADDRESS);
        logAddress("SCROLL_PROFILE_REGISTRY_PROXY_ADMIN_ADDRESS", address(proxyAdmin));
        logAddress("SCROLL_PROFILE_REGISTRY_PROXY_CONTRACT_ADDRESS", address(profileRegistryProxy));
        logAddress("SCROLL_BADGE_RESOLVER_CONTRACT_ADDRESS", address(resolver));
        logBytes32("SCROLL_BADGE_SCHEMA_UID", schema);
        logAddress("SCROLL_PROFILE_IMPLEMENTATION_CONTRACT_ADDRESS", address(profileImpl));
        logAddress("SCROLL_PROFILE_REGISTRY_IMPLEMENTATION_CONTRACT_ADDRESS", address(profileRegistryImpl));

        vm.stopBroadcast();
    }

    function logAddress(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
    }

    function logBytes32(string memory name, bytes32 data) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(data))));
    }
}
