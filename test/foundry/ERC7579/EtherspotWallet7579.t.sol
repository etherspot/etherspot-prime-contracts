// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "@ERC7579/src/accountExamples/MSA_ValidatorInSignature.sol";
import "@ERC7579/src/interfaces/IMSA.sol";
import "../../../src/ERC7579/wallet/EtherspotWallet7579Factory.sol";
import "../../../src/ERC7579/wallet/EtherspotWallet7579.sol";
import "@ERC7579/test/Bootstrap.t.sol";
import {MockValidator} from "@ERC7579/test/mocks/MockValidator.sol";
import {MockExecutor} from "@ERC7579/test/mocks/MockExecutor.sol";
import {MockTarget} from "@ERC7579/test/mocks/MockTarget.sol";
import {ECDSAValidator, ECDSA} from "../../../src/ERC7579/modules/ECDSAValidator.sol";

import "@ERC7579/test/dependencies/EntryPoint.sol";

contract EtherspotWallet7579Test is BootstrapUtil, Test {
    // singletons
    EtherspotWallet7579 implementation;
    EtherspotWallet7579Factory factory;
    IEntryPoint entrypoint = IEntryPoint(ENTRYPOINT_ADDR);

    MockValidator defaultValidator;
    MockExecutor defaultExecutor;
    ECDSAValidator ecdsaValidator;

    MockTarget target;

    EtherspotWallet7579 account;

    function setUp() public virtual {
        etchEntrypoint();
        implementation = new EtherspotWallet7579();
        factory = new EtherspotWallet7579Factory(address(implementation));

        // setup module singletons
        defaultExecutor = new MockExecutor();
        defaultValidator = new MockValidator();
        target = new MockTarget();
        ecdsaValidator = new ECDSAValidator();

        (address owner, uint256 key) = makeAddrAndKey("owner");

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

        // create account
        account = EtherspotWallet7579(
            factory.createAccount({
                salt: "1",
                initCode: bootstrapSingleton._getInitMSACalldata(
                    validators,
                    executors,
                    hook,
                    fallbackHandler
                )
            })
        );
        vm.deal(address(account), 1 ether);
    }

    function test_AccountFeatureDetectionExecutors() public {
        assertTrue(account.supportsInterface(type(IMSA).interfaceId));
    }

    function test_AccountFeatureDetectionConfig() public {
        assertTrue(account.supportsInterface(type(IAccountConfig).interfaceId));
    }

    function test_AccountFeatureDetectionConfigWHooks() public {
        assertFalse(
            account.supportsInterface(type(IAccountConfig_Hook).interfaceId)
        );
    }

    function test_checkValidatorEnabled() public {
        assertTrue(account.isValidatorInstalled(address(defaultValidator)));
    }

    function test_checkExecutorEnabled() public {
        assertTrue(account.isExecutorInstalled(address(defaultExecutor)));
    }

    function test_execVia4337() public {
        bytes memory setValueOnTarget = abi.encodeCall(
            MockTarget.setValue,
            1337
        );
        bytes memory execFunction = abi.encodeCall(
            IExecution.execute,
            (address(target), 0, setValueOnTarget)
        );

        (address owner, uint256 ownerKey) = makeAddrAndKey("owner");

        bytes memory initCode = abi.encode(
            address(bootstrapSingleton),
            abi.encodeCall(
                Bootstrap.singleInitMSA,
                (ecdsaValidator, abi.encodePacked(owner))
            )
        );

        bytes32 salt = keccak256("1");

        address newAccount = factory.getAddress(salt, initCode);
        vm.deal(newAccount, 1 ether);

        uint192 key = uint192(bytes24(bytes20(address(ecdsaValidator))));
        uint256 nonce = entrypoint.getNonce(address(account), key);

        UserOperation memory userOp = UserOperation({
            sender: newAccount,
            nonce: nonce,
            initCode: abi.encodePacked(
                address(factory),
                abi.encodeWithSelector(
                    factory.createAccount.selector,
                    salt,
                    initCode
                )
            ),
            callData: execFunction,
            callGasLimit: 2e6,
            verificationGasLimit: 2e6,
            preVerificationGas: 2e6,
            maxFeePerGas: 1,
            maxPriorityFeePerGas: 1,
            paymasterAndData: bytes(""),
            signature: ""
        });

        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            ownerKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;
        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = userOp;

        entrypoint.handleOps(userOps, payable(address(0x69)));

        assertTrue(target.value() == 1337);
    }
}
