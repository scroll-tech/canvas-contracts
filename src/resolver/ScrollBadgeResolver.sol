// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation, IEAS} from "@eas/contracts/IEAS.sol";
import {EMPTY_UID, NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";
import {SchemaResolver, ISchemaResolver} from "@eas/contracts/resolver/SchemaResolver.sol";

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IProfile} from "../interfaces/IProfile.sol";
import {IProfileRegistry} from "../interfaces/IProfileRegistry.sol";
import {IScrollBadge} from "../interfaces/IScrollBadge.sol";
import {IScrollBadgeResolver} from "../interfaces/IScrollBadgeResolver.sol";
import {IScrollSelfAttestationBadge} from "../interfaces/IScrollSelfAttestationBadge.sol";
import {SCROLL_BADGE_SCHEMA, decodeBadgeData} from "../Common.sol";
import {ScrollBadgeResolverWhitelist} from "./ScrollBadgeResolverWhitelist.sol";

import {
    AttestationExpired,
    AttestationNotFound,
    AttestationRevoked,
    AttestationSchemaMismatch,
    BadgeNotAllowed,
    BadgeNotFound,
    ResolverPaymentsDisabled,
    UnknownSchema
} from "../Errors.sol";

/// @title ScrollBadgeResolver
/// @notice This resolver contract receives callbacks every time a Scroll badge
//          attestation is created or revoked. It executes some basic checks and
//          then delegates the logic to the specific badge implementation.
contract ScrollBadgeResolver is IScrollBadgeResolver, SchemaResolver, ScrollBadgeResolverWhitelist {
    /**
     *
     * Constants *
     *
     */

    /// @inheritdoc IScrollBadgeResolver
    address public immutable registry;

    /**
     *
     * Variables *
     *
     */

    /// @inheritdoc IScrollBadgeResolver
    bytes32 public schema;

    /// @notice The list of self attested badges, mapping from badge id to badge address.
    /// @dev This is a list of badges with special needs which EAS cannot satisfy, such as
    /// auto attest/revoke badge based on certain token holding amount.
    /// The uid for the badge is customized in the following way:
    /// ```text
    /// [  address  | badge id | customized data ]
    /// [ 160  bits | 32  bits |     64 bits     ]
    /// [LSB                                  MSB]
    /// ```
    mapping(uint256 => address) public selfAttestedBadges;

    // Storage slots reserved for future upgrades.
    uint256[48] private __gap;

    /**
     *
     * Constructor *
     *
     */

    /// @dev Creates a new ScrollBadgeResolver instance.
    /// @param eas_ The address of the global EAS contract.
    /// @param registry_ The address of the profile registry contract.
    constructor(address eas_, address registry_) SchemaResolver(IEAS(eas_)) {
        registry = registry_;
        _disableInitializers();
    }

    function initialize() external initializer {
        __Whitelist_init();

        // register Scroll badge schema,
        // we do this here to ensure that the resolver is correctly configured
        schema = _eas.getSchemaRegistry().register(
            SCROLL_BADGE_SCHEMA,
            ISchemaResolver(address(this)), // resolver
            true // revocable
        );
    }

    /**
     *
     * Schema Resolver Functions *
     *
     */

    /// @inheritdoc SchemaResolver
    function onAttest(Attestation calldata attestation, uint256 value)
        internal
        override (SchemaResolver)
        returns (bool)
    {
        // do not accept resolver tips
        if (value != 0) {
            revert ResolverPaymentsDisabled();
        }

        // do not process other schemas
        if (attestation.schema != schema) {
            revert UnknownSchema();
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

        // auto-attach self-minted badges
        // note: in some cases attestation.attester is a proxy, so we also check tx.origin.
        if (attestation.recipient == attestation.attester || attestation.recipient == tx.origin) {
            _autoAttach(attestation);
        }

        emit IssueBadge(attestation.uid);
        return true;
    }

    /// @inheritdoc SchemaResolver
    function onRevoke(Attestation calldata attestation, uint256 value)
        internal
        override (SchemaResolver)
        returns (bool)
    {
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

    /**
     *
     * Public View Functions *
     *
     */

    /// @inheritdoc IScrollBadgeResolver
    function eas() external view returns (address) {
        return address(_eas);
    }

    /// @inheritdoc IScrollBadgeResolver
    function getAndValidateBadge(bytes32 uid) external view returns (Attestation memory) {
        Attestation memory attestation = _eas.getAttestation(uid);

        // if we cannot find the badge in EAS, try self attestation
        if (attestation.uid == EMPTY_UID) {
            // extract badge address from uid and do self attestation
            uint256 badgeId = uint256(uid) >> 160 & 0xffffffff;
            address badgeAddr = selfAttestedBadges[badgeId];
            if (badgeAddr != address(0)) {
                attestation = IScrollSelfAttestationBadge(badgeAddr).getAttestation(uid);
            }
            if (attestation.uid == EMPTY_UID) {
                revert AttestationNotFound(uid);
            } else {
                return attestation;
            }
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

    /**
     *
     * Restricted Functions *
     *
     */

    /// @notice Update the address of a self attested badge.
    function updateSelfAttestedBadge(uint256 badgeId, address badgeAddress) external onlyOwner {
        selfAttestedBadges[badgeId] = badgeAddress;
    }

    /**
     *
     * Internal Functions *
     *
     */
    function _autoAttach(Attestation calldata attestation) internal {
        IProfileRegistry _registry = IProfileRegistry(registry);
        address profile = _registry.getProfile(attestation.recipient);

        if (!_registry.isProfileMinted(profile)) {
            return;
        }

        // note: at this point the attestation is already registered in EAS,
        // so attaching it should succeed, unless the profile is full, in
        // which case the following call will be a no-op.
        IProfile(profile).autoAttach(attestation.uid);
    }
}
