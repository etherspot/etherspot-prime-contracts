// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import {IValidator, MODULE_TYPE_VALIDATOR, VALIDATION_FAILED, VALIDATION_SUCCESS} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../../../account-abstraction/contracts/core/Helpers.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import {ArrayLib} from "../../libraries/ArrayLib.sol";

import "forge-std/console2.sol";

contract MockTokenLockValidator is IValidator {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event MockSessionKeyEnabled(
        address indexed sessionKey,
        address indexed wallet
    );

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error NotImplemented();

    /*//////////////////////////////////////////////////////////////
                               STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct MockSessionData {
        address solver;
        bytes4 selector;
        uint48 validAfter;
        uint48 validUntil;
        address[] lockedTokens;
        uint256[] lockedAmounts;
    }

    /*//////////////////////////////////////////////////////////////
                               MAPPINGS
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) public initialized;
    mapping(address sessionKey => mapping(address wallet => MockSessionData))
        public sessionData;

    /*//////////////////////////////////////////////////////////////
                           PUBLIC/EXTERNAL
    //////////////////////////////////////////////////////////////*/

    function enableSessionKey(bytes calldata _sessionData) public {
        address sessionKey = address(bytes20(_sessionData[0:20]));
        address solver = address(bytes20(_sessionData[20:40]));
        bytes4 funcSelector = bytes4(_sessionData[40:44]);
        uint48 validAfter = uint48(bytes6(_sessionData[44:50]));
        uint48 validUntil = uint48(bytes6(_sessionData[50:56]));
        uint256 tokenLength = uint256(bytes32(_sessionData[56:88]));
        address[] memory tokens = new address[](tokenLength);
        uint256 offset = 88;
        for (uint256 i; i < tokenLength; ++i) {
            tokens[i] = address(
                uint160(uint256(bytes32(_sessionData[offset:offset + 32])))
            );
            offset += 32;
        }
        uint256 amountLength = uint256(
            bytes32(_sessionData[offset:offset + 32])
        );
        offset += 32;
        uint256[] memory amounts = new uint256[](amountLength);
        for (uint256 i; i < amountLength; ++i) {
            amounts[i] = uint256(bytes32(_sessionData[offset:offset + 32]));
            offset += 32;
        }
        sessionData[sessionKey][msg.sender] = MockSessionData(
            solver,
            funcSelector,
            validAfter,
            validUntil,
            tokens,
            amounts
        );
        emit MockSessionKeyEnabled(sessionKey, msg.sender);
    }

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256) {
        address sessionKeySigner = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(userOpHash),
            userOp.signature
        );
        MockSessionData memory sd = sessionData[sessionKeySigner][msg.sender];
        return _packValidationData(false, sd.validUntil, sd.validAfter);
    }

    function isModuleType(
        uint256 moduleTypeId
    ) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function onInstall(bytes calldata data) external override {
        initialized[msg.sender] = true;
    }

    function onUninstall(bytes calldata data) external override {
        initialized[msg.sender] = false;
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4) {
        revert NotImplemented();
    }

    function isInitialized(address smartAccount) external view returns (bool) {
        return initialized[smartAccount];
    }
}
