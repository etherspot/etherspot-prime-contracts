// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {SessionKeyValidator} from "../../../src/modular-etherspot-wallet/modules/validators/SessionKeyValidator.sol";
import {ExecutionValidation, SessionData} from "../../../src/modular-etherspot-wallet/common/Structs.sol";
import {ComparisonRule} from "../../../src/modular-etherspot-wallet/common/Enums.sol";

contract SessionKeyValidatorHarness is SessionKeyValidator {
    function exposed_extractExecutionValidationAndSignature(
        bytes calldata _userOpSig
    )
        external
        pure
        returns (
            ExecutionValidation[] memory execValidations,
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        return _extractExecutionValidationAndSignature(_userOpSig);
    }

    function exposed_validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata _userOp,
        ExecutionValidation[] memory _execVals
    ) external returns (bool success, uint48 validAfter, uint48 validUntil) {
        return _validateSessionKeyParams(_sessionKey, _userOp, _execVals);
    }

    function exposed_validatePermission(
        address _sender,
        SessionData memory _sd,
        ExecutionValidation memory _execValidations,
        address target,
        uint256 value,
        bytes calldata callData
    ) external returns (bool) {
        return
            _validatePermission(
                _sender,
                _sd,
                _execValidations,
                target,
                value,
                callData
            );
    }

    function exposed_checkCondition(
        bytes32 _param,
        bytes32 _value,
        ComparisonRule _rule
    ) external returns (bool) {
        return _checkCondition(_param, _value, _rule);
    }
}
