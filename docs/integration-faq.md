# Skelly Integration FAQ

In the examples on this page, we use the following configurations:

```bash
# EAS constants -- these will not change on a network
SCROLL_SEPOLIA_EAS_ADDRESS="0xaEF4103A04090071165F78D45D83A0C0782c2B2a"
SCROLL_SEPOLIA_EAS_SCHEMA_REGISTRY_ADDRESS="0x55D26f9ae0203EF95494AE4C170eD35f4Cf77797"

# Scroll Skelly constants -- these will not change on a network (after the final deployment)
SCROLL_SEPOLIA_BADGE_RESOLVER_ADDRESS="0xb9D21d4B73132B7ab2D13711b7B5cFCE2BEBeb24"
SCROLL_SEPOLIA_BADGE_SCHEMA="0xc6b4e9e7f31283212a123aced1e8fdd6a126a5f2d9f6f249eab8e3edc9ac9dc6"
SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS="0x886c1b524e3fc6568EC7AB9d13E7cAcb6a07a2db"

# Skelly badges -- each badge type is a new contract, here we only have a simple test contract
SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS="0x8eb3bf3866084fD5c2Ca39fe6b251958ca2a5be0"
SCROLL_SEPOLIA_SIMPLE_BADGE_B_ADDRESS="0x3D649e9946634BBEe903e1263d000Be7d77EFfF1"
SCROLL_SEPOLIA_SIMPLE_BADGE_C_ADDRESS="0xF45e0026DDfc249864fD4E7d045a3be9e7a1313f"

# Skelly profiles -- each user has their own profile (a smart contract), here we provide a simple test profile
SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS="0x97218b8fEDfB8980a4505901185f4757129F032B"

# APIs
SCROLL_SEPOLIA_RPC_URL="https://sepolia-rpc.scroll.io"
SCROLL_SEPOLIA_EAS_GRAPHQL_URL="https://scroll-sepolia.easscan.org/graphql"
```

The following examples use Foundry's `cast`, but the same queries can be made using curl, ethers, etc. analogously.


### How to check if a user has minted their profile yet?

We first query the user's deterministic profile address, then see if the profile has been minted or not.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "getProfile(address)(address)" "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0"
0x97218b8fEDfB8980a4505901185f4757129F032B

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "isProfileMinted(address)(bool)" "0x97218b8fEDfB8980a4505901185f4757129F032B"
false
```


### How to mint a profile?

Mint a profile without referral:

```bash
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "mint(string,bytes)" "username1" "" --value "0.001ether" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
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
      schemaId: { equals: "0xc6b4e9e7f31283212a123aced1e8fdd6a126a5f2d9f6f249eab8e3edc9ac9dc6" },
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
          schemaId: { equals: \"0xc6b4e9e7f31283212a123aced1e8fdd6a126a5f2d9f6f249eab8e3edc9ac9dc6\" }, \
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
        "data": "0x0000000000000000000000008eb3bf3866084fd5c2ca39fe6b251958ca2a5be000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0xad95b842d4dda20d4de0056214bfb2de0eac7157ab2ee90ed252c55bea05f0ff",
        "time": 1708702218,
        "txid": "0xdff7194d9b276354d968cdf6a70e380def3335f2889b5963b72b2b74a0dcc06c"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x0000000000000000000000003d649e9946634bbee903e1263d000be7d77efff100000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0x63c31ad75a5b36e742e650b0b233606b4425af9df3e6edffea14248157724ce9",
        "time": 1708702227,
        "txid": "0x2680da68b08115aa7e1d451d5697a79e96520b13c262139775536f06252ed1e1"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x000000000000000000000000f45e0026ddfc249864fd4e7d045a3be9e7a1313f00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0x593e2d05bc8a893d3bd32bf810cf7d99dff85cdfbb4ab4a943db6438c6790286",
        "time": 1708702236,
        "txid": "0x5f27d84bb1c01f5ac5480e67dad66bea95b5ee7a141d61fdbb573cb1bfd9e8b1"
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
> cast abi-decode "foo(address,bytes)" --input "0x0000000000000000000000008eb3bf3866084fd5c2ca39fe6b251958ca2a5be000000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000"
0x8eb3bf3866084fD5c2Ca39fe6b251958ca2a5be0
0x
```


### How to get a badge image?

First, collect the badge attestation UID and the badge contract address. Then call `badgeTokenURI`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS" "badgeTokenURI(bytes32)(string)" "0xad95b842d4dda20d4de0056214bfb2de0eac7157ab2ee90ed252c55bea05f0ff"
"https://ipfs.io/ipfs/QmVXPw1DfL9h5uZ34voQ3QtdN8akpPEuVpKKNRPjfAii2K"
```

The result is a badge token URI, which follows the same schema as ERC721 tokens: The token URI points to a JSON file with `name`, `description`, and `image` fields. The token URI can be a HTTP or IPFS link, or it can be a [data URL](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URLs).


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
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attachOne(bytes32)" "0xad95b842d4dda20d4de0056214bfb2de0eac7157ab2ee90ed252c55bea05f0ff" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# attach many
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attach(bytes32[])" "[0x63c31ad75a5b36e742e650b0b233606b4425af9df3e6edffea14248157724ce9,0x593e2d05bc8a893d3bd32bf810cf7d99dff85cdfbb4ab4a943db6438c6790286]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# detach
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "detach(bytes32[])" "[0x593e2d05bc8a893d3bd32bf810cf7d99dff85cdfbb4ab4a943db6438c6790286]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```


### How to query the attached badges?

To see which badges are attached to a profile, we can call `getAttachedBadges`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getAttachedBadges()(bytes32[])"
[0xad95b842d4dda20d4de0056214bfb2de0eac7157ab2ee90ed252c55bea05f0ff, 0x63c31ad75a5b36e742e650b0b233606b4425af9df3e6edffea14248157724ce9, 0x593e2d05bc8a893d3bd32bf810cf7d99dff85cdfbb4ab4a943db6438c6790286]
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
[0xad95b842d4dda20d4de0056214bfb2de0eac7157ab2ee90ed252c55bea05f0ff, 0x63c31ad75a5b36e742e650b0b233606b4425af9df3e6edffea14248157724ce9, 0x593e2d05bc8a893d3bd32bf810cf7d99dff85cdfbb4ab4a943db6438c6790286]

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getBadgeOrder()(uint256[])"
[3, 2, 1]
```
