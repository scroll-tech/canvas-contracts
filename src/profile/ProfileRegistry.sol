// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

import { Profile } from "./Profile.sol";

address constant PLACEHOLDER = address(1);

/// @title ProfileRegistry
/// @notice Profile registry keeps track of minted profiles and manages their implementation.
contract ProfileRegistry is UpgradeableBeacon {
    error ProfileAlreadyMinted();

    mapping (address => address) private addressToProfile;

    constructor(address profileImpl_) UpgradeableBeacon(profileImpl_) {
        // empty
    }

    function mintProfile(string calldata username) external {
        if (addressToProfile[msg.sender] != address(0)) {
            revert ProfileAlreadyMinted();
        }

        // initialize before external constructor call to prevent
        // reentrancy (just in case)
        addressToProfile[msg.sender] = PLACEHOLDER;

        // create an initialize new profile
        bytes memory data = abi.encodeCall(Profile.initialize, (msg.sender, username));
        BeaconProxy profile = new BeaconProxy(address(this), data);

        addressToProfile[msg.sender] = address(profile);
    }

    function getProfile(address owner) external view returns (address) {
        return addressToProfile[owner];
    }
}
