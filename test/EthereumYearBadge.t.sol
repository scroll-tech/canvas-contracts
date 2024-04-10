// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {ScrollBadgeTestBase} from "./ScrollBadgeTestBase.sol";

import {EMPTY_UID, NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";
import {AttestationRequest, AttestationRequestData} from "@eas/contracts/IEAS.sol";

import {EthereumYearBadge} from "../src/badge/examples/EthereumYearBadge.sol";

contract EthereumYearBadgeTest is ScrollBadgeTestBase {
    EthereumYearBadge internal badge;

    string baseTokenURI = "http://scroll-canvas.io/";

    function setUp() public virtual override {
        super.setUp();

        badge = new EthereumYearBadge(address(resolver), baseTokenURI);
        resolver.toggleBadge(address(badge), true);
        badge.toggleAttester(address(this), true);
    }

    function testAttestOnce(address recipient) external {
        bytes memory payload = abi.encode(2024);
        bytes memory attestationData = abi.encode(badge, payload);

        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: recipient,
            expirationTime: NO_EXPIRATION_TIME,
            revocable: false,
            refUID: EMPTY_UID,
            data: attestationData,
            value: 0
        });

        AttestationRequest memory _req = AttestationRequest({schema: schema, data: _attData});
        bytes32 uid = eas.attest(_req);

        string memory uri = badge.badgeTokenURI(uid);
        assertEq(uri, "http://scroll-canvas.io/2024.json");
    }
}
