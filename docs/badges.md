# Badges

This section introduces the basic concepts of Canvas badges.
For jumping into code examples, see [Badge Examples](./badge-examples.md).

- [What is a badge?](#what-is-a-badge)
- [How to implement a new badge?](#how-to-implement-a-new-badge)
- [Badge Token URI](#badge-token-uri)
- [Ways to Issue Badges](#ways-to-issue-badges)
- [Overview of Requirements](#overview-of-requirements)
- [Upgradable Badges](#upgradable-badges)
- [Extensions](#extensions)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

### What is a badge?

Each Canvas badge is an [EAS attestation](https://docs.attest.sh/docs/core--concepts/attestations), with some additional logic attached to it.

The badge attestation uses the official Scroll Canvas schema (see `BADGE_SCHEMA` in [Deployments](./deployments.md)).
This means that the badge data contains two fields: `address badge, bytes payload`, and badges are issued through the official Canvas badge [resolver contract](../src/resolver/ScrollBadgeResolver.sol).


### How to implement a new badge?

Each badge must implement a certain interface to ensure it is compatible with Canvas.
In particular, each badge must implement 3 APIs (see [`IScrollBadge`](../src/interfaces/IScrollBadge.sol)):
- `issueBadge`: Implement arbitrary logic that is triggered when a new badge is created.
- `revokeBadge`: Implement arbitrary logic that is triggered when a badge is revoked.
- `badgeTokenURI`: Return the badge token URI.
  This follows the same schema as ERC721's `tokenURI`.
  In most cases, the badge contract would use a static image, shared by all instances of this badge.
  However, on-chain-generated SVG data URLs are also possible.

As a badge developer, it is strongly recommended that your contract inherits from [`ScrollBadge`](../src/badge/ScrollBadge.sol).
Additionally, you can use one or more [extensions](../src/badge/extensions).
Refer to the examples in [examples](../src/badge/examples).

> While this is not mandatory, we recommend creating badges that do no expire, are non-revocable, and are singletons (at most 1 badge per user).


### <a name="badge-token-uri"></a>Badge Token URI

Each badge must define a badge token URI.

The badge token URI is very similar to the tokenURI in ERC-721.
It must point to a metadata JSON object that contains `name`, `description`, `image`, and `issuerName`.
You can use a normal URL, an IPFS link, or a [data URL](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URLs) as your token URI.
The metadata is used by the Canvas frontend to render the badge.


For example, the badge token URI https://nft.scroll.io/canvas/year/2024.json points to the following metadata:

```json
{
  "name": "Ethereum Year",
  "description": "Check out the Ethereum Year Badge! It's like a digital trophy that shows off the year your wallet made its debut on Ethereum. It's a little present from Scroll to celebrate all the cool stuff you've done in the Ethereum ecosystem.",
  "image": "https://nft.scroll.io/canvas/year/2024.webp",
  "issuerName": "Scroll"
}
```

Your badge contract can provide a single URI for all badges, in which case all instances of your badge will look the same.
Alternatively, you can also render a different image for different instances of your badge, see [`EthereumYearBadge`](../src/badge/examples/EthereumYearBadge.sol).
You should also configure a default badge token URI, see [`ScrollBadgeDefaultURI`](../src/badge/extensions/ScrollBadgeDefaultURI.sol).

Design guidelines for badge images:
- Maximum resolution: 480px x 480px
- Optimal resolution: 600px x 600px
- File size: Under 300KB


### Ways to Issue Badges

Badges are created by attesting to the recipient using the [`BADGE_SCHEMA`](./deployments.md).
EAS provides multiple interfaces to attest: `attest`, `attestByDelegation`, `multiAttest`, `multiAttestByDelegation`. See [`IEAS.sol`](https://github.com/ethereum-attestation-service/eas-contracts/blob/master/contracts/IEAS.sol).

There are three main badge types of badges:

1. **Permissionless**.
   Permissionless badges allow users to attest to themselves using `EAS.attest`.
   The badge contract ensures that the user is authorized to mint.
   See [`ScrollBadgePermissionless.sol`](../src/badge/examples/ScrollBadgePermissionless.sol) and [`ScrollBadgeTokenOwner.sol`](../src/badge/examples/ScrollBadgeTokenOwner.sol).

2. **Backend-authorized**.
   For backend-authorized badges, the issuer maintains a centralized backend service.
   This backend implements some off-chain eligibility check and exposes an eligibility check and claim API.
   If the user is authorized to mint, the backend issues a signed permit.
   The user then mints using this permit.

   See [this document](https://scrollzkp.notion.site/Badge-APIs-95890d7ca14944e2a6d34835ceb6b914) for the API requirements.

   For backend-authorized badges, you need to deploy two contracts: the badge contract, and an [`AttesterProxy`](../src/AttesterProxy.sol).
   `AttesterProxy` allows executing delegated attestations in arbitrary order.
   The user can mint the badge by calling `AttesterProxy.attestByDelegation` and providing the signed permit.

3. **Gifted**.
   Badges can also be issued with no user interaction.
   To do this, the issuer uses `EAS.attest` or `EAS.multiAttest` to airdrop these badges to a list of users.


### Overview of Requirements

<table>
<tr>
<th style="text-align: center">Type</th>
<th style="text-align: center">Description</th>
<th style="text-align: center">Requirements</th>
<th style="text-align: center">Examples</th>
</tr>

<!-- row -->
<tr>
   <td>

   `Permissionless`

   </td>
   <td>

   Badge checks eligibility based on smart contract.

   **Example: Badges attesting to completing an onchain transaction or holding an NFT are eligible to mint the badge.**

   </td>
   <td>

   **Basic Requirements**:

   <ul>
   <li>

   The badge contract is deployed on the **Scroll Mainnet** and verified on [Scrollscan](https://scrollscan.com).

   </li>
   <li>

   The badge contract is configured to use the correct **badge resolver address**, see [Deployments](./deployments.md).

   </li>
   <li>

   The badge contract has a **default token URI**, see [ScrollBadgeDefaultURI](../src/badge/extensions/ScrollBadgeDefaultURI.sol).

   </li>
   <li>

   Your project is listed on [Scroll Ecosystem - Browse all protocols](https://scroll.io/ecosystem#protocols). (If not listed, apply [here](https://tally.so/r/waxLBW).)

   </li>
   </ul>

   **Additional Requirements**:

   <ul>
   <li>

   The badge contract implements on-chain eligibility check, see [ScrollBadgeEligibilityCheck](../src/badge/extensions/ScrollBadgeEligibilityCheck.sol).

   </li>
   </ul>
   </td>

   <td>

   [`ScrollBadgePermissionless`](../src/badge/examples/ScrollBadgePermissionless.sol), [`ScrollBadgeTokenOwner`](../src/badge/examples/ScrollBadgeTokenOwner.sol), [`ScrollBadgeWhale`](../src/badge/examples/ScrollBadgeWhale.sol).

   </td>
</tr>

<!-- row -->
<tr>
   <td>

   `Backend-authorized`

   </td>
   <td>

   Badge checks eligibility based on the issuer’s API.

   **Example: Badges attesting to completing offchain actions or a certain allow list.**

   </td>
   <td>

   All **Basic Requirements**, plus

   <ul>
   <li>

   The [**check API**](https://scrollzkp.notion.site/Badge-APIs-95890d7ca14944e2a6d34835ceb6b914) (off-chain eligibility check) and [**claim API**](https://scrollzkp.notion.site/Badge-APIs-95890d7ca14944e2a6d34835ceb6b914) have been deployed to **production**.

   </li>
   <li>

   All involved URLs, including those for the Check API, Claim API, and the badgeTokenURI returned by the contract, are configured for cross-origin access (CORS) on https://scroll.io.

   </li>
   <li>

   The attester proxy contract is deployed on the **Scroll Mainnet** and verified on [Scrollscan](https://scrollscan.com).

   </li>
   <li>

   The attester proxy contract is authorized to mint your badge (through `badge.toggleAttester`).

   </li>
   <li>

   The backend signer is authorized to sign permits (through `attesterProxy.toggleAttester`).

   </li>
   </ul>
   </td>

   <td>

   [`EthereumYearBadge`](../src/badge/examples/EthereumYearBadge.sol), [`ScrollBadgeSimple`](../src/badge/examples/ScrollBadgeSimple.sol).

   </td>
</tr>

<!-- row -->
<tr>
   <td>

   `Gifted`

   </td>
   <td>

   Badge checks eligibility based on the issuer’s API and automatically sends to users' canvas. There is no minting required for users to display the badge.

   **Example: Badges attesting to ownership or paid membership on other platforms / chains.**

   </td>
   <td>

   All **Basic Requirements**, plus

   <ul>
   <li>

   The [**check API**](https://scrollzkp.notion.site/Badge-APIs-95890d7ca14944e2a6d34835ceb6b914) has been deployed to **production**.

   </li>
   </ul>
   </td>

   <td>
   N/A
   </td>
</tr>

</table>


### Upgradable Badges

> This section is not about contract upgradability.
> If you want to make your badge contract upgradable, use any standard [upgradability pattern](https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies).

Upgradable badges are badges that can evolve over time.
This pattern is most suitable for badges that represent that the user has reached a certain "level".
A user can first mint a badge at a certain level.
Then, once the user is eligible, they can upgrade their badge to a higher level.

Upgradable badges must implement the [`IScrollBadgeUpgradeable`](../src/badge/extensions/IScrollBadgeUpgradeable.sol) interface.
Currently this interface only supports on-chain upgrade conditions.



### Extensions

This repo contains some useful [extensions](src/badge/extensions):
- `ScrollBadgeAccessControl` restricts who can create and revoke this badge.
- `ScrollBadgeCustomPayload` adds custom payload support to the badge.
- `ScrollBadgeDefaultURI` sets a default badge token URI.
- `ScrollBadgeEligibilityCheck` adds a standard on-chain eligibility check interface.
- `ScrollBadgeNoExpiry` disables expiration for the badge.
- `ScrollBadgeNonRevocable` disables revocation for the badge.
- `ScrollBadgeSBT` attaches an SBT token to each badge attestation.
- `ScrollBadgeSelfAttest` ensures that only the recipient of the badge can create the badge.
- `ScrollBadgeSingleton` ensures that each user can only have at most one of the badge.


### Examples

This repo also contains some [examples](src/badge/examples):
- `ScrollBadgeSimple` is a simple badge with fixed metadata.
- `ScrollBadgePermissionless` is a permissionless badge that anyone can mint to themselves.
- `ScrollBadgeLevels` is an SBT badge that stores a level in its payload and renders different images based on this level.
- `ScrollBadgeTokenOwner` is a badge that is tied to the ownership of a Scroll Origins NFT.


### Troubleshooting

We recommend going through the [requirements](#overview-of-requirements) before your badge is published.

If your badge minting transaction reverts, we recommend debugging using `cast`:

```sh
cast run --rpc-url https://rpc.scroll.io [txhash]
```

This call will simulate the transaction in a local environment and show you the call stack and revert reason.
