// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {TokenLockHook} from "../../../src/modular-etherspot-wallet/modules/hooks/TokenLockHook.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";

contract TokenLockHookHarness is TokenLockHook {
    function exposed_lockToken(address _token, uint256 _amount) external {
        return _lockToken(_token, _amount);
    }

    function exposed_handleMultiTokenSessionKeyValidator(
        CallType _callType,
        bytes calldata _executionData
    ) external {
        return _handleMultiTokenSessionKeyValidator(_callType, _executionData);
    }

    function exposed_checkLockedTokens(
        CallType _callType,
        bytes calldata _executionData
    ) external returns (bytes memory) {
        return _checkLockedTokens(_callType, _executionData);
    }

    function exposed_getTokenAmount(
        bytes calldata _data
    ) external pure returns (uint256) {
        return _getTokenAmount(_data);
    }
}
