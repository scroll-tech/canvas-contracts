#!/bin/bash

set -m

if [ ! -e ".env" ]; then
    cp .env.example .env
fi

anvil --port 8545 &
sleep 1

# anvil test accounts
export DEPLOYER_PRIVATE_KEY='0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80'
export ATTESTER_ADDRESS='0x70997970C51812dc3A010C7d01b50e0d17dc79C8'

pushd ..
forge script script/DeployTestContracts.sol:DeployTestContracts --rpc-url http://localhost:8545 --broadcast 2>&1

fg
