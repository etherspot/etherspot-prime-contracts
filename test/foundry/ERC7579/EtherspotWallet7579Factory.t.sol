// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "@ERC7579/test/dependencies/EntryPoint.sol";
import "@ERC7579/test/Bootstrap.t.sol";
import {MockValidator} from "@ERC7579/test/mocks/MockValidator.sol";
import {MockExecutor} from "@ERC7579/test/mocks/MockExecutor.sol";
import {MockTarget} from "@ERC7579/test/mocks/MockTarget.sol";
import {EtherspotWallet7579Factory} from "../../../src/ERC7579/wallet/EtherspotWallet7579Factory.sol";
import {EtherspotWallet7579} from "../../../src/ERC7579/wallet/EtherspotWallet7579.sol";

contract EtherspotWallet7579FactoryTest is BootstrapUtil, Test {
    bytes32 immutable SALT = bytes32("TestSALT");
    // singletons
    EtherspotWallet7579 implementation;
    EtherspotWallet7579Factory factory;
    IEntryPoint entrypoint = IEntryPoint(ENTRYPOINT_ADDR);
    MockValidator defaultValidator;
    MockExecutor defaultExecutor;
    MockTarget target;
    EtherspotWallet7579 account;

    address owner1;
    uint256 owner1Key;

    function setUp() public virtual {
        etchEntrypoint();
        implementation = new EtherspotWallet7579();
        factory = new EtherspotWallet7579Factory(address(implementation));

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
        account = EtherspotWallet7579(
            factory.createAccount({salt: SALT, initCode: initCode})
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
        account = EtherspotWallet7579(
            factory.createAccount({salt: SALT, initCode: initCode})
        );
        // re run to return created address
        EtherspotWallet7579 accountDuplicate = EtherspotWallet7579(
            factory.createAccount({salt: SALT, initCode: initCode})
        );

        assertEq(address(account), address(accountDuplicate));
        vm.stopPrank();
    }
}
