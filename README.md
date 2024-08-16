# Scroll Canvas Contracts

[![test](https://github.com/scroll-tech/canvas-contracts/actions/workflows/contracts.yml/badge.svg)](https://github.com/scroll-tech/canvas-contracts/actions/workflows/contracts.yml)

## Welcome to Scroll Canvas

We are thrilled to have you join us in building unique discoveries with Scroll Canvas, a new product designed for ecosystem projects to interact with users in a more tailored way.

## Overview

**Scroll Canvas** allows users to showcase on-chain credentials, status, and achievements called **Badges** issued and collected across the Scroll ecosystem.
Users can mint a non-transferable and unique personal persona to collect and display their **Badges**.

### Key Features

- **Canvas**: Each Canvas is a smart contract minted through the `ProfileRegistry` contract by the user on Scroll’s website.
- **Badges**: Attestations of achievements and traits verified through the Ethereum Attestation Service ([EAS service](https://docs.attest.sh/docs/welcome)), issued by different projects and the Scroll Foundation.
  Badges are wallet-bound and non-transferable.

| Attestation | NFT |
| --- | --- |
| Witness Proofs | Tokenized Assets |
| Non-transferable | Transferable |
| Recorded on disk (blockchain history) | Recorded in memory (blockchain states) |
| Prove ownership at a point in time | Exercise custodianship of an asset |

## Developer Quickstart

Visit the [Developer Documentation](./docs) in this repo to learn more about Canvas.

See [Deployments](./docs/deployments.md) for the official Canvas contract addresses.

## Running the Code

### Node.js

First install [`Node.js`](https://nodejs.org/en) and [`npm`](https://www.npmjs.com/).
Run the following command to install [`yarn`](https://classic.yarnpkg.com/en/):

```bash
npm install --global yarn
```

### Foundry

Install `foundryup`, the Foundry toolchain installer:

```bash
curl -L https://foundry.paradigm.xyz | bash
```

If you do not want to use the redirect, feel free to manually download the `foundryup` installation script from [here](https://raw.githubusercontent.com/foundry-rs/foundry/master/foundryup/foundryup). Then, run `foundryup` in a new terminal session or after reloading `PATH`.

Other ways to install Foundry can be found [here](https://github.com/foundry-rs/foundry#installation).

### Install Dependencies

Run the following command to install all dependencies locally.

```
yarn
```

### Run Contract Tests

Run the following command to run the contract tests.

```
yarn test
```

## Contributing

We welcome community contributions to this repository.
For larger changes, please [open an issue](https://github.com/scroll-tech/canvas-contracts/issues/new/choose) and discuss with the team before submitting code changes.

## License

Scroll Monorepo is licensed under the [MIT](./LICENSE) license.
