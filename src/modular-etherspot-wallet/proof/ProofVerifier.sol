pragma solidity 0.8.23;

import {IProofVerifier} from "../interfaces/IProofVerifier.sol";

// @inheritdoc IProofVerifier
contract ProofVerifier is IProofVerifier {
    function verifyProof(bytes calldata proof) external view returns (bool) {
        return true;
    }
}