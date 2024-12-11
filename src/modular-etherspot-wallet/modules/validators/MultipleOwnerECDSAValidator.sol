// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import {ModularEtherspotWallet} from "../../wallet/ModularEtherspotWallet.sol";
import {ECDSA} from "solady/src/utils/ECDSA.sol";

contract MultipleOwnerECDSAValidator is IValidator {
    using ExecutionLib for bytes;
    using ECDSA for bytes32;

    string constant NAME = "MultipleOwnerECDSAValidator";
    string constant VERSION = "1.1.0";

    error InvalidExec();

    mapping(address => bool) internal _initialized;

    function onInstall(bytes calldata data) external override {
        if (isInitialized(msg.sender)) revert AlreadyInitialized(msg.sender);
        _initialized[msg.sender] = true;
    }

    function onUninstall(bytes calldata data) external override {
        if (!isInitialized(msg.sender)) revert NotInitialized(msg.sender);
        _initialized[msg.sender] = false;
    }

    function isInitialized(
        address smartAccount
    ) public view override returns (bool) {
        return _initialized[smartAccount];
    }

    function isModuleType(
        uint256 typeID
    ) external pure override returns (bool) {
        return typeID == MODULE_TYPE_VALIDATOR;
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        address signer = hash.recover(userOp.signature);
        if (
            signer == address(0) ||
            !ModularEtherspotWallet(payable(msg.sender)).isOwner(signer)
        ) {
            return VALIDATION_FAILED;
        }
        // get the function selector that will be called by EntryPoint
        bytes4 execFunction = bytes4(userOp.callData[:4]);

        // get the mode
        CallType callType = CallType.wrap(bytes1(userOp.callData[4]));
        bytes calldata executionCalldata = userOp.callData[36:];
        if (callType == CALLTYPE_BATCH) {
            Execution[] calldata executions = executionCalldata.decodeBatch();
        } else if (callType == CALLTYPE_SINGLE) {
            (
                address target,
                uint256 value,
                bytes calldata callData
            ) = executionCalldata.decodeSingle();
        }
    }

    function isValidSignatureWithSender(
        address,
        bytes32 hash,
        bytes calldata data
    ) external view override returns (bytes4) {
        address recoveredOwner = ECDSA.recover(hash, data);
        if (
            ModularEtherspotWallet(payable(msg.sender)).isOwner(recoveredOwner)
        ) {
            return 0x1626ba7e; // ERC1271_MAGICVALUE
        }
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(hash);
        address owner = ECDSA.recover(ethHash, data);
        if (ModularEtherspotWallet(payable(msg.sender)).isOwner(owner)) {
            return 0x1626ba7e;
        }
        return 0xffffffff;
    }
}
