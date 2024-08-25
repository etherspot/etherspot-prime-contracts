// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAggregatorV3Interface} from "../../interfaces/IAggregatorV3Interface.sol";
import {IERC20SessionKeyValidator} from "../../interfaces/IERC20SessionKeyValidator.sol";
import {ArrayLib} from "../../libraries/ArrayLib.sol";
import {ECDSA} from "solady/src/utils/ECDSA.sol";
import {IERC20} from "../../interfaces/IERC20.sol";
import {PackedUserOperation} from "../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../erc7579-ref-impl/interfaces/IERC7579Account.sol";
import {MODULE_TYPE_VALIDATOR, VALIDATION_FAILED, VALIDATION_SUCCESS} from "../../erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../../../account-abstraction/contracts/core/Helpers.sol";
import "../../erc7579-ref-impl/libs/ModeLib.sol";
import "../../erc7579-ref-impl/libs/ExecutionLib.sol";
import {IMultiTokenSessionKeyValidator} from "../../interfaces/IMultiTokenSessionKeyValidator.sol";
import {ArrayLib} from "../../libraries/ArrayLib.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";


contract MultiTokenSessionKeyValidator is IMultiTokenSessionKeyValidator, Ownable {
    using ModeLib for ModeCode;
    using ExecutionLib for bytes;
    using ArrayLib for address[];
    using EnumerableSet for EnumerableSet.AddressSet;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                  CONSTANTS                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    string constant NAME = "MultiTokenSessionKeyValidator";
    string constant VERSION = "1.0.0";

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    ERRORS                 */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    error MTSKV_ModuleAlreadyInstalled();
    error MTSKV_ModuleNotInstalled();
    error MTSKV_InvalidSessionKey();
    error MTSKV_InvalidToken();
    error MTSKV_InvalidFunctionSelector();
    error MTSKV_InvalidSpendingLimit();
    error MTSKV_InvalidValidAfter(uint48 validAfter);
    error MTSKV_InvalidValidUntil(uint48 validUntil);
    error MTSKV_SessionKeyAlreadyExists(address sessionKey);
    error MTSKV_SessionKeyDoesNotExist(address session);
    error MTSKV_SessionPaused(address sessionKey);
    error NotImplemented();

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   MAPPINGS                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    mapping(address => bool) public initialized;

    mapping(address => mapping(address => MultiTokenSessionData)) public multiTokenSessionData;
    
    mapping(address wallet => address[] assocSessionKeys) public walletSessionKeys;
    
    // session-key to tokenAddress to spentAmount
    mapping(address => mapping(address => uint256)) public spentAmounts;

    EnumerableSet.AddressSet private allowedTokens;
    
    mapping(address token => IAggregatorV3Interface) internal priceFeeds;

    constructor(address[] memory tokens, address[] memory _priceFeeds) Ownable(msg.sender) {
        _addAllowedTokens(tokens, _priceFeeds);
    }

    function addAllowedTokens(address[] memory _tokens, address[] memory _priceFeeds) external onlyOwner {
        _addAllowedTokens(_tokens, _priceFeeds);
    }

    function _addAllowedTokens(address[] memory _tokens, address[] memory _priceFeeds) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedTokens.add(_tokens[i]);
            priceFeeds[_tokens[i]] = IAggregatorV3Interface(_priceFeeds[i]);
        }
    }

    function removeAllowedTokens(address[] memory _tokens) external onlyOwner {
        _removeAllowedTokens(_tokens);
    }

    function _removeAllowedTokens(address[] memory _tokens) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedTokens.remove(_tokens[i]);
            delete priceFeeds[_tokens[i]];
        }
    }

    function updatePriceFeeds(address[] memory _tokens, address[] memory _priceFeeds) external onlyOwner {
        _updatePriceFeeds(_tokens, _priceFeeds);
    }

    function _updatePriceFeeds(address[] memory _tokens, address[] memory _priceFeeds) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            priceFeeds[_tokens[i]] = IAggregatorV3Interface(_priceFeeds[i]);
        }
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*               PUBLIC/EXTERNAL             */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    // @inheritdoc IMultiTokenSessionKeyValidator
    function enableSessionKey(bytes calldata _sessionData) public {
        address sessionKey = address(bytes20(_sessionData[0:20]));
        if (sessionKey == address(0)) revert MTSKV_InvalidSessionKey();
        if (
            multiTokenSessionData[sessionKey][msg.sender].validUntil != 0 &&
            ArrayLib._contains(getAssociatedSessionKeys(), sessionKey)
        ) revert MTSKV_SessionKeyAlreadyExists(sessionKey);

        uint256 numTokens = uint256(uint8(_sessionData[20]));
        address[] memory tokens = new address[](numTokens);
        for (uint256 i = 0; i < numTokens; i++) {
            tokens[i] = address(bytes20(_sessionData[21 + i * 20:41 + i * 20]));
            if (tokens[i] == address(0)) revert MTSKV_InvalidToken();
        }

        bytes4 funcSelector = bytes4(_sessionData[21 + numTokens * 20:25 + numTokens * 20]);
        if (funcSelector == bytes4(0)) revert MTSKV_InvalidFunctionSelector();

        uint256 cumulativeSpendingLimitUSD = uint256(bytes32(_sessionData[25 + numTokens * 20:57 + numTokens * 20]));
        if (cumulativeSpendingLimitUSD == 0) revert MTSKV_InvalidSpendingLimit();

        uint48 validAfter = uint48(bytes6(_sessionData[57 + numTokens * 20:63 + numTokens * 20]));
        if (validAfter == 0) revert MTSKV_InvalidValidAfter(validAfter);

        uint48 validUntil = uint48(bytes6(_sessionData[63 + numTokens * 20:69 + numTokens * 20]));
        if (validUntil == 0) revert MTSKV_InvalidValidUntil(validUntil);

        multiTokenSessionData[sessionKey][msg.sender] = MultiTokenSessionData(
            tokens,
            funcSelector,
            cumulativeSpendingLimitUSD,
            validAfter,
            validUntil,
            true
        );
        walletSessionKeys[msg.sender].push(sessionKey);
        emit MTSKV_SessionKeyEnabled(sessionKey, msg.sender);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function disableSessionKey(address _session) public {
        if (multiTokenSessionData[_session][msg.sender].validUntil == 0)
            revert MTSKV_SessionKeyDoesNotExist(_session);
        delete multiTokenSessionData[_session][msg.sender];
        walletSessionKeys[msg.sender] = ArrayLib._removeElement(
            getAssociatedSessionKeys(),
            _session
        );
        emit MTSKV_SessionKeyDisabled(_session, msg.sender);
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
        MultiTokenSessionData storage sd = multiTokenSessionData[_sessionKey][msg.sender];
        if (sd.validUntil == 0)
            revert MTSKV_SessionKeyDoesNotExist(_sessionKey);
        if (sd.live) {
            sd.live = false;
            emit MTSKV_SessionKeyPaused(_sessionKey, msg.sender);
        } else {
            sd.live = true;
            emit MTSKV_SessionKeyUnpaused(_sessionKey, msg.sender);
        }
    }

    function isSessionKeyLive(address _sessionKey) public view returns (bool) {
        MultiTokenSessionData storage data = multiTokenSessionData[_sessionKey][msg.sender];
        return (data.validAfter <= block.timestamp && data.validUntil >= block.timestamp);
    }


    function validateSessionKeyParams(
        address _sessionKey,
        PackedUserOperation calldata _userOp
    ) public view returns (bool) {
        MultiTokenSessionData storage sd = multiTokenSessionData[_sessionKey][msg.sender];

        // Check if the session key is live
        if (!isSessionKeyLive(_sessionKey)) {
            return false;
        }

        bytes calldata callData = _userOp.callData;
        bytes4 sel = bytes4(callData[:4]);

        // Validate function selector (e.g., execute function)
        if (sel == IERC7579Account.execute.selector) {
            ModeCode mode = ModeCode.wrap(bytes32(callData[4:36]));
            (CallType calltype, , , ) = ModeLib.decode(mode);

            if (calltype == CALLTYPE_SINGLE) {
                return _validateSingleCall(_sessionKey, sd, callData);
            }

            if (calltype == CALLTYPE_BATCH) {
                return _validateBatchCall(_sessionKey, sd, callData);
            }
        }
        return false;
    }

    function _validateSingleCall(
        address _sessionKey,
        MultiTokenSessionData storage _mtsd,
        bytes calldata _callData
    ) internal view returns (bool) {
        (, , bytes calldata execData) = ExecutionLib.decodeSingle(_callData[100:]);

        (bytes4 selector, address target, , uint256 amount) = _digest(execData);

        if (!ArrayLib._contains(_mtsd.tokens, target)) {
            return false;
        }

        if (selector != _mtsd.funcSelector) {
            return false;
        }

        if (!checkSpendingLimit(_sessionKey, msg.sender, target, amount)) {
            return false;
        }

        return true;
    }

    function _validateBatchCall(
        address _sessionKey,
        MultiTokenSessionData storage _mtsd,
        bytes calldata _callData
    ) internal view returns (bool) {
        Execution[] calldata execs = ExecutionLib.decodeBatch(_callData[100:]);

        for (uint256 i; i < execs.length; i++) {
            (bytes4 selector, address target, , uint256 amount) = _digest(execs[i].callData);

            if (!ArrayLib._contains(_mtsd.tokens, target)) {
                return false;
            }

            if (selector != _mtsd.funcSelector) {
                return false;
            }

            if (!checkSpendingLimit(_sessionKey, msg.sender, target, amount)) {
                return false;
            }
        }

        return true;
    }

    // @inheritdoc IMultiTokenSessionKeyValidator
    function getAssociatedSessionKeys() public view returns (address[] memory) {
        return walletSessionKeys[msg.sender];
    }

    // @inheritdoc IMultiTokenSessionKeyValidator
    function getSessionKeyData(
        address _sessionKey
    ) public view returns (MultiTokenSessionData memory) {
        return multiTokenSessionData[_sessionKey][msg.sender];
    }

    // @inheritdoc IERC20SessionKeyValidator
    function validateUserOp(
    PackedUserOperation calldata userOp,
    bytes32 userOpHash
    ) external override returns (uint256) {
        // Recover the session key signer from the signature
        address sessionKeySigner = ECDSA.recover(
            ECDSA.toEthSignedMessageHash(userOpHash),
            userOp.signature
        );

        // Validate the session key parameters
        if (!validateSessionKeyParams(sessionKeySigner, userOp)) {
            return VALIDATION_FAILED;
        }

        // Fetch session data to return validation data
        MultiTokenSessionData storage sd = multiTokenSessionData[sessionKeySigner][msg.sender];
        
        // Return validation data with expiration info
        return _packValidationData(false, sd.validUntil, sd.validAfter);
    }


    // @inheritdoc IERC20SessionKeyValidator
    function isModuleType(
        uint256 moduleTypeId
    ) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    // @inheritdoc IERC20SessionKeyValidator
    function onInstall(bytes calldata) external override {
        if (initialized[msg.sender] == true)
            revert MTSKV_ModuleAlreadyInstalled();
        initialized[msg.sender] = true;
        emit MTSKV_ModuleInstalled(msg.sender);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function onUninstall(bytes calldata) external override {
        if (initialized[msg.sender] == false)
            revert MTSKV_ModuleNotInstalled();
        address[] memory sessionKeys = getAssociatedSessionKeys();
        uint256 sessionKeysLength = sessionKeys.length;
        for (uint256 i; i < sessionKeysLength; i++) {
            delete multiTokenSessionData[sessionKeys[i]][msg.sender];
        }
        delete walletSessionKeys[msg.sender];
        initialized[msg.sender] = false;
        emit MTSKV_ModuleUninstalled(msg.sender);
    }

    // @inheritdoc IERC20SessionKeyValidator
    function isValidSignatureWithSender(
        address,
        bytes32,
        bytes memory
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


    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   VIEW                    */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function getTokenPriceUSD(address token) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeeds[token].latestRoundData();
        require(price > 0, "Invalid price from oracle");
        return uint256(price);
    }

    function getTokenDecimals(address token) internal view returns (uint8) {
        return IERC20(token).decimals();
    }

    function checkSpendingLimit(address sessionKey, address user, address token, uint256 amount) public view returns (bool) {
        MultiTokenSessionData storage data = multiTokenSessionData[sessionKey][user];
        uint256 tokenPriceUSD = getTokenPriceUSD(token);
        uint8 tokenDecimals = getTokenDecimals(token);
        uint256 amountInUSD = (amount * tokenPriceUSD) / (10 ** tokenDecimals);
        uint256 totalSpentUSD = 0;

        for (uint256 i = 0; i < data.tokens.length; i++) {
            address currentToken = data.tokens[i];
            uint256 spentAmount = spentAmounts[sessionKey][currentToken];
            uint256 currentTokenPriceUSD = getTokenPriceUSD(currentToken);
            uint8 currentTokenDecimals = getTokenDecimals(currentToken);
            totalSpentUSD += (spentAmount * currentTokenPriceUSD) / (10 ** currentTokenDecimals);
        }

        return (totalSpentUSD + amountInUSD) <= data.spendingLimit;
    }

}