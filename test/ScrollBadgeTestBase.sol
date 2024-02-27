// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";

import { EAS } from "@eas/contracts/EAS.sol";
import { EMPTY_UID, NO_EXPIRATION_TIME } from "@eas/contracts/Common.sol";
import { IEAS, AttestationRequest, AttestationRequestData, RevocationRequest, RevocationRequestData } from "@eas/contracts/IEAS.sol";
import { ISchemaResolver } from "@eas/contracts/resolver/ISchemaResolver.sol";
import { SchemaRegistry, ISchemaRegistry } from "@eas/contracts/SchemaRegistry.sol";
import { ScrollBadgeResolver } from "../src/resolver/ScrollBadgeResolver.sol";

contract ScrollBadgeTestBase is DSTestPlus {
    ISchemaRegistry internal registry;
    IEAS internal eas;
    ScrollBadgeResolver internal resolver;

    bytes32 schema;

    address internal constant alice = address(1);
    address internal constant bob = address(2);

    function setUp() public virtual {
        // EAS infra
        registry = new SchemaRegistry();
        eas = new EAS(registry);

        // Scroll components
        address profileRegistry = address(0);
        resolver = new ScrollBadgeResolver(address(eas), profileRegistry);
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

        AttestationRequest memory _req = AttestationRequest({
            schema: schema,
            data: _attData
        });

        return eas.attest(_req);
    }

    function _revoke(bytes32 uid) internal {
        RevocationRequestData memory _data = RevocationRequestData({
            uid: uid,
            value: 0
        });

        RevocationRequest memory _req = RevocationRequest({
            schema: schema,
            data: _data
        });

        eas.revoke(_req);
    }
}
