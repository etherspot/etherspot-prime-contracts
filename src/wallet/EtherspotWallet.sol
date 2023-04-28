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
import "../helpers/UniversalSignatureValidator.sol";
import "../access/AccessController.sol";

contract EtherspotWallet is
    BaseAccount,
    UUPSUpgradeable,
    Initializable,
    TokenCallbackHandler,
    UniversalSigValidator,
    AccessController
{
    using ECDSA for bytes32;

    IEntryPoint private _entryPoint;

    event EtherspotWalletInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );
    event EtherspotWalletReceived(address indexed from, uint256 indexed amount);
    event EntryPointChanged(address oldEntryPoint, address newEntryPoint);

    constructor() {
        _disableInitializers();
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    receive() external payable {
        emit EtherspotWalletReceived(msg.sender, msg.value);
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
        bytes[] calldata func
    ) external onlyOwnerOrEntryPoint(address(entryPoint())) {
        require(
            dest.length == func.length,
            "EtherspotWallet:: executeBatch: wrong array lengths"
        );
        for (uint256 i = 0; i < dest.length; i++) {
            _call(dest[i], 0, func[i]);
        }
    }

    function initialize(
        IEntryPoint anEntryPoint,
        address anOwner
    ) public virtual initializer {
        _initialize(anEntryPoint, anOwner);
    }

    function _initialize(
        IEntryPoint anEntryPoint,
        address anOwner
    ) internal virtual {
        _entryPoint = anEntryPoint;
        _addOwner(anOwner);
        emit EtherspotWalletInitialized(_entryPoint, anOwner);
    }

    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (!isOwner(hash.recover(userOp.signature)))
            return SIG_VALIDATION_FAILED;
        return 0;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
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
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) public onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function updateEntryPoint(address _newEntryPoint) external onlyOwner {
        require(
            _newEntryPoint != address(0),
            "EtherspotWallet:: EntryPoint address cannot be zero"
        );
        emit EntryPointChanged(address(_entryPoint), _newEntryPoint);
        _entryPoint = IEntryPoint(payable(_newEntryPoint));
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override onlyOwner {
        (newImplementation);
    }
}
