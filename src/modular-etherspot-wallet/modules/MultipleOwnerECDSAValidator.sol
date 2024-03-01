// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import "../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../erc7579-ref-impl/libs/ModeLib.sol";
import "../erc7579-ref-impl/libs/ExecutionLib.sol";
import {ModularEtherspotWallet} from "../wallet/ModularEtherspotWallet.sol";
import {ECDSA} from "solady/src/utils/ECDSA.sol";

contract MultipleOwnerECDSAValidator is IValidator {
    using ExecutionLib for bytes;
    using ECDSA for bytes32;

    bytes4 private constant ERC1271_SUCCESS = 0x1626ba7e;
    bytes4 private constant ERC1271_FAILURE = 0xffffffff;
    bytes32 constant NAME = 0x4a32d5b1f5956a46c94bfb08ef0f9d70b9fd1e76f1047bcfd4b8d1cf4ec606ae; // keccak256("MultipleOwnerECDSAValidator")
    bytes32 constant VERSION = 0x604f330029e6455b43bfb3cfb2e9ebd9e2c90142aa85c5e4be430e6b2b57b740; // keccak256("1.0.0")


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
        bytes32 domainSeparator;
        assembly {
            let temp := mload(0x40) // Load free memory pointer
            mstore(temp, 0x1901) // Prefix for EIP-191 signature
            mstore(add(temp, 2), NAME) // Place contract name
            mstore(add(temp, 34), VERSION) // Place contract version
            mstore(add(temp, 66), chainid()) // Place chain ID
            mstore(add(temp, 98), caller()) // Place verifying contract address
            domainSeparator := keccak256(temp, 130) // Hash the concatenated values
        }
        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hash)
        );
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(signedMessageHash);
        address owner = ECDSA.recover(ethHash, data);
        if (ModularEtherspotWallet(payable(msg.sender)).isOwner(owner)) {
            return ERC1271_SUCCESS;
        }
        return ERC1271_FAILURE;
    }
}
