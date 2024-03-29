// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";
import {ModularEtherspotWallet} from "../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {MultipleOwnerECDSAValidator} from "../../src/modular-etherspot-wallet/modules/MultipleOwnerECDSAValidator.sol";
import "../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Account.sol";
import {ModularEtherspotWalletFactory} from "../../src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol";
import {BootstrapUtil, BootstrapConfig} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/test/Bootstrap.t.sol";
import {MockValidator} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockValidator.sol";
import {MockExecutor} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockExecutor.sol";
import {MockTarget} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockTarget.sol";
import {ExecutionLib} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ExecutionLib.sol";
import {ModeLib, ModeCode, CallType, ExecType, ModeSelector, ModePayload} from "../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";

import "../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";

contract TestAdvancedUtils is BootstrapUtil, Test {
    // singletons
    ModularEtherspotWallet implementation;
    ModularEtherspotWalletFactory factory;
    IEntryPoint entrypoint = IEntryPoint(ENTRYPOINT_ADDR);

    MockValidator defaultValidator;
    MockExecutor defaultExecutor;
    MultipleOwnerECDSAValidator ecdsaValidator;

    ModularEtherspotWallet mewAccount;
    MockTarget target;

    address owner1;
    uint256 owner1Key;

    function setUp() public virtual {
        // Set up EntryPoint
        etchEntrypoint();

        // Set up MSA and Factory
        implementation = new ModularEtherspotWallet();
        factory = new ModularEtherspotWalletFactory(address(implementation));

        // Set up Modules
        defaultExecutor = new MockExecutor();
        defaultValidator = new MockValidator();

        // MultipleOwnerECDSAValidator for MEW
        ecdsaValidator = new MultipleOwnerECDSAValidator();

        // Set up Target for testing
        target = new MockTarget();
    }

    function getAccountAndInitCode()
        internal
        returns (address account, bytes memory initCode)
    {
               // Create config for initial modules
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(defaultValidator), "");
        BootstrapConfig[] memory executors = makeBootstrapConfig(address(defaultExecutor), "");
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig[] memory fallbacks = makeBootstrapConfig(address(0), "");

        // Create initcode and salt to be sent to Factory
        bytes memory _initCode = bootstrapSingleton._getInitMSACalldata(validators, executors, hook, fallbacks);

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
        address account
    ) internal view returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(address(ecdsaValidator))));
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
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(ecdsaValidator),
            abi.encodePacked(owner1));
        BootstrapConfig[] memory executors = makeBootstrapConfig(address(defaultExecutor), "");
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig[] memory fallbacks = makeBootstrapConfig(address(0), "");

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
        BootstrapConfig[] memory validators = makeBootstrapConfig( address(ecdsaValidator),
            abi.encodePacked(owner1));
        BootstrapConfig[] memory executors = makeBootstrapConfig(address(defaultExecutor), "");
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig[] memory fallbacks = makeBootstrapConfig(address(0), "");

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
}
