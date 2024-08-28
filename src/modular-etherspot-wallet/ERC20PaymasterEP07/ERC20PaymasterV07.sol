// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IEntryPoint} from "../../../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {_packValidationData} from "../../../account-abstraction/contracts/core/Helpers.sol";
import {UserOperationLib} from "../../../account-abstraction/contracts/core/UserOperationLib.sol";
import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";

import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import {IOracle} from "./interfaces/oracles/IOracle.sol";
import {SafeTransferLib} from "./utils/SafeTransferLib.sol";
import {BaseERC20Paymaster} from "./base/BaseERC20Paymaster.sol";
import {IPaymaster} from "./interfaces/paymasters/IPaymasterV07.sol";

using UserOperationLib for PackedUserOperation;

/// @title ERC20PaymasterV07
/// @author Pimlico (https://github.com/pimlicolabs/erc20-paymaster/blob/main/src/ERC20PaymasterV06.sol)
/// @author Using Solady (https://github.com/vectorized/solady)
/// @notice An ERC-4337 Paymaster contract which is able to sponsor gas fees in exchange for ERC-20 tokens.
/// The contract refunds excess tokens. It also allows updating price configuration and withdrawing tokens by the contract owner.
/// The contract uses oracles to fetch the latest token prices.
/// The paymaster supports standard and up-rebasing ERC-20 tokens. It does not support down-rebasing and fee-on-transfer tokens.
/// @dev Inherits from BaseERC20Paymaster.
/// @custom:security-contact security@pimlico.io
contract ERC20Paymaster is BaseERC20Paymaster, IPaymaster {
    constructor(
        IERC20Metadata _token,
        address _entryPoint,
        IOracle _tokenOracle,
        IOracle _nativeAssetOracle,
        uint32 _stalenessThreshold,
        address _owner,
        uint32 _priceMarkupLimit,
        uint32 _priceMarkup,
        uint256 _refundPostOpCost,
        uint256 _refundPostOpCostWithGuarantor
    ) BaseERC20Paymaster(
        _token,
        _entryPoint,
        _tokenOracle,
        _nativeAssetOracle,
        _stalenessThreshold,
        _owner,
        _priceMarkupLimit,
        _priceMarkup,
        _refundPostOpCost,
        _refundPostOpCostWithGuarantor
    ) {}

    /// @inheritdoc IPaymaster
    function validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 maxCost
    ) external override returns (bytes memory context, uint256 validationData) {
        _requireFromEntryPoint();
        return _validatePaymasterUserOp(userOp, userOpHash, maxCost);
    }

    /// @inheritdoc IPaymaster
    function postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost,
        uint256 actualUserOpFeePerGas
    ) external override {
        _requireFromEntryPoint();
        _postOp(mode, context, actualGasCost, actualUserOpFeePerGas);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                ERC-4337 PAYMASTER FUNCTIONS                */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /**
     * Validate a user operation.
     * @param userOp     - The user operation.
     * @param userOpHash - The hash of the user operation.
     * @param maxCost    - The maximum cost of the user operation.
     */
    function _validatePaymasterUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost)
        internal
        returns (bytes memory context, uint256 validationResult)
    {
        (uint8 mode, bytes calldata paymasterConfig) = _parsePaymasterAndData(userOp.paymasterAndData);

        // valid modes are 0, 1, 2, 3
        if (mode >= 4) {
            revert PaymasterDataModeInvalid();
        }

        uint192 tokenPrice = getPrice();
        uint256 tokenAmount;
        {
            uint256 maxFeePerGas = UserOperationLib.unpackMaxFeePerGas(userOp);
            if (mode == 0 || mode == 1) {
                tokenAmount = (maxCost + (refundPostOpCost) * maxFeePerGas) * priceMarkup * tokenPrice
                    / (1e18 * PRICE_DENOMINATOR);
            } else {
                tokenAmount = (maxCost + (refundPostOpCostWithGuarantor) * maxFeePerGas) * priceMarkup * tokenPrice
                    / (1e18 * PRICE_DENOMINATOR);
            }
        }

        if (mode == 0) {
            SafeTransferLib.safeTransferFrom(address(token), userOp.sender, address(this), tokenAmount);
            context = abi.encodePacked(tokenAmount, tokenPrice, userOp.sender, userOpHash);
            validationResult = 0;
        } else if (mode == 1) {
            if (paymasterConfig.length != 32) {
                revert PaymasterDataLengthInvalid();
            }
            if (uint256(bytes32(paymasterConfig[0:32])) == 0) {
                revert TokenLimitZero();
            }
            if (tokenAmount > uint256(bytes32(paymasterConfig[0:32]))) {
                revert TokenAmountTooHigh();
            }
            SafeTransferLib.safeTransferFrom(address(token), userOp.sender, address(this), tokenAmount);
            context = abi.encodePacked(tokenAmount, tokenPrice, userOp.sender, userOpHash);
            validationResult = 0;
        } else if (mode == 2) {
            if (paymasterConfig.length < 32) {
                revert PaymasterDataLengthInvalid();
            }

            address guarantor = address(bytes20(paymasterConfig[0:20]));

            bool signatureValid = SignatureChecker.isValidSignatureNow(
                guarantor,
                getHash(userOp, uint48(bytes6(paymasterConfig[20:26])), uint48(bytes6(paymasterConfig[26:32])), 0),
                paymasterConfig[32:]
            );

            SafeTransferLib.safeTransferFrom(address(token), guarantor, address(this), tokenAmount);
            context = abi.encodePacked(tokenAmount, tokenPrice, userOp.sender, userOpHash, guarantor);
            validationResult = _packValidationData(
                !signatureValid, uint48(bytes6(paymasterConfig[20:26])), uint48(bytes6(paymasterConfig[26:32]))
            );
        } else {
            if (paymasterConfig.length < 64) {
                revert PaymasterDataLengthInvalid();
            }

            address guarantor = address(bytes20(paymasterConfig[32:52]));

            if (uint256(bytes32(paymasterConfig[0:32])) == 0) {
                revert TokenLimitZero();
            }
            if (tokenAmount > uint256(bytes32(paymasterConfig[0:32]))) {
                revert TokenAmountTooHigh();
            }

            bool signatureValid = SignatureChecker.isValidSignatureNow(
                guarantor,
                getHash(
                    userOp,
                    uint48(bytes6(paymasterConfig[52:58])),
                    uint48(bytes6(paymasterConfig[58:64])),
                    uint256(bytes32(paymasterConfig[0:32]))
                ),
                paymasterConfig[64:]
            );

            SafeTransferLib.safeTransferFrom(address(token), guarantor, address(this), tokenAmount);
            context = abi.encodePacked(tokenAmount, tokenPrice, userOp.sender, userOpHash, guarantor);
            validationResult = _packValidationData(
                !signatureValid, uint48(bytes6(paymasterConfig[52:58])), uint48(bytes6(paymasterConfig[58:64]))
            );
        }
    }

    /**
     * Post-operation handler.
     * (verified to be called only through the entryPoint)
     * @dev If subclass returns a non-empty context from validatePaymasterUserOp,
     *      it must also implement this method.
     * @param context       - The context value returned by validatePaymasterUserOp
     * @param actualGasCost - Actual gas used so far (without this postOp call).
     * @param actualUserOpFeePerGas - the gas price this UserOp pays. This value is based on the UserOp's maxFeePerGas
     *                        and maxPriorityFee (and basefee)
     *                        It is not the same as tx.gasprice, which is what the bundler pays.
     */
    function _postOp(PostOpMode, bytes calldata context, uint256 actualGasCost, uint256 actualUserOpFeePerGas)
        internal
    {
        uint256 prefundTokenAmount = uint256(bytes32(context[0:32]));
        uint192 tokenPrice = uint192(bytes24(context[32:56]));
        address sender = address(bytes20(context[56:76]));
        bytes32 userOpHash = bytes32(context[76:108]);

        if (context.length == 128) {
            // A guarantor is used
            uint256 actualTokenNeeded = (actualGasCost + refundPostOpCostWithGuarantor * actualUserOpFeePerGas)
                * priceMarkup * tokenPrice / (1e18 * PRICE_DENOMINATOR);
            address guarantor = address(bytes20(context[108:128]));

            bool success = SafeTransferLib.trySafeTransferFrom(address(token), sender, address(this), actualTokenNeeded);
            if (success) {
                // If the token transfer is successful, transfer the held tokens back to the guarantor
                SafeTransferLib.safeTransfer(address(token), guarantor, prefundTokenAmount);
                emit UserOperationSponsored(userOpHash, sender, guarantor, actualTokenNeeded, tokenPrice, false);
            } else {
                // If the token transfer fails, the guarantor is deemed responsible for the token payment
                SafeTransferLib.safeTransfer(address(token), guarantor, prefundTokenAmount - actualTokenNeeded);
                emit UserOperationSponsored(userOpHash, sender, guarantor, actualTokenNeeded, tokenPrice, true);
            }
        } else {
            uint256 actualTokenNeeded = (actualGasCost + refundPostOpCost * actualUserOpFeePerGas) * priceMarkup
                * tokenPrice / (1e18 * PRICE_DENOMINATOR);

            SafeTransferLib.safeTransfer(address(token), sender, prefundTokenAmount - actualTokenNeeded);
            emit UserOperationSponsored(userOpHash, sender, address(0), actualTokenNeeded, tokenPrice, false);
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      PUBLIC HELPERS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Hashes the user operation data.
    /// @param userOp The user operation data.
    /// @param validUntil The timestamp until which the user operation is valid.
    /// @param validAfter The timestamp after which the user operation is valid.
    /// @param tokenLimit The maximum amount of tokens allowed for the user operation. 0 if no limit.
    function getHash(PackedUserOperation calldata userOp, uint48 validUntil, uint48 validAfter, uint256 tokenLimit)
        public
        view
        returns (bytes32)
    {
        address sender = userOp.getSender();
        return keccak256(
            abi.encode(
                sender,
                userOp.nonce,
                keccak256(userOp.initCode),
                keccak256(userOp.callData),
                userOp.accountGasLimits,
                uint256(bytes32(userOp.paymasterAndData[PAYMASTER_VALIDATION_GAS_OFFSET:PAYMASTER_DATA_OFFSET])),
                userOp.preVerificationGas,
                userOp.gasFees,
                block.chainid,
                address(this),
                validUntil,
                validAfter,
                tokenLimit
            )
        );
    }
}
