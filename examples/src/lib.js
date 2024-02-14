import { SchemaEncoder, ZERO_BYTES32, NO_EXPIRATION } from '@ethereum-attestation-service/eas-sdk';

export function normalizeAddress(address) {
  return address.toLowerCase();
}

export async function createAttestation({ schema, recipient, data, deadline, proxy, signer }) {
  const attestation = {
    // attestation data
    schema,
    recipient,
    data,

    // unused fields
    revocable: true,
    refUID: ZERO_BYTES32,
    value: 0n,
    expirationTime: NO_EXPIRATION,

    // signature details
    deadline,
    attester: signer.address,
  };

  // sign
  const delegatedProxy = await proxy.connect(signer).getDelegated();
  const signature = await delegatedProxy.signDelegatedProxyAttestation(attestation, signer);

  const req = {
    schema: attestation.schema,
    data: attestation,
    attester: attestation.attester,
    signature: signature.signature,
    deadline: attestation.deadline,
  }

  // note: to use multiAttestByDelegationProxy, change to
  // data: [attestation],
  // signatures: [signature.signature],

  return req;
}

export async function createBadge({ badge, recipient, payload, proxy, signer }) {
  const encoder = new SchemaEncoder(process.env.SCROLL_BADGE_SCHEMA);
  const data = encoder.encodeData([
    { name: "badge", value: badge, type: "address" },
    { name: "payload", value: payload, type: "bytes" },
  ]);

  const currentTime = Math.floor(new Date().getTime() / 1000);
  const deadline = currentTime + 3600;

  const attestation = await createAttestation({
    schema: process.env.SCROLL_BADGE_SCHEMA_UID,
    recipient,
    data,
    deadline,
    proxy,
    signer,
  });

  return attestation;
}
