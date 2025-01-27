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
    
    uint8 constant public USD_AMOUNT_DECIMALS = 18;

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
    error MTSKV_InvalidTokenPrice(address token);
    error MTSKV_InvalidStalenessThreshold();
    error MTSKV_StaleTokenPrice(address token);

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   MAPPINGS                */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    
    mapping(address => bool) public initialized;

    mapping(address sessionKey => mapping(address wallet => MultiTokenSessionData)) public multiTokenSessionData;
    
    mapping(address wallet => address[] assocSessionKeys) public walletSessionKeys;
    
    EnumerableSet.AddressSet private allowedTokens;
    
    mapping(address token => IAggregatorV3Interface) internal priceFeeds;

    mapping(address sessionKey => uint256) public totalSpentInUsd;

    uint256 public stalenessThresholdInSeconds;

    constructor(address[] memory tokens, address[] memory _priceFeeds, uint256 _stalenessThresholdInSeconds) Ownable(msg.sender) {
        _addAllowedTokens(tokens, _priceFeeds);

        if(_stalenessThresholdInSeconds == 0) {
            revert MTSKV_InvalidStalenessThreshold();
        }
        stalenessThresholdInSeconds = _stalenessThresholdInSeconds;
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

        uint256 cumulativeSpendingLimitInUsd = uint256(bytes32(_sessionData[25 + numTokens * 20:57 + numTokens * 20]));
        if (cumulativeSpendingLimitInUsd == 0) revert MTSKV_InvalidSpendingLimit();

        uint48 validAfter = uint48(bytes6(_sessionData[57 + numTokens * 20:63 + numTokens * 20]));
        if (validAfter == 0) revert MTSKV_InvalidValidAfter(validAfter);

        uint48 validUntil = uint48(bytes6(_sessionData[63 + numTokens * 20:69 + numTokens * 20]));
        if (validUntil == 0) revert MTSKV_InvalidValidUntil(validUntil);

        multiTokenSessionData[sessionKey][msg.sender] = MultiTokenSessionData(
            tokens,
            funcSelector,
            cumulativeSpendingLimitInUsd,
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

        return isEstimatedTotalUsdSpentWithInLimits(_sessionKey, msg.sender, target, amount);
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

            if (!isEstimatedTotalUsdSpentWithInLimits(_sessionKey, msg.sender, target, amount)) {
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

    function addAllowedTokens(address[] memory _tokens, address[] memory _priceFeeds) external onlyOwner {
        _addAllowedTokens(_tokens, _priceFeeds);
    }

    function removeAllowedTokens(address[] memory _tokens) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedTokens.remove(_tokens[i]);
            delete priceFeeds[_tokens[i]];
        }
    }

    function updatePriceFeeds(address[] memory _tokens, address[] memory _priceFeeds) external onlyOwner {
        for (uint256 i = 0; i < _tokens.length; i++) {
            priceFeeds[_tokens[i]] = IAggregatorV3Interface(_priceFeeds[i]);
        }
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

    function _addAllowedTokens(address[] memory _tokens, address[] memory _priceFeeds) internal {
        for (uint256 i = 0; i < _tokens.length; i++) {
            allowedTokens.add(_tokens[i]);
            priceFeeds[_tokens[i]] = IAggregatorV3Interface(_priceFeeds[i]);
        }
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   VIEW                    */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function getTokenPriceInUsd(address token) internal view returns (uint256, uint8) {

        (, int256 price, ,uint256 updatedAt, ) = priceFeeds[token].latestRoundData();

        if(price == 0) {
            revert MTSKV_InvalidTokenPrice(token);
        }

        if(block.timestamp - updatedAt >= stalenessThresholdInSeconds) {
            revert MTSKV_StaleTokenPrice(token);
        }

        uint8 feedDecimals = priceFeeds[token].decimals();

        return (uint256(price), feedDecimals);
    }

    // @inheritdoc IMultiTokenSessionKeyValidator
    /// @dev Estimates the total amount spent in USD for a given session key and token
    /// @dev token decimals and feed decimals are different and to derive the USD amount in a fixed precision of 18 decimals
    /// @dev scale the tokenPrice up or down by different to target precision and divide by 10 ** feedDecimals
    /// @dev amountInUsd will be in decimal precision of 18
    function estimateTotalSpentAmountInUsd(
        address sessionKey,
        address token,
        uint256 amount
    ) public view returns (uint256) {
        (uint256 tokenPriceUSD, uint8 feedDecimals) = getTokenPriceInUsd(token);

        uint8 tokenDecimals = IERC20(token).decimals();
        uint256 scaledAmount;

        if (tokenDecimals < USD_AMOUNT_DECIMALS) {
            // If token has fewer than 18 decimals, scale the amount up to 18 decimals
            scaledAmount = amount * (10 ** (USD_AMOUNT_DECIMALS - tokenDecimals));
        } else if(tokenDecimals > USD_AMOUNT_DECIMALS) {
            // If token has more than 18 decimals, scale the amount down to 18 decimals
            scaledAmount = amount / (10 ** (tokenDecimals - USD_AMOUNT_DECIMALS));            
        } else {
            scaledAmount = amount;
        }

        uint256 amountInUsd = (scaledAmount * tokenPriceUSD) / (10 ** feedDecimals);

        // add the amountInUsd with the totalSpentInUsd for the session key
        return amountInUsd + totalSpentInUsd[sessionKey];
    }


    function isEstimatedTotalUsdSpentWithInLimits(address sessionKey, address user, address token, uint256 amount) public view returns (bool) {
        MultiTokenSessionData memory data = multiTokenSessionData[sessionKey][user];
        return estimateTotalSpentAmountInUsd(sessionKey, token, amount) <= data.cumulativeSpendingLimitInUsd;
    }

}
