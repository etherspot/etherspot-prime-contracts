// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CredibleAccountHook} from "../../../src/modular-etherspot-wallet/modules/hooks/CredibleAccountHook.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";

contract CredibleAccountHookHarness is CredibleAccountHook {
    constructor(address _validator) CredibleAccountHook(_validator) {}

    function exposed_getTokenBalance(
        address _token
    ) external view returns (uint256) {
        return _getTokenBalance(_token);
    }

    function exposed_lockTokens(bytes calldata _data) external returns (bool) {
        return _lockTokens(_data);
    }

    function exposed_unlockTokens(
        address _sessionKey,
        address _token,
        address _receiver,
        uint256 _amount
    ) external returns (bool) {
        return _unlockTokens(_sessionKey, _token, _receiver, _amount);
    }

    function exposed_digestERC20Transaction(
        bytes calldata _data
    )
        external
        pure
        returns (bytes4 selector, address recipient, uint256 amount)
    {
        (selector, recipient, amount) = _digestERC20Transaction(_data);
    }

    function exposed_encodeInitialLockedState()
        external
        view
        returns (bytes memory)
    {
        return _encodeInitialLockedState();
    }
}
