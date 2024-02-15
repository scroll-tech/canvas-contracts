# Scroll Skelly Contracts

![Components overview](images/overview.png "Overview")

## Overview

- Each user can create a `Profile` contract, minted through the `ProfileRegistry`. All profiles share the same implementation.
- Each badge is an EAS attestation that goes through the `ScrollBadgeResolver` contract.
- Each individual badge type is a standalone `ScrollBadge` contract, which manages the badge-specific logic.
- Badges are minted to the user's wallet address. The user can express their personalization preferences (attach and order badges, choose a profile photo) through their `Profile`.

## ScrollBadge Schema and Resolver

We define a *Scroll badge* [EAS schema](https://docs.attest.sh/docs/core--concepts/schemas):

```
address badge
bytes   payload
```

This schema is tied to `ScrollBadgeResolver`. Every time a Scroll badge attestation is created or revoked, `ScrollBadgeResolver` executes some checks. After that, it forwards the call to the actual badge implementation.

## Badges

Each badge is a standalone contract, inheriting from `ScrollBadge`.

### Extensions

This repo contains some useful [extensions](src/badge/extensions):
- `ScrollBadgeAccessControl` restricts who can create and revoke this badge.
- `ScrollBadgeCustomPayload` adds custom payload support to the badge.
- `ScrollBadgeNonRevocable` disables revocation for this badge.
- `ScrollBadgeSBT` attaches an SBT token to each badge attestation.

### Examples

This repo also contains some [examples](src/badge/examples):
- `ScrollBadgeSimple` is a simple SBT badge with fixed metadata.
- `ScrollBadgePermissionless` is a permissionless SBT badge that anyone can mint to themselves.
- `ScrollBadgeLevels` is an SBT badge that stores a level in its payload and renders different images based on this level.
- `ScrollBadgeOrigins` is an SBT badge that is tied to a Scroll Origins NFT.

## Issuing Badges

Once the badge contract is deployed, we can start issuing badges by creating attestations.

The simplest way to create a badge attestation is to call `EAS.attest`. EAS also has [SDK support](https://github.com/ethereum-attestation-service/eas-sdk?tab=readme-ov-file#creating-onchain-attestations) for this.

There are multiple possible badge minting flows, each described in one of the subsections below.

### Fully Permissionless

It is possible to deploy a badge contract that anyone can mint permissionlessly. In this scenario, anyone can mint a badge by attesting to themselves.

See [ScrollBadgePermissionless](src/badge/examples/ScrollBadgePermissionless.sol).

### Eligibility Check in Badge Contract

A badge can allow permissionless minting, while implementing additional checks of eligibility in the contract. For example, an eligibility check could be checking if a user has a certain NFT token. It can even implement a Merkle drop.

See [ScrollBadgeOrigins](src/badge/examples/ScrollBadgeOrigins.sol).

### Eligibility Check in Backend with Direct Attestation

An application can implement eligibility checking in a centralized backend, and airdrop badges with no user interaction. The issuer (backend) simply calls `EAS.attest` or `EAS.multiAttest`.

### Eligibility Check in Backend with Delegated Attestation

EAS also makes it possible to sign a delegated attestation that someone else can submit. In this scenario, the backend checks eligibility, and then signs a delegated attestation that the user can then submit.

By default EAS uses ERC-712 with nonces, so delegated attestations would need to be submitted in order. For unordered submission, one can use `AttesterProxy`:

- The attester signs a delegated attestation request to the `AttesterProxy` and sends it to the user.
- The user submits this request to `AttesterProxy`.
- `AttesterProxy` verifies the signature, then submits an equivalent attestation to EAS.

The recommended way is for the backend to use `AttesterProxy` with unordered delegated attestations. An example for this can be found in [examples](examples).

## Profiles

Profiles are minted through `ProfileRegistry`. Each wallet can mint only one profile. All profile share the same implementation, upgradable by Scroll to enable new features.

In its current version, a profile simply stores a user's preference when attaching badges.