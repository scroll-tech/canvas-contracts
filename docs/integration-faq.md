# Skelly Integration FAQ

In the examples on this page, we use the configurations from [deployments.md](./deployments.md), as well as the following values:

```bash
# Skelly badges -- each badge type is a new contract, here we only have three simple test contracts
SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS="0x54E0C87672ebEC2A4d86dF3BDbB5286E7Af23396"
SCROLL_SEPOLIA_SIMPLE_BADGE_B_ADDRESS="0xF03214B490B6d05527cAD0B99a2820356b97840B"
SCROLL_SEPOLIA_SIMPLE_BADGE_C_ADDRESS="0x5892067fEB828020FBA7B3dD87428010Ecaa86a7"

# Skelly profiles -- each user has their own profile (a smart contract), here we provide a simple test profile
SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS="0x1BB2543cA2e55c83524276DB767218bFa7624A49"
```

The following examples use Foundry's `cast`, but the same queries can be made using curl, ethers, etc. analogously.


### How to check if a user has minted their profile yet?

We first query the user's deterministic profile address, then see if the profile has been minted or not.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "getProfile(address)(address)" "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0"
0x1BB2543cA2e55c83524276DB767218bFa7624A49

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "isProfileMinted(address)(bool)" "0x1BB2543cA2e55c83524276DB767218bFa7624A49"
false
```


### How to mint a profile?

Mint a profile without referral:

```bash
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "mint(string,bytes)" "username1" "" --value "0.001ether" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
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

We can use the EAS GraphQL API to query a user's Skelly badges.

> Warning: Badges are minted to the user's wallet address, not to their profile address!

```
query Attestation {
  attestations(
    where: {
      schemaId: { equals: "0x1bcce3df7047d5c9af46729cbf8d8b3ac29332b7b9afe7037ed6696a3b86c783" },
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
          schemaId: { equals: \"0x1bcce3df7047d5c9af46729cbf8d8b3ac29332b7b9afe7037ed6696a3b86c783\" }, \
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
        "data": "0x00000000000000000000000054e0c87672ebec2a4d86df3bdbb5286e7af2339600000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0xc64ad0c8dba972edea5770c6dd1ca6361655cfcf6804f60c351ac406bd0274a8",
        "time": 1710172032,
        "txid": "0xeb0ed13780c253cd13a9cf0b7b2a8f23598520d25d4f9b0665026aa35b7fc0b2"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x000000000000000000000000f03214b490b6d05527cad0b99a2820356b97840b00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0x81472ca091e0af5c93a23cccd59e0a6f8482847130e2bc89ef4308c9a889b17a",
        "time": 1710172041,
        "txid": "0x66513603a8e7cf5023d9f41cf79d2b53dd6da9dbd9167746e03567f566456d79"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x0000000000000000000000005892067feb828020fba7b3dd87428010ecaa86a700000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0xe2971a22c2922f48fa3d32c4ec08bac14667efdec0d4bd1a1ae223d8f337c4b1",
        "time": 1710172053,
        "txid": "0x3b16b4d04cff130f11fda426f066cafefbc6faf8f586a87d83757be071e8300b"
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
> cast abi-decode "foo(address,bytes)" --input "0x00000000000000000000000054e0c87672ebec2a4d86df3bdbb5286e7af2339600000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000"
0x54E0C87672ebEC2A4d86dF3BDbB5286E7Af23396
0x
```


### How to get a badge image?

To get the token URI of a certain badge, first collect the badge attestation UID and the badge contract address. Then call `badgeTokenURI`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS" "badgeTokenURI(bytes32)(string)" "0xc64ad0c8dba972edea5770c6dd1ca6361655cfcf6804f60c351ac406bd0274a8"
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
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attach(bytes32[])" "[0xc64ad0c8dba972edea5770c6dd1ca6361655cfcf6804f60c351ac406bd0274a8]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# attach many
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attach(bytes32[])" "[0x81472ca091e0af5c93a23cccd59e0a6f8482847130e2bc89ef4308c9a889b17a,0xe2971a22c2922f48fa3d32c4ec08bac14667efdec0d4bd1a1ae223d8f337c4b1]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# detach
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "detach(bytes32[])" "[0xe2971a22c2922f48fa3d32c4ec08bac14667efdec0d4bd1a1ae223d8f337c4b1]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```


### How to query the attached badges?

To see which badges are attached to a profile, we can call `getAttachedBadges`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getAttachedBadges()(bytes32[])"
[0xc64ad0c8dba972edea5770c6dd1ca6361655cfcf6804f60c351ac406bd0274a8, 0x81472ca091e0af5c93a23cccd59e0a6f8482847130e2bc89ef4308c9a889b17a, 0xe2971a22c2922f48fa3d32c4ec08bac14667efdec0d4bd1a1ae223d8f337c4b1]
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
[0xc64ad0c8dba972edea5770c6dd1ca6361655cfcf6804f60c351ac406bd0274a8, 0x81472ca091e0af5c93a23cccd59e0a6f8482847130e2bc89ef4308c9a889b17a, 0xe2971a22c2922f48fa3d32c4ec08bac14667efdec0d4bd1a1ae223d8f337c4b1]

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getBadgeOrder()(uint256[])"
[3, 2, 1]
```
