# Skelly Origins Badge

In the examples on this page, we use the configurations from [integration-faq.md](./integration-faq.md), as well as the following values:

```bash
# Scroll Origins NFT addresses
SCROLL_SEPOLIA_ORIGINS_V1_ADDRESS="TBD"
SCROLL_SEPOLIA_ORIGINS_V2_ADDRESS="0xDd7d857F570B0C211abfe05cd914A85BefEC2464"

# Badge address
SCROLL_SEPOLIA_ORIGINS_BADGE_ADDRESS="0xd9892Bb7579becC9343C9a2c94eF21bc1e08d6d1"
```


### How to check eligibility?

The Scroll Origin NFT's eligibility has two components:

1. The user owns a Scroll Origins NFT token. Check this using `tokenOfOwnerByIndex`.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_ORIGINS_V2_ADDRESS" "tokenOfOwnerByIndex(address,uint256)(uint256)" 0x58DB79a596Bf46D400C14672084a145aed08e19b 0
10000008
```

2. The user has not minted a Scroll Origins badge yet.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_ORIGINS_BADGE_ADDRESS" "hasBadge(address)(bool)" "0xF138EdC6038C237e94450bcc9a7085a7b213cAf0"
false
```


### How to mint a Scroll Origins badge?

A Scroll Origins badge can be minted from the frontend, no backend support is required.

In this example, we will assume that the user's address is `0x58DB79a596Bf46D400C14672084a145aed08e19b`.

First, find the user's token ID.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_ORIGINS_V2_ADDRESS" "tokenOfOwnerByIndex(address,uint256)(uint256)" 0x58DB79a596Bf46D400C14672084a145aed08e19b 0
10000008
```

The user's Origins NFT is token `10000008` on contract `$SCROLL_SEPOLIA_ORIGINS_V2_ADDRESS`.

Next, we mint a badge directly through EAS.

```bash
# encode Scroll Origins badge payload
# schema: "address originsTokenAddress, uint256 originsTokenId"
> ORIGINS_BADGE_PAYLOAD=$(cast abi-encode "abc(address,uint256)" "$SCROLL_SEPOLIA_ORIGINS_V2_ADDRESS" "10000008")

# encode badge payload
> BADGE_PAYLOAD=$(cast abi-encode "abc(address,bytes)" "$SCROLL_SEPOLIA_ORIGINS_BADGE_ADDRESS" "$ORIGINS_BADGE_PAYLOAD")

# attest
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_EAS_ADDRESS" "attest((bytes32,(address,uint64,bool,bytes32,bytes,uint256)))" "($SCROLL_SEPOLIA_BADGE_SCHEMA,(0x58DB79a596Bf46D400C14672084a145aed08e19b,0,false,0x0000000000000000000000000000000000000000000000000000000000000000,$BADGE_PAYLOAD,0))" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```

Note: only the recipient (`0x58DB79a596Bf46D400C14672084a145aed08e19b` in this case) can mint this badge.
