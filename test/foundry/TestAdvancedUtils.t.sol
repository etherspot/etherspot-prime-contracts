// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {ECDSA} from "solady/src/utils/ECDSA.sol";
import "../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Account.sol";
import {ModularEtherspotWalletFactory} from "../../src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol";
import {BootstrapUtil, BootstrapConfig} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/test/Bootstrap.t.sol";
import {MockValidator} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockValidator.sol";
import {MockExecutor} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockExecutor.sol";
import {MockTarget} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockTarget.sol";
import {MockFallback} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockFallbackHandler.sol";
import {ExecutionLib} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ExecutionLib.sol";
import {ModeLib, ModeCode, CallType, ExecType, ModeSelector, ModePayload, CALLTYPE_STATIC} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";
import {PackedUserOperation} from "../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";

import {ModularEtherspotWallet} from "../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {MultipleOwnerECDSAValidator} from "../../src/modular-etherspot-wallet/modules/validators/MultipleOwnerECDSAValidator.sol";
import {ERC20SessionKeyValidator} from "../../src/modular-etherspot-wallet/modules/validators/ERC20SessionKeyValidator.sol";
import {TokenLockHook} from "../../src/modular-etherspot-wallet/modules/hooks/TokenLockHook.sol";

contract TestAdvancedUtils is BootstrapUtil, Test {
    // singletons
    ModularEtherspotWallet implementation;
    ModularEtherspotWalletFactory factory;
    IEntryPoint entrypoint = IEntryPoint(ENTRYPOINT_ADDR);

    MockValidator defaultValidator;
    MockExecutor defaultExecutor;
    MockFallback fallbackHandler;
    MultipleOwnerECDSAValidator ecdsaValidator;
    ERC20SessionKeyValidator sessionKeyValidator;
    TokenLockHook tokenLockHook;

    ModularEtherspotWallet mewAccount;
    MockTarget target;

    address owner1;
    uint256 owner1Key;

    uint256 constant EXEC_SPEND_CAP = 10 ether;

    function setUp() public virtual {
        (owner1, owner1Key) = makeAddrAndKey("owner1");

        // Set up EntryPoint
        etchEntrypoint();
        vm.startPrank(owner1);
        // Set up MSA and Factory
        implementation = new ModularEtherspotWallet();
        factory = new ModularEtherspotWalletFactory(
            address(implementation),
            owner1
        );

        // Set up Modules
        defaultExecutor = new MockExecutor();
        defaultValidator = new MockValidator();
        fallbackHandler = new MockFallback();

        // MultipleOwnerECDSAValidator for MEW
        ecdsaValidator = new MultipleOwnerECDSAValidator();

        // ERC20SessionKeyValidtor for MEW
        sessionKeyValidator = new ERC20SessionKeyValidator();

        // TokenLockHook for MEW
        tokenLockHook = new TokenLockHook();

        // Set up Target for testing
        target = new MockTarget();
        vm.stopPrank();
    }

    function getAccountAndInitCode()
        internal
        returns (address account, bytes memory initCode)
    {
        // Create config for initial modules
        BootstrapConfig[] memory validators = makeBootstrapConfig(
            address(defaultValidator),
            ""
        );
        BootstrapConfig[] memory executors = makeBootstrapConfig(
            address(defaultExecutor),
            ""
        );
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig[] memory fallbacks = makeBootstrapConfig(
            address(0),
            ""
        );

        // Create initcode and salt to be sent to Factory
        bytes memory _initCode = bootstrapSingleton._getInitMSACalldata(
            validators,
            executors,
            hook,
            fallbacks
        );

        bytes32 salt = keccak256("1");
        // Get address of new account
        account = factory.getAddress(salt, _initCode);

        // Pack the initcode to include in the userOp
        initCode = abi.encodePacked(
            address(factory),
            abi.encodeWithSelector(
                factory.createAccount.selector,
                salt,
                _initCode
            )
        );

        // Deal 100 ether to the account
        vm.deal(account, 100 ether);
    }

    function getNonce(
        address account,
        address validator
    ) internal view returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(validator)));
        nonce = entrypoint.getNonce(address(account), key);
    }

    function getDefaultUserOp()
        internal
        pure
        returns (PackedUserOperation memory userOp)
    {
        userOp = PackedUserOperation({
            sender: address(0),
            nonce: 0,
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(
                abi.encodePacked(uint128(2e6), uint128(2e6))
            ),
            preVerificationGas: 2e6,
            gasFees: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
            paymasterAndData: bytes(""),
            signature: abi.encodePacked(hex"41414141")
        });
    }

    function getMEWAndInitCode()
        internal
        returns (address account, bytes memory initCode)
    {
        // Create config for initial modules
        BootstrapConfig[] memory validators = makeBootstrapConfig(
            address(ecdsaValidator),
            abi.encodePacked(owner1)
        );
        BootstrapConfig[] memory executors = makeBootstrapConfig(
            address(defaultExecutor),
            ""
        );
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig[] memory fallbacks = makeBootstrapConfig(
            address(0),
            ""
        );

        // Create owner
        (owner1, owner1Key) = makeAddrAndKey("owner1");

        // Create initcode and salt to be sent to Factory
        bytes memory _initCode = abi.encode(
            owner1,
            address(bootstrapSingleton),
            abi.encodeCall(
                bootstrapSingleton.initMSA,
                (validators, executors, hook, fallbacks)
            )
        );
        bytes32 salt = keccak256("1");

        // Get address of new account
        account = factory.getAddress(salt, _initCode);

        // Pack the initcode to include in the userOp
        initCode = abi.encodePacked(
            address(factory),
            abi.encodeWithSelector(
                factory.createAccount.selector,
                salt,
                _initCode
            )
        );

        // Deal 100 ether to the account
        vm.deal(account, 100 ether);
    }

    function setupMEW() internal returns (ModularEtherspotWallet mew) {
        // Create config for initial modules
        BootstrapConfig[] memory validators = makeBootstrapConfig(
            address(ecdsaValidator),
            abi.encodePacked(owner1)
        );
        BootstrapConfig[] memory executors = makeBootstrapConfig(
            address(defaultExecutor),
            ""
        );
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig[] memory fallbacks = makeBootstrapConfig(
            address(0),
            ""
        );

        // Create owner
        (owner1, owner1Key) = makeAddrAndKey("owner1");

        // Create initcode and salt to be sent to Factory
        bytes memory _initCode = abi.encode(
            owner1,
            address(bootstrapSingleton),
            abi.encodeCall(
                bootstrapSingleton.initMSA,
                (validators, executors, hook, fallbacks)
            )
        );
        bytes32 salt = keccak256("1");

        vm.startPrank(owner1);
        // create account
        mewAccount = ModularEtherspotWallet(
            payable(factory.createAccount({salt: salt, initCode: _initCode}))
        );
        vm.deal(address(mewAccount), 100 ether);
        vm.stopPrank();
        return mewAccount;
    }

    function setupMEWWithSessionKeys()
        internal
        returns (ModularEtherspotWallet mew)
    {
        // Create config for initial modules
        BootstrapConfig[] memory validators = new BootstrapConfig[](2);
        validators[0] = _makeBootstrapConfig(address(ecdsaValidator), "");
        validators[1] = _makeBootstrapConfig(address(sessionKeyValidator), "");
        BootstrapConfig[] memory executors = makeBootstrapConfig(
            address(defaultExecutor),
            ""
        );
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig[] memory fallbacks = makeBootstrapConfig(
            address(0),
            ""
        );

        // Create owner
        (owner1, owner1Key) = makeAddrAndKey("owner1");
        vm.deal(owner1, 100 ether);

        // Create initcode and salt to be sent to Factory
        bytes memory _initCode = abi.encode(
            owner1,
            address(bootstrapSingleton),
            abi.encodeCall(
                bootstrapSingleton.initMSA,
                (validators, executors, hook, fallbacks)
            )
        );
        bytes32 salt = keccak256("1");

        vm.startPrank(owner1);
        // create account
        mewAccount = ModularEtherspotWallet(
            payable(factory.createAccount({salt: salt, initCode: _initCode}))
        );
        vm.deal(address(mewAccount), 100 ether);
        vm.stopPrank();
        return mewAccount;
    }

    function setupMEWWithTokenLockHook()
        internal
        returns (ModularEtherspotWallet mew)
    {
        // Create config for initial modules
        BootstrapConfig[] memory validators = new BootstrapConfig[](2);
        validators[0] = _makeBootstrapConfig(address(ecdsaValidator), "");
        validators[1] = _makeBootstrapConfig(address(sessionKeyValidator), "");
        BootstrapConfig[] memory executors = makeBootstrapConfig(
            address(defaultExecutor),
            ""
        );
        BootstrapConfig memory hook = _makeBootstrapConfig(
            address(tokenLockHook),
            ""
        );
        BootstrapConfig[] memory fallbacks = makeBootstrapConfig(
            address(0),
            ""
        );

        // Create owner
        (owner1, owner1Key) = makeAddrAndKey("owner1");
        vm.deal(owner1, 100 ether);

        // Create initcode and salt to be sent to Factory
        bytes memory _initCode = abi.encode(
            owner1,
            address(bootstrapSingleton),
            abi.encodeCall(
                bootstrapSingleton.initMSA,
                (validators, executors, hook, fallbacks)
            )
        );
        bytes32 salt = keccak256("1");

        vm.startPrank(owner1);
        // create account
        mewAccount = ModularEtherspotWallet(
            payable(factory.createAccount({salt: salt, initCode: _initCode}))
        );
        vm.deal(address(mewAccount), 100 ether);
        vm.stopPrank();
        return mewAccount;
    }
}
