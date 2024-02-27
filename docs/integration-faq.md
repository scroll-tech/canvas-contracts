# Skelly Integration FAQ

In the examples on this page, we use the following configurations:

```bash
# EAS constants -- these will not change on a network
SCROLL_SEPOLIA_EAS_ADDRESS="0xaEF4103A04090071165F78D45D83A0C0782c2B2a"
SCROLL_SEPOLIA_EAS_SCHEMA_REGISTRY_ADDRESS="0x55D26f9ae0203EF95494AE4C170eD35f4Cf77797"

# Scroll Skelly constants -- these will not change on a network (after the final deployment)
SCROLL_SEPOLIA_BADGE_RESOLVER_ADDRESS="0x2e755a76445C97DB9a85f9d8D16c23D8B0B905a2"
SCROLL_SEPOLIA_BADGE_SCHEMA="0x27286228489df3c9e68c47f3b408177df3ed1e5c19bec34c009a6e1357e1182e"
SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS="0xD9c84A60881d11995Ffe11192a2eD3df601E3E1f"

# Skelly badges -- each badge type is a new contract, here we only have three simple test contracts
SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS="0x20a6c7B796287eB897bCc99c1d574F29Cd332CE5"
SCROLL_SEPOLIA_SIMPLE_BADGE_B_ADDRESS="0xf9498A67A01E9a09070D56B0125a78683dc32653"
SCROLL_SEPOLIA_SIMPLE_BADGE_C_ADDRESS="0xEE68fbcA1D3B03C0d1FA3e4c8697e90fA00BcF39"

# Skelly profiles -- each user has their own profile (a smart contract), here we provide a simple test profile
SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS="0x984f0481E246E94B3524C8875Dfa5163FbaBa5c6"

# APIs
SCROLL_SEPOLIA_RPC_URL="https://sepolia-rpc.scroll.io"
SCROLL_SEPOLIA_EAS_GRAPHQL_URL="https://scroll-sepolia.easscan.org/graphql"
```

The following examples use Foundry's `cast`, but the same queries can be made using curl, ethers, etc. analogously.


### How to check if a user has minted their profile yet?

We first query the user's deterministic profile address, then see if the profile has been minted or not.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "getProfile(address)(address)" "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0"
0x984f0481E246E94B3524C8875Dfa5163FbaBa5c6

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "isProfileMinted(address)(bool)" "0x984f0481E246E94B3524C8875Dfa5163FbaBa5c6"
false
```


### How to mint a profile?

Mint a profile without referral:

```bash
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "mint(string,bytes)" "username1" "" --value "0.001ether" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```

To mint a profile with a referral, produce a signed referral, then submit it along with the `mint` call (see [referral.js](../examples/src/referral.js) for details).

```bash
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "mint(string,bytes)" "username2" "0x000000000000000000000000f138edc6038c237e94450bcc9a7085a7b213caf00000000000000000000000000000000000000000000000000000000065dc905500000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000041abd19d967e8e5f5f410afebd45752e36f78e6a6ae41939bce4b9747289e191b5659b58e6ce555a72e4c811bc3c8e8e7f9c2537a7295073c7cf060d4179d38d4f1c00000000000000000000000000000000000000000000000000000000000000" --value "0.0005ether" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```


### How to query and change the username?

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "username()(string)"
"username1"

> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "changeUsername(string)" "username2" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```


### How to list all badges that a user has?

We can use the EAS GraphQL API to query a user's Skelly badges.

> Warning: Badges are minted to the user's wallet address, not to their profile address!

```
query Attestation {
  attestations(
    where: {
      schemaId: { equals: "0x27286228489df3c9e68c47f3b408177df3ed1e5c19bec34c009a6e1357e1182e" },
      recipient: { equals: "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0" },
      revoked: { equals: false }
    }
  ) {
    attester
    data
    id
    time
    txid
  }
}
```

See https://studio.apollographql.com/sandbox/explorer for more query options.

Request:

```bash
> curl --request POST --header 'content-type: application/json' --url "$SCROLL_SEPOLIA_EAS_GRAPHQL_URL" --data-binary @- << EOF
{
  "query": " \
    query Attestation { \
      attestations( \
        where: { \
          schemaId: { equals: \"0x27286228489df3c9e68c47f3b408177df3ed1e5c19bec34c009a6e1357e1182e\" }, \
          recipient: { equals: \"0xF138EdC6038C237e94450bcc9a7085a7b213cAf0\" }, \
          revoked: { equals: false } \
        } \
      ) { \
        attester \
        data \
        id \
        time \
        txid \
      } \
    } \
  "
}
EOF
```

Response:

```json
{
  "data": {
    "attestations": [
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x00000000000000000000000020a6c7b796287eb897bcc99c1d574f29cd332ce500000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0xfa97ab8fd614a202937e83b8f68fdf16e688b2fa4d0e657b5e02872ec7521c83",
        "time": 1708949771,
        "txid": "0x26ce8f531afab59d00ee9fc1a6063a559b4458f75d68ef653415cff9d150ebc4"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x000000000000000000000000f9498a67a01e9a09070d56b0125a78683dc3265300000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0xb9a4419bc40585bd37d3642302b35b1e79249843af501a4795ad8497dbc6e5ec",
        "time": 1708949780,
        "txid": "0x2a1677180ec12c458e3b2aca1931b8b98ef4ba7b6852521d390aa2d188395d1a"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x000000000000000000000000ee68fbca1d3b03c0d1fa3e4c8697e90fa00bcf3900000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0x609040a78544efe6caceddd184836907060a9ebbdf606d264a8665e245bb2115",
        "time": 1708949793,
        "txid": "0xd9e051afa84b4e50c38d3b9fb5b4a9399828b5349d2d64d6b7b83b4acb38791d"
      }
    ]
  }
}
```


### How to decode badge payload?

Each badge is an attestation, whose `data` field contains the abi-encoded badge payload, using the following schema:

```
address badge, bytes payload
```

`badge` is the badge contract address, while `payload` is additional application-specific data.

```bash
> cast abi-decode "foo(address,bytes)" --input "0x00000000000000000000000020a6c7b796287eb897bcc99c1d574f29cd332ce500000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000"
0x20a6c7B796287eB897bCc99c1d574F29Cd332CE5
0x
```


### How to get a badge image?

To get the token URI of a certain badge, first collect the badge attestation UID and the badge contract address. Then call `badgeTokenURI`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS" "badgeTokenURI(bytes32)(string)" "0xfa97ab8fd614a202937e83b8f68fdf16e688b2fa4d0e657b5e02872ec7521c83"
"https://ipfs.io/ipfs/QmVXPw1DfL9h5uZ34voQ3QtdN8akpPEuVpKKNRPjfAii2K"
```

The result is a badge token URI, which follows the same schema as ERC721 tokens: The token URI points to a JSON file with `name`, `description`, and `image` fields. The token URI can be a HTTP or IPFS link, or it can be a [data URL](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URLs).

To get the default token URI of a badge, simply call `badgeTokenURI` with the *zero UID*. The default badge token URI can be the same as the token URI of a specific badge, or it can be different, depending on the badge implementation.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS" "badgeTokenURI(bytes32)(string)" "0x0000000000000000000000000000000000000000000000000000000000000000"
"https://ipfs.io/ipfs/QmVXPw1DfL9h5uZ34voQ3QtdN8akpPEuVpKKNRPjfAii2K"
```


### How to check if a user has a certain badge or not?

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS" "hasBadge(address)(bool)" "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0"
true
```


### How to configure a profile avatar?

A user can use one of their own NFTs as their avatar. To do this, they need to provide the ERC721 contract address and the token ID.

```bash
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "changeAvatar(address,uint256)" "0x74670A3998d9d6622E32D0847fF5977c37E0eC91" "1" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```


### How to attach a badge?

A user can attach one or more badges to their profile. Badges are referenced by their attestation UID.

```bash
# attach one
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attach([bytes32])" "[0xfa97ab8fd614a202937e83b8f68fdf16e688b2fa4d0e657b5e02872ec7521c83]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# attach many
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attach(bytes32[])" "[0xb9a4419bc40585bd37d3642302b35b1e79249843af501a4795ad8497dbc6e5ec,0x609040a78544efe6caceddd184836907060a9ebbdf606d264a8665e245bb2115]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# detach
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "detach(bytes32[])" "[0x609040a78544efe6caceddd184836907060a9ebbdf606d264a8665e245bb2115]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```


### How to query the attached badges?

To see which badges are attached to a profile, we can call `getAttachedBadges`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getAttachedBadges()(bytes32[])"
[0xfa97ab8fd614a202937e83b8f68fdf16e688b2fa4d0e657b5e02872ec7521c83, 0xb9a4419bc40585bd37d3642302b35b1e79249843af501a4795ad8497dbc6e5ec, 0x609040a78544efe6caceddd184836907060a9ebbdf606d264a8665e245bb2115]
```

To get the order of the badges, we can call `getBadgeOrder`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getBadgeOrder()(uint256[])"
[1, 2, 3]
```


### How to reorder the attached badges?

Let's say the user has 3 badges attached: `A`, `B`, `C`. If we want to reorder these to `C`, `B`, `A`, we need to submit the following transaction:

```bash
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "reorderBadges(uint256[])" "[3, 2, 1]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getAttachedBadges()(bytes32[])"
[0xfa97ab8fd614a202937e83b8f68fdf16e688b2fa4d0e657b5e02872ec7521c83, 0xb9a4419bc40585bd37d3642302b35b1e79249843af501a4795ad8497dbc6e5ec, 0x609040a78544efe6caceddd184836907060a9ebbdf606d264a8665e245bb2115]

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getBadgeOrder()(uint256[])"
[3, 2, 1]
```
