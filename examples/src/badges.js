import { normalizeAddress } from './lib.js';

export const badges = {};

badges[normalizeAddress(process.env.SIMPLE_BADGE_CONTRACT_ADDRESS)] = {
  name: 'Simple Badge',
  address: normalizeAddress(process.env.SIMPLE_BADGE_CONTRACT_ADDRESS),
  proxy: normalizeAddress(process.env.SIMPLE_BADGE_ATTESTER_PROXY_CONTRACT_ADDRESS),
  isEligible: async (recipient) => true,
  createPayload: async (recipient) => '0x',
};
