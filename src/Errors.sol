// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

error Unauthorized();

// attestation errors
// note: these don't include the uid since it is not known prior to the attestation.
error BadgeNotAllowed(address badge);
error BadgeNotFound(address badge);
error ExpirationDisabled();
error MissingPayload();
error ResolverPaymentsDisabled();
error RevocationDisabled();
error SingletonBadge();
error UnknownSchema();

// query errors
error AttestationBadgeMismatch(bytes32 uid);
error AttestationExpired(bytes32 uid);
error AttestationNotFound(bytes32 uid);
error AttestationOwnerMismatch(bytes32 uid);
error AttestationRevoked(bytes32 uid);
error AttestationSchemaMismatch(bytes32 uid);

// profile errors
error BadgeCountReached();
error LengthMismatch();
error TokenNotOwnedByUser(address token, uint256 tokenId);

// profile registry errors
error CallerIsNotUserProfile();
error DuplicatedUsername();
error ExpiredSignature();
error ImplementationNotContract();
error InvalidReferrer();
error InvalidSignature();
error InvalidUsername();
error MsgValueMismatchWithMintFee();
error ProfileAlreadyMinted();
