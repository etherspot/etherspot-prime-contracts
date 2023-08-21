// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../../account-abstraction/contracts/core/BaseAccount.sol";
import "../../account-abstraction/contracts/samples/callback/TokenCallbackHandler.sol";
import "../interfaces/IEtherspotWallet.sol";
import "../interfaces/IEtherspotWalletFactory.sol";
import "../access/AccessController.sol";

contract EtherspotWallet is
    BaseAccount,
    UUPSUpgradeable,
    Initializable,
    TokenCallbackHandler,
    AccessController,
    IEtherspotWallet
{
    using ECDSA for bytes32;

    /// STORAGE
    IEntryPoint private immutable _entryPoint;
    IEtherspotWalletFactory private immutable _walletFactory;
    bytes4 private constant ERC1271_SUCCESS = 0x1626ba7e;

    /// EXTERNAL METHODS
    constructor(
        IEntryPoint anEntryPoint,
        IEtherspotWalletFactory anWalletFactory
    ) {
        require(
            address(anEntryPoint) != address(0) &&
                address(anWalletFactory) != address(0),
            "EtherspotWallet:: invalid constructor parameter"
        );
        _entryPoint = anEntryPoint;
        _walletFactory = anWalletFactory;
        _disableInitializers();
        // solhint-disable-previous-line no-empty-blocks
    }

    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external onlyOwnerOrEntryPoint(address(entryPoint())) {
        _call(dest, value, func);
    }

    function executeBatch(
        address[] calldata dest,
        uint256[] calldata value,
        bytes[] calldata func
    ) external onlyOwnerOrEntryPoint(address(entryPoint())) {
        require(
            dest.length > 0 &&
                dest.length == value.length &&
                value.length == func.length,
            "EtherspotWallet:: executeBatch: wrong array lengths"
        );
        for (uint256 i; i < dest.length; ) {
            _call(dest[i], value[i], func[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * Implementation of ISignatureValidator
     * @dev doesn't allow the owner to be a smart contract, SCW should use {isValidSig}
     * @param hash 32 bytes hash of the data signed on the behalf of address(msg.sender)
     * @param signature Signature byte array associated with _dataHash
     * @return ERC1271 magic value.
     */
    function isValidSignature(
        bytes32 hash,
        bytes calldata signature
    ) external view returns (bytes4) {
        address owner = ECDSA.recover(hash, signature);
        if (isOwner(owner)) {
            return ERC1271_SUCCESS;
        }
        return bytes4(0xffffffff);
    }

    receive() external payable {
        emit EtherspotWalletReceived(msg.sender, msg.value);
    }

    /// PUBLIC

    /// @inheritdoc BaseAccount
    function entryPoint()
        public
        view
        virtual
        override(BaseAccount, IEtherspotWallet)
        returns (IEntryPoint)
    {
        return _entryPoint;
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    function initialize(address anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() external payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) external onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    /// INTERNAL

    function _initialize(address anOwner) internal virtual {
        _addOwner(anOwner);
        emit EtherspotWalletInitialized(_entryPoint, anOwner);
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (!isOwner(hash.recover(userOp.signature)))
            return SIG_VALIDATION_FAILED;
        return 0;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override onlyOwner {
        require(
            _walletFactory.checkImplementation(newImplementation),
            "EtherspotWallet:: upgrade implementation invalid"
        );
    }
}
