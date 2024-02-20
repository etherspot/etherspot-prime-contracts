// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/Bootstrap.t.sol";
import {MockValidator} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockValidator.sol";
import {MockExecutor} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockExecutor.sol";
import {MockTarget} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/mocks/MockTarget.sol";
import {ModularEtherspotWalletFactory} from "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWalletFactory.sol";
import {ModularEtherspotWallet} from "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";

contract ModularEtherspotWalletFactoryTest is BootstrapUtil, Test {
    bytes32 immutable SALT = bytes32("TestSALT");
    // singletons
    ModularEtherspotWallet implementation;
    ModularEtherspotWalletFactory factory;
    IEntryPoint entrypoint = IEntryPoint(ENTRYPOINT_ADDR);
    MockValidator defaultValidator;
    MockExecutor defaultExecutor;
    MockTarget target;
    ModularEtherspotWallet account;

    address owner1;
    uint256 owner1Key;

    function setUp() public virtual {
        etchEntrypoint();
        implementation = new ModularEtherspotWallet();
        factory = new ModularEtherspotWalletFactory(address(implementation));

        // setup module singletons
        defaultExecutor = new MockExecutor();
        defaultValidator = new MockValidator();
        target = new MockTarget();

        (owner1, owner1Key) = makeAddrAndKey("owner1");
    }

    function test_setUpState() public {
        assertEq(address(implementation), factory.implementation());
    }

    function testFuzz_createAccount(address _eoa) public {
        // setup account init config
        BootstrapConfig[] memory validators = makeBootstrapConfig(
            address(defaultValidator),
            ""
        );
        BootstrapConfig[] memory executors = makeBootstrapConfig(
            address(defaultExecutor),
            ""
        );
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig memory fallbackHandler = _makeBootstrapConfig(
            address(0),
            ""
        );

        bytes memory initCode = abi.encode(
            _eoa,
            address(bootstrapSingleton),
            abi.encodeCall(
                Bootstrap.initMSA,
                (validators, executors, hook, fallbackHandler)
            )
        );

        vm.startPrank(_eoa);
        // create account
        account = ModularEtherspotWallet(
            payable(factory.createAccount({salt: SALT, initCode: initCode}))
        );
        address expectedAddress = factory.getAddress({
            salt: SALT,
            initcode: initCode
        });
        assertEq(
            address(account),
            expectedAddress,
            "Computed wallet address should always equal wallet address created"
        );
        vm.stopPrank();
    }

    function test_createAccount_returnsAddressIfAlreadyCreated() public {
        // setup account init config
        BootstrapConfig[] memory validators = makeBootstrapConfig(
            address(defaultValidator),
            ""
        );
        BootstrapConfig[] memory executors = makeBootstrapConfig(
            address(defaultExecutor),
            ""
        );
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig memory fallbackHandler = _makeBootstrapConfig(
            address(0),
            ""
        );

        bytes memory initCode = abi.encode(
            owner1,
            address(bootstrapSingleton),
            abi.encodeCall(
                Bootstrap.initMSA,
                (validators, executors, hook, fallbackHandler)
            )
        );

        vm.startPrank(owner1);
        // create account
        account = ModularEtherspotWallet(
            payable(factory.createAccount({salt: SALT, initCode: initCode}))
        );
        // re run to return created address
        ModularEtherspotWallet accountDuplicate = ModularEtherspotWallet(
            payable(factory.createAccount({salt: SALT, initCode: initCode}))
        );

        assertEq(address(account), address(accountDuplicate));
        vm.stopPrank();
    }

    function test_ensureTwoAddressesNotSame() public {
        ModularEtherspotWallet account2;

        address owner2;
        uint256 owner2Key;
        (owner2, owner2Key) = makeAddrAndKey("owner2");

        BootstrapConfig[] memory validators = makeBootstrapConfig(
            address(defaultValidator),
            ""
        );
        BootstrapConfig[] memory executors = makeBootstrapConfig(
            address(defaultExecutor),
            ""
        );
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        BootstrapConfig memory fallbackHandler = _makeBootstrapConfig(
            address(0),
            ""
        );

        bytes memory initCode = abi.encode(
            owner1,
            address(bootstrapSingleton),
            abi.encodeCall(
                Bootstrap.initMSA,
                (validators, executors, hook, fallbackHandler)
            )
        );

        vm.startPrank(owner1);
        // create account
        account = ModularEtherspotWallet(
            payable(factory.createAccount({salt: SALT, initCode: initCode}))
        );
        vm.stopPrank();
        vm.startPrank(owner2);

        initCode = abi.encode(
            owner2,
            address(bootstrapSingleton),
            abi.encodeCall(
                Bootstrap.initMSA,
                (validators, executors, hook, fallbackHandler)
            )
        );

        // create 2nd account
        account2 = ModularEtherspotWallet(
            payable(
                factory.createAccount({
                    salt: bytes32("TestSALT1"),
                    initCode: initCode
                })
            )
        );
        vm.stopPrank();
        console2.log("address(account):", address(account));
        console2.log("address(account2):", address(account2));
        assertFalse(address(account) == address(account2));
    }
}
