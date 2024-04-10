# Canvas Integration FAQ

In the examples on this page, we use the configurations from [deployments.md](./deployments.md), as well as the following values:

```bash
# Canvas badges -- each badge type is a new contract, here we only have three simple test contracts
SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS="0x30C98067517f8ee38e748A3aF63429974103Ea6B"
SCROLL_SEPOLIA_SIMPLE_BADGE_B_ADDRESS="0xeBFc9B95328B2Cdb3c4CA8913e329c101d2Abbc2"
SCROLL_SEPOLIA_SIMPLE_BADGE_C_ADDRESS="0x64492EF5a60245fbaF65F69782FCf158F3a8e3Aa"

# Canvas profiles -- each user has their own profile (a smart contract), here we provide a simple test profile
SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS="0xa10561B0b0f9F66Ec18A1Eff58e6F37D59dbbdeC"
```

The following examples use Foundry's `cast`, but the same queries can be made using curl, ethers, etc. analogously.


### How to check if a user has minted their profile yet?

We first query the user's deterministic profile address, then see if the profile has been minted or not.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "getProfile(address)(address)" "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0"
0xa10561B0b0f9F66Ec18A1Eff58e6F37D59dbbdeC

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "isProfileMinted(address)(bool)" "0xa10561B0b0f9F66Ec18A1Eff58e6F37D59dbbdeC"
false
```


### How to mint a profile?

Mint a profile without referral:

```bash
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "mint(string,bytes)" "username1" "0x" --value "0.001ether" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```

To mint a profile with a referral, produce a signed referral, then submit it along with the `mint` call (see [referral.js](../examples/src/referral.js) for details).

```bash
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "mint(string,bytes)" "username2" "0x000000000000000000000000f138edc6038c237e94450bcc9a7085a7b213caf00000000000000000000000000000000000000000000000000000000065e194a500000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000041dbced15b87df9b122ae418b3189b39a46c542daf4a724b57fb796670ece2dcdc652a1ae20a6a459e85b77fd4135dc4b90c4eac5352b555c0e42c8d8b8999e64e1c00000000000000000000000000000000000000000000000000000000000000" --value "0.0005ether" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY2"
```


### How to query and change the username?

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "username()(string)"
"username1"

> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "changeUsername(string)" "username2" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```


### How to list all badges that a user has?

We can use the EAS GraphQL API to query a user's Canvas badges.

> Warning: Badges are minted to the user's wallet address, not to their profile address!

```
query Attestation {
  attestations(
    where: {
      schemaId: { equals: "0xa35b5470ebb301aa5d309a8ee6ea258cad680ea112c86e456d5f2254448afc74" },
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
          schemaId: { equals: \"0xa35b5470ebb301aa5d309a8ee6ea258cad680ea112c86e456d5f2254448afc74\" }, \
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
        "data": "0x00000000000000000000000030c98067517f8ee38e748a3af63429974103ea6b00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0x719876cb21ec011354a230c9446ee0dadfe716127f56ef997850fc14231787b0",
        "time": 1712751313,
        "txid": "0x1c732351884b1fa0d9f9828190ca430763e3408f62a25f3c46efc52597268ceb"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x000000000000000000000000ebfc9b95328b2cdb3c4ca8913e329c101d2abbc200000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0xb3e474b7bed202a54d1c922635fb999abe8432b654a3410be7d5b578ea788fdd",
        "time": 1712751325,
        "txid": "0x12410df5c994e744d2e4f7f22bb389937ffd2dd12a3be02164dfbd0703f3f5fe"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x00000000000000000000000064492ef5a60245fbaf65f69782fcf158f3a8e3aa00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0x80b82bdd262be13a673d1e8684c97b41646cf6168232cd6b600802e4e8d06a54",
        "time": 1712751427,
        "txid": "0xa2575ccaba7b9f89a1e056bea28573fa0b70b077bca0e3f19f1dc2f88e89e395"
      }
    ]
  }
}
```


### How to decode the badge payload?

Each badge is an attestation, whose `data` field contains the abi-encoded badge payload, using the following schema:

```
address badge, bytes payload
```

`badge` is the badge contract address, while `payload` is additional application-specific data.

```bash
> cast abi-decode "foo(address,bytes)" --input "0x00000000000000000000000030c98067517f8ee38e748a3af63429974103ea6b00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000"
0x30C98067517f8ee38e748A3aF63429974103Ea6B
0x
```


### How to get a badge image?

To get the token URI of a certain badge, first collect the badge attestation UID and the badge contract address. Then call `badgeTokenURI`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS" "badgeTokenURI(bytes32)(string)" "0x719876cb21ec011354a230c9446ee0dadfe716127f56ef997850fc14231787b0"
"ipfs://bafybeibc5sgo2plmjkq2tzmhrn54bk3crhnc23zd2msg4ea7a4pxrkgfna/1"
```

The result is a badge token URI, which follows the same schema as ERC721 tokens: The token URI points to a JSON file with `name`, `description`, and `image` fields. The token URI can be a HTTP or IPFS link, or it can be a [data URL](https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URLs).

To get the default token URI of a badge, simply call `badgeTokenURI` with the *zero UID*. The default badge token URI can be the same as the token URI of a specific badge, or it can be different, depending on the badge implementation.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS" "badgeTokenURI(bytes32)(string)" "0x0000000000000000000000000000000000000000000000000000000000000000"
"ipfs://bafybeibc5sgo2plmjkq2tzmhrn54bk3crhnc23zd2msg4ea7a4pxrkgfna/1"
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
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attach(bytes32[])" "[0x719876cb21ec011354a230c9446ee0dadfe716127f56ef997850fc14231787b0]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# attach many
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attach(bytes32[])" "[0xb3e474b7bed202a54d1c922635fb999abe8432b654a3410be7d5b578ea788fdd,0x80b82bdd262be13a673d1e8684c97b41646cf6168232cd6b600802e4e8d06a54]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# detach
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "detach(bytes32[])" "[0x80b82bdd262be13a673d1e8684c97b41646cf6168232cd6b600802e4e8d06a54]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```


### How to query the attached badges?

To see which badges are attached to a profile, we can call `getAttachedBadges`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getAttachedBadges()(bytes32[])"
[0x719876cb21ec011354a230c9446ee0dadfe716127f56ef997850fc14231787b0, 0xb3e474b7bed202a54d1c922635fb999abe8432b654a3410be7d5b578ea788fdd, 0x80b82bdd262be13a673d1e8684c97b41646cf6168232cd6b600802e4e8d06a54]
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
[0x719876cb21ec011354a230c9446ee0dadfe716127f56ef997850fc14231787b0, 0xb3e474b7bed202a54d1c922635fb999abe8432b654a3410be7d5b578ea788fdd, 0x80b82bdd262be13a673d1e8684c97b41646cf6168232cd6b600802e4e8d06a54]

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getBadgeOrder()(uint256[])"
[3, 2, 1]
```
