# Scroll Skelly Contracts

![Components overview](images/overview.png "Overview")

([Editable link](https://viewer.diagrams.net/?tags=%7B%7D&highlight=0000ff&edit=_blank&layers=1&nav=1&title=skelly-v4.drawio#R7VpLc6M4EP41rpo5xIWEMeYYx8nsIdma2Rx2clRABs0K5BVybO%2BvXwkknk7ijCEwNalUyqjVenV%2F%2FVDDxL6K91842kR3LMB0Aq1gP7FXEwgBsIH8UZRDTllY85wQchJoppJwT%2F7Dmmhp6pYEOK0xCsaoIJs60WdJgn1RoyHO2a7Otma0vuoGhbhFuPcRbVP%2FJoGI9Ckcq6T%2FgUkYmZWBpXtiZJg1IY1QwHYVkn09sa84YyJ%2FivdXmCrhGbnk426e6S02xnEiThkQf%2Ft2uwvggibu7Q9%2Fk1hfCbzQykjFwRwYB%2FL8usm4iFjIEkSvS%2BqSs20SYDWrJVslzy1jG0kEkvgDC3HQykRbwSQpEjHVvXLD%2FPBdj88aD6oxdUxzta92rg66lQrO%2FinUIAW4XBNKrxhlPNu7vV742PcLzkrP48KZOWqOttS0IFO25T5%2BQVQGfYiHWLzAZ%2Bd8So6VBbROvmAWY3kmycAxRYI81XGGNFzDgq%2FUqHzQSn2DgsEsn%2FgJ0a1eagLnVB5gGZCnmurn%2F24VFpd%2BLrZLtcfw8ZPjTaBc2yp%2FP2dylLaUiIs1igk95Nx3OKEsZ7qTgPD1s5wZxRIZSz3%2FlZQ0wVz2%2FIl3zc58SMwSlm6Q0kexUprBSa0DrM0%2B76AkwReRtr%2Bsy9Fd82K%2Beah%2BkRA4FZ8%2Bm8NLYWbnz3uPWsEtepTOrIZcREmYyGdfokeewF4%2BYS6I9BaXuiMmQZAbCZb7RY%2FZfAp3G0YSkSnXWU6clcKuPJQxNKsNy5fMVa2K95Mj%2Fk%2BvWHMxNdTpURfW1Fo4bj72UJvpZFzqyb%2Bqk5WzXHj1EWy9TqW9NHFcbOkMaLeQfX1539LkLiIC3%2BdYWu1kkGpoNN3kYWNN9sqn1dRyxMeCZzTwrKTthVWTsu3q9q4STjQpqkQSQ%2BvcI8CW2O79CMfIWMYjN1bxFw5JapY8R6Ytd7zM%2FrS0j9F7EDx0Bha8O2isLRqnxVq8J%2BJ7ySlbD5WecpBq1OPzm9T5atS1T4y6cFRR12uperCkqR5mOrXFzpQ3G5XyzNVjDNobNuU9VX%2FOqPRnHwlwnFG6RGp%2FR6JcyuiTykdHljk4zsgyh%2FZVoibYDsXXsaM6XeZuU%2BZwYJk77ybzLiDbFN9saPEB%2BJv48ld9NOjaRzeufxoB0G0gADRUmwcdPaqHS2Hb%2B3%2FUO37Zeocx304KHrAGTN06E%2B5FsmiqH4v6DD1WPxYfQFe%2F1pRnZQrMxwT202Ppm5Hs2I26Rn%2BVonbForfgCU8tSIBqOaIoTrxfQQLOhwq4512KwFEz6L36FFyql3CymbAE55QborauFYS4MBw%2BRWlKfEPWbKBnPfadEIFZw1y9hrnmQGolRFIq6FBh0z7mzevc%2FBy%2FfMh30GnQMkKvBK3LLFFRUaN5Mf%2FK2f782vMorpWwKeyha9HwI3vIMEbSdIuzu%2FSYsodXUuXOUom5Z00tS6JzMfechV2%2FuM1U38yZyX%2FHdW3YV2CyPpBYXtiWh7YfXGGKQxmCWDImjPYIS5DBEngAQMe1JDgXdec596ae58zmnu1CD3p9AXPgb2PKetJDte%2B59PiVTCtAaZTtC5yVNRk38Ktlv27LyUh7Q340Dst5EX%2Fn25M1BZb51uNns9n%2BCxoGWhUdyQxwTej4ytzNTwtm3sDpnH3sK68hndfkTZXxM%2FzRqa8oDbpedUhlvdC27XpKZGp9I7ah9usin2Mk2iY0Ij9nsNtFjRdA68zCrinkNt9b9Ki09iuLwvH19klW1y4RgndzibJZfjWdK6H89ty%2B%2Fh8%3D))

## Overview

**Profiles**: Each user can create a `Profile` contract, minted through the `ProfileRegistry`. All profiles share the same implementation.

**Badges**: Each badge is an EAS attestation that goes through the `ScrollBadgeResolver` contract.
- Each individual badge type is a standalone `ScrollBadge` contract, which manages the badge-specific logic. This badge contract can implement arbitrary logic attached to the attestation.
- Badges implement a `badgeTokenURI` interface, similar to `ERC721.tokenURI`.
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