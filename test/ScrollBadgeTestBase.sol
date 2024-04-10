// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";

import {EAS} from "@eas/contracts/EAS.sol";
import {EMPTY_UID, NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";
import {ISchemaResolver} from "@eas/contracts/resolver/ISchemaResolver.sol";
import {SchemaRegistry, ISchemaRegistry} from "@eas/contracts/SchemaRegistry.sol";

import {
    IEAS,
    AttestationRequest,
    AttestationRequestData,
    RevocationRequest,
    RevocationRequestData
} from "@eas/contracts/IEAS.sol";

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import {ScrollBadgeResolver} from "../src/resolver/ScrollBadgeResolver.sol";
import {ProfileRegistry} from "../src/profile/ProfileRegistry.sol";

contract ScrollBadgeTestBase is Test {
    ISchemaRegistry internal registry;
    IEAS internal eas;
    ScrollBadgeResolver internal resolver;

    bytes32 schema;

    address internal constant alice = address(1);
    address internal constant bob = address(2);

    address internal constant PROXY_ADMIN_ADDRESS = 0x2000000000000000000000000000000000000000;

    function setUp() public virtual {
        // EAS infra
        registry = new SchemaRegistry();
        eas = new EAS(registry);

        // Scroll components
        // no need to initialize the registry, since resolver
        // only uses it to see if a profile has been minted or not.
        address profileRegistry = address(new ProfileRegistry());

        address resolverImpl = address(new ScrollBadgeResolver(address(eas), profileRegistry));
        address resolverProxy = address(new TransparentUpgradeableProxy(resolverImpl, PROXY_ADMIN_ADDRESS, ""));
        resolver = ScrollBadgeResolver(payable(resolverProxy));
        resolver.initialize();

        schema = resolver.schema();
    }

    function _attest(address badge, bytes memory payload, address recipient) internal returns (bytes32) {
        bytes memory attestationData = abi.encode(badge, payload);

        AttestationRequestData memory _attData = AttestationRequestData({
            recipient: recipient,
            expirationTime: NO_EXPIRATION_TIME,
            revocable: true,
            refUID: EMPTY_UID,
            data: attestationData,
            value: 0
        });

        AttestationRequest memory _req = AttestationRequest({schema: schema, data: _attData});

        return eas.attest(_req);
    }

    function _revoke(bytes32 uid) internal {
        RevocationRequestData memory _data = RevocationRequestData({uid: uid, value: 0});

        RevocationRequest memory _req = RevocationRequest({schema: schema, data: _data});

        eas.revoke(_req);
    }
}
