// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IFallback} from "../../modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract TestUniswapAction is IFallback {
    function onInstall(bytes calldata data) external override {}

    function onUninstall(bytes calldata data) external override {}
    function isModuleType(
        uint256 moduleTypeId
    ) external view override returns (bool) {}

    function isInitialized(address _mew) external view returns (bool) {}
    function swapSingle(
        address _target,
        ISwapRouter.ExactInputSingleParams memory _swapParams
    ) external returns (uint256 amountOut) {
        amountOut = ISwapRouter(_target).exactInputSingle(_swapParams);
    }

    function invalidAction() public pure returns (uint256) {
        return 0;
    }
}
