// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { EMPTY_UID } from "@eas/contracts/Common.sol";
import { IEAS, Attestation } from "@eas/contracts/IEAS.sol";

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import { MAX_ATTACHED_BADGE_NUM } from "../Common.sol";
import { IScrollBadgeResolver } from "../interfaces/IScrollBadgeResolver.sol";
import { InvalidBadge } from "../Errors.sol";

contract Profile is Initializable {
    error Unauthorized();
    error BadgeCountReached();

    address public immutable resolver;

    address public owner;
    string public username;

    bytes private _attached;

    constructor(address resolver_) {
        resolver = resolver_;
        _disableInitializers();
    }

    function initialize(address owner_, string memory username_) external initializer {
        owner = owner_;
        username = username_;
    }

    function attach(bytes32[] memory uids) external {
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        if (uids.length > MAX_ATTACHED_BADGE_NUM) {
            revert BadgeCountReached();
        }

        for (uint256 ii = 0; ii < uids.length; ii++) {
            getAndValidateBadge(uids[ii]); // validate
        }

        _attached = abi.encode(uids);
    }

    function attachOne(bytes32 uid) external {
        if (msg.sender != owner) {
            revert Unauthorized();
        }

        getAndValidateBadge(uid); // validate

        bytes32[] memory uids = abi.decode(_attached, (bytes32[]));

        if (uids.length == MAX_ATTACHED_BADGE_NUM) {
            revert BadgeCountReached();
        }

        bytes32[] memory newUids = new bytes32[](uids.length + 1);

        for (uint256 ii = 0; ii < uids.length; ii++) {
            newUids[ii] = uids[ii];
        }

        newUids[uids.length] = uid;
        _attached = abi.encode(newUids);
    }

    function getAndValidateBadge(bytes32 uid) public view returns (Attestation memory) {
        Attestation memory badge = IScrollBadgeResolver(resolver).getAndValidateBadge(uid);

        if (badge.recipient != owner) {
            revert InvalidBadge(badge.uid);
        }

        return badge;
    }

    function isBadgeValid(bytes32 uid) public view returns (bool) {
        try this.getAndValidateBadge(uid) {
            return true;
        } catch {
            return false;
        }
    }

    function getValidBadges() external view returns (bytes32[] memory) {
        bytes32[] memory uids = abi.decode(_attached, (bytes32[]));
        uint256 length = 0;

        for (uint256 ii = 0; ii < uids.length; ii++) {
            if (isBadgeValid(uids[ii])) {
                length++;
            }
        }

        bytes32[] memory result = new bytes32[](length);
        length = 0;

        for (uint256 ii = 0; ii < uids.length; ii++) {
            if (isBadgeValid(uids[ii])) {
                result[length++] = uids[ii];
            }
        }

        return result;
    }
}
