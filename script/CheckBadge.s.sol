// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {AttesterProxy} from "../src/AttesterProxy.sol";
import {ScrollBadge} from "../src/badge/ScrollBadge.sol";
import {ScrollBadgeEligibilityCheck} from "../src/badge/extensions/ScrollBadgeEligibilityCheck.sol";
import {ScrollBadgeAccessControl} from "../src/badge/extensions/ScrollBadgeAccessControl.sol";

contract CheckBadge is Script {
    uint256 SCROLL_CHAIN_ID = 534_352;
    address SCROLL_BADGE_RESOLVER_CONTRACT_ADDRESS = 0x4560FECd62B14A463bE44D40fE5Cfd595eEc0113;

    function run() external {
        address badge = vm.promptAddress("Please provide your badge address");
        address attesterProxy = promptAddressOpt("Please provide your attester proxy address (leave empty if none)");
        address signer = promptAddressOpt("Please provide your backend signer address (leave empty if none)");

        run(badge, attesterProxy, signer);
    }

    function run(address badge, address attesterProxy, address signer) public {
        console.log(
            string(
                abi.encodePacked(
                    "Checking badge ",
                    vm.toString(badge),
                    " with attester proxy ",
                    vm.toString(attesterProxy),
                    " and signer ",
                    vm.toString(signer)
                )
            )
        );

        // check chain id
        if (block.chainid != SCROLL_CHAIN_ID) {
            revert("Wrong chain, make sure to run this script with --rpc-url https://rpc.scroll.io");
        }

        // check if badge exists
        if (badge.code.length == 0) {
            revert(unicode"❌ Badge contract not deployed");
        } else {
            console.log(unicode"✅ Badge contract deployed");
        }

        // check if attester proxy exists
        if (attesterProxy != address(0) && attesterProxy.code.length == 0) {
            revert(unicode"❌ Attester proxy contract not deployed");
        } else {
            console.log(unicode"✅ Attester proxy contract deployed");
        }

        // check resolver
        try ScrollBadge(badge).resolver() returns (address resolver) {
            if (resolver != SCROLL_BADGE_RESOLVER_CONTRACT_ADDRESS) {
                console.log(
                    unicode"❌ Incorrect resolver, make sure that you pass the correct constructor argument to ScrollBadge"
                );
            } else {
                console.log(unicode"✅ Badge resolver configured");
            }
        } catch {
            console.log(unicode"❌ Failed to call badge.resolver(), make sure that your badge implements ScrollBadge");
        }

        // check default badgeTokenURI
        try ScrollBadge(badge).badgeTokenURI(bytes32("")) returns (string memory defaultUri) {
            if (bytes(defaultUri).length == 0) {
                console.log(
                    unicode"❌ Missing default badge URI, make sure that your badge implements ScrollBadgeDefaultURI"
                );
            } else {
                console.log(unicode"✅ Default badge URI is configured");
            }
        } catch {
            console.log(
                unicode"❌ Missing default badge URI, make sure that your badge implements ScrollBadgeDefaultURI"
            );
        }

        // on-chain eligibility check
        if (attesterProxy == address(0)) {
            try ScrollBadgeEligibilityCheck(badge).isEligible(address(1)) {
                console.log(unicode"✅ On-chain eligibility check is configured");
            } catch {
                console.log(
                    unicode"❌ Missing on-chain eligibility check, make sure that your badge implements ScrollBadgeEligibilityCheck"
                );
            }
        }

        // authorization
        if (attesterProxy != address(0)) {
            try ScrollBadgeAccessControl(badge).isAttester(attesterProxy) returns (bool isAttester) {
                if (!isAttester) {
                    console.log(
                        unicode"❌ Attester proxy is not whitelisted, please call badge.toggleAttester(attesterProxy, true)"
                    );
                } else {
                    console.log(unicode"✅ Attester proxy is whitelisted");
                }
            } catch {
                console.log(
                    unicode"❌ Missing access control, make sure that your badge implements ScrollBadgeAccessControl"
                );
            }
        }

        if (attesterProxy != address(0) && signer != address(0)) {
            try AttesterProxy(attesterProxy).isAttester(signer) returns (bool isAttester) {
                if (!isAttester) {
                    console.log(
                        unicode"❌ Your signer is not whitelisted, please call attesterProxy.toggleAttester(signer, true)"
                    );
                } else {
                    console.log(unicode"✅ Signer is whitelisted");
                }
            } catch {
                console.log(
                    unicode"❌ Failed to query attester proxy, make sure this contract is an instance of AttesterProxy"
                );
            }
        }
    }

    function promptAddressOpt(string memory promptText) private returns (address addr) {
        string memory str = vm.prompt(promptText);

        if (bytes(str).length > 0) {
            addr = vm.parseAddress(str);
        }
    }
}
