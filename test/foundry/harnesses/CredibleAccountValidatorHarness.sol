// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CredibleAccountValidator} from "../../../src/modular-etherspot-wallet/modules/validators/CredibleAccountValidator.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";

contract CredibleAccountValidatorHarness is CredibleAccountValidator {

    constructor(address _proofVerifier) CredibleAccountValidator(_proofVerifier) {}

    function exposed_validateSingleCall(
        bytes calldata _callData,
        address _sessionKey,
        SessionData memory _sd,
        address _userOpSender
    ) external returns (bool) {
        return _validateSingleCall(_callData, _sessionKey, _sd, _userOpSender);
    }

    function exposed_validateBatchCall(
        bytes calldata _callData,
        address _sessionKey,
        SessionData memory _sd,
        address _userOpSender
    ) external returns (bool) {
        return _validateBatchCall(_callData, _sessionKey, _sd, _userOpSender);
    }

    function exposed_validateTokenData(
        address _sessionKey,
        LockedToken[] memory _lockedTokens,
        bytes4 _selector,
        address _userOpSender,
        address _from,
        uint256 _amount,
        address _token
    ) external returns (bool) {
        return
            _validateTokenData(
                _sessionKey,
                _lockedTokens,
                _selector,
                _userOpSender,
                _from,
                _amount,
                _token
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
        bytes calldata _signatureWithProof
    )
        external
        view
        returns (
            bytes memory signature,
            bytes memory proof
        )
    {
        return _digestSignature(_signatureWithProof);
    }
}
