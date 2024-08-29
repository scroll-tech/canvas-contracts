# Badge Examples

- [Permissionless Singleton Badge](#permissionless-singleton-badge)
  - [Writing the badge from scratch](#writing-the-badge-from-scratch)
  - [Reusing extensions](#reusing-extensions)
  - [Minting the badge](#minting-the-badge)
- [Custom Payload and Complex On-Chain Eligibility Checks](#custom-payload-and-complex-on-chain-eligibility-checks)
- [Backend-Authorized Badges](#backend-authorized-badges)

## Permissionless Singleton Badge

### Writing the badge from scratch

First, we will walk through an example of implementing a simple badge from scratch.
The example here, `MyScrollBadge`, is a permissionless badge, i.e. anyone can mint it independently.
The only restriction is that we will require that each user mint for themselves, i.e. you cannot gift a badge to someone else.
We will also ensure that it is a singleton badge, meaning that each user can mint at most one badge.

We start by importing [`Attestation`](https://github.com/ethereum-attestation-service/eas-contracts/blob/b84f18326432e5f23ec0dfa5dab06ea154c2a502/contracts/Common.sol#L25) from EAS, and [`ScrollBadge`](../src/badge/ScrollBadge.sol) from Canvas.
Just like our example `MyScrollBadge` here, each valid badge is a direct or indirect subclass of `ScrollBadge`.
This ensures that each badge implements the correct interface that [`ScrollBadgeResolver`](../src/resolver/ScrollBadgeResolver.sol) knows how to interact with.

```solidity
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";
import {ScrollBadge} from "../ScrollBadge.sol";

contract MyScrollBadge is ScrollBadge {
    // ...
}
```

For correct display, each badge must have a [badge token URI](./badges.md#badge-token-uri).
In this example, we will use a static token URI that is shared for all badges minted with this contract.
This can be a link to a JSON stored on a centralized backend, or stored on decentralized storage like IPFS.

It is important to note that each badge must configure the correct resolved address during deployment.
See the address in [Deployments](./deployments.md).

```solidity
string public staticTokenURI;

constructor(address resolver_, string memory tokenURI_) ScrollBadge(resolver_) {
    staticTokenURI = tokenURI_;
}

function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
    return staticTokenURI;
}
```

Next, we implement the `onIssueBadge` hook that is called when your badge is minted.
You can execute checks and revert or return false to prevent an invalid badge from being minted.
Here, we implement two checks:
First, we make sure that the user does not already have a badge.
Second, we check whether the user is minting for themselves or not.

```solidity
function onIssueBadge(Attestation calldata attestation) internal virtual override returns (bool) {
    if (!super.onIssueBadge(attestation)) {
        return false;
    }

    // singleton
    if (hasBadge(attestation.recipient)) {
        revert SingletonBadge();
    }

    // self-attest
    if (attestation.recipient != attestation.attester) {
        revert Unauthorized();
    }

    return true;
}
```

Similarly, we also need to implement the `onRevokeBadge` hook, but in most cases, this will be empty.

```solidity
/// @inheritdoc ScrollBadge
function onRevokeBadge(Attestation calldata attestation) internal virtual override returns (bool) {
    return super.onRevokeBadge(attestation);
}
```

Finally, we add the on-chain eligibility check function `isEligible` so that the frontend can check if the user is eligible or not.

```solidity
function isEligible(address recipient) external virtual returns (bool) {
    return !hasBadge(recipient);
}
```

And now we are ready!
You have implemented your first badge.

### Reusing extensions

This type of badge is quite common, so we offer some useful extensions that you can reuse.
You can write the same contract using the [`ScrollBadgeSelfAttest`](../src/badge/extensions/ScrollBadgeSelfAttest.sol), [`ScrollBadgeEligibilityCheck`](../src/badge/extensions/ScrollBadgeEligibilityCheck.sol), and [`ScrollBadgeSingleton`](../src/badge/extensions/ScrollBadgeSingleton.sol) extensions from this repo.

```solidity
pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadge} from "../ScrollBadge.sol";
import {ScrollBadgeSelfAttest} from "../extensions/ScrollBadgeSelfAttest.sol";
import {ScrollBadgeEligibilityCheck} from "../extensions/ScrollBadgeEligibilityCheck.sol";
import {ScrollBadgeSingleton} from "../extensions/ScrollBadgeSingleton.sol";

/// @title ScrollBadgePermissionless
/// @notice A simple badge that anyone can mint in a permissionless manner.
contract ScrollBadgePermissionless is ScrollBadgeSelfAttest, ScrollBadgeEligibilityCheck, ScrollBadgeSingleton {
    string public staticTokenURI;

    constructor(address resolver_, string memory tokenURI_) ScrollBadge(resolver_) {
        staticTokenURI = tokenURI_;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        virtual
        override (ScrollBadge, ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        virtual
        override (ScrollBadge, ScrollBadgeSelfAttest, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 /*uid*/ ) public pure override returns (string memory) {
        return staticTokenURI;
    }
}
```

### Minting the badge

Permissionless badges can be minted directly through EAS.
The user can simply call [`EAS.attest`](https://github.com/ethereum-attestation-service/eas-contracts/blob/b84f18326432e5f23ec0dfa5dab06ea154c2a502/contracts/IEAS.sol#L117) and provide the Scroll Canvas [schema UID](./deployments.md) and the attestation.
The attestation payload must include the badge contract address.


## Custom Payload and Complex On-Chain Eligibility Checks

You can attach a custom payload to your badge attestations, that can then be processed in your badge contract.
Let us consider an example of a simple badge that attests that you have reached a certain level.

Start by deciding your badge payload format.
In this case, we only need a single `uint8` field, signifying the user's level.
Note: The badge payload is encoded using Solidity's [ABI encoding](https://docs.soliditylang.org/en/develop/abi-spec.html).

```solidity
string constant BADGE_LEVELS_SCHEMA = "uint8 scrollLevel";

function decodePayloadData(bytes memory data) pure returns (uint8) {
    return abi.decode(data, (uint8));
}
```

If your contract inherits from the [`ScrollBadgeCustomPayload`](../src/badge/extensions/ScrollBadgeCustomPayload.sol) extension, then you can conveniently use the `getPayload` function.

```solidity
contract ScrollBadgeLevels is ScrollBadgeCustomPayload {
    // ...

    /// @inheritdoc ScrollBadgeCustomPayload
    function getSchema() public pure override returns (string memory) {
        return BADGE_LEVELS_SCHEMA;
    }

    function getCurrentLevel(bytes32 uid) public view returns (uint8) {
        Attestation memory badge = getAndValidateBadge(uid);
        bytes memory payload = getPayload(badge);
        (uint8 level) = decodePayloadData(payload);
        return level;
    }
}
```

You can access and interpret the payload during badge minting (in `onIssueBadge`) and badge revocation (in `onRevokeBadge`):

```solidity
function onIssueBadge(Attestation calldata attestation) internal override returns (bool) {
    if (!super.onIssueBadge(attestation)) return false;

    bytes memory payload = getPayload(attestation);
    (uint8 level) = decodePayloadData(payload);

    if (level > 10) {
        revert InvalidLevel();
    }

    return true;
}
```

You can also use the custom payload when constructing the token URI (in `badgeTokenURI`).
This is particularly useful for badges that generate different token URIs based on each badge using [Data URLs](https://developer.mozilla.org/en-US/docs/Web/URI/Schemes/data):

```solidity
/// @inheritdoc ScrollBadge
function badgeTokenURI(bytes32 uid) public pure override returns (string memory) {
    uint8 level = getCurrentLevel(uid);

    string memory name = string(abi.encode("Level #", Strings.toString(level)));
    string memory description = "Level Badge";
    string memory image = ""; // IPFS, HTTP, or data URL
    string memory issuerName = "Scroll";

    string memory tokenUriJson = Base64.encode(
        abi.encodePacked('{"name":"', name, '", "description":"', description, ', "image": "', image, ', "issuerName": "', issuerName, '"}')
    );

    return string(abi.encodePacked("data:application/json;base64,", tokenUriJson));
}
```

You can see the full example in [`ScrollBadgeLevels`](../src/badge/examples/ScrollBadgeLevels.sol).


## Backend-Authorized Badges

Backend authorized badges are badges that require a signed permit to be minted.
This is generally used for badges when there is a centralized issuer who wishes to control who can and cannot mint.
Another use case is off-chain eligibility check, when the signer of the permit vouches that the user is eligible.

The simplest backend-authorized badge is implemented like this (see [`ScrollBadgeSimple`](../src/badge/examples/ScrollBadgeSimple.sol)):

```solidity
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";

import {ScrollBadgeAccessControl} from "../extensions/ScrollBadgeAccessControl.sol";
import {ScrollBadgeSingleton} from "../extensions/ScrollBadgeSingleton.sol";
import {ScrollBadge} from "../ScrollBadge.sol";

/// @title ScrollBadgeSimple
/// @notice A simple badge that has the same static metadata for each token.
contract ScrollBadgeSimple is ScrollBadgeAccessControl, ScrollBadgeSingleton {
    string public sharedTokenURI;

    constructor(address resolver_, string memory tokenUri_) ScrollBadge(resolver_) {
        sharedTokenURI = tokenUri_;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation)
        internal
        override (ScrollBadgeAccessControl, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onIssueBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata attestation)
        internal
        override (ScrollBadgeAccessControl, ScrollBadgeSingleton)
        returns (bool)
    {
        return super.onRevokeBadge(attestation);
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 /*uid*/ ) public view override returns (string memory) {
        return sharedTokenURI;
    }
}
```

Importantly, this badge inherits from `ScrollBadgeAccessControl`.
This allows the deployed to control who is authorized to mint.

To implement the backend-authorized minting flow, you need to deploy two contracts: the badge contract itself (`ScrollBadgeSimple` in this example) and the attester proxy contract ([`AttesterProxy`](../src/AttesterProxy.sol)).
The attester proxy is a simple contract that verifies permits and mints badges.

For such badges, all attestations are minted through the attester proxy.
For this reason, you need to authorize the proxy to mint your badge by calling `badge.toggleAttester(attesterProxy, true)`.

The attester proxy in turn needs to know who is authorized to sign permits, which is typically a private key in your backend.
You also need to authorize this account by calling `attesterProxy.toggleAttester(signer, true)`.

Finally, you need to configure a backend that implements two public APIs: eligibility check and claim.

Minting through the Scroll Canvas website then works as follows:
1. The frontend calls your eligibility API to see if the user is eligible.
2. If yes, a mint button is shown to the user. When the user clicks it, the frontend calls your claim API to get the signer permit.
3. The signed permit is submitted from the user's wallet to your attester proxt contract.
4. The attester proxy contract verifies the signature and then creates an attestation through EAS.
5. EAS creates an attestation, then calls `ScrollBadgeResolver`, which in turn calls your badge contract.
6. Your badge contract executes any additional actions and checks.
