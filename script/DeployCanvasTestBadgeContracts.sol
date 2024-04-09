// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {ScrollBadgeTokenOwner} from "../src/badge/examples/ScrollBadgeTokenOwner.sol";
import {ScrollBadgeSelfAttest} from "../src/badge/extensions/ScrollBadgeSelfAttest.sol";
import {ScrollBadgeSingleton} from "../src/badge/extensions/ScrollBadgeSingleton.sol";
import {ScrollBadgeResolver} from "../src/resolver/ScrollBadgeResolver.sol";

contract CanvasTestBadge is ScrollBadgeSelfAttest, ScrollBadgeSingleton {
    string public sharedTokenURI;

    constructor(address resolver_, string memory tokenUri_) ScrollBadge(resolver_) {
        sharedTokenURI = tokenUri_;
    }

    function onIssueBadge(Attestation calldata attestation)
        internal
        virtual
        override (ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    function onRevokeBadge(Attestation calldata attestation)
        internal
        virtual
        override (ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }

    function badgeTokenURI(bytes32 /*uid*/ ) public view override returns (string memory) {
        return sharedTokenURI;
    }
}

contract DeployTestContracts is Script {
    uint256 DEPLOYER_PRIVATE_KEY = vm.envUint("DEPLOYER_PRIVATE_KEY");

    address RESOLVER_ADDRESS = vm.envAddress("SCROLL_BADGE_RESOLVER_CONTRACT_ADDRESS");

    function run() external {
        vm.startBroadcast(DEPLOYER_PRIVATE_KEY);

        ScrollBadgeResolver resolver = ScrollBadgeResolver(payable(RESOLVER_ADDRESS));

        // deploy test badges
        CanvasTestBadge badge1 = new CanvasTestBadge(
            address(resolver), "ipfs://bafybeibc5sgo2plmjkq2tzmhrn54bk3crhnc23zd2msg4ea7a4pxrkgfna/1"
        );

        CanvasTestBadge badge2 = new CanvasTestBadge(
            address(resolver), "ipfs://bafybeibc5sgo2plmjkq2tzmhrn54bk3crhnc23zd2msg4ea7a4pxrkgfna/2"
        );

        CanvasTestBadge badge3 = new CanvasTestBadge(
            address(resolver), "ipfs://bafybeibc5sgo2plmjkq2tzmhrn54bk3crhnc23zd2msg4ea7a4pxrkgfna/3"
        );

        address[] memory tokens = new address[](1);
        tokens[0] = 0xDd7d857F570B0C211abfe05cd914A85BefEC2464;

        ScrollBadgeTokenOwner badge4 = new ScrollBadgeTokenOwner(address(resolver), tokens);

        // set permissions
        resolver.toggleBadge(address(badge1), true);
        resolver.toggleBadge(address(badge2), true);
        resolver.toggleBadge(address(badge3), true);
        resolver.toggleBadge(address(badge4), true);

        // log addresses
        logAddress("DEPLOYER_ADDRESS", vm.addr(DEPLOYER_PRIVATE_KEY));
        logAddress("SIMPLE_BADGE_A_CONTRACT_ADDRESS", address(badge1));
        logAddress("SIMPLE_BADGE_B_CONTRACT_ADDRESS", address(badge2));
        logAddress("SIMPLE_BADGE_C_CONTRACT_ADDRESS", address(badge3));
        logAddress("ORIGINS_BADGE_ADDRESS", address(badge4));

        vm.stopBroadcast();
    }

    function logAddress(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
    }
}
