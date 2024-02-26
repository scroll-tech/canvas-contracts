import { ethers } from 'ethers';

import 'dotenv/config';

const SCROLL_REFERRAL_DOMAIN = {
  name: 'ProfileRegistry',
  version: '1',
  chainId: 1, // set correct chain id
  verifyingContract: process.env.SCROLL_PROFILE_REGISTRY_PROXY_CONTRACT_ADDRESS,
};

const SCROLL_REFERRAL_TYPES = {
  Referral: [
    { name: 'referral', type: 'address' },
    { name: 'owner',    type: 'address' },
    { name: 'deadline', type: 'uint256' },
  ],
};

async function signTypedData() {
  const provider = new ethers.JsonRpcProvider(process.env.RPC_ENDPOINT);
  const signer = (new ethers.Wallet(process.env.SIGNER_PRIVATE_KEY)).connect(provider);
  const referrer = (new ethers.Wallet(process.env.DEPLOYER_PRIVATE_KEY)).address;
  const claimer = (new ethers.Wallet(process.env.CLAIMER_PRIVATE_KEY)).address;

  // set correct chain ID
  const chainId = (await provider.getNetwork()).chainId;
  SCROLL_REFERRAL_DOMAIN.chainId = chainId;

  // set deadline
  const currentTime = Math.floor(new Date().getTime() / 1000);
  const deadline = currentTime + 3600;

  // construct and sign message
  const message = {
    // "referral" is the referrer address, this is the user who will get the fee reward.
    referral: referrer,
    // "owner" is the mint transaction sender, the owner of the new profile.
    owner: claimer,
    deadline,
  };

  // note: replay protection is built into the contract, since one wallet can only mint one profile.

  const signature = await signer.signTypedData(SCROLL_REFERRAL_DOMAIN, SCROLL_REFERRAL_TYPES, message);
  console.log('Signature:', signature);

  const coder = ethers.AbiCoder.defaultAbiCoder();
  const referral = coder.encode(['address', 'uint256', 'bytes'], [claimer, deadline, signature]);
  console.log('Referral:', referral);
}

signTypedData();
