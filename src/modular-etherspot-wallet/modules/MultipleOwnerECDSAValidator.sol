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
    string constant NAME = "MultipleOwnerECDSAValidator";
    string constant VERSION = "1.0.0";

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
    ) external view override returns (bool) {}

    function getModuleTypes() external view returns (EncodedModuleTypes) {}

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
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view override returns (bytes4) {
        bytes32 domainSeparator = _domainSeparator();
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

    /// @dev EIP-712 compliant domain separator
    function _domainSeparator() internal view returns (bytes32) {
        bytes32 nameHash = keccak256(bytes(NAME));
        bytes32 versionHash = keccak256(bytes(VERSION));
        // Use proxy address for the EIP-712 domain separator.
        address proxyAddress = address(this);
        // Construct domain separator with name, version, chainId, and proxy address.
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    proxyAddress
                )
            );
    }
}
