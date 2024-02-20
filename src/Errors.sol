// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

error AttestationBadgeMismatch(bytes32 uid);
error AttestationExpired(bytes32 uid);
error AttestationNotFound(bytes32 uid);
error AttestationRevoked(bytes32 uid);
error AttestationSchemaMismatch(bytes32 uid);
error BadgeNotAllowed(address badge);
error BadgeNotFound(address badge);
error ExpirationTimeDisabled();
error InvalidPayload(bytes32 uid);
error InvalidBadge(bytes32 uid);
error ResolverPaymentsDisabled();
error Unauthorized();
error InvalidOffset();
error SingletonBadge(bytes32 uid);
