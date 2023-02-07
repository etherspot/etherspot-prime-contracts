// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable reason-string */

import "./core/BasePaymaster.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * A sample paymaster that uses external service to decide whether to pay for the UserOp.
 * The paymaster trusts an external signer to sign the transaction.
 * The calling user must pass the UserOp to that external signer first, which performs
 * whatever off-chain verification before signing the UserOp.
 * Note that this signature is NOT a replacement for wallet signature:
 * - the paymaster signs to agree to PAY for GAS.
 * - the wallet signs to prove identity and account ownership.
 */
contract EtherspotPaymaster is BasePaymaster {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    using UserOperationLib for UserOperation;

    // struct Beneficiary {
    //     address beneficiary;
    //     address token;
    //     uint256 allowance;
    // }

    mapping(address => mapping(address => bool)) public whitelist;

    // mapping(address => Beneficiary) private paymasters;

    error EtherspotPaymaster_BeneficiaryCannotBeZeroAddress();
    error EtherspotPaymaster_InvalidBeneficiary();
    error EtherspotPaymaster_BalanceLessThanDeposit();
    error EtherspotPaymaster_WithdrawGreaterThanBalance();
    event AddedToWhitelist(address paymaster, address account);
    event RemovedFromWhitelist(address paymaster, address account);
    event AllowanceDeposited(
        address paymaster,
        address beneficiary,
        address token,
        uint256 amount
    );
    event AllowanceWithdrawn(
        address paymaster,
        address beneficiary,
        address token,
        uint256 amount
    );

    constructor(IEntryPoint _entryPoint) BasePaymaster(_entryPoint) {}

    function addToWhitelist(address _account) external {
        require(
            _account != address(0),
            "EtherspotPaymaster:: Account cannot be address(0)"
        );
        require(
            !whitelist[msg.sender][_account],
            "EtherspotPaymaster:: Account is already whitelisted"
        );
        whitelist[msg.sender][_account] = true;
        emit AddedToWhitelist(msg.sender, _account);
    }

    function removeFromWhitelist(address _account) external {
        require(
            _account != address(0),
            "EtherspotPaymaster:: Account cannot be address(0)"
        );
        require(
            whitelist[msg.sender][_account],
            "EtherspotPaymaster:: Account is not whitelisted"
        );
        whitelist[msg.sender][_account] = false;
        emit RemovedFromWhitelist(msg.sender, _account);
    }

    /**
     * return the hash we're going to sign off-chain (and validate on-chain)
     * this method is called by the off-chain service, to sign the request.
     * it is called on-chain from the validatePaymasterUserOp, to validate the signature.
     * note that this signature covers all fields of the UserOperation, except the "paymasterAndData",
     * which will carry the signature itself.
     */
    function getHash(UserOperation calldata userOp)
        public
        pure
        returns (bytes32)
    {
        //can't use userOp.hash(), since it contains also the paymasterAndData itself.
        return
            keccak256(
                abi.encode(
                    userOp.getSender(),
                    userOp.nonce,
                    keccak256(userOp.initCode),
                    keccak256(userOp.callData),
                    userOp.callGasLimit,
                    userOp.verificationGasLimit,
                    userOp.preVerificationGas,
                    userOp.maxFeePerGas,
                    userOp.maxPriorityFeePerGas
                )
            );
    }

    /**
     * verify our external signer signed this request.
     * the "paymasterAndData" is expected to be the paymaster and a signature over the entire request params
     */
    function validatePaymasterUserOp(
        UserOperation calldata userOp,
        bytes32, /*userOpHash*/
        uint256 requiredPreFund
    )
        external
        view
        override
        returns (bytes memory context, uint256 sigTimeRange)
    {
        (requiredPreFund);

        bytes32 hash = getHash(userOp);
        bytes calldata paymasterAndData = userOp.paymasterAndData;
        uint256 sigLength = paymasterAndData.length - 20;
        //ECDSA library supports both 64 and 65-byte long signatures.
        // we only "require" it here so that the revert reason on invalid signature will be of "VerifyingPaymaster", and not "ECDSA"
        require(
            sigLength == 64 || sigLength == 65,
            "VerifyingPaymaster: invalid signature length in paymasterAndData"
        );

        // check for valid paymaster
        address sig = userOp.getSender();
        address extSig = hash.toEthSignedMessageHash().recover(
            paymasterAndData[20:]
        );

        if (!whitelist[extSig][sig]) return ("", 1);

        //don't revert on signature failure: return SIG_VALIDATION_FAILED
        // if (
        //     verifyingSigner !=
        //     hash.toEthSignedMessageHash().recover(paymasterAndData[20:])
        // ) {
        //     return ("", 1);
        // }

        //no need for other on-chain validation: entire UserOp should have been checked
        // by the external service prior to signing it.
        return ("", 0);
    }
}
