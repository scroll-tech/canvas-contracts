// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Attestation, AttestationRequest, AttestationRequestData, IEAS, RevocationRequest, RevocationRequestData } from "@eas/contracts/IEAS.sol";
import { EMPTY_UID, NO_EXPIRATION_TIME } from "@eas/contracts/Common.sol";

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import { ScrollBadge } from "../ScrollBadge.sol";
import { IScrollBadgeResolver } from "../../interfaces/IScrollBadgeResolver.sol";
import { Unauthorized } from "../../Errors.sol";

/// @title ScrollBadgeNFT
/// @notice This contract attaches an transferrable NFT token to each badge.
abstract contract ScrollBadgeNFT is ERC721, ScrollBadge {
    error MultipleActiveAttestationsDisabled();
    error BatchTransfersDisabled();

    // Whether it is allowed to mint multiple tokens per address.
    bool public immutable singleton;

    mapping (uint256 => bytes32) public token2uid;

    /// @dev Creates a new ScrollBadgeNFT instance.
    /// @param name_ The ERC721 token name.
    /// @param symbol_ The ERC721 token symbol.
    /// @param singleton_ If true, each user can only have one badge.
    constructor(string memory name_, string memory symbol_, bool singleton_) ERC721(name_, symbol_) {
        singleton = singleton_;
    }

    /// @inheritdoc ScrollBadge
    function onIssueBadge(Attestation calldata attestation) internal virtual override returns (bool) {
        if (!super.onIssueBadge(attestation)) {
            return false;
        }

        if (attestation.attester != address(this)) {
            revert Unauthorized();
        }

        if (singleton && balanceOf(attestation.recipient) > 0) {
            revert MultipleActiveAttestationsDisabled();
        }

        return true;
    }

    ///@inheritdoc ERC721
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize) internal override(ERC721) {
        if (batchSize != 1) {
            revert BatchTransfersDisabled();
        }

        IScrollBadgeResolver _resolver = IScrollBadgeResolver(resolver);
        IEAS _eas = IEAS(_resolver.eas());

        // if not minting, revoke from previous owner
        if (from != address(0)) {
            bytes32 uid = token2uid[tokenId];

            RevocationRequestData memory data = RevocationRequestData({
                uid: uid,
                value: 0
            });

            RevocationRequest memory request = RevocationRequest({
                schema: _resolver.schema(),
                data: data
            });

            _eas.revoke(request);
        }

        // if not burning, attest to new owner
        if (to != address(0)) {
            bytes memory payload = "";
            bytes memory badgeData = abi.encode(address(this), payload);

            AttestationRequestData memory data = AttestationRequestData({
                recipient: to,
                expirationTime: NO_EXPIRATION_TIME,
                revocable: true,
                refUID: EMPTY_UID,
                data: badgeData,
                value: 0
            });

            AttestationRequest memory request = AttestationRequest({
                schema: _resolver.schema(),
                data: data
            });

            bytes32 newUid = _eas.attest(request);
            token2uid[tokenId] = newUid;
        }
    }

    function mint(address to, uint256 tokenId) external virtual;
}
