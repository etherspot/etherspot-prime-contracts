// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {CredibleAccountHook} from "../../../src/modular-etherspot-wallet/modules/hooks/CredibleAccountHook.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";

contract CredibleAccountHookHarness is CredibleAccountHook {
    function exposed_lockTokens(bytes calldata _data) external returns (bool) {
        return _lockTokens(_data);
    }

    function exposed_getTokenBalance(
        address _token
    ) external view returns (uint256) {
        return _getTokenBalance(_token);
    }
}
