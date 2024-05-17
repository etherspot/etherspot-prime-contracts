// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFallback} from "../../../modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";

contract ERC20Actions is IFallback {
    function onInstall(bytes calldata data) external override {}

    function onUninstall(bytes calldata data) external override {}
    function isModuleType(
        uint256 moduleTypeId
    ) external view override returns (bool) {}

    function isInitialized(address _mew) external view returns (bool) {}
    function transferERC20Action(
        address _token,
        address _to,
        uint256 _amount
    ) external {
        IERC20(_token).transferFrom(msg.sender, _to, _amount);
    }

    function invalidERC20Action() public pure returns (uint256) {
        return 0;
    }
}
