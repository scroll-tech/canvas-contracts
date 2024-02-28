// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {
    EIP712Proxy,
    AttestationRequest,
    RevocationRequest,
    DelegatedProxyAttestationRequest
} from "@eas/contracts/eip712/proxy/EIP712Proxy.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {AccessDenied} from "@eas/contracts/Common.sol";
import {IEAS, Attestation} from "@eas/contracts/IEAS.sol";

/// @title AttesterProxy
/// @notice An EIP712 proxy that allows only specific addresses to attest.
///         Based on PermissionedEIP712Proxy in the EAS repo.
contract AttesterProxy is EIP712Proxy, Ownable {
    // The global EAS contract.
    IEAS private immutable _eas;

    // Authorized badge attester accounts.
    mapping(address => bool) public isAttester;

    /// @dev Creates a new PermissionedEIP712Proxy instance.
    /// @param eas The address of the global EAS contract.
    constructor(IEAS eas) EIP712Proxy(eas, "AttesterProxy") {
        _eas = eas;
    }

    /// @notice Enables or disables a given attester.
    /// @param attester The attester address.
    /// @param enable True if enable, false if disable.
    function toggleAttester(address attester, bool enable) external onlyOwner {
        isAttester[attester] = enable;
    }

    /// @inheritdoc EIP712Proxy
    function attestByDelegation(DelegatedProxyAttestationRequest calldata delegatedRequest)
        public
        payable
        override
        returns (bytes32)
    {
        // Ensure that only the owner is allowed to delegate attestations.
        _verifyAttester(delegatedRequest.attester);

        // Ensure that only the recipient can submit delegated attestation transactions.
        if (msg.sender != delegatedRequest.data.recipient) {
            revert AccessDenied();
        }

        return super.attestByDelegation(delegatedRequest);
    }

    /// @notice Create attestation through the proxy.
    /// @param request The arguments of the attestation request.
    /// @return The UID of the new attestation.
    function attest(AttestationRequest calldata request) external returns (bytes32) {
        _verifyAttester(msg.sender);
        return _eas.attest(request);
    }

    /// @notice Revoke attestation through the proxy.
    /// @param request The arguments of the revocation request.
    function revoke(RevocationRequest calldata request) external {
        _verifyAttester(msg.sender);
        _eas.revoke(request);
    }

    /// @dev Ensures that only the allowed attester can attest.
    /// @param attester The attester to verify.
    function _verifyAttester(address attester) private view {
        if (!isAttester[attester]) {
            revert AccessDenied();
        }
    }
}
