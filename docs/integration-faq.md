# Skelly Integration FAQ

In the examples on this page, we use the configurations from [deployments.md](./deployments.md), as well as the following values:

```bash
# Skelly badges -- each badge type is a new contract, here we only have three simple test contracts
SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS="0xF955E3CDffA1D67E3de6FDC6247D3724DE8DA561"
SCROLL_SEPOLIA_SIMPLE_BADGE_B_ADDRESS="0xf7f7d145ddAD3Fd3EaE26D4DaC03EcD8183399eE"
SCROLL_SEPOLIA_SIMPLE_BADGE_C_ADDRESS="0x6697Df63b2951aa3167Db26E293772D50e68c11c"

# Skelly profiles -- each user has their own profile (a smart contract), here we provide a simple test profile
SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS="0x3d9b1a157B8927E6D7116dfE8D30AeC77866dC98"
```

The following examples use Foundry's `cast`, but the same queries can be made using curl, ethers, etc. analogously.


### How to check if a user has minted their profile yet?

We first query the user's deterministic profile address, then see if the profile has been minted or not.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "getProfile(address)(address)" "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0"
0x3d9b1a157B8927E6D7116dfE8D30AeC77866dC98

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "isProfileMinted(address)(bool)" "0x3d9b1a157B8927E6D7116dfE8D30AeC77866dC98"
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
      schemaId: { equals: "0x06cc89865218afac3602d8eb5c84cf0183c3c27bf54327218f2efe12a2383d65" },
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
          schemaId: { equals: \"0x06cc89865218afac3602d8eb5c84cf0183c3c27bf54327218f2efe12a2383d65\" }, \
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
        "data": "0x000000000000000000000000f955e3cdffa1d67e3de6fdc6247d3724de8da56100000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0xf360e9632960221c26690aff471c0dc82f9b2b806f838c19097555c569eb5ef5",
        "time": 1709239263,
        "txid": "0xb89f9bd3fbdef3abd395a10b2873d52f0b10f5bac27bdbad4d543a9bc0e30e10"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x000000000000000000000000f7f7d145ddad3fd3eae26d4dac03ecd8183399ee00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0xae3f93e4870b6188cdf7b7276bd26031714eb029542d142a4e5e6c8cb1f2d4bb",
        "time": 1709239272,
        "txid": "0xc4b83aca70cbf84a5c459c861d06d05773f459c89c0e516c16824051784bbd24"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x0000000000000000000000006697df63b2951aa3167db26e293772d50e68c11c00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0xb2365c2a2309a3d94f0d51292d67311caecc88bce20cbc4ad151e149858d8830",
        "time": 1709239281,
        "txid": "0x9c2a5694da60da57e109287ec52ec1393d06c4b437c9b3f9dd6f0a3e37c614d9"
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
> cast abi-decode "foo(address,bytes)" --input "0x000000000000000000000000f955e3cdffa1d67e3de6fdc6247d3724de8da56100000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000"
0xF955E3CDffA1D67E3de6FDC6247D3724DE8DA561
0x
```


### How to get a badge image?

To get the token URI of a certain badge, first collect the badge attestation UID and the badge contract address. Then call `badgeTokenURI`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS" "badgeTokenURI(bytes32)(string)" "0xf360e9632960221c26690aff471c0dc82f9b2b806f838c19097555c569eb5ef5"
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
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attach(bytes32[])" "[0xf360e9632960221c26690aff471c0dc82f9b2b806f838c19097555c569eb5ef5]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# attach many
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attach(bytes32[])" "[0xae3f93e4870b6188cdf7b7276bd26031714eb029542d142a4e5e6c8cb1f2d4bb,0xb2365c2a2309a3d94f0d51292d67311caecc88bce20cbc4ad151e149858d8830]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# detach
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "detach(bytes32[])" "[0xb2365c2a2309a3d94f0d51292d67311caecc88bce20cbc4ad151e149858d8830]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```


### How to query the attached badges?

To see which badges are attached to a profile, we can call `getAttachedBadges`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getAttachedBadges()(bytes32[])"
[0xf360e9632960221c26690aff471c0dc82f9b2b806f838c19097555c569eb5ef5, 0xae3f93e4870b6188cdf7b7276bd26031714eb029542d142a4e5e6c8cb1f2d4bb, 0xb2365c2a2309a3d94f0d51292d67311caecc88bce20cbc4ad151e149858d8830]
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
[0xf360e9632960221c26690aff471c0dc82f9b2b806f838c19097555c569eb5ef5, 0xae3f93e4870b6188cdf7b7276bd26031714eb029542d142a4e5e6c8cb1f2d4bb, 0xb2365c2a2309a3d94f0d51292d67311caecc88bce20cbc4ad151e149858d8830]

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getBadgeOrder()(uint256[])"
[3, 2, 1]
```
