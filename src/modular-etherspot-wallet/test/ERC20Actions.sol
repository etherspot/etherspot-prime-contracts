// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IFallback} from "../erc7579-ref-impl/interfaces/IERC7579Module.sol";

contract ERC20Actions is IFallback {
    function onInstall(bytes calldata data) external override {
        // Initialize
    }

    function onUninstall(bytes calldata data) external override {
        // Clean up
    }
    function isModuleType(
        uint256 moduleTypeId
    ) external view override returns (bool) {}

    function isInitialized(address _mew) external view returns (bool) {}
    function transferERC20Action(
        address _token,
        uint256 _amount,
        address _to
    ) external {
        IERC20(_token).transferFrom(msg.sender, _to, _amount);
    }

    function invalidERC20Action() public pure returns (uint256) {
        return 0;
    }

    // fallback() external payable {
    //     address target;
    //     assembly {
    //         target := sload(address())
    //         calldatacopy(0, 0, calldatasize())
    //         let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
    //         returndatacopy(0, 0, returndatasize())
    //         switch result
    //         case 0 {
    //             revert(0, returndatasize())
    //         }
    //         default {
    //             return(0, returndatasize())
    //         }
    //     }
    // }
}
