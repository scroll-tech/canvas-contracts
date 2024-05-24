// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Attestation, IEAS} from "@eas/contracts/IEAS.sol";

import {AttesterProxy} from "../src/AttesterProxy.sol";
import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {EthereumYearBadge} from "../src/badge/examples/EthereumYearBadge.sol";
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

contract DeployCanvasTestBadgeContracts is Script {
    uint256 DEPLOYER_PRIVATE_KEY = vm.envUint("DEPLOYER_PRIVATE_KEY");

    address RESOLVER_ADDRESS = vm.envAddress("SCROLL_BADGE_RESOLVER_CONTRACT_ADDRESS");
    address ETHEREUM_YEAR_SIGNER_ADDRESS = vm.envAddress("ETHEREUM_YEAR_SIGNER_ADDRESS");

    address EAS_ADDRESS = vm.envAddress("EAS_ADDRESS");

    bool IS_MAINNET = vm.envBool("IS_MAINNET");

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

        // deploy origins NFT badge
        address[] memory tokens;

        if (IS_MAINNET) {
            tokens = new address[](2);
            tokens[0] = 0x74670A3998d9d6622E32D0847fF5977c37E0eC91;
            tokens[1] = 0x42bCaCb8D24Ba588cab8Db0BB737DD2eFca408EC;
        } else {
            tokens = new address[](1);
            tokens[0] = 0xDd7d857F570B0C211abfe05cd914A85BefEC2464;
        }

        ScrollBadgeTokenOwner badge4 = new ScrollBadgeTokenOwner(address(resolver), tokens);

        // deploy Ethereum year badge
        EthereumYearBadge badge5 = new EthereumYearBadge(address(resolver), "https://nft.scroll.io/canvas/year/");
        AttesterProxy yearBadgeProxy = new AttesterProxy(IEAS(EAS_ADDRESS));

        // set permissions
        badge5.toggleAttester(address(yearBadgeProxy), true);
        yearBadgeProxy.toggleAttester(ETHEREUM_YEAR_SIGNER_ADDRESS, true);

        // set permissions
        resolver.toggleBadge(address(badge1), true);
        resolver.toggleBadge(address(badge2), true);
        resolver.toggleBadge(address(badge3), true);
        resolver.toggleBadge(address(badge4), true);
        resolver.toggleBadge(address(badge5), true);

        // log addresses
        logAddress("DEPLOYER_ADDRESS", vm.addr(DEPLOYER_PRIVATE_KEY));
        logAddress("SIMPLE_BADGE_A_CONTRACT_ADDRESS", address(badge1));
        logAddress("SIMPLE_BADGE_B_CONTRACT_ADDRESS", address(badge2));
        logAddress("SIMPLE_BADGE_C_CONTRACT_ADDRESS", address(badge3));
        logAddress("ORIGINS_BADGE_ADDRESS", address(badge4));
        logAddress("ETHEREUM_YEAR_BADGE_ADDRESS", address(badge5));
        logAddress("ETHEREUM_YEAR_ATTESTER_PROXY_ADDRESS", address(yearBadgeProxy));

        vm.stopBroadcast();
    }

    function logAddress(string memory name, address addr) internal view {
        console.log(string(abi.encodePacked(name, "=", vm.toString(address(addr)))));
    }
}
