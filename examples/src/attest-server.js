import 'dotenv/config.js';

import { EIP712Proxy } from '@ethereum-attestation-service/eas-sdk/dist/eip712-proxy.js';
import { ethers } from 'ethers';
import express from 'express';

import { createBadge, normalizeAddress } from './lib.js';
import { badges } from './badges.js';

const app = express();
const provider = new ethers.JsonRpcProvider(process.env.RPC_ENDPOINT);
const signer = new ethers.Wallet(process.env.SIGNER_PRIVATE_KEY).connect(provider);

// example query:
// curl 'localhost:3000/api/check?badge=0x30C98067517f8ee38e748A3aF63429974103Ea6B&recipient=0x0000000000000000000000000000000000000001'
app.get('/api/check', async (req, res) => {
  const { badge: badgeAddress, recipient } = req.query;

  if (!recipient) return res.json({ code: 0, message: 'missing query parameter "recipient"' });
  if (!badgeAddress) return res.json({ code: 0, message: 'missing parameter "badge"' });
  const badge = badges[normalizeAddress(badgeAddress)];

  if (!badge) return res.json({ code: 0, message: `unknown badge "${address}"` });
  const eligibility = await badge.isEligible(recipient);
  if (!eligibility) return res.json({ code: 0, message: 'why the recipient is not eligible', eligibility: false });

  res.json({ code: 1, message: 'success', eligibility: true });
});

// example query:
// curl 'localhost:3000/api/claim?badge=0x30C98067517f8ee38e748A3aF63429974103Ea6B&recipient=0x0000000000000000000000000000000000000001'
app.get('/api/claim', async (req, res) => {
  const { badge: badgeAddress, recipient } = req.query;

  if (!recipient) return res.json({ code: 0, message: 'missing query parameter "recipient"' });
  if (!badgeAddress) return res.json({ code: 0, message: 'missing parameter "badge"' });

  const badge = badges[normalizeAddress(badgeAddress)];

  if (!badge) return res.json({ code: 0, message: `unknown badge "${badgeAddress}"` });
  const eligibility = await badge.isEligible(recipient);
  if (!eligibility) return res.json({ code: 0, message: 'not eligible' });

  const proxy = new EIP712Proxy(badge.proxy);

  const attestation = await createBadge({
    badge: badge.address,
    recipient,
    payload: await badge.createPayload(),
    proxy,
    signer,
  });

  const tx = await proxy.contract.attestByDelegation.populateTransaction(attestation);
  res.json({ code: 1, message: 'success', tx });
});

// Start the server
app.listen(process.env.EXPRESS_SERVER_PORT, () => {
  console.log(`Server is running on port ${process.env.EXPRESS_SERVER_PORT}`);
});
