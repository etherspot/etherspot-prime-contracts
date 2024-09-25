pragma solidity 0.8.23;

import {ICredibleAccountProofVerifier} from "../interfaces/ICredibleAccountProofVerifier.sol";

// @inheritdoc ICredibleAccountProofVerifier
contract CredibleAccountProofVerifier is ICredibleAccountProofVerifier {
    function verifyProof(bytes calldata proof) external view returns (bool) {
        return true;
    }
}