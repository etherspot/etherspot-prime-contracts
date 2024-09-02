// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import {MODULE_TYPE_VALIDATOR, VALIDATION_FAILED, VALIDATION_SUCCESS} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../../../account-abstraction/contracts/core/Helpers.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import {ITokenLockSessionKeyValidator} from "../../interfaces/ITokenLockSessionKeyValidator.sol";
import {ArrayLib} from "../../libraries/ArrayLib.sol";

contract TokenLockSessionKeyValidator is ITokenLockSessionKeyValidator {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                  CONSTANTS                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    string constant NAME = "TokenLockSessionKeyValidator";
    string constant VERSION = "1.0.0";

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    ERRORS                 */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    error ERC20SKV_ModuleAlreadyInstalled();
    error ERC20SKV_ModuleNotInstalled();
    error ERC20SKV_InvalidSessionKey();
    error ERC20SKV_InvalidToken();
    error ERC20SKV_InvalidFunctionSelector();
    error ERC20SKV_InvalidSpendingLimit();
    error ERC20SKV_InvalidValidAfter(uint48 validAfter);
    error ERC20SKV_InvalidValidUntil(uint48 validUntil);
    error ERC20SKV_SessionKeyAlreadyExists(address sessionKey);
    error ERC20SKV_SessionKeyDoesNotExist(address session);
    error ERC20SKV_SessionPaused(address sessionKey);
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
        uint256 offset = 0;

        address sessionKey = address(bytes20(_sessionData[offset:offset + 20]));
        offset += 20;
        if (sessionKey == address(0)) revert ERC20SKV_InvalidSessionKey();

        uint256 tokensLength = uint256(bytes32(_sessionData[offset:offset + 32]));
        offset += 32;

        address[] memory tokens = new address[](tokensLength);
        for (uint256 i = 0; i < tokensLength; i++) {
            tokens[i] = address(bytes20(_sessionData[offset:offset + 20]));
            offset += 20;
        }

        bytes4 funcSelector = bytes4(_sessionData[offset:offset + 4]);
        offset += 4;
        if (funcSelector == bytes4(0)) revert ERC20SKV_InvalidFunctionSelector();

        uint256 amountsLength = uint256(bytes32(_sessionData[offset:offset + 32]));
        offset += 32;

        uint256[] memory amounts = new uint256[](amountsLength);
        for (uint256 i = 0; i < amountsLength; i++) {
            amounts[i] = uint256(bytes32(_sessionData[offset:offset + 32]));
            offset += 32;
        }

        address solverAddress = address(bytes20(_sessionData[offset:offset + 20]));
        offset += 20;

        uint48 validUntil = uint48(uint256(bytes32(_sessionData[offset:offset + 6])));
        offset += 6;
        if (validUntil == 0) revert ERC20SKV_InvalidValidUntil(validUntil);

        uint48 validAfter = uint48(uint256(bytes32(_sessionData[offset:offset + 6])));
        offset += 6;
        if (validAfter == 0) revert ERC20SKV_InvalidValidAfter(validAfter);

        sessionData[sessionKey][msg.sender] = SessionData(
            tokens,
            funcSelector,
            amounts,
            solverAddress,
            validUntil,
            validAfter,
            true
        );
        walletSessionKeys[msg.sender].push(sessionKey);
        emit ERC20SKV_SessionKeyEnabled(sessionKey, msg.sender);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function disableSessionKey(address _session) public {
        if (sessionData[_session][msg.sender].validUntil == 0)
            revert ERC20SKV_SessionKeyDoesNotExist(_session);
        delete sessionData[_session][msg.sender];
        walletSessionKeys[msg.sender] = ArrayLib._removeElement(
            getAssociatedSessionKeys(),
            _session
        );
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
        if (sd.validUntil == 0)
            revert ERC20SKV_SessionKeyDoesNotExist(_sessionKey);
        if (sd.live) {
            sd.live = false;
            emit ERC20SKV_SessionKeyPaused(_sessionKey, msg.sender);
        } else {
            sd.live = true;
            emit ERC20SKV_SessionKeyUnpaused(_sessionKey, msg.sender);
        }
    }

    // @inheritdoc IERC20SessionKeyValidator
    function isSessionKeyLive(address _sessionKey) public view returns (bool) {
        return sessionData[_sessionKey][msg.sender].live;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata userOp
    ) public view returns (bool) {
        SessionData memory sd = sessionData[_sessionKey][msg.sender];
        if (isSessionKeyLive(_sessionKey) == false) {
            return false;
        }
        address target;
        bytes calldata callData = userOp.callData;
        bytes4 sel = bytes4(callData[:4]);
        if (sel == IERC7579Account.execute.selector) {
            ModeCode mode = ModeCode.wrap(bytes32(callData[4:36]));
            (CallType calltype, , , ) = ModeLib.decode(mode);
            if (calltype == CALLTYPE_SINGLE) {
                bytes calldata execData;
                // 0x00 ~ 0x04 : selector
                // 0x04 ~ 0x24 : mode code
                // 0x24 ~ 0x44 : execution target
                // 0x44 ~0x64 : execution value
                // 0x64 ~ : execution calldata
                (target, , execData) = ExecutionLib.decodeSingle(
                    callData[100:]
                );
                (
                    bytes4 selector,
                    address from,
                    address to,
                    uint256 amount
                ) = _digest(execData);

                if (selector != sd.funcSelector) return false;

                bool tokenFound = false;
                uint256 tokenIndex = 0;
                for (uint256 i = 0; i < sd.tokens.length; i++) {
                    if (sd.tokens[i] == target) {
                        tokenFound = true;
                        tokenIndex = i;
                        break;
                    }
                }
                if (!tokenFound) return false;

                if (! (amount == sd.amounts[tokenIndex])) return false;

                // validate if wallet has sufficient balance
                if (selector == IERC20.transfer.selector) {
                    if (IERC20(target).balanceOf(from) < amount) return false;
                } else if (selector == IERC20.transferFrom.selector) {
                    if (IERC20(target).allowance(from, to) < amount) return false;
                }

                return true;
            }
            if (calltype == CALLTYPE_BATCH) {
                Execution[] calldata execs = ExecutionLib.decodeBatch(
                    callData[100:]
                );
                for (uint256 i; i < execs.length; i++) {
                    target = execs[i].target;
                    (
                        bytes4 selector,
                        address from,
                        address to,
                        uint256 amount
                    ) = _digest(execs[i].callData);
                    if (selector != sd.funcSelector) return false;
                    bool tokenFound = false;
                    uint256 tokenIndex = 0;
                    for (uint256 j = 0; j < sd.tokens.length; j++) {
                        if (sd.tokens[j] == target) {
                            tokenFound = true;
                            tokenIndex = j;
                            break;
                        }
                    }
                    if (!tokenFound) return false;

                    if (!(amount == sd.amounts[tokenIndex])) return false;
                }
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    // @inheritdoc IERC20SessionKeyValidator
    function getAssociatedSessionKeys() public view returns (address[] memory) {
        return walletSessionKeys[msg.sender];
    }

    // @inheritdoc IERC20SessionKeyValidator
    function getSessionKeyData(
        address _sessionKey
    ) public view returns (SessionData memory) {
        return sessionData[_sessionKey][msg.sender];
    }

    // @inheritdoc IERC20SessionKeyValidator
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external override returns (uint256) {
        address sessionKeySigner = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(userOpHash),
            userOp.signature
        );
        if (!validateSessionKeyParams(sessionKeySigner, userOp))
            return VALIDATION_FAILED;
        SessionData memory sd = sessionData[sessionKeySigner][msg.sender];

        //disable SessionKey
        //disable is run because the SessioneKey is only valid for one operation
        //once used it should be disabled
        disableSessionKey(sessionKeySigner);

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
        if (initialized[msg.sender] == true)
            revert ERC20SKV_ModuleAlreadyInstalled();
        initialized[msg.sender] = true;
        emit ERC20SKV_ModuleInstalled(msg.sender);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function onUninstall(bytes calldata data) external override {
        if (initialized[msg.sender] == false)
            revert ERC20SKV_ModuleNotInstalled();
        address[] memory sessionKeys = getAssociatedSessionKeys();
        uint256 sessionKeysLength = sessionKeys.length;
        for (uint256 i; i < sessionKeysLength; i++) {
            delete sessionData[sessionKeys[i]][msg.sender];
        }
        delete walletSessionKeys[msg.sender];
        initialized[msg.sender] = false;
        emit ERC20SKV_ModuleUninstalled(msg.sender);
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
        return initialized[smartAccount];
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   INTERNAL                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function _digest(
        bytes calldata _data
    )
        internal
        pure
        returns (bytes4 selector, address from, address to, uint256 amount)
    {
        selector = bytes4(_data[0:4]);
        if (
            selector == IERC20.approve.selector ||
            selector == IERC20.transfer.selector
        ) {
            to = address(bytes20(_data[16:36]));
            amount = uint256(bytes32(_data[36:68]));
            return (selector, address(0), to, amount);
        } else if (selector == IERC20.transferFrom.selector) {
            from = address(bytes20(_data[16:36]));
            to = address(bytes20(_data[48:68]));
            amount = uint256(bytes32(_data[68:100]));
            return (selector, from, to, amount);
        } else {
            return (bytes4(0), address(0), address(0), 0);
        }
    }
}
