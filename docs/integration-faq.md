# Skelly Integration FAQ

In the examples on this page, we use the following configurations:

```bash
# EAS constants -- these will not change on a network
SCROLL_SEPOLIA_EAS_ADDRESS="0xaEF4103A04090071165F78D45D83A0C0782c2B2a"
SCROLL_SEPOLIA_EAS_SCHEMA_REGISTRY_ADDRESS="0x55D26f9ae0203EF95494AE4C170eD35f4Cf77797"

# Scroll Skelly constants -- these will not change on a network (after the final deployment)
SCROLL_SEPOLIA_BADGE_RESOLVER_ADDRESS="0x3749329c69849d771a5b0B13530B899990dEe747"
SCROLL_SEPOLIA_BADGE_SCHEMA="0x9666930cb582ee5a2a570d84fdd20754cdfccfb0b2dc9c6fc114412de9a7991f"
SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS="0x71f356552988D13b3a9EDC8001275f6Ac0493671"

# Skelly badges -- each badge type is a new contract, here we only have three simple test contracts
SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS="0xC5920c1c11E38cd315597504Dbb645b6d1030e1F"
SCROLL_SEPOLIA_SIMPLE_BADGE_B_ADDRESS="0x97E18b7e0310997722a64935Dea0511F119C3461"
SCROLL_SEPOLIA_SIMPLE_BADGE_C_ADDRESS="0x109d2ccAcF10E8c7E0F11EC0c997EAb99C379675"

# Skelly profiles -- each user has their own profile (a smart contract), here we provide a simple test profile
SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS="0xE32c7bb049A4cD8fEd758266E92AbC80BD94B563"

# APIs
SCROLL_SEPOLIA_RPC_URL="https://sepolia-rpc.scroll.io"
SCROLL_SEPOLIA_EAS_GRAPHQL_URL="https://scroll-sepolia.easscan.org/graphql"
```

The following examples use Foundry's `cast`, but the same queries can be made using curl, ethers, etc. analogously.


### How to check if a user has minted their profile yet?

We first query the user's deterministic profile address, then see if the profile has been minted or not.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "getProfile(address)(address)" "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0"
0xE32c7bb049A4cD8fEd758266E92AbC80BD94B563

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "isProfileMinted(address)(bool)" "0xE32c7bb049A4cD8fEd758266E92AbC80BD94B563"
false
```


### How to mint a profile?

Mint a profile without referral:

```bash
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "mint(string,bytes)" "username1" "" --value "0.001ether" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```

To mint a profile with a referral, produce a signed referral, then submit it along with the `mint` call (see [referral.js](../examples/src/referral.js) for details).

```bash
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_PROFILE_REGISTRY_ADDRESS" "mint(string,bytes)" "username2" "0x000000000000000000000000f138edc6038c237e94450bcc9a7085a7b213caf00000000000000000000000000000000000000000000000000000000065df58b700000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000041f67a57c6bc0b93d7b7fb0ed30544825569c1e2a08037f235fb1716bdc260839657f8f9f130b3e43c55743912914103e5b4da7b7178081bece2149a53f14b5b251c00000000000000000000000000000000000000000000000000000000000000" --value "0.0005ether" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY2"
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
      schemaId: { equals: "0x9666930cb582ee5a2a570d84fdd20754cdfccfb0b2dc9c6fc114412de9a7991f" },
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
          schemaId: { equals: \"0x9666930cb582ee5a2a570d84fdd20754cdfccfb0b2dc9c6fc114412de9a7991f\" }, \
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
        "data": "0x000000000000000000000000c5920c1c11e38cd315597504dbb645b6d1030e1f00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0x1b814342d6c8c8bf92550ade68497dd49e7764f08ce666f28b916bd99c411c70",
        "time": 1709132195,
        "txid": "0x6a3b4dab8fe5b9371d2e81134f3532641c1eb02d1fd94622860b2ccdb118dbba"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x00000000000000000000000097e18b7e0310997722a64935dea0511f119c346100000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0x618cac42314dfe8cc14b7830b2b2b5a17f478f536e8c9503f530c754c97c9f72",
        "time": 1709132207,
        "txid": "0x3b1563f4134769279198cc5ee6ec3606f5924941d2b36bf83509c4ba5362dbb3"
      },
      {
        "attester": "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0",
        "data": "0x000000000000000000000000109d2ccacf10e8c7e0f11ec0c997eab99c37967500000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000",
        "id": "0xd711e470bd2ee0863e3b75fa255f8155c11f80baf2e7b9d2952345a5b204a8e9",
        "time": 1709132217,
        "txid": "0x6b70d7b974023dd325ace6b35cd63008516aa8130f60f7d74518438c7e7a15fb"
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
> cast abi-decode "foo(address,bytes)" --input "0x000000000000000000000000c5920c1c11e38cd315597504dbb645b6d1030e1f00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000000"
0xC5920c1c11E38cd315597504Dbb645b6d1030e1F
0x
```


### How to get a badge image?

To get the token URI of a certain badge, first collect the badge attestation UID and the badge contract address. Then call `badgeTokenURI`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_SIMPLE_BADGE_A_ADDRESS" "badgeTokenURI(bytes32)(string)" "0x1b814342d6c8c8bf92550ade68497dd49e7764f08ce666f28b916bd99c411c70"
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
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attach(bytes32[])" "[0x1b814342d6c8c8bf92550ade68497dd49e7764f08ce666f28b916bd99c411c70]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# attach many
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "attach(bytes32[])" "[0x618cac42314dfe8cc14b7830b2b2b5a17f478f536e8c9503f530c754c97c9f72,0xd711e470bd2ee0863e3b75fa255f8155c11f80baf2e7b9d2952345a5b204a8e9]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"

# detach
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "detach(bytes32[])" "[0xd711e470bd2ee0863e3b75fa255f8155c11f80baf2e7b9d2952345a5b204a8e9]" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```


### How to query the attached badges?

To see which badges are attached to a profile, we can call `getAttachedBadges`:

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getAttachedBadges()(bytes32[])"
[0x1b814342d6c8c8bf92550ade68497dd49e7764f08ce666f28b916bd99c411c70, 0x618cac42314dfe8cc14b7830b2b2b5a17f478f536e8c9503f530c754c97c9f72, 0xd711e470bd2ee0863e3b75fa255f8155c11f80baf2e7b9d2952345a5b204a8e9]
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
[0x1b814342d6c8c8bf92550ade68497dd49e7764f08ce666f28b916bd99c411c70, 0x618cac42314dfe8cc14b7830b2b2b5a17f478f536e8c9503f530c754c97c9f72, 0xd711e470bd2ee0863e3b75fa255f8155c11f80baf2e7b9d2952345a5b204a8e9]

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_TEST_PROFILE_ADDRESS" "getBadgeOrder()(uint256[])"
[3, 2, 1]
```
