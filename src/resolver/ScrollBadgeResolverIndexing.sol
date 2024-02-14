// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation } from "@eas/contracts/IEAS.sol";

import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { decodeBadgeData } from "../Common.sol";
import { InvalidOffset } from "../Errors.sol";

abstract contract ScrollBadgeResolverIndexing {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // Index user => badges
    mapping (address => EnumerableSet.Bytes32Set) private _recipientBadge;

    // user => contract => badges
    mapping (address => mapping (address => EnumerableSet.Bytes32Set)) private _recipientContractBadge;

    /// @notice Indexes an existing attestation.
    /// @dev The caller must ensure that attestations are only indexed once.
    function _indexBadge(Attestation memory attestation) internal {
        (address badge,) = decodeBadgeData(attestation.data);
        _recipientBadge[attestation.recipient].add(attestation.uid);
        _recipientContractBadge[attestation.recipient][badge].add(attestation.uid);
    }

    function getRecipientBadgeCount(address recipient) external view returns (uint256) {
        return _recipientBadge[recipient].length();
    }

    function getRecipientBadges(address recipient, uint256 start, uint256 length, bool reverseOrder) external view returns (bytes32[] memory) {
        return _sliceUIDs(_recipientBadge[recipient], start, length, reverseOrder);
    }

    function getRecipientContractBadgeCount(address recipient, address addr) external view returns (uint256) {
        return _recipientContractBadge[recipient][addr].length();
    }

    function getRecipientContractBadges(address recipient, address addr, uint256 start, uint256 length, bool reverseOrder) external view returns (bytes32[] memory) {
        return _sliceUIDs(_recipientContractBadge[recipient][addr], start, length, reverseOrder);
    }

    // adopted from EAS/Indexer.sol
    function _sliceUIDs(EnumerableSet.Bytes32Set storage uids, uint256 start, uint256 length, bool reverseOrder) private view returns (bytes32[] memory) {
        uint256 attestationsLength = uids.length();
        if (attestationsLength == 0) {
            return new bytes32[](0);
        }

        if (start >= attestationsLength) {
            revert InvalidOffset();
        }

        unchecked {
            uint256 len = length;
            if (attestationsLength < start + length) {
                len = attestationsLength - start;
            }

            bytes32[] memory res = new bytes32[](len);

            for (uint256 i = 0; i < len; ++i) {
                res[i] = uids.at(reverseOrder ? attestationsLength - (start + i + 1) : start + i);
            }

            return res;
        }
    }
}
