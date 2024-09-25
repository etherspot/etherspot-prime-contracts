// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @title ICredibleAccountProofVerifier
/// @author Etherspot
/// @notice Interface for the contract with verification function to verify credible account proof
interface ICredibleAccountProofVerifier {
    function verifyProof(bytes calldata proof) external view returns (bool);
}