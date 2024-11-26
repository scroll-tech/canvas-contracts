// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Attestation} from "@eas/contracts/IEAS.sol";
import {NO_EXPIRATION_TIME} from "@eas/contracts/Common.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IScrollBadgeResolver} from "../../interfaces/IScrollBadgeResolver.sol";
import {IScrollBadge, IScrollSelfAttestationBadge} from "../../interfaces/IScrollSelfAttestationBadge.sol";
import {encodeBadgeData} from "../../Common.sol";
import {ScrollBadge} from "../ScrollBadge.sol";
import {ScrollBadgeCustomPayload} from "../extensions/ScrollBadgeCustomPayload.sol";
import {ScrollBadgeDefaultURI} from "../extensions/ScrollBadgeDefaultURI.sol";

string constant SCR_HOLDING_BADGE_SCHEMA = "uint256 level";

function decodePayloadData(bytes memory data) pure returns (uint256) {
    return abi.decode(data, (uint256));
}

/// @title SCRHoldingBadge
/// @notice A badge that represents user's SCR holding amount.
contract SCRHoldingBadge is ScrollBadgeCustomPayload, ScrollBadgeDefaultURI, Ownable, IScrollSelfAttestationBadge {
    uint256 private constant LEVEL_ONE_SCR_AMOUNT = 1 ether;
    uint256 private constant LEVEL_TWO_SCR_AMOUNT = 10 ether;
    uint256 private constant LEVEL_THREE_SCR_AMOUNT = 100 ether;
    uint256 private constant LEVEL_FOUR_SCR_AMOUNT = 1000 ether;
    uint256 private constant LEVEL_FIVE_SCR_AMOUNT = 10_000 ether;
    uint256 private constant LEVEL_SIX_SCR_AMOUNT = 100_000 ether;

    /// @notice The address of SCR token.
    address public immutable scr;

    constructor(address resolver_, string memory baseTokenURI_, address scr_)
        ScrollBadge(resolver_)
        ScrollBadgeDefaultURI(baseTokenURI_)
    {
        scr = scr_;
    }

    /// @notice Update the base token URI.
    /// @param baseTokenURI_ The new base token URI.
    function updateBaseTokenURI(string memory baseTokenURI_) external onlyOwner {
        defaultBadgeURI = baseTokenURI_;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata)
        internal
        virtual
        override (ScrollBadge, ScrollBadgeCustomPayload)
        returns (bool)
    {
        return false;
    }

    /// @inheritdoc ScrollBadge
    function onRevokeBadge(Attestation calldata)
        internal
        virtual
        override (ScrollBadge, ScrollBadgeCustomPayload)
        returns (bool)
    {
        return false;
    }

    /// @inheritdoc ScrollBadge
    function badgeTokenURI(bytes32 uid)
        public
        view
        override (IScrollBadge, ScrollBadge, ScrollBadgeDefaultURI)
        returns (string memory)
    {
        return ScrollBadgeDefaultURI.badgeTokenURI(uid);
    }

    /// @inheritdoc IScrollBadge
    function hasBadge(address user) public view virtual override (IScrollBadge, ScrollBadge) returns (bool) {
        uint256 balance = IERC20(scr).balanceOf(user);
        return balance >= LEVEL_ONE_SCR_AMOUNT;
    }

    /// @inheritdoc ScrollBadgeDefaultURI
    function getBadgeTokenURI(bytes32 uid) internal view override returns (string memory) {
        Attestation memory attestation = getAndValidateBadge(uid);
        bytes memory payload = getPayload(attestation);
        uint256 level = decodePayloadData(payload);

        return string(abi.encodePacked(defaultBadgeURI, Strings.toString(level), ".json"));
    }

    /// @inheritdoc ScrollBadgeCustomPayload
    function getSchema() public pure override returns (string memory) {
        return SCR_HOLDING_BADGE_SCHEMA;
    }

    /// @inheritdoc IScrollSelfAttestationBadge
    function getBadgeId() external pure returns (uint256) {
        return 0;
    }

    /// @inheritdoc IScrollSelfAttestationBadge
    ///
    /// @dev The uid encoding should be
    /// ```text
    /// [  address  | badge id | customized data ]
    /// [ 160  bits | 32  bits |     64 bits     ]
    /// [LSB                                  MSB]
    /// ```
    /// The *badge id* and the *customized data* should both be zero.
    function getAttestation(bytes32 uid) external view override returns (Attestation memory attestation) {
        // invalid uid, return empty badge
        if ((uint256(uid) >> 160) > 0) return attestation;

        // extract badge recipient from uid
        address recipient;
        assembly {
            recipient := and(uid, 0xffffffffffffffffffffffffffffffffffffffff)
        }

        // compute payload
        uint256 level;
        uint256 balance = IERC20(scr).balanceOf(recipient);
        // not hold enough SCR, return empty badge
        if (balance < LEVEL_ONE_SCR_AMOUNT) return attestation;
        else if (balance < LEVEL_TWO_SCR_AMOUNT) level = 1;
        else if (balance < LEVEL_THREE_SCR_AMOUNT) level = 2;
        else if (balance < LEVEL_FOUR_SCR_AMOUNT) level = 3;
        else if (balance < LEVEL_FIVE_SCR_AMOUNT) level = 4;
        else if (balance < LEVEL_SIX_SCR_AMOUNT) level = 5;
        else level = 6;
        bytes memory payload = abi.encode(level);

        // fill data in Attestation
        attestation.uid = uid;
        attestation.schema = IScrollBadgeResolver(resolver).schema();
        attestation.time = uint64(block.timestamp);
        attestation.expirationTime = NO_EXPIRATION_TIME;
        attestation.refUID = bytes32(0);
        attestation.recipient = recipient;
        attestation.attester = address(this);
        attestation.revocable = false;
        attestation.data = encodeBadgeData(address(this), payload);

        return attestation;
    }
}
