// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../../account-abstraction/contracts/core/BaseAccount.sol";
import "../../account-abstraction/contracts/core/Helpers.sol";
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
    /// STORAGE
    IEntryPoint private immutable _entryPoint;
    IEtherspotWalletFactory private immutable _walletFactory;
    bytes4 private constant ERC1271_SUCCESS = 0x1626ba7e;
    string constant NAME = "EtherspotWallet";
    string constant VERSION = "0.2.0";

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

    /**
     * execute a sequence of transactions
     * @dev to reduce gas consumption for trivial case (no value), use a zero-length array to mean zero value
     * @param dest an array of destination addresses
     * @param value an array of values to pass to each call. can be zero-length for no-value calls
     * @param func an array of calldata to pass to each call
     */
    function executeBatch(
        address[] calldata dest,
        uint256[] calldata value,
        bytes[] calldata func
    ) external onlyOwnerOrEntryPoint(address(entryPoint())) {
        require(
            dest.length == func.length &&
                (value.length == 0 || value.length == func.length),
            "EtherspotWallet:: executeBatch: wrong array lengths"
        );
        if (value.length == 0) {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], 0, func[i]);
            }
        } else {
            for (uint256 i = 0; i < dest.length; i++) {
                _call(dest[i], value[i], func[i]);
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
        bytes32 domainSeparator = _domainSeparator();
        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hash)
        );
        bytes32 ethHash = MessageHashUtils.toEthSignedMessageHash(
            signedMessageHash
        );
        address owner = ECDSA.recover(ethHash, signature);
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
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        bytes32 hash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        if (!isOwner(ECDSA.recover(hash, userOp.signature)))
            return SIG_VALIDATION_FAILED;
        return SIG_VALIDATION_SUCCESS;
    }

    /// @dev EIP-712 compliant domain separator
    function _domainSeparator() internal view returns (bytes32) {
        bytes32 nameHash = keccak256(bytes(NAME));
        bytes32 versionHash = keccak256(bytes(VERSION));
        // Use proxy address for the EIP-712 domain separator.
        address proxyAddress = address(this);
        // Construct domain separator with name, version, chainId, and proxy address.
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    proxyAddress
                )
            );
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
