// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation, IEAS } from "@eas/contracts/IEAS.sol";
import { EMPTY_UID, NO_EXPIRATION_TIME } from "@eas/contracts/Common.sol";
import { SchemaResolver, ISchemaResolver } from "@eas/contracts/resolver/SchemaResolver.sol";

import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IProfile } from "../interfaces/IProfile.sol";
import { IProfileRegistry } from "../interfaces/IProfileRegistry.sol";
import { IScrollBadge } from "../interfaces/IScrollBadge.sol";
import { IScrollBadgeResolver } from "../interfaces/IScrollBadgeResolver.sol";
import { ResolverPaymentsDisabled, AttestationSchemaMismatch, ExpirationTimeDisabled, BadgeNotFound, BadgeNotAllowed, AttestationNotFound, AttestationExpired, AttestationRevoked } from "../Errors.sol";
import { SCROLL_BADGE_SCHEMA, decodeBadgeData } from "../Common.sol";
import { ScrollBadgeResolverWhitelist } from "./ScrollBadgeResolverWhitelist.sol";

/// @title ScrollBadgeResolver
/// @notice This resolver contract receives callbacks every time a Scroll badge
//          attestation is created or revoked. It executes some basic checks and
//          then delegates the logic to the specific badge implementation.
contract ScrollBadgeResolver is IScrollBadgeResolver, SchemaResolver, ScrollBadgeResolverWhitelist {
    /// @inheritdoc IScrollBadgeResolver
    bytes32 public immutable schema;

    /// @inheritdoc IScrollBadgeResolver
    address public registry;

    /// @inheritdoc IScrollBadgeResolver
    mapping(address => bool) public isBadgeAutoAttach;

    /// @dev Creates a new ScrollBadgeResolver instance.
    /// @param eas_ The address of the global EAS contract.
    /// @param registry_ The address of the profile registry contract.
    constructor(address eas_, address registry_) SchemaResolver(IEAS(eas_)) {
        // register Scroll badge schema,
        // we do this here to ensure that the resolver is correctly configured
        schema = IEAS(eas_).getSchemaRegistry().register(
            SCROLL_BADGE_SCHEMA,
            ISchemaResolver(address(this)), // resolver
            true // revocable
        );

        registry = registry_;
    }

    /// @inheritdoc SchemaResolver
    function onAttest(Attestation calldata attestation, uint256 value) internal override(SchemaResolver) returns (bool) {
        // do not accept resolver tips
        if (value != 0) {
            revert ResolverPaymentsDisabled();
        }

        // do not process other schemas
        if (attestation.schema != schema) {
            revert AttestationSchemaMismatch(attestation.uid);
        }

        // decode attestation
        (address badge,) = decodeBadgeData(attestation.data);

        // check if badge exists
        if (!Address.isContract(badge)) {
            revert BadgeNotFound(badge);
        }

        // check badge whitelist
        if (whitelistEnabled && !whitelist[badge]) {
            revert BadgeNotAllowed(badge);
        }

        // delegate to badge contract for application-specific checks and actions
        if (!IScrollBadge(badge).issueBadge(attestation)) {
            return false;
        }

        // auto-attach whitelisted badges
        if (isBadgeAutoAttach[badge]) {
            _autoAttach(attestation);
        }

        emit IssueBadge(attestation.uid);
        return true;
    }

    /// @inheritdoc SchemaResolver
    function onRevoke(Attestation calldata attestation, uint256 value) internal override(SchemaResolver) returns (bool) {
        // do not accept resolver tips
        if (value != 0) {
            revert ResolverPaymentsDisabled();
        }

        // delegate to badge contract for application-specific checks and actions
        (address badge,) = decodeBadgeData(attestation.data);

        if (!IScrollBadge(badge).revokeBadge(attestation)) {
            return false;
        }

        emit RevokeBadge(attestation.uid);
        return true;
    }

    /// @inheritdoc IScrollBadgeResolver
    function eas() external view returns (address) {
        return address(_eas);
    }

    /// @inheritdoc IScrollBadgeResolver
    function getAndValidateBadge(bytes32 uid) external view returns (Attestation memory) {
        Attestation memory attestation = _eas.getAttestation(uid);

        if (attestation.uid == EMPTY_UID) {
            revert AttestationNotFound(uid);
        }

        if (attestation.schema != schema) {
            revert AttestationSchemaMismatch(uid);
        }

        if (attestation.expirationTime != NO_EXPIRATION_TIME && attestation.expirationTime <= block.timestamp) {
            revert AttestationExpired(uid);
        }

        if (attestation.revocationTime != 0 && attestation.revocationTime <= block.timestamp) {
            revert AttestationRevoked(uid);
        }

        return attestation;
    }

    /// @notice Enable or disable auto-attach for a badge.
    /// @param badge The address of the badge contract.
    /// @param enable Enable auto-attach if true, disable if false.
    function toggleBadgeAutoAttach(address badge, bool enable) external onlyOwner {
        isBadgeAutoAttach[badge] = enable;
        emit UpdateAutoAttachWhitelist(badge, enable);
    }

    function _autoAttach(Attestation calldata attestation) internal {
        IProfileRegistry _registry = IProfileRegistry(registry);
        address profile = _registry.getProfile(attestation.recipient);

        if (!_registry.isProfileMinted(profile)) {
            return;
        }

        bytes32[] memory uids = new bytes32[](1);
        uids[0] = attestation.uid;
        IProfile(profile).attach(uids);
    }
}
