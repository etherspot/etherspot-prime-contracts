// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {EIP712} from "solady/src/utils/EIP712.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {MODULE_TYPE_VALIDATOR, VALIDATION_FAILED} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../../../account-abstraction/contracts/core/Helpers.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";

import {ModularEtherspotWallet} from "../../wallet/ModularEtherspotWallet.sol";
import {IERC20SessionKeyValidator} from "../../interfaces/IERC20SessionKeyValidator.sol";
import {ERC20Actions} from "../executors/ERC20Actions.sol";

contract ERC20SessionKeyValidator is IERC20SessionKeyValidator, EIP712 {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                  CONSTANTS                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    /// @dev `keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")`.
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    string constant NAME = "ERC20SessionKeyValidator";
    string constant VERSION = "1.0.0";

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    ERRORS                 */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    error ERC20SKV_InvalidSessionKey();
    error ERC20SKV_SessionKeyDoesNotExist(address session);
    error ERC20SKV_SessionPaused(address sessionKey);
    error ERC20SKV_UnsuportedToken();
    error ERC20SKV_UnsupportedSelector(bytes4 selectorUsed);
    error ERC20SKV_UnsupportedInterface();
    error ERC20SKV_SessionKeySpendLimitExceeded();
    error ERC20SKV_InsufficientApprovalAmount();
    error NotImplemented();

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   MAPPINGS                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    mapping(address => bool) public initialized;
    mapping(address wallet => address[] assocSessionKeys)
        public walletSessionKeys;
    mapping(address sessionKey => mapping(address wallet => SessionData))
        public sessionData;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*               PUBLIC/EXTERNAL             */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    // @inheritdoc IERC20SessionKeyValidator
    function enableSessionKey(bytes calldata _sessionData) public {
        address sessionKey = address(bytes20(_sessionData[0:20]));
        address token = address(bytes20(_sessionData[20:40]));
        bytes4 interfaceId = bytes4(_sessionData[40:44]);
        bytes4 funcSelector = bytes4(_sessionData[44:48]);
        uint256 spendingLimit = uint256(bytes32(_sessionData[48:80]));
        uint48 validAfter = uint48(bytes6(_sessionData[80:86]));
        uint48 validUntil = uint48(bytes6(_sessionData[86:92]));
        sessionData[sessionKey][msg.sender] = SessionData(
            token,
            interfaceId,
            funcSelector,
            spendingLimit,
            validAfter,
            validUntil,
            false
        );
        walletSessionKeys[msg.sender].push(sessionKey);
        emit ERC20SKV_SessionKeyEnabled(sessionKey, msg.sender);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function disableSessionKey(address _session) public {
        if (sessionData[_session][msg.sender].validUntil == 0)
            revert ERC20SKV_SessionKeyDoesNotExist(_session);
        delete sessionData[_session][msg.sender];
        emit ERC20SKV_SessionKeyDisabled(_session, msg.sender);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function rotateSessionKey(
        address _oldSessionKey,
        bytes calldata _newSessionData
    ) external {
        disableSessionKey(_oldSessionKey);
        enableSessionKey(_newSessionData);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function toggleSessionKeyPause(address _sessionKey) external {
        SessionData storage sd = sessionData[_sessionKey][msg.sender];
        sd.paused = !sd.paused;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function checkSessionKeyPaused(
        address _sessionKey
    ) public view returns (bool paused) {
        return sessionData[_sessionKey][msg.sender].paused;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) public returns (bool valid) {
        bytes calldata callData = userOp.callData;
        (
            bytes4 selector,
            address target,
            address to,
            address from,
            uint256 amount
        ) = _digest(callData);

        SessionData storage sd = sessionData[_sessionKey][msg.sender];
        if (sd.validUntil == 0 || sd.validUntil < block.timestamp)
            revert ERC20SKV_InvalidSessionKey();
        if (target != sd.token) revert ERC20SKV_UnsuportedToken();
        if (IERC165(target).supportsInterface(sd.interfaceId) == false)
            revert ERC20SKV_UnsupportedInterface();
        if (selector != sd.funcSelector)
            revert ERC20SKV_UnsupportedSelector(selector);
        if (amount > sd.spendingLimit)
            revert ERC20SKV_SessionKeySpendLimitExceeded();
        if (checkSessionKeyPaused(_sessionKey))
            revert ERC20SKV_SessionPaused(_sessionKey);
        return true;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function getAssociatedSessionKeys()
        public
        view
        returns (address[] memory keys)
    {
        return walletSessionKeys[msg.sender];
    }

    // @inheritdoc IERC20SessionKeyValidator
    function getSessionKeyData(
        address _sessionKey
    ) public view returns (SessionData memory data) {
        return sessionData[_sessionKey][msg.sender];
    }

    // @inheritdoc IERC20SessionKeyValidator
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256 validationData) {
        // EIP712
        bytes32 domainSeparator = _domainSeparator();
        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, userOpHash)
        );
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(signedMessageHash);
        address sessionKeySigner = ECDSA.recover(ethHash, userOp.signature);

        if (!validateSessionKeyParams(sessionKeySigner, userOp))
            return VALIDATION_FAILED;
        SessionData storage sd = sessionData[sessionKeySigner][msg.sender];
        return _packValidationData(false, sd.validUntil, sd.validAfter);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function isModuleType(
        uint256 moduleTypeId
    ) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function onInstall(bytes calldata data) external override {
        initialized[msg.sender] = true;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function onUninstall(bytes calldata data) external override {
        address[] memory sessionKeys = getAssociatedSessionKeys();
        for (uint256 i; i < sessionKeys.length; i++) {
            delete sessionData[sessionKeys[i]][msg.sender];
        }
        initialized[msg.sender] = false;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    ) external view returns (bytes4) {
        revert NotImplemented();
    }

    // @inheritdoc IERC20SessionKeyValidator
    function isInitialized(address smartAccount) external view returns (bool) {
        revert NotImplemented();
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   INTERNAL                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function _digest(
        bytes calldata _data
    )
        internal
        pure
        returns (
            bytes4 selector,
            address targetContract,
            address to,
            address from,
            uint256 amount
        )
    {
        bytes4 functionSelector;
        assembly {
            functionSelector := calldataload(_data.offset)
            targetContract := calldataload(add(_data.offset, 0x04))
        }
        if (
            functionSelector == IERC20.approve.selector ||
            functionSelector == IERC20.transfer.selector ||
            functionSelector == ERC20Actions.transferERC20Action.selector
        ) {
            assembly {
                targetContract := calldataload(add(_data.offset, 0x04))
                to := calldataload(add(_data.offset, 0x24))
                amount := calldataload(add(_data.offset, 0x44))
            }
            return (functionSelector, targetContract, to, address(0), amount);
        } else if (functionSelector == IERC20.transferFrom.selector) {
            assembly {
                targetContract := calldataload(add(_data.offset, 0x04))
                from := calldataload(add(_data.offset, 0x24))
                to := calldataload(add(_data.offset, 0x44))
                amount := calldataload(add(_data.offset, 0x64))
            }
            return (functionSelector, targetContract, to, from, amount);
        } else {
            revert ERC20SKV_UnsupportedSelector(functionSelector);
        }
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
