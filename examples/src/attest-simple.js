import { EAS, getUIDsFromMultiAttestTx } from '@ethereum-attestation-service/eas-sdk';
import { EIP712Proxy } from '@ethereum-attestation-service/eas-sdk/dist/eip712-proxy.js';
import { ethers } from 'ethers';

import { createBadge } from './lib.js';

import 'dotenv/config';

const abi = [
  'error SingletonBadge()',
  'error Unauthorized()'
]

async function main() {
  const provider = new ethers.JsonRpcProvider(process.env.RPC_ENDPOINT);

  const eas = new EAS(process.env.EAS_MAIN_CONTRACT_ADDRESS);
  const attesterProxy = new EIP712Proxy(process.env.SIMPLE_BADGE_ATTESTER_PROXY_CONTRACT_ADDRESS);

  eas.connect(provider);
  attesterProxy.connect(provider);

  const contract = new ethers.Interface(abi);

  const signer = (new ethers.Wallet(process.env.SIGNER_PRIVATE_KEY)).connect(provider);
  const claimer = (new ethers.Wallet(process.env.CLAIMER_PRIVATE_KEY)).connect(provider);

  const badge = await createBadge({
    badge: process.env.SIMPLE_BADGE_CONTRACT_ADDRESS,
    recipient: claimer.address,
    payload: '0x',
    proxy: attesterProxy,
    signer,
  });

  try {
    const res = await attesterProxy.connect(claimer).attestByDelegationProxy(badge);

    const uids = await getUIDsFromMultiAttestTx(res.tx);
    console.log(uids);
    // const attestation = await eas.getAttestation(uid);
  } catch (err) {
    console.log();
    const decodedError = contract.parseError(err.data)
    console.log('error:', decodedError.name)
  }
}

main();
