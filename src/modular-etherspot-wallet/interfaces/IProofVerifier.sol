// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title IProofVerifier
/// @author Etherspot
/// @notice Interface for the contract with verification function to verify proof
interface IProofVerifier {
    function verifyProof(bytes calldata proof) external view returns (bool);
}