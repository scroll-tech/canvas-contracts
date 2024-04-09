import 'dotenv/config.js';

import { EIP712Proxy } from '@ethereum-attestation-service/eas-sdk/dist/eip712-proxy.js';
import { ethers } from 'ethers';
import express from 'express';

import { createBadge, normalizeAddress } from './lib.js';
import { badges } from './badges.js';

const app = express();
const provider = new ethers.JsonRpcProvider(process.env.RPC_ENDPOINT);
const signer = (new ethers.Wallet(process.env.SIGNER_PRIVATE_KEY)).connect(provider);

// example query:
// curl 'localhost:3000/api/badge/0xA51c1fc2f0D1a1b8494Ed1FE312d7C3a78Ed91C0/claim?recipient=0x0000000000000000000000000000000000000001'
app.get('/api/badge/:address/claim', async (req, res) => {
  const { recipient } = req.query;
  const { address } = req.params;

  if (!recipient) return res.json({ error: 'missing query parameter "recipient"' });
  if (!address) return res.json({ error: 'missing parameter "address"' });

  const badge = badges[normalizeAddress(address)];

  if (!badge) return res.json({ error: `unknown badge "${address}"` });
  if (!badge.isEligible(recipient)) return res.json({ error: null, status: 'not eligible' });

  const proxy = new EIP712Proxy(badge.proxy);

  const attestation = await createBadge({
    badge: badge.address,
    recipient,
    payload: await badge.createPayload(),
    proxy,
    signer,
  });

  const tx = await proxy.contract.attestByDelegation.populateTransaction(attestation);
  res.json({ error: null, status: 'eligible', tx });
});

// Start the server
app.listen(process.env.EXPRESS_SERVER_PORT, () => {
  console.log(`Server is running on port ${process.env.EXPRESS_SERVER_PORT}`);
});
