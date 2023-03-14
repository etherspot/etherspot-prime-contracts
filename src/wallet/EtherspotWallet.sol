// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../aa-4337/core/BaseAccount.sol";
import "./helpers/WalletCompatability.sol";

contract EtherspotWallet is
    BaseAccount,
    WalletCompatability,
    UUPSUpgradeable,
    Initializable
{
    using ECDSA for bytes32;

    IEntryPoint private _entryPoint;

    bytes28 private _filler;
    uint96 private _nonce;
    address public owner;

    event EtherspotWalletInitialized(
        IEntryPoint indexed entryPoint,
        address indexed registry,
        address indexed owner
    );
    event EntryPointChanged(address oldEntryPoint, address newEntryPoint);
    event RegistryChanged(address oldRegistry, address newRegistry);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    /// @inheritdoc BaseAccount
    function nonce() public view virtual override returns (uint256) {
        return _nonce;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(
            msg.sender == owner || msg.sender == address(this),
            "EtherspotWallet:: only owner"
        );
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        _requireFromEntryPointOrOwner();
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func)
        external
    {
        _requireFromEntryPointOrOwner();
        require(
            dest.length == func.length,
            "EtherspotWallet:: executeBatch: wrong array lengths"
        );
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of SimpleAccount must be deployed with the new EntryPoint address, then upgrading
     * the implementation by calling `upgradeTo()`
     */
    function initialize(
        IEntryPoint anEntryPoint,
        address anRegistry,
        address anOwner
    ) public virtual initializer {
        _initialize(anEntryPoint, anRegistry, anOwner);
    }

    function _initialize(
        IEntryPoint anEntryPoint,
        address anRegistry,
        address anOwner
    ) internal virtual {
        _entryPoint = anEntryPoint;
        _registry = anRegistry;
        owner = anOwner;
        emit EtherspotWalletInitialized(_entryPoint, _registry, owner);
    }

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        require(
            msg.sender == address(entryPoint()) || msg.sender == owner,
            "EtherspotWallet:: not Owner or EntryPoint"
        );
    }

    /// implement template method of BaseAccount
    function _validateAndUpdateNonce(UserOperation calldata userOp)
        internal
        override
    {
        require(_nonce++ == userOp.nonce, "EtherspotWallet:: invalid nonce");
    }

    /// implement template method of BaseAccount
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (owner != hash.recover(userOp.signature))
            return SIG_VALIDATION_FAILED;
        return 0;
    }

    function _call(
        address target,
        uint256 value,
        bytes memory data
    ) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount)
        public
        onlyOwner
    {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function updateEntryPoint(address _newEntryPoint) external {
        _onlyOwner();

        require(
            _newEntryPoint != address(0),
            "EtherspotWallet:: EntryPoint address cannot be zero"
        );
        emit EntryPointChanged(address(_entryPoint), _newEntryPoint);
        _entryPoint = IEntryPoint(payable(_newEntryPoint));
    }

    function updateRegistry(address _newRegistry) external {
        _onlyOwner();

        require(
            _newRegistry != address(0),
            "EtherspotWallet:: Registry address cannot be zero"
        );
        emit RegistryChanged(_registry, _newRegistry);
        _registry = _newRegistry;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        (newImplementation);
        _onlyOwner();
    }
}
