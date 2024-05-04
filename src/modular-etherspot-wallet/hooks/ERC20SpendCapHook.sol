// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.23;

// import {ECDSA} from "solady/src/utils/ECDSA.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IValidator, IHook, MODULE_TYPE_VALIDATOR, MODULE_TYPE_HOOK, VALIDATION_FAILED} from "../erc7579-ref-impl/interfaces/IERC7579Module.sol";
// import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
// import "../../../account-abstraction/contracts/core/Helpers.sol";
// import "../erc7579-ref-impl/libs/ModeLib.sol";
// import "../erc7579-ref-impl/libs/ExecutionLib.sol";
// import {ModularEtherspotWallet} from "../wallet/ModularEtherspotWallet.sol";

// import "forge-std/console2.sol";

// contract ERC20SpendCapHook is IHook {
//     using ModeLib for ModeCode;
//     using ExecutionLib for bytes;

//     error ERC20SKV_PaymasterNotSet();
//     error ERC20SKV_InvalidPaymaster();
//     error ERC20SKV_InvalidSessionKey();
//     error ERC20SKV_SessionPaused(address sessionKey);
//     error ERC20SKV_UnsuportedToken();
//     error ERC20SKV_UnsupportedSelector(bytes4 selectorUsed);
//     error ERC20SKV_SessionKeySpendLimitExceeded();
//     error ERC20SKV_ExceedsExecutorSpendCap(uint256 total, uint256 spendCap);
//     error ERC20SKV_InsufficientApprovalAmount();
//     event ERC20SKV_ExecutorSpendCapReduced(uint256 amount, uint256 newCap);
//     event ERC20SKV_SessionKeySpentLimitReduced(
//         uint256 amount,
//         uint256 newLimit
//     );
//     error NotImplemented();

//     mapping(address wallet => uint256 spendingCap) public executorSpendCap;

//     function onInstall(bytes calldata data) external override {
//         if (data.length <= 68) return;
//         uint256 offset = 4;
//         offset += 64;
//         uint256 execSpendCap = abi.decode(data[offset:], (uint256));
//         executorSpendCap[msg.sender] = execSpendCap;
//         // TODO: add event
//     }

//     function onUninstall(bytes calldata data) external override {
//         // Clean up
//     }

//     function isInitialized(address _mew) external view returns (bool) {
//         revert NotImplemented();
//     }

//     function preCheck(
//         address msgSender,
//         bytes calldata msgData
//     ) external override returns (bytes memory hookData) {
//         console2.log("ESKV - preCheck called by", msg.sender);
//         ModeCode mode = ModeCode.wrap(bytes32(msgData[4:36]));
//         CallType callType = mode.getCallType();
//         uint256 total = this.calculateSpend(
//             callType,
//             msgData[68 + 32:msgData.length - 8]
//         );
//         if (total > executorSpendCap[msg.sender])
//             revert ERC20SKV_ExceedsExecutorSpendCap(
//                 total,
//                 executorSpendCap[msg.sender]
//             );
//         return abi.encode(total);
//     }

//     function calculateSpend(
//         CallType callType,
//         bytes calldata executionCallData
//     ) public returns (uint256 total) {
//         console2.log("calculateSpend called");
//         uint256 amt;
//         if (callType == CALLTYPE_BATCH) {
//             console2.log("BATCH CALL");
//             Execution[] calldata executions = executionCallData.decodeBatch();
//             for (uint256 i; i < executions.length; i++) {
//                 bytes calldata d = executions[i].callData;
//                 bytes4 selector = bytes4(d[0:4]);
//                 if (selector != IERC20.approve.selector) {
//                     uint256 a;
//                     assembly {
//                         // Calculate the offset of the last 32 bytes
//                         let offset := sub(d.length, 0x20)
//                         // Load the last 32 bytes into a
//                         a := calldataload(add(d.offset, offset))
//                     }
//                     amt = amt + a;
//                 }
//                 console2.log("Amount:", amt);
//             }
//         } else if (callType == CALLTYPE_SINGLE) {
//             console2.log("SINGLE CALL");
//             (
//                 address target,
//                 uint256 value,
//                 bytes calldata callData
//             ) = executionCallData.decodeSingle();
//             console2.logBytes(callData);
//             bytes4 selector = bytes4(callData[0:4]);
//             if (selector != IERC20.approve.selector) {
//                 uint256 a;
//                 assembly {
//                     let offset := sub(callData.length, 0x20)
//                     a := calldataload(add(callData.offset, offset))
//                 }
//                 console2.log(a);
//                 amt = amt + a;
//             }
//             console2.log("Amount:", amt);
//         } else if (callType == CALLTYPE_DELEGATECALL) {
//             console2.log("DELEGATE CALL");
//             bytes4 selector = bytes4(executionCallData[0:4]);
//             if (selector != IERC20.approve.selector) {
//                 uint256 a;
//                 assembly {
//                     let offset := sub(executionCallData.length, 0x20)
//                     a := calldataload(add(executionCallData.offset, offset))
//                 }
//                 amt = amt + a;
//             }
//             console2.log("Amount:", amt);
//         }
//         return amt;
//     }

//     function postCheck(
//         bytes calldata hookData
//     ) external override returns (bool success) {
//         uint256 amt = abi.decode(hookData, (uint256));
//         console2.log("ESKV - postCheck called");
//         console2.log("Total amount to be spent:", amt);
//         console2.log(
//             "Executor spend cap before:",
//             executorSpendCap[msg.sender]
//         );
//         console2.log(
//             "Executor spend cap after:",
//             executorSpendCap[msg.sender] - amt
//         );
//         executorSpendCap[msg.sender] = executorSpendCap[msg.sender] - amt;
//         emit ERC20SKV_ExecutorSpendCapReduced(
//             amt,
//             executorSpendCap[msg.sender]
//         );
//         return true;
//     }

//     function _validateSelector(bytes4 _selector) internal pure returns (bool) {
//         bytes4[] memory allowedSigs = new bytes4[](3);
//         allowedSigs[0] = IERC20.approve.selector;
//         allowedSigs[1] = IERC20.transfer.selector;
//         allowedSigs[2] = IERC20.transferFrom.selector;
//         for (uint256 i; i < allowedSigs.length; i++) {
//             if (_selector == allowedSigs[i]) {
//                 return true;
//             }
//         }
//         return false;
//     }

//     function _digest(
//         bytes calldata _data
//     )
//         internal
//         view
//         returns (
//             bytes4 selector,
//             address targetContract,
//             address to,
//             address from,
//             uint256 amount
//         )
//     {
//         bytes4 functionSelector;
//         assembly {
//             functionSelector := calldataload(_data.offset)
//             targetContract := calldataload(add(_data.offset, 0x04))
//         }
//         if (functionSelector == IERC20.approve.selector) {
//             console2.log("Approve function detected");
//             assembly {
//                 targetContract := calldataload(add(_data.offset, 0x04))
//                 to := calldataload(add(_data.offset, 0x24))
//                 amount := calldataload(add(_data.offset, 0x44))
//             }
//             return (functionSelector, targetContract, address(0), to, amount);
//         } else if (functionSelector == IERC20.transfer.selector) {
//             console2.log("Transfer function detected");
//             assembly {
//                 targetContract := calldataload(add(_data.offset, 0x04))
//                 to := calldataload(add(_data.offset, 0x24))
//                 amount := calldataload(add(_data.offset, 0x44))
//             }
//             return (functionSelector, targetContract, to, address(0), amount);
//         } else if (functionSelector == IERC20.transferFrom.selector) {
//             console2.log("TransferFrom function detected");
//             assembly {
//                 targetContract := calldataload(add(_data.offset, 0x04))
//                 from := calldataload(add(_data.offset, 0x24))
//                 to := calldataload(add(_data.offset, 0x44))
//                 amount := calldataload(add(_data.offset, 0x64))
//             }
//             return (functionSelector, targetContract, to, from, amount);
//         } else {
//             revert ERC20SKV_UnsupportedSelector(functionSelector);
//         }
//     }

//     function isModuleType(
//         uint256 moduleTypeId
//     ) external pure override returns (bool) {
//         return moduleTypeId == MODULE_TYPE_HOOK;
//     }
// }
