# Skelly Integration FAQ

In the examples on this page, we use the following configurations:

```bash
# EAS constants -- these will not change on a network
SCROLL_SEPOLIA_EAS_ADDRESS="0xaEF4103A04090071165F78D45D83A0C0782c2B2a"
SCROLL_SEPOLIA_EAS_SCHEMA_REGISTRY_ADDRESS="0x55D26f9ae0203EF95494AE4C170eD35f4Cf77797"

# Scroll Skelly constants -- these will not change on a network (after the final deployment)
SCROLL_SEPOLIA_BADGE_RESOLVER_ADDRESS="0xD4F2403f470B8B056e36D9903BA6EE69e8fF0433"
SCROLL_SEPOLIA_BADGE_SCHEMA="0x9fc9fd858b77f32006252152958f4a2aa256608bd8813ebfb9d36ddb6ac454a7"
SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS="0x7f58D95D31E36DF5F287dd919EFd214CD9485A6d"

# Skelly badges -- each badge type is a new contract, here we only have a simple test contract
SCROLL_SEPOLIA_SIMPLE_BADGE_ADDRESS="0xB5a278028866bB619601B58B032B02d31A9Fa539"

# Skelly profiles -- each user has their own profile (a smart contract), here we provide a simple test profile
SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS="0x487C1f4AD3eB56F61BC049108410d6E9F1EFb3F9"

# APIs
SCROLL_SEPOLIA_RPC_URL="https://sepolia-rpc.scroll.io"
SCROLL_SEPOLIA_EAS_GRAPHQL_URL="https://scroll-sepolia.easscan.org/graphql"
```

The following examples use Foundry's `cast`, but the same queries can be made using curl, ethers, etc. analogously.


### How to check if a user has minted their profile yet?

We first query the user's deterministic profile address, then see if the profile has been minted or not.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "getProfile(address)(address)" "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0"
0x487C1f4AD3eB56F61BC049108410d6E9F1EFb3F9

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "isProfileMinted(address)(bool)" "0x487C1f4AD3eB56F61BC049108410d6E9F1EFb3F9"
false
```


### How to mint a profile?

```bash
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "mintProfile(string)" "username1" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
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
      schemaId: { equals: "0x9fc9fd858b77f32006252152958f4a2aa256608bd8813ebfb9d36ddb6ac454a7" },
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

```bash
> curl --request POST --header 'content-type: application/json' --url "$SCROLL_SEPOLIA_EAS_GRAPHQL_URL" --data-binary @- << EOF
{
  "query": " \
    query Attestation { \
      attestations( \
        where: { \
          schemaId: { equals: \"0x9fc9fd858b77f32006252152958f4a2aa256608bd8813ebfb9d36ddb6ac454a7\" }, \
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

{
  "data": {
    "attestations": [
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x000000000000000000000000b5a278028866bb619601b58b032b02d31a9fa53900000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0x6346f8fd2ba17fb5540589cf4ba88ce1c5a5c3af01f3b807c28abd0ea4f80737",
        "time": 1708607016,
        "txid": "0x1ebef71e392065c7ce26960fc2b15bcf27164a77369ac8fe0a891f78d3042015"
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
> cast abi-decode "foo(address,bytes)" --input "0x000000000000000000000000b5a278028866bb619601b58b032b02d31a9fa53900000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000"
0xB5a278028866bB619601B58B032B02d31A9Fa539
0x
```


### How to get a badge image?

First, collect the badge attestation UID and the badge contract address. Then call `badgeTokenURI`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "0xB5a278028866bB619601B58B032B02d31A9Fa539" "badgeTokenURI(bytes32)(string)" "0x6346f8fd2ba17fb5540589cf4ba88ce1c5a5c3af01f3b807c28abd0ea4f80737"
"https://ipfs.io/ipfs/QmVXPw1DfL9h5uZ34voQ3QtdN8akpPEuVpKKNRPjfAii2K"
```

The result is a badge token URI, which follows the same schema as ERC721 tokens: The token URI points to a JSON file with `name`, `description`, and `image` fields. The token URI can be a HTTP or IPFS link, or it can be a [data URL](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URLs).


### How to check if a user has a certain badge or not?

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_SIMPLE_BADGE_ADDRESS" "hasBadge(address)(bool)" "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0"
true
```
