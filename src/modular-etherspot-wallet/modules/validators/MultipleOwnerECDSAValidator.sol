// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "../../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import {ModularEtherspotWallet} from "../../wallet/ModularEtherspotWallet.sol";
import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {EIP712} from "solady/src/utils/EIP712.sol";

contract MultipleOwnerECDSAValidator is EIP712, IValidator {
    using ExecutionLib for bytes;
    using ECDSA for bytes32;

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    string constant NAME = "MultipleOwnerECDSAValidator";
    string constant VERSION = "1.0.0";

    error InvalidExec();
    error RequiredModule();

    mapping(address => bool) internal _initialized;

    function onInstall(bytes calldata data) external override {
        if (isInitialized(msg.sender)) revert AlreadyInitialized(msg.sender);
        _initialized[msg.sender] = true;
    }

    function onUninstall(bytes calldata data) external override {
        revert RequiredModule();
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
        // Include the proxy address in the domain separator
        bytes32 domainSeparator = _domainSeparator();
        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hash)
        );
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(signedMessageHash);
        address owner = ECDSA.recover(ethHash, data);
        if (ModularEtherspotWallet(payable(msg.sender)).isOwner(owner)) {
            return 0x1626ba7e;
        }
        return 0xffffffff;
    }

    function _domainSeparator() internal view override returns (bytes32) {
        (string memory _name, string memory _version) = _domainNameAndVersion();
        bytes32 nameHash = keccak256(bytes(_name));
        bytes32 versionHash = keccak256(bytes(_version));
        // Use the proxy address for the EIP-712 domain separator.
        address proxyAddress = address(this);

        // Construct the domain separator with name, version, chainId, and proxy address.
        bytes32 typeHash = EIP712_DOMAIN_TYPEHASH;
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

    function _domainNameAndVersion()
        internal
        pure
        override
        returns (string memory, string memory)
    {
        return (NAME, VERSION);
    }
}
