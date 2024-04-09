import { ethers } from 'ethers';

import 'dotenv/config';

const abi = [
  'error Unauthorized()',

  'error BadgeNotAllowed(address badge)',
  'error BadgeNotFound(address badge)',
  'error ExpirationDisabled()',
  'error MissingPayload()',
  'error ResolverPaymentsDisabled()',
  'error RevocationDisabled()',
  'error SingletonBadge()',
  'error UnknownSchema()',

  'error AttestationBadgeMismatch(bytes32 uid)',
  'error AttestationExpired(bytes32 uid)',
  'error AttestationNotFound(bytes32 uid)',
  'error AttestationOwnerMismatch(bytes32 uid)',
  'error AttestationRevoked(bytes32 uid)',
  'error AttestationSchemaMismatch(bytes32 uid)',

  'error BadgeCountReached()',
  'error LengthMismatch()',
  'error TokenNotOwnedByUser(address token, uint256 tokenId)',

  'error CallerIsNotUserProfile()',
  'error DuplicatedUsername()',
  'error ExpiredSignature()',
  'error ImplementationNotContract()',
  'error InvalidReferrer()',
  'error InvalidSignature()',
  'error InvalidUsername()',
  'error MsgValueMismatchWithMintFee()',
  'error ProfileAlreadyMinted()',
];

async function main() {
  const errData = '0x8baa579f';
  const contract = new ethers.Interface(abi);
  const decodedError = contract.parseError(errData);
  console.log('error:', decodedError.name);
}

main();
