// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable reason-string */

import "./core/BasePaymaster.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Whitelist} from "./Whitelist.sol";

import "hardhat/console.sol";

/**
 * A sample paymaster that uses external service to decide whether to pay for the UserOp.
 * The paymaster trusts an external signer to sign the transaction.
 * The calling user must pass the UserOp to that external signer first, which performs
 * whatever off-chain verification before signing the UserOp.
 * Note that this signature is NOT a replacement for wallet signature:
 * - the paymaster signs to agree to PAY for GAS.
 * - the wallet signs to prove identity and account ownership.
 */
contract EtherspotPaymaster is BasePaymaster, Whitelist {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    using UserOperationLib for UserOperation;

    mapping(address => uint256) public sponsorFunds;

    event SponsorSuccessful(
        address paymaster,
        address sender,
        bytes userOpHash
    );
    event SponsorUnsuccessful(
        address paymaster,
        address sender,
        bytes userOpHash
    );

    constructor(IEntryPoint _entryPoint) BasePaymaster(_entryPoint) {}

    function depositFunds() public payable {
        require(
            msg.sender.balance >= msg.value,
            "EtherspotPaymaster:: Not enough balance"
        );
        entryPoint.depositTo{value: msg.value}(address(this));
        sponsorFunds[msg.sender] += msg.value;
    }

    function checkSponsorFunds(address _sponsor) public view returns (uint256) {
        return sponsorFunds[_sponsor];
    }

    function _debitSponsor(address _sponsor, uint256 _amount) internal {
        sponsorFunds[_sponsor] -= _amount;
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
            "EtherspotPaymaster: invalid signature length in paymasterAndData"
        );

        // check for valid paymaster
        address sig = userOp.getSender();
        address extSig = hash.toEthSignedMessageHash().recover(
            paymasterAndData[20:]
        );

        //don't revert on signature failure: return SIG_VALIDATION_FAILED
        if (!_check(extSig, sig)) {
            return ("", 1);
        }

        // check sponsor has enough funds deposited to pay for gas
        require(
            checkSponsorFunds(extSig) >= requiredPreFund,
            "EtherspotPaymaster:: Sponsor paymaster funds too low"
        );

        // TODO: how do we debit from deposited funds for specified sponsor

        //no need for other on-chain validation: entire UserOp should have been checked
        // by the external service prior to signing it.
        return (abi.encode(extSig, sig, userOp), 0);
    }

    function _postOp(
        PostOpMode mode,
        bytes calldata context,
        uint256 actualGasCost
    ) internal override {
        (address paymaster, address sender, bytes memory userOpHash) = abi
            .decode(context, (address, address, bytes));
        if (
            mode == IPaymaster.PostOpMode.opSucceeded ||
            mode == IPaymaster.PostOpMode.opReverted
        ) {
            _debitSponsor(paymaster, actualGasCost);
            emit SponsorSuccessful(paymaster, sender, userOpHash);
        } else {
            emit SponsorUnsuccessful(paymaster, sender, userOpHash);
        }
    }
}
