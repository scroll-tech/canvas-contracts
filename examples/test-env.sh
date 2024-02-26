#!/bin/bash

set -m

if [ ! -e ".env" ]; then
    cp .env.example .env
fi

source ".env"

anvil --port 8545 &
sleep 1

export DEPLOYER_PRIVATE_KEY
export ATTESTER_ADDRESS=$(cast wallet address "$SIGNER_PRIVATE_KEY")
export SIGNER_ADDRESS=$(cast wallet address "$SIGNER_PRIVATE_KEY")
export TREASURY_ADDRESS=$(cast wallet address "$SIGNER_PRIVATE_KEY")

pushd ..
forge script script/DeployTestContracts.sol:DeployTestContracts --rpc-url http://localhost:8545 --broadcast 2>&1

fg
