// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {EtherspotWallet7579Base} from "./EtherspotWallet7579Base.sol";
import {IValidator} from "@ERC7579/src/interfaces/IModule.sol";
import {AccessController} from "../access/AccessController.sol";
import {ArrayLib} from "../libraries/ArrayLib.sol";

contract EtherspotWallet7579 is AccessController, EtherspotWallet7579Base {
    function execute(
        address target,
        uint256 value,
        bytes calldata callData
    ) external payable virtual override returns (bytes memory result) {
        // only allow ERC-4337 EntryPoint OR self OR owner (Ownable)
        if (
            !(msg.sender == entryPoint() ||
                msg.sender == address(this) ||
                isOwner(msg.sender))
        ) {
            revert AccountAccessUnauthorized();
        }
        result = _execute(target, value, callData);
    }

    function initializeAccount(bytes calldata data) public virtual override {
        (address owner, , ) = abi.decode(data, (address, address, bytes));
        _addOwner(owner);
        super.initializeAccount(data);
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        payable
        virtual
        override
        payPrefund(missingAccountFunds)
        returns (uint256 validSignature)
    {
        address validator;
        uint256 nonce = userOp.nonce;
        assembly {
            validator := shr(96, nonce)
        }

        // check if validator is enabled
        if (!isValidatorInstalled(validator)) return 0;
        validSignature = IValidator(validator).validateUserOp(
            userOp,
            userOpHash
        );
    }

    function isValidSignature(
        bytes32 hash,
        bytes calldata data
    ) external view virtual override returns (bytes4) {
        return _isValidSignature(hash, data);
    }

    function _isValidSignature(
        bytes32 hash,
        bytes calldata data
    ) internal view returns (bytes4) {
        address validator = address(bytes20(data[0:20]));
        if (!isValidatorInstalled(validator)) revert InvalidModule(validator);
        return
            IValidator(validator).isValidSignatureWithSender(
                msg.sender,
                hash,
                data[20:]
            );
    }
}
