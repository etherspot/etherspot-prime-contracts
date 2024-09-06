// TODO: WIP

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {ModularEtherspotWallet} from "../../../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {CredibleAccountHookHarness} from "../../../harnesses/CredibleAccountHookHarness.sol";
import {CredibleAccountValidator} from "../../../../../src/modular-etherspot-wallet/modules/validators/CredibleAccountValidator.sol";
import {TestERC20} from "../../../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";
import {PackedUserOperation} from "../../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../../TestAdvancedUtils.t.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CredibleAccountHookTestUtils is TestAdvancedUtils {
    using ERC4337Utils for IEntryPoint;
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Contract instances
    ModularEtherspotWallet internal mew;
    CredibleAccountHookHarness internal harness;
    CredibleAccountValidator internal caValidator;
    TestERC20 internal token1;
    TestERC20 internal token2;

    // Test addresses and keys
    address internal alice;
    uint256 internal aliceKey;
    address internal sessionKey;
    uint256 internal sessionKeyPrivateKey;
    address payable internal immutable beneficiary;
    address payable internal immutable receiver;

    // Test variables
    address internal immutable solver = address(0xdeadbeef);
    bytes4 internal immutable selector = IERC20.transfer.selector;
    uint48 internal validAfter;
    uint48 internal validUntil;
    address[2] internal lockedTokens;
    uint256 internal constant TOKENS_LENGTH = 2;
    uint256[2] internal lockedAmounts;
    uint256 internal constant AMOUNTS_LENGTH = 2;

    /*//////////////////////////////////////////////////////////////
                        TEST HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor() {
        beneficiary = payable(
            address(
                uint160(uint256(keccak256(abi.encodePacked("beneficiary"))))
            )
        );
        receiver = payable(
            address(uint160(uint256(keccak256(abi.encodePacked("receiver")))))
        );
    }

    function _testSetup() internal {
        // Set up contracts and wallet
        mew = setupMEWWithCredibleAccountHook();
        harness = new CredibleAccountHookHarness();
        caValidator = new CredibleAccountValidator();
        token1 = new TestERC20();
        token2 = new TestERC20();
        // Set up test addresses and keys
        (alice, aliceKey) = makeAddrAndKey("alice");
        (sessionKey, sessionKeyPrivateKey) = makeAddrAndKey("sessionKey");
        vm.deal(beneficiary, 1 ether);
        vm.startPrank(address(mew));
        // Set up test variables
        validAfter = uint48(block.timestamp);
        validUntil = uint48(block.timestamp + 1000);
        lockedTokens = [address(token1), address(token2)];
        lockedAmounts = [1 ether, 2 ether];
        // Mint tokens to modular wallet
        token1.mint(address(mew), 1 ether);
        token1.approve(address(mew), 1 ether);
        token2.mint(address(mew), 2 ether);
        token2.approve(address(mew), 2 ether);
        // Install CredibleAccountValidator
        _installCredibleAccountValidator();
    }

    function _installCredibleAccountValidator() internal {
        defaultExecutor.executeViaAccount(
            IERC7579Account(mew),
            address(mew),
            0,
            abi.encodeWithSelector(
                ModularEtherspotWallet.installModule.selector,
                uint256(1),
                address(caValidator),
                ""
            )
        );
    }

    function _getLockingMode(
        CallType _callType
    ) internal pure returns (ModeCode) {
        ModeCode mode = ModeCode.wrap(
            bytes32(
                abi.encodePacked(
                    _callType,
                    ExecType.wrap(0x00),
                    bytes4(0),
                    ModeSelector.wrap(
                        bytes4(keccak256("etherspot.credibleaccount.action"))
                    ),
                    bytes22(0)
                )
            )
        );
        return mode;
    }

    function _getUnlockingMode(
        CallType _callType,
        address _sessionKey
    ) internal pure returns (ModeCode) {
        ModeCode mode = ModeCode.wrap(
            bytes32(
                abi.encodePacked(
                    _callType,
                    ExecType.wrap(0x00),
                    bytes4(0),
                    ModeSelector.wrap(
                        bytes4(keccak256("etherspot.credibleaccount.action"))
                    ),
                    ModePayload.wrap(bytes22(abi.encodePacked(_sessionKey)))
                )
            )
        );
        return mode;
    }

    function _getDefaultSessionData() internal view returns (bytes memory) {
        return
            abi.encodePacked(
                sessionKey,
                solver,
                selector,
                validAfter,
                validUntil,
                TOKENS_LENGTH,
                lockedTokens,
                AMOUNTS_LENGTH,
                lockedAmounts
            );
    }

    function _createTokenTransferExecution(
        address _recipient,
        uint256 _amount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                _recipient,
                _amount
            );
    }

    function _enableSessionKeyUserOp(
        address _wallet,
        ModeCode _mode,
        bytes memory _sessionData,
        uint256 _signerPrivateKey
    ) internal view returns (bytes32, PackedUserOperation[] memory) {
        // Set up calldata
        bytes memory callData = abi.encodeWithSelector(
            caValidator.enableSessionKey.selector,
            _sessionData
        );
        // Set up UserOperation
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                _mode,
                ExecutionLib.encodeSingle(address(caValidator), 0, callData)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            _wallet,
            userOpCalldata
        );
        userOp.nonce = getNonce(_wallet, address(ecdsaValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _signerPrivateKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        userOp.signature = abi.encodePacked(r, s, v);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        return (hash, userOps);
    }

    function _createUserOperation(
        address _account,
        bytes memory _callData,
        address _validator,
        uint256 _signerKey
    ) internal view returns (bytes32, PackedUserOperation memory) {
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            _account,
            _callData
        );
        userOp.nonce = getNonce(_account, address(_validator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _signerKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        userOp.signature = abi.encodePacked(r, s, v);
        return (hash, userOp);
    }

    function _executeUserOperation(
        PackedUserOperation memory _userOp
    ) internal {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = _userOp;
        entrypoint.handleOps(userOps, beneficiary);
    }

    function _verifyTokenLocking(
        address _token,
        bool _expectedLockStatus
    ) internal {
        assertEq(
            caHook.isTokenLocked(address(mew), _token),
            _expectedLockStatus,
            "Unexpected token lock status"
        );
    }
}
