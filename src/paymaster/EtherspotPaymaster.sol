// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/* solhint-disable reason-string */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "../../account-abstraction/contracts/core/UserOperationLib.sol";
import "../../account-abstraction/contracts/core/Helpers.sol";
import "./BasePaymaster.sol";
import "./Whitelist.sol";

/**
 * A sample paymaster that uses external service to decide whether to pay for the UserOp.
 * The paymaster trusts an external signer to sign the transaction.
 * The calling user must pass the UserOp to that external signer first, which performs
 * whatever off-chain verification before signing the UserOp.
 * Note that this signature is NOT a replacement for wallet signature:
 * - the paymaster signs to agree to PAY for GAS.
 * - the wallet signs to prove identity and account ownership.
 */
contract EtherspotPaymaster is BasePaymaster, Whitelist, ReentrancyGuard {
    using UserOperationLib for PackedUserOperation;

    uint256 private constant VALID_TIMESTAMP_OFFSET = PAYMASTER_DATA_OFFSET;
    uint256 private constant SIGNATURE_OFFSET = VALID_TIMESTAMP_OFFSET + 64;
    // calculated cost of the postOp
    uint256 private constant COST_OF_POST = 40000;

    mapping(address => uint256) private _sponsorBalances;

    event SponsorSuccessful(address paymaster, address sender);

    constructor(IEntryPoint _entryPoint) BasePaymaster(_entryPoint) {}

    function depositFunds() external payable nonReentrant {
        _creditSponsor(msg.sender, msg.value);
        entryPoint.depositTo{value: msg.value}(address(this));
    }

    function withdrawFunds(uint256 _amount) external nonReentrant {
        require(
            getSponsorBalance(msg.sender) >= _amount,
            "EtherspotPaymaster:: not enough deposited funds"
        );
        _debitSponsor(msg.sender, _amount);
        entryPoint.withdrawTo(payable(msg.sender), _amount);
    }

    function getSponsorBalance(address _sponsor) public view returns (uint256) {
        return _sponsorBalances[_sponsor];
    }

    function _debitSponsor(address _sponsor, uint256 _amount) internal {
        _sponsorBalances[_sponsor] -= _amount;
    }

    function _creditSponsor(address _sponsor, uint256 _amount) internal {
        _sponsorBalances[_sponsor] += _amount;
    }


        /**
     * return the hash we're going to sign off-chain (and validate on-chain)
     * this method is called by the off-chain service, to sign the request.
     * it is called on-chain from the validatePaymasterUserOp, to validate the signature.
     * note that this signature covers all fields of the UserOperation, except the "paymasterAndData",
     * which will carry the signature itself.
     */
    function getHash(PackedUserOperation calldata userOp, uint48 validUntil, uint48 validAfter)
    public view returns (bytes32) {
        //can't use userOp.hash(), since it contains also the paymasterAndData itself.
        address sender = userOp.getSender();
        return
            keccak256(
            abi.encode(
                sender,
                userOp.nonce,
                keccak256(userOp.initCode),
                keccak256(userOp.callData),
                userOp.accountGasLimits,
                uint256(bytes32(userOp.paymasterAndData[PAYMASTER_VALIDATION_GAS_OFFSET : PAYMASTER_DATA_OFFSET])),
                userOp.preVerificationGas,
                userOp.gasFees,
                block.chainid,
                address(this),
                validUntil,
                validAfter
            )
        );
    }
    
    /**
     * verify our external signer signed this request.
     * the "paymasterAndData" is expected to be the paymaster and a signature over the entire request params
     * paymasterAndData[:20] : address(this)
     * paymasterAndData[20:84] : abi.encode(validUntil, validAfter)
     * paymasterAndData[84:] : signature
     */
    function _validatePaymasterUserOp(
        PackedUserOperation calldata userOp,
        bytes32 /*userOpHash*/,
        uint256 requiredPreFund
    ) internal override returns (bytes memory context, uint256 validationData) {
        (requiredPreFund);

        (
            uint48 validUntil,
            uint48 validAfter,
            bytes calldata signature
        ) = parsePaymasterAndData(userOp.paymasterAndData);
        // ECDSA library supports both 64 and 65-byte long signatures.
        // we only "require" it here so that the revert reason on invalid signature will be of "EtherspotPaymaster", and not "ECDSA"
        require(
            signature.length == 64 || signature.length == 65,
            "EtherspotPaymaster:: invalid signature length in paymasterAndData"
        );
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(
            getHash(userOp, validUntil, validAfter)
        );
        address sig = userOp.getSender();

        // check for valid paymaster
        address sponsorSig = ECDSA.recover(hash, signature);

        // don't revert on signature failure: return SIG_VALIDATION_FAILED
        if (!_check(sponsorSig, sig)) {
            return ("", _packValidationData(true, validUntil, validAfter));
        }

        (, uint256 maxFeePerGas) = (uint128(bytes16(userOp.gasFees)), uint128(uint256(userOp.gasFees)));
        uint256 costOfPost = maxFeePerGas * COST_OF_POST;
        uint256 totalPreFund = requiredPreFund + costOfPost;

        // check sponsor has enough funds deposited to pay for gas
        require(
            getSponsorBalance(sponsorSig) >= totalPreFund,
            "EtherspotPaymaster:: Sponsor paymaster funds too low"
        );

        // debit requiredPreFund amount
        _debitSponsor(sponsorSig, totalPreFund);

        // no need for other on-chain validation: entire UserOp should have been checked
        // by the external service prior to signing it.
        return (
            abi.encode(sponsorSig, sig, totalPreFund, costOfPost),
            _packValidationData(false, validUntil, validAfter)
        );
    }

    function parsePaymasterAndData(bytes calldata paymasterAndData) public pure returns (uint48 validUntil, uint48 validAfter, bytes calldata signature) {
        (validUntil, validAfter) = abi.decode(paymasterAndData[VALID_TIMESTAMP_OFFSET :], (uint48, uint48));
        signature = paymasterAndData[SIGNATURE_OFFSET :];
    }

    function _postOp(
        PostOpMode,
        bytes calldata context,
        uint256 actualGasCost,
         uint256 actualUserOpFeePerGas
    ) internal override {
        (
            address paymaster,
            address sender,
            uint256 totalPrefund,
            uint256 costOfPost
        ) = abi.decode(context, (address, address, uint256, uint256));
        _creditSponsor(paymaster, totalPrefund - (actualGasCost + costOfPost));
        emit SponsorSuccessful(paymaster, sender);
    }
}
