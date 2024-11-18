// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CredibleAccountModule} from "../../../src/modular-etherspot-wallet/modules/validators/CredibleAccountModule.sol";
import {TokenData} from "../../../src/modular-etherspot-wallet/common/Structs.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";

contract CredibleAccountModuleHarness is CredibleAccountModule {
    constructor(
        address _proofVerifier,
        address _hookMultiPlexer
    ) CredibleAccountModule(_proofVerifier, _hookMultiPlexer) {}

    function exposed_validateSingleCall(
        bytes calldata _callData,
        address _sessionKey,
        address _userOpSender
    ) external returns (bool) {
        return _validateSingleCall(_callData, _sessionKey, _userOpSender);
    }

    function exposed_validateBatchCall(
        bytes calldata _callData,
        address _sessionKey,
        address _userOpSender
    ) external returns (bool) {
        return _validateBatchCall(_callData, _sessionKey, _userOpSender);
    }

    function exposed_validateTokenData(
        address _sessionKey,
        address _userOpSender,
        uint256 _amount,
        address _token
    ) external returns (bool) {
        return _validateTokenData(_sessionKey, _userOpSender, _amount, _token);
    }

    function exposed_digestClaimTx(
        bytes calldata _data
    )
        external
        returns (bytes4 selector, address to, uint256 amount)
    {
        return _digestClaimTx(_data);
    }

    function exposed_digestSignature(
        bytes calldata _signatureWithProof
    ) external pure returns (bytes memory signature, bytes memory proof) {
        return _digestSignature(_signatureWithProof);
    }

    function exposed_retrieveLockedBalance(
        address _wallet,
        address _token
    ) external view returns (uint256) {
        return _retrieveLockedBalance(_wallet, _token);
    }

    function exposed_cumulativeLockedForWallet(
        address _wallet
    ) external view returns (TokenData[] memory) {
        return _cumulativeLockedForWallet(_wallet);
    }
}
