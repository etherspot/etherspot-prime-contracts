// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable reason-string */

import "../aa-4337/core/BasePaymaster.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Whitelist} from "./Whitelist.sol";

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

    uint256 private constant VALID_TIMESTAMP_OFFSET = 20;
    uint256 private constant SIGNATURE_OFFSET = 84;

    mapping(address => uint256) public sponsorFunds;
    mapping(address => uint256) public senderNonce;

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

    function _pack(UserOperation calldata userOp)
        internal
        pure
        returns (bytes memory ret)
    {
        // lighter signature scheme. must match UserOp.ts#packUserOp
        bytes calldata pnd = userOp.paymasterAndData;
        // copy directly the userOp from calldata up to (but not including) the paymasterAndData.
        // this encoding depends on the ABI encoding of calldata, but is much lighter to copy
        // than referencing each field separately.
        assembly {
            let ofs := userOp
            let len := sub(sub(pnd.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
    }

    /**
     * return the hash we're going to sign off-chain (and validate on-chain)
     * this method is called by the off-chain service, to sign the request.
     * it is called on-chain from the validatePaymasterUserOp, to validate the signature.
     * note that this signature covers all fields of the UserOperation, except the "paymasterAndData",
     * which will carry the signature itself.
     */
    function getHash(
        UserOperation calldata userOp,
        uint48 validUntil,
        uint48 validAfter
    ) public view returns (bytes32) {
        //can't use userOp.hash(), since it contains also the paymasterAndData itself.

        return
            keccak256(
                abi.encode(
                    _pack(userOp),
                    block.chainid,
                    address(this),
                    senderNonce[userOp.getSender()],
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
        UserOperation calldata userOp,
        bytes32, /*userOpHash*/
        uint256 requiredPreFund
    ) internal override returns (bytes memory context, uint256 validationData) {
        (requiredPreFund);

        (
            uint48 validUntil,
            uint48 validAfter,
            bytes calldata signature
        ) = parsePaymasterAndData(userOp.paymasterAndData);
        //ECDSA library supports both 64 and 65-byte long signatures.
        // we only "require" it here so that the revert reason on invalid signature will be of "EtherspotPaymaster", and not "ECDSA"
        require(
            signature.length == 64 || signature.length == 65,
            "EtherspotPaymaster:: invalid signature length in paymasterAndData"
        );
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            getHash(userOp, validUntil, validAfter)
        );
        senderNonce[userOp.getSender()]++;

        // check for valid paymaster
        address sig = userOp.getSender();
        address sponsorSig = ECDSA.recover(hash, signature);

        //don't revert on signature failure: return SIG_VALIDATION_FAILED
        if (!_check(sponsorSig, sig)) {
            return ("", _packValidationData(true, validUntil, validAfter));
        }

        // check sponsor has enough funds deposited to pay for gas
        require(
            checkSponsorFunds(sponsorSig) >= requiredPreFund,
            "EtherspotPaymaster:: Sponsor paymaster funds too low"
        );

        // TODO: how do we debit from deposited funds for specified sponsor

        //no need for other on-chain validation: entire UserOp should have been checked
        // by the external service prior to signing it.
        return (
            abi.encode(sponsorSig, sig, userOp),
            _packValidationData(false, validUntil, validAfter)
        );
    }

    function parsePaymasterAndData(bytes calldata paymasterAndData)
        public
        pure
        returns (
            uint48 validUntil,
            uint48 validAfter,
            bytes calldata signature
        )
    {
        (validUntil, validAfter) = abi.decode(
            paymasterAndData[VALID_TIMESTAMP_OFFSET:SIGNATURE_OFFSET],
            (uint48, uint48)
        );
        signature = paymasterAndData[SIGNATURE_OFFSET:];
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
