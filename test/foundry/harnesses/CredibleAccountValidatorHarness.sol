// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CredibleAccountValidator} from "../../../src/modular-etherspot-wallet/modules/validators/CredibleAccountValidator.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";

contract CredibleAccountValidatorHarness is CredibleAccountValidator {
    function exposed_validateSingleCall(
        bytes calldata callData,
        SessionData memory sd,
        address userOpSender
    ) external view returns (bool) {
        return _validateSingleCall(callData, sd, userOpSender);
    }

    function exposed_validateBatchCall(
        bytes calldata callData,
        SessionData memory sd,
        address userOpSender
    ) external view returns (bool) {
        return _validateBatchCall(callData, sd, userOpSender);
    }

    function exposed_validateTokenData(
        address[] memory tokens,
        bytes4 selector,
        address userOpSender,
        address from,
        uint256 amount,
        address token
    ) external view returns (bool) {
        return
            _validateTokenData(
                tokens,
                selector,
                userOpSender,
                from,
                amount,
                token
            );
    }

    function exposed_digest(
        bytes calldata _data
    )
        external
        pure
        returns (bytes4 selector, address from, address to, uint256 amount)
    {
        return _digest(_data);
    }

    function exposed_digestSignature(
        bytes calldata signatureWithMerkleProof
    )
        external
        view
        returns (
            bytes memory signature,
            bytes32 merkleRoot,
            bytes32[] memory merkleProof
        )
    {
        return _digestSignature(signatureWithMerkleProof);
    }
}
