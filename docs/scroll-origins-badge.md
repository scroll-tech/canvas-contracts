# Skelly Origins Badge

In the examples on this page, we use the configurations from [integration-faq.md](./integration-faq.md), as well as the following values:

```bash
# Scroll Origins NFT addresses
SCROLL_SEPOLIA_ORIGINS_V1_ADDRESS="TBD"
SCROLL_SEPOLIA_ORIGINS_V2_ADDRESS="TBD"

# Badge address
SCROLL_SEPOLIA_ORIGINS_BADGE_ADDRESS="0xE207971d5B1332f267d00f4a75D9949AE69b03a4"
```

### How to mint a Scroll Origins badge?

A Scroll Origins badge can be minted from the frontend, no backend support is required.

In this example, we will assume that the user's address is `0x9b5096219f278055557165bef4eb7dc59f8d0fe8`.

First, find the user's token ID.

```bash
> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_ORIGINS_V1_ADDRESS" "tokenOfOwnerByIndex(address,uint256)(uint256)" 0x9b5096219f278055557165bef4eb7dc59f8d0fe8 0
843487

> cast call --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_ORIGINS_V2_ADDRESS" "tokenOfOwnerByIndex(address,uint256)(uint256)" 0x9b5096219f278055557165bef4eb7dc59f8d0fe8 0
Error:
(code: 3, message: execution reverted, data: Some(String("0xa57d13dc0000000000000000000000009b5096219f278055557165bef4eb7dc59f8d0fe80000000000000000000000000000000000000000000000000000000000000000")))
```

The user's Origins NFT is token `0` on contract `$SCROLL_SEPOLIA_ORIGINS_V1_ADDRESS`.

Next, we mint a badge directly through EAS.

```bash
# encode Scroll Origins badge payload
# schema: "address originsTokenAddress, uint256 originsTokenId"
> ORIGINS_BADGE_PAYLOAD=$(cast abi-encode "abc(address,uint256)" "$SCROLL_SEPOLIA_ORIGINS_V1_ADDRESS" "0")

# encode badge payload
> BADGE_PAYLOAD=$(cast abi-encode "abc(address,bytes)" "$SCROLL_SEPOLIA_ORIGINS_BADGE_ADDRESS" "$ORIGINS_BADGE_PAYLOAD")

# attest
> cast send --rpc-url "$SCROLL_SEPOLIA_RPC_URL" "$SCROLL_SEPOLIA_EAS_ADDRESS" "attest((bytes32,(address,uint64,bool,bytes32,bytes,uint256)))" "($SCROLL_SEPOLIA_BADGE_SCHEMA,(0x9b5096219f278055557165bef4eb7dc59f8d0fe8,0,false,0x0000000000000000000000000000000000000000000000000000000000000000,$BADGE_PAYLOAD,0))" --private-key "$SCROLL_SEPOLIA_PRIVATE_KEY"
```

Note: only the recipient (`0x9b5096219f278055557165bef4eb7dc59f8d0fe8` in this case) can mint this badge.
