# Canvas Ethereum Year Badge

In the examples on this page, we use the configurations from [deployments.md](./deployments.md), as well as the following values:

```bash
ETHEREUM_YEAR_BADGE_ADDRESS=0xB59B6466B21a089c93B14030AF88b164905a58fd
ETHEREUM_YEAR_ATTESTER_PROXY_ADDRESS=0xdAe8D9a30681899C305534849e138579aF0BF88e
```

This badge uses backend-authorized delegated attestations. For details, refer to [badges.md](./badges.md). For an example of producing delegated attestations, refer to [attest-server.js](../examples/src/attest-server.js).

### How to encode the badge payload?

Each badge is an attestation, whose `data` field contains the abi-encoded badge payload, using the following schema:

```
address badge, bytes payload
```

Where `payload` uses the following schema:

```
uint256 year
```

Example:

```bash
> PAYLOAD=$(cast abi-encode "foo(uint256)" "2024")
> ATTESTATION_PAYLOAD=$(cast abi-encode "foo(address,bytes)" "0xB59B6466B21a089c93B14030AF88b164905a58fd" "$PAYLOAD")
> echo "$ATTESTATION_PAYLOAD"
0x000000000000000000000000b59b6466b21a089c93b14030af88b164905a58fd0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000007e8
```
