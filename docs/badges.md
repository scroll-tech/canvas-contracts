# Skelly Badge FAQ

### What is a badge?

Each Skelly badge is an [EAS attestation](https://docs.attest.sh/docs/core--concepts/attestations), with some additional logic attached to it.

The badge attestation uses the official Scroll Skelly schema (see `SCROLL_SEPOLIA_BADGE_SCHEMA` in [deployments.md](./deployments.md)).
This means that the badge data includes two fields: `address badge, bytes payload`, and badges will go through the official Skelly badge resolver contract.


### How to implement a new badge?

As a badge developer, you need to deploy a badge contract that inherits from [`ScrollBadge`](../src/badge/ScrollBadge.sol).
Additionally, you can use one of more [extensions](../src/badge/extensions).

The badge must implement 3 APIs (see [`IScrollBadge`](../src/interfaces/IScrollBadge.sol)):
- `issueBadge`: Implement arbitrary logic that is triggered when a new badge is created.
- `revokeBadge`: Implement arbitrary logic that is triggered when a badge is revoked.
- `badgeTokenURI`: Return the badge token URI.
  This follows the same schema as ERC721's `tokenURI`.
  In most cases, the badge contract would use a static image, shared by all instances of this badge.
  However, on-chain-generated SVG data URLs are also possible.

Refer to the examples in [examples](../src/badge/examples).

> While this is not compulsory, we recommend creating badges that do no expire, are non-revocable, and are singletons (at most 1 badge per user).


### How to mint a badge?

Badges are created by attesting to the recipient using the `SCROLL_SEPOLIA_BADGE_SCHEMA`.
EAS provides multiple interfaces to attest: `attest`, `attestByDelegation`, `multiAttest`, `multiAttestByDelegation`. See [`IEAS.sol`](https://github.com/ethereum-attestation-service/eas-contracts/blob/master/contracts/IEAS.sol).
Another useful example is [`AttesterProxy.sol`](../src/AttesterProxy.sol), which allows creating unordered delegated attestations.

There are 3 main badge minting flows:
1. **Fully permissionless**.
   The user attests to themselves using `EAS.attest`.
   The badge contract ensures that the issuer is authorized.
   See [`ScrollBadgePermissionless.sol`](../src/badge/examples/ScrollBadgePermissionless.sol) and [`ScrollBadgeTokenOwner.sol`](../src/badge/examples/ScrollBadgeTokenOwner.sol).

2. **Backend-authorized**.
   A centralized backend implements some off-chain eligibility check.
   If the user is authorized to mint, the backend issues a signed permit.
   The user then mints by calling `AttesterProxy.attestByDelegation`.
   Note: In this case, the badge issuer will be the address of `AttesterProxy`.

3. **Airdropped**.
   Badges can also be issues with no user interaction.
   To do this, the issuer uses `EAS.attest` or `EAS.multiAttest`.


### How to ensure that the badge can be shown on scroll.io?

Simply provide the deployed badge contract address to the Scroll team.


### How to ensure that the badge can be minted on scroll.io?

TBA
