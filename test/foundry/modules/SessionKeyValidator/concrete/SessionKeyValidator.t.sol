// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {ModularEtherspotWallet} from "../../../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {SessionKeyValidator} from "../../../../../src/modular-etherspot-wallet/modules/validators/SessionKeyValidator.sol";
import {ExecutionValidation, ParamCondition, Permission, SessionData} from "../../../../../src/modular-etherspot-wallet/common/Structs.sol";
import {ComparisonRule} from "../../../../../src/modular-etherspot-wallet/common/Enums.sol";
import {SessionKeyValidatorHarness} from "../../../harnesses/SessionKeyValidatorHarness.sol";
import {TestCounter} from "../../../../../src/modular-etherspot-wallet/test/TestCounter.sol";
import {TestERC20} from "../../../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import {TestWETH} from "../../../../../src/modular-etherspot-wallet/test/TestWETH.sol";
import {TestUniswap} from "../../../../../src/modular-etherspot-wallet/test/TestUniswap.sol";
import {TestERC721} from "../../../../../src/modular-etherspot-wallet/test/TestERC721.sol";
import {SessionKeyTestUtils} from "../utils/SessionKeyTestUtils.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";
import {IEntryPoint} from "../../../../../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {PackedUserOperation} from "../../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {MODULE_TYPE_VALIDATOR} from "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../../../TestAdvancedUtils.t.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";
import {SentinelListLib} from "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/SentinelList.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

using ERC4337Utils for IEntryPoint;

contract SessionKeyValidator_Concrete_Test is SessionKeyTestUtils {
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/
    TestERC20 private erc20;
    TestUniswap private uniswap;
    // Test addresses and keys
    address payable private receiver;
    address private sessionKeyAddr;
    uint256 private sessionKeyPrivate;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event SKV_ModuleInstalled(address indexed wallet);
    event SKV_ModuleUninstalled(address indexed wallet);
    event SKV_SessionKeyEnabled(
        address indexed sessionKey,
        address indexed wallet
    );
    event SKV_SessionKeyDisabled(
        address indexed sessionKey,
        address indexed wallet
    );
    event SKV_SessionKeyPauseToggled(
        address indexed sessionKey,
        address indexed wallet,
        bool live
    );
    event SKV_PermissionUsesUpdated(
        address indexed sessionKey,
        uint256 index,
        uint256 previousUses,
        uint256 newUses
    );
    event SKV_SessionKeyValidUntilUpdated(
        address indexed sessionKey,
        address indexed wallet,
        uint48 newValidUntil
    );
    event SKV_PermissionAdded(
        address indexed sessionKey,
        address indexed wallet,
        address indexed target,
        bytes4 selector,
        uint256 payableLimit,
        uint256 uses,
        ParamCondition[] paramConditions
    );
    event SKV_PermissionRemoved(
        address indexed sessionKey,
        address indexed wallet,
        uint256 indexToRemove
    );
    event SKV_PermissionModified(
        address indexed sessionKey,
        address indexed wallet,
        uint256 index,
        address target,
        bytes4 selector,
        uint256 payableLimit,
        uint256 uses,
        ParamCondition[] paramConditions
    );
    event SKV_PermissionUsed(
        address indexed sessionKey,
        Permission permission,
        uint256 oldUses,
        uint256 newUses
    );

    // From TestCounter contract
    event ReceivedPayableCall(uint256 amount, uint256 payment);
    event ReceivedMultiTypeCall(address addr, uint256 num, bool boolVal);

    // From TestUniswap contract
    event MockUniswapExchangeEvent(
        uint256 amountIn,
        uint256 amountOut,
        address tokenIn,
        address tokenOut
    );

    // From TestERC721 contract
    event TestNFTPuchased(
        address indexed buyer,
        address indexed receiver,
        uint256 tokenId
    );

    /*//////////////////////////////////////////////////////////////
                                SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public override {
        super.setUp();
        erc20 = new TestERC20();
        (sessionKeyAddr, sessionKeyPrivate) = makeAddrAndKey("session_key");
        receiver = payable(address(makeAddr("receiver")));
    }

    /*//////////////////////////////////////////////////////////////
                                TESTS
    //////////////////////////////////////////////////////////////*/

    function test_installModule() public {
        // Set up the Modular Etherspot Wallet
        mew = setupMEW();
        vm.startPrank(owner1);
        // Prepare the execution data for installing the module
        Execution[] memory batchCall = new Execution[](1);
        batchCall[0].target = address(mew);
        batchCall[0].value = 0;
        batchCall[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(sessionKeyValidator),
            hex""
        );
        // Expect the module installation event to be emitted
        vm.expectEmit(true, false, false, false);
        emit SKV_ModuleInstalled(address(mew));
        // Execute the module installation
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall);
        // Verify that the module is installed
        assertTrue(
            mew.isModuleInstalled(1, address(sessionKeyValidator), ""),
            "SessionKeyValidator module should be installed"
        );
    }

    function test_installModule_cantDoubleInstall() public {
        // Set up the Modular Etherspot Wallet
        mew = setupMEW();
        vm.startPrank(owner1);
        // Prepare the execution data for installing the module
        Execution[] memory batchCall = new Execution[](1);
        batchCall[0].target = address(mew);
        batchCall[0].value = 0;
        batchCall[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(sessionKeyValidator),
            hex""
        );
        // Expect the module installation event to be emitted
        vm.expectEmit(true, false, false, false);
        emit SKV_ModuleInstalled(address(mew));
        // Execute the module installation
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall);
        vm.expectRevert(
            abi.encodeWithSelector(
                SentinelListLib.LinkedList_EntryAlreadyInList.selector,
                address(sessionKeyValidator)
            )
        );
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall);
    }

    function test_uninstallModule() public {
        // Set up the test environment
        _testSetup();
        // Install the default validator module
        Execution[] memory batchCall = new Execution[](1);
        batchCall[0].target = address(mew);
        batchCall[0].value = 0;
        batchCall[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(defaultValidator),
            hex""
        );
        // Verify that all modules are installed
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall);
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(sessionKeyValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        // Set up a session key
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Verify that one session key is associated with the wallet
        assertEq(
            sessionKeyValidator.getSessionKeysByWallet().length,
            1,
            "Should have 1 associated session key"
        );
        // Get the previous validator in the chain for linked list
        address prevValidator = _getPrevValidator(address(sessionKeyValidator));
        // Prepare uninstall module execution
        Execution[] memory uninstallBatchCall = new Execution[](1);
        uninstallBatchCall[0].target = address(mew);
        uninstallBatchCall[0].value = 0;
        uninstallBatchCall[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.uninstallModule.selector,
            uint256(1),
            address(sessionKeyValidator),
            abi.encode(prevValidator, hex"")
        );
        // Expect the module uninstallation event to be emitted
        vm.expectEmit(true, false, false, false);
        emit SKV_ModuleUninstalled(address(mew));
        // Execute the module uninstallation
        defaultExecutor.execBatch(IERC7579Account(mew), uninstallBatchCall);
        // Verify that ECDSA and Default validators remain installed
        assertTrue(
            mew.isModuleInstalled(1, address(ecdsaValidator), ""),
            "ECDSA validator should remain installed"
        );
        assertTrue(
            mew.isModuleInstalled(1, address(defaultValidator), ""),
            "Default validator should remain installed"
        );
        // Verify that SessionKeyValidator is uninstalled
        assertFalse(
            mew.isModuleInstalled(1, address(sessionKeyValidator), ""),
            "SessionKeyValidator should be uninstalled"
        );
        // Verify that SessionKeyValidator is not initialized on wallet after uninstall
        assertFalse(
            sessionKeyValidator.isInitialized(address(mew)),
            "SessionKeyValidator should not be initialized after uninstall"
        );
        // Verify that no session keys are associated after uninstall
        assertEq(
            sessionKeyValidator.getSessionKeysByWallet().length,
            0,
            "Should have no associated session keys after uninstall"
        );
    }

    function test_uninstallModule_cantUninstallIfNotInstalled() public {
        // Set up the test environment
        _testSetup();
        // Stop mew account prank
        vm.stopPrank();
        // Prank account that does not have SessionKeyValidator installed
        vm.prank(owner1);
        // Expect the function call to revert with SKV_ModuleNotInstalled error
        // when trying to uninstall without installing first
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_ModuleNotInstalled.selector
            )
        );
        // Attempt to uninstall SessionKeyValidator
        sessionKeyValidator.onUninstall("");
    }

    function test_isModuleType() public {
        // Verify that SessionKeyValidator is of MODULE_TYPE_VALIDATOR type
        assertTrue(
            sessionKeyValidator.isModuleType(MODULE_TYPE_VALIDATOR),
            "SessionKeyValidator should be of MODULE_TYPE_VALIDATOR type"
        );
        // Verify that SessionKeyValidator is not of type 0
        assertFalse(
            sessionKeyValidator.isModuleType(0),
            "SessionKeyValidator should not be of type 0"
        );
        // Verify that SessionKeyValidator is not of type 2
        assertFalse(
            sessionKeyValidator.isModuleType(2),
            "SessionKeyValidator should not be of type 2"
        );
    }

    function test_isInitialized() public {
        // Set up the test environment
        _testSetup();
        // Verify that SessionKeyValidator is initialized for the wallet
        assertTrue(
            sessionKeyValidator.isInitialized(address(mew)),
            "SessionKeyValidator should be initialized for MEW"
        );
        // Verify that SessionKeyValidator is not initialized for a random address
        assertFalse(
            sessionKeyValidator.isInitialized(address(0x1234)),
            "SessionKeyValidator should not be initialized for random address"
        );
    }

    function test_isValidSignatureWithSender() public {
        // Expect the function call to revert with NotImplemented error
        vm.expectRevert(SessionKeyValidator.NotImplemented.selector);
        // Call isValidSignatureWithSender
        sessionKeyValidator.isValidSignatureWithSender(
            address(0),
            bytes32(0),
            ""
        );
    }

    function test_enableSessionKey() public {
        _testSetup();
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);

        vm.expectEmit(false, false, false, true);
        emit SKV_SessionKeyEnabled(sessionKeyAddr, address(mew));
        sessionKeyValidator.enableSessionKey(sd, perms);

        Permission[] memory skPerm = sessionKeyValidator
            .getSessionKeyPermissions(sessionKeyAddr);
        assertEq(skPerm.length, 1);
        assertEq(skPerm[0].target, address(counter1));
        assertEq(skPerm[0].selector, TestCounter.multiTypeCall.selector);
        assertEq(skPerm[0].payableLimit, 100 wei);
        assertEq(skPerm[0].paramConditions.length, 2);
        assertEq(skPerm[0].paramConditions[0].offset, 4);
        assertEq(
            uint8(skPerm[0].paramConditions[0].rule),
            2 // ComparisonRule.EQUAL
        );
        assertEq(
            skPerm[0].paramConditions[0].value,
            bytes32(uint256(uint160(alice)))
        );
        assertEq(skPerm[0].paramConditions[1].offset, 36);
        assertEq(
            uint8(skPerm[0].paramConditions[1].rule),
            1 // ComparisonRule.LESS_THAN_OR_EQUAL_TO
        );
        assertEq(skPerm[0].paramConditions[1].value, bytes32(uint256(5)));
    }

    function test_enableSessionKey_RevertIf_SessionKeyZeroAddress() public {
        // Set up the test environment
        _testSetup();
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(address(0));

        // Expect the function call to revert with SKV_InvalidSessionKeyData error
        // when trying to set up a session key with a zero address
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidSessionKeyData.selector,
                address(0),
                validAfter,
                validUntil
            )
        );
        // Attempt to set up a session key with a zero address
        sessionKeyValidator.enableSessionKey(sd, perms);
    }

    function test_enableSessionKey_RevertIf_SessionKeyAlreadyExists() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Expect the function call to revert with SKV_SessionKeyAlreadyExists error
        // when trying to enable an already existing session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyAlreadyExists.selector,
                sessionKeyAddr
            )
        );
        // Attempt to enable the same session key again
        sessionKeyValidator.enableSessionKey(sd, perms);
    }

    function test_enableSessionKey_RevertIf_InvalidValidAfter() public {
        // Set up the test environment
        _testSetup();
        // Set up targets with one valid address and one invalid (zero) validAfter timestamp
        SessionData memory sd = SessionData({
            sessionKey: sessionKeyAddr,
            validAfter: uint48(0),
            validUntil: validUntil,
            live: false
        });
        ParamCondition[] memory conditions = new ParamCondition[](1);
        conditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(alice)))
        });
        Permission[] memory perms = new Permission[](1);
        perms[0] = Permission({
            target: address(counter1),
            selector: TestCounter.multiTypeCall.selector,
            payableLimit: 100 wei,
            uses: tenUses,
            paramConditions: conditions
        });
        // Expect the function call to revert with SKV_InvalidSessionKeyData error
        // when trying to set up a session key with an invalid (zero) validAfter timestamp
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidSessionKeyData.selector,
                sessionKeyAddr,
                uint48(0),
                validUntil
            )
        );
        // Attempt to set up a session key with an invalid (zero) validAfter timestamp
        sessionKeyValidator.enableSessionKey(sd, perms);
    }

    function test_enableSessionKey_RevertIf_InvalidValidUntil() public {
        // Set up the test environment
        _testSetup();
        // Set up targets with one valid address and one invalid (zero) validUntil timestamp
        SessionData memory sd = SessionData({
            sessionKey: sessionKeyAddr,
            validAfter: validAfter,
            validUntil: uint48(0),
            live: false
        });
        ParamCondition[] memory conditions = new ParamCondition[](1);
        conditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(alice)))
        });
        Permission[] memory perms = new Permission[](1);
        perms[0] = Permission({
            target: address(counter1),
            selector: TestCounter.multiTypeCall.selector,
            payableLimit: 100 wei,
            uses: tenUses,
            paramConditions: conditions
        });
        // Expect the function call to revert with SKV_InvalidSessionKeyData error
        // when trying to set up a session key with an invalid (zero) validUntil timestamp
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidSessionKeyData.selector,
                sessionKeyAddr,
                validAfter,
                uint48(0)
            )
        );
        // Attempt to set up a session key with an invalid (zero) validAfter timestamp
        sessionKeyValidator.enableSessionKey(sd, perms);
    }

    function test_enableSessionKey_RevertIf_InvalidUsageAmount() public {
        // Set up the test environment
        _testSetup();
        // Set up SessionData with invalid uses amount
        SessionData memory sd = SessionData({
            sessionKey: sessionKeyAddr,
            validAfter: validAfter,
            validUntil: validUntil,
            live: false
        });
        ParamCondition[] memory conditions = new ParamCondition[](1);
        conditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(alice)))
        });
        Permission[] memory perms = new Permission[](1);
        perms[0] = Permission({
            target: address(counter1),
            selector: TestCounter.multiTypeCall.selector,
            payableLimit: 100 wei,
            uses: 0,
            paramConditions: conditions
        });

        // Expect the function call to revert with SKV_InvalidSessionKeyData error
        // when trying to set up a session key with an invalid (zero) usage amount
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidPermissionData.selector,
                sessionKeyAddr,
                address(counter1),
                TestCounter.multiTypeCall.selector,
                100 wei,
                0,
                conditions
            )
        );
        // Attempt to set up a session key with an invalid (zero) usage amount
        sessionKeyValidator.enableSessionKey(sd, perms);
    }

    function test_enableSessionKey_RevertIf_PermissionInvalidTarget() public {
        // Set up the test environment
        _testSetup();
        // Set up targets with one valid address and one invalid (zero) address
        SessionData memory sd = SessionData({
            sessionKey: sessionKeyAddr,
            validAfter: validAfter,
            validUntil: validUntil,
            live: false
        });
        ParamCondition[] memory conditions = new ParamCondition[](1);
        conditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(alice)))
        });
        Permission[] memory perms = new Permission[](1);
        perms[0] = Permission({
            target: address(0),
            selector: TestCounter.multiTypeCall.selector,
            payableLimit: 100 wei,
            uses: tenUses,
            paramConditions: conditions
        });
        // Expect the function call to revert with SKV_InvalidPermissionData error
        // when trying to set up a session key with an invalid (zero) target address
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidPermissionData.selector,
                sessionKeyAddr,
                address(0),
                perms[0].selector,
                perms[0].payableLimit,
                perms[0].uses,
                conditions
            )
        );
        // Attempt to set up a session key with the invalid target
        sessionKeyValidator.enableSessionKey(sd, perms);
    }

    function test_disableSessionKey() public {
        // Set up the test environment
        _testSetup();
        // Set up default session key and permission data
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);

        // Verify that wallet has one session key initially
        assertEq(
            sessionKeyValidator.getSessionKeysByWallet().length,
            1,
            "Should have one associated session key initially"
        );
        // Verify that the session key is valid initially
        assertFalse(
            sessionKeyValidator.getSessionKeyData(sessionKeyAddr).validUntil ==
                0,
            "Session key should be valid initially"
        );
        // Expect the SKV_SessionKeyDisabled event to be emitted
        vm.expectEmit(true, true, false, false);
        emit SKV_SessionKeyDisabled(sessionKeyAddr, address(mew));
        // Disable the session key
        sessionKeyValidator.disableSessionKey(sessionKeyAddr);
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to get  SessionData for disabled session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                sessionKeyAddr
            )
        );
        sessionKeyValidator.getSessionKeyData(sessionKeyAddr);

        // Verify that there are no associated session keys after disabling
        assertEq(
            sessionKeyValidator.getSessionKeysByWallet().length,
            0,
            "Should have no associated session keys after disabling"
        );
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to get Permission data for disabled session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                sessionKeyAddr
            )
        );
        sessionKeyValidator.getSessionKeyPermissions(sessionKeyAddr);
    }

    function test_disableSessionKey_RevertIf_SessionKeyAlreadyDisabled()
        public
    {
        // Set up the test environment
        _testSetup();
        // Set up default session key and permission data
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Disable the session key
        sessionKeyValidator.disableSessionKey(sessionKeyAddr);
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to disable an already disabled session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                sessionKeyAddr
            )
        );
        // Attempt to disable the already disabled session key
        sessionKeyValidator.disableSessionKey(sessionKeyAddr);
    }

    function test_disableSessionKey_RevertIf_NonExistentSessionKey() public {
        address newSessionKey = address(
            0x1234567890123456789012345678901234567890
        );

        // Set up the test environment
        _testSetup();
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to disable a non-existant session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                newSessionKey
            )
        );
        // Attempt to disable the already disabled session key
        sessionKeyValidator.disableSessionKey(newSessionKey);
    }

    function test_rotateSessionKey() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);

        address newSessionKey = address(
            0x1234567890123456789012345678901234567890
        );
        SessionData memory newSd = SessionData({
            sessionKey: newSessionKey,
            validAfter: uint48(block.timestamp),
            validUntil: uint48(block.timestamp + 7 days),
            live: false
        });
        ParamCondition[] memory newConditions = new ParamCondition[](1);
        newConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.GREATER_THAN_OR_EQUAL,
            value: bytes32(uint256(7))
        });
        Permission[] memory newPerms = new Permission[](1);
        newPerms[0] = Permission({
            target: address(counter2),
            selector: TestCounter.changeCount.selector,
            payableLimit: 0,
            uses: 20,
            paramConditions: newConditions
        });

        sessionKeyValidator.rotateSessionKey(sessionKeyAddr, newSd, newPerms);
        assertFalse(
            sessionKeyValidator.getSessionKeyData(newSessionKey).validUntil ==
                0,
            "New session key should be valid after rotation"
        );
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to get SessionData for disabled session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                sessionKeyAddr
            )
        );
        sessionKeyValidator.getSessionKeyData(sessionKeyAddr);
    }

    function test_rotateSessionKey_RevertIf_NonExistantSessionKey() public {
        address newSessionKey = address(
            0x1234567890123456789012345678901234567890
        );
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to rotate non-existant session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                newSessionKey
            )
        );
        // Attempt to rotate the non-existant session key
        sessionKeyValidator.rotateSessionKey(newSessionKey, sd, perms);
    }

    function test_toggleSessionKeyPause_and_isSessionLive() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Verify that the session key is live initially
        assertTrue(
            sessionKeyValidator.isSessionLive(sessionKeyAddr),
            "Session key should be live initially"
        );
        // Expect the SKV_SessionKeyPaused event to be emitted
        vm.expectEmit(true, true, false, false);
        emit SKV_SessionKeyPauseToggled(sessionKeyAddr, address(mew), false);
        // Pause the session key
        sessionKeyValidator.toggleSessionKeyPause(sessionKeyAddr);
        // Verify that the session key is now paused
        assertFalse(
            sessionKeyValidator.isSessionLive(sessionKeyAddr),
            "Session key should be paused"
        );
    }

    function test_toggleSessionKeyPause_RevertIf_SessionKeyDoesNotExist()
        public
    {
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to toggle pause for a non-existent session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                sessionKeyAddr
            )
        );
        // Attempt to toggle pause for a non-existent session key
        sessionKeyValidator.toggleSessionKeyPause(sessionKeyAddr);
    }

    function test_getSessionKeyData_and_getSessionKeyPermissions() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Get SessionData
        SessionData memory data = sessionKeyValidator.getSessionKeyData(
            sessionKeyAddr
        );
        // Verify SessionData
        assertEq(
            data.validAfter,
            validAfter,
            "ValidAfter should match the set value"
        );
        assertEq(
            data.validUntil,
            validUntil,
            "ValidUntil should match the set value"
        );
        assertEq(data.live, true, "Session key should be live");
        // Get Permission data
        Permission[] memory permissions = sessionKeyValidator
            .getSessionKeyPermissions(sessionKeyAddr);
        // Verify Permission data
        assertEq(
            permissions[0].target,
            address(counter1),
            "First permission target should be counter1"
        );
        assertEq(
            permissions[0].selector,
            TestCounter.multiTypeCall.selector,
            "First permission selector should be multiTypeCall"
        );
        assertEq(
            permissions[0].payableLimit,
            100 wei,
            "First permission payable limit should be 1 wei"
        );
        assertEq(
            permissions[0].uses,
            tenUses,
            "First permission uses should be 10"
        );
        // Get ParamCondition data for Permission
        ParamCondition[] memory conditions = permissions[0].paramConditions;
        // Verify ParamCondition data
        assertEq(
            conditions[0].offset,
            4,
            "First permission value offset should be 4"
        );
        assertEq(
            uint8(conditions[0].rule),
            2,
            "First permission rule should be EQUAL (2)"
        );
        assertEq(
            conditions[0].value,
            bytes32(uint256(uint160(address(alice)))),
            "First permission value should be alice's address"
        );
        assertEq(
            conditions[1].offset,
            36,
            "Second permission value offset should be 68"
        );
        assertEq(
            uint8(conditions[1].rule),
            1,
            "Second permission rule should be LESS_THAN_OR_EQUAL (1)"
        );
        assertEq(
            conditions[1].value,
            bytes32(uint256(5)),
            "Second permission value should be 14"
        );
    }

    function test_getSessionKeyData_RevertIf_SessionKeyDoesNotExist() public {
        address newSessionKey = address(
            0x1234567890123456789012345678901234567890
        );
        // Set up the test environment
        _testSetup();
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to get data for a non-existent session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                newSessionKey
            )
        );
        // Attempt to get data for a non-existent session key
        sessionKeyValidator.getSessionKeyData(newSessionKey);
    }

    function test_getSessionKeyPermissions_RevertIf_SessionKeyDoesNotExist()
        public
    {
        // Set up the test environment
        _testSetup();
        // Define a non-existent session key address
        address nonExistentSessionKey = address(0x123);
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to get permissions for a non-existent session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                nonExistentSessionKey
            )
        );
        // Attempt to get permissions for the non-existent session key
        sessionKeyValidator.getSessionKeyPermissions(nonExistentSessionKey);
    }

    function test_getSessionKeysByWallet() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Get wallet session keys
        address[] memory walletSessionKeys = sessionKeyValidator
            .getSessionKeysByWallet();
        // Verify that the wallet session keys match the expected session key
        assertEq(walletSessionKeys.length, 1);
        assertEq(walletSessionKeys[0], sessionKeyAddr);
    }

    function test_getSessionKeyByWallet_returnEmptyForWalletWithNoSessionKeys()
        public
    {
        // Set up the test environment
        _testSetup();
        // Get wallet session keys
        address[] memory walletSessionKeys = sessionKeyValidator
            .getSessionKeysByWallet();
        // Verify that the wallet session keys match the expected session key
        assertEq(walletSessionKeys.length, 0);
    }

    function test_getUsesLeft_and_updateUses() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Verify that the session key has 10 uses initially
        assertEq(sessionKeyValidator.getUsesLeft(sessionKeyAddr, 0), 10);
        // Update the session key to have 5 uses and should emit event
        vm.expectEmit(true, true, false, false);
        emit SKV_PermissionUsesUpdated(sessionKeyAddr, 0, 10, 5);
        sessionKeyValidator.updateUses(sessionKeyAddr, 0, 5);
        // Verify that the session key has 5 uses
        assertEq(sessionKeyValidator.getUsesLeft(sessionKeyAddr, 0), 5);
    }

    function test_updateUses_RevertIf_InvaildSessionKey() public {
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                sessionKeyAddr
            )
        );
        // Attempt to update uses for a non-existent session key
        sessionKeyValidator.updateUses(sessionKeyAddr, 0, uint256(11));
    }

    function test_updateValidUntil() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Verify that the session key has 10 uses initially
        assertEq(
            sessionKeyValidator.getSessionKeyData(sessionKeyAddr).validUntil,
            validUntil
        );
        // Update the session key to have later timestamp and should emit event
        uint48 newValidUntil = uint48(block.timestamp + 14 days);
        vm.expectEmit(true, true, false, false);
        emit SKV_SessionKeyValidUntilUpdated(
            sessionKeyAddr,
            address(mew),
            newValidUntil
        );
        sessionKeyValidator.updateValidUntil(sessionKeyAddr, newValidUntil);
        // Verify that the session key has 5 uses
        assertEq(
            sessionKeyValidator.getSessionKeyData(sessionKeyAddr).validUntil,
            newValidUntil
        );
    }

    function test_updateValidUntil_RevertIf_SessionKeyDoesNotExist() public {
        // Set up the test environment
        _testSetup();
        // Define a non-existent session key address
        address nonExistentSessionKey = address(0x123);
        // Define a new validUntil timestamp
        uint48 newValidUntil = uint48(block.timestamp + 2 days);
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to update validUntil for a non-existent session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                nonExistentSessionKey
            )
        );
        // Attempt to update validUntil for the non-existent session key
        sessionKeyValidator.updateValidUntil(
            nonExistentSessionKey,
            newValidUntil
        );
    }

    function test_updateValidUntil_MultipleTimes() public {
        // Set up the test environment
        _testSetup();
        // Define multiple new validUntil timestamps
        uint48[] memory newValidUntilList = new uint48[](3);
        newValidUntilList[0] = uint48(block.timestamp + 2 days);
        newValidUntilList[1] = uint48(block.timestamp + 3 days);
        newValidUntilList[2] = uint48(block.timestamp + 4 days);
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Perform multiple updates to the validUntil timestamp
        for (uint256 i; i < newValidUntilList.length; ++i) {
            // Expect the SKV_SessionKeyValidUntilUpdated event to be emitted
            vm.expectEmit(true, true, false, true);
            emit SKV_SessionKeyValidUntilUpdated(
                sessionKeyAddr,
                address(mew),
                newValidUntilList[i]
            );
            // Update the validUntil timestamp
            sessionKeyValidator.updateValidUntil(
                sessionKeyAddr,
                newValidUntilList[i]
            );
            // Retrieve updated session key data
            SessionData memory updatedData = sessionKeyValidator
                .getSessionKeyData(sessionKeyAddr);
            // Verify that the validUntil timestamp has been updated correctly
            assertEq(
                updatedData.validUntil,
                newValidUntilList[i],
                "ValidUntil should be updated correctly"
            );
        }
    }

    function test_addPermission() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Verify that session key is set up initially with one permission
        assertEq(
            sessionKeyValidator.getSessionKeyPermissions(sessionKeyAddr).length,
            1
        );
        // Create a new permission and add to session key
        ParamCondition[] memory newConditions = new ParamCondition[](1);
        newConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(uint256(14))
        });
        Permission memory newPerm = Permission({
            target: address(counter1),
            selector: TestCounter.changeCount.selector,
            payableLimit: 0,
            uses: tenUses,
            paramConditions: newConditions
        });
        // Expect event to be emitted
        vm.expectEmit(false, false, false, true);
        emit SKV_PermissionAdded(
            sessionKeyAddr,
            address(mew),
            newPerm.target,
            newPerm.selector,
            newPerm.payableLimit,
            newPerm.uses,
            newPerm.paramConditions
        );
        sessionKeyValidator.addPermission(sessionKeyAddr, newPerm);
        // Verify that session key now has two permissions
        assertEq(
            sessionKeyValidator.getSessionKeyPermissions(sessionKeyAddr).length,
            2
        );
    }

    function test_addPermission_RevertIf_SessionKeyDoesNotExist() public {
        // Set up the test environment
        _testSetup();
        // Define a non-existent session key address
        address nonExistentSessionKey = address(0x456);
        ParamCondition[] memory newConditions = new ParamCondition[](1);
        newConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(uint256(14))
        });
        Permission memory newPerm = Permission({
            target: address(counter1),
            selector: TestCounter.changeCount.selector,
            payableLimit: 0,
            uses: tenUses,
            paramConditions: newConditions
        });
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to add a permission to a non-existent session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                nonExistentSessionKey
            )
        );
        // Attempt to add a permission to the non-existent session key
        sessionKeyValidator.addPermission(nonExistentSessionKey, newPerm);
    }

    function test_addPermission_RevertIf_InvalidTarget() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Set up new Permission to be added with invalid target
        ParamCondition[] memory newConditions = new ParamCondition[](1);
        newConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(uint256(14))
        });
        Permission memory newPerm = Permission({
            target: address(0),
            selector: TestCounter.changeCount.selector,
            payableLimit: 0,
            uses: tenUses,
            paramConditions: newConditions
        });

        // Expect the function call to revert with SKV_InvalidPermissionData error
        // when trying to add a permission with an invalid (zero) target address
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidPermissionData.selector,
                sessionKeyAddr,
                address(0),
                TestCounter.changeCount.selector,
                0,
                tenUses,
                newConditions
            )
        );
        // Attempt to add a permission with an invalid (zero) target address
        sessionKeyValidator.addPermission(sessionKeyAddr, newPerm);
    }

    function test_removePermission() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create a new permission and add to session key
        ParamCondition[] memory newConditions = new ParamCondition[](1);
        newConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(uint256(14))
        });
        Permission memory newPerm = Permission({
            target: address(counter1),
            selector: TestCounter.changeCount.selector,
            payableLimit: 0,
            uses: tenUses,
            paramConditions: newConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, newPerm);
        // Verify that session key has two permissions
        assertEq(
            sessionKeyValidator.getSessionKeyPermissions(sessionKeyAddr).length,
            2
        );

        // Index to be removed (0)
        uint256 idx;
        // Expect event to be emitted
        vm.expectEmit(false, false, false, true);
        emit SKV_PermissionRemoved(sessionKeyAddr, address(mew), idx);
        sessionKeyValidator.removePermission(sessionKeyAddr, idx);
        // Verify that session key now has two permissions
        assertEq(
            sessionKeyValidator.getSessionKeyPermissions(sessionKeyAddr).length,
            1
        );
    }

    function test_removePermission_RevertIf_SessionKeyDoesNotExist() public {
        // Set up the test environment
        _testSetup();
        // Define a non-existent session key address
        address nonExistentSessionKey = address(0x123);
        // Expect the function call to revert with SKV_SessionKeyDoesNotExist error
        // when trying to remove a permission from a non-existent session key
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                nonExistentSessionKey
            )
        );
        // Attempt to remove a permission from the non-existent session key
        sessionKeyValidator.removePermission(nonExistentSessionKey, 0);
    }

    function test_removePermission_RevertIf_InvalidPermissionIndex() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Get an invalid index (equal to the number of permissions)
        uint256 invalidIndex = sessionKeyValidator
            .getSessionKeyPermissions(sessionKeyAddr)
            .length;
        // Expect the function call to revert with SKV_InvalidPermissionIndex error
        // when trying to remove a permission with an invalid index
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidPermissionIndex.selector
            )
        );
        // Attempt to remove a permission using the invalid index
        sessionKeyValidator.removePermission(sessionKeyAddr, invalidIndex);
    }

    function test_removePermission_RemoveLastPermission() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Get the index of the last permission
        uint256 lastPermissionIndex = sessionKeyValidator
            .getSessionKeyPermissions(sessionKeyAddr)
            .length - 1;
        // Remove the last permission
        sessionKeyValidator.removePermission(
            sessionKeyAddr,
            lastPermissionIndex
        );
        // Retrieve updated session key data
        Permission[] memory newPermissionData = sessionKeyValidator
            .getSessionKeyPermissions(sessionKeyAddr);
        // Verify the number of permissions has decreased by 1
        assertEq(
            newPermissionData.length,
            0,
            "Number of permissions should decrease by 1"
        );
    }

    function test_modifyPermission() public {
        _testSetup();
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        address newTarget = address(0x1234);
        bytes4 newSelector = bytes4(keccak256("newFunction()"));
        uint256 newPayableLimit = 200;
        uint256 newUses = 99;
        ParamCondition[] memory newConditions = new ParamCondition[](1);
        newConditions[0] = ParamCondition({
            offset: 0,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(42))
        });
        sessionKeyValidator.modifyPermission(
            sessionKeyAddr,
            0,
            newTarget,
            newSelector,
            newPayableLimit,
            newUses,
            newConditions
        );
        Permission[] memory modifiedPerms = sessionKeyValidator
            .getSessionKeyPermissions(sessionKeyAddr);
        assertEq(modifiedPerms[0].target, newTarget);
        assertEq(modifiedPerms[0].selector, newSelector);
        assertEq(modifiedPerms[0].payableLimit, newPayableLimit);
        assertEq(modifiedPerms[0].uses, newUses);
        assertEq(modifiedPerms[0].paramConditions.length, 1);
        assertEq(modifiedPerms[0].paramConditions[0].offset, 0);
        assertEq(
            uint8(modifiedPerms[0].paramConditions[0].rule),
            uint8(ComparisonRule.EQUAL)
        );
        assertEq(
            modifiedPerms[0].paramConditions[0].value,
            bytes32(uint256(42))
        );
    }

    function test_modifyPermission_PartialUpdate() public {
        _testSetup();
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Store the original paramConditions
        ParamCondition[] memory originalConditions = sessionKeyValidator
        .getSessionKeyPermissions(sessionKeyAddr)[0].paramConditions;
        address newTarget = address(0x1234);
        bytes4 newSelector = bytes4(keccak256("newFunction()"));
        uint256 newPayableLimit = 200;
        uint256 newUses = 99;
        // Modify the permission with partial updates
        sessionKeyValidator.modifyPermission(
            sessionKeyAddr,
            0,
            newTarget,
            newSelector,
            newPayableLimit,
            newUses,
            new ParamCondition[](0) // Empty array to keep paramConditions unchanged
        );
        Permission[] memory modifiedPerms = sessionKeyValidator
            .getSessionKeyPermissions(sessionKeyAddr);
        // Assert that the specified fields have been updated
        assertEq(modifiedPerms[0].target, newTarget);
        assertEq(modifiedPerms[0].selector, newSelector);
        assertEq(modifiedPerms[0].payableLimit, newPayableLimit);
        assertEq(modifiedPerms[0].uses, newUses);
        // Assert that paramConditions have remained unchanged
        assertEq(
            modifiedPerms[0].paramConditions.length,
            originalConditions.length
        );
        for (uint256 i; i < originalConditions.length; ++i) {
            assertEq(
                modifiedPerms[0].paramConditions[i].offset,
                originalConditions[i].offset
            );
            assertEq(
                uint8(modifiedPerms[0].paramConditions[i].rule),
                uint8(originalConditions[i].rule)
            );
            assertEq(
                modifiedPerms[0].paramConditions[i].value,
                originalConditions[i].value
            );
        }
    }

    function test_modifyPermission_NonExistentSessionKey() public {
        _testSetup();
        address nonExistentSessionKey = address(0xdead);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyDoesNotExist.selector,
                nonExistentSessionKey
            )
        );
        sessionKeyValidator.modifyPermission(
            nonExistentSessionKey,
            0,
            address(0x1234),
            bytes4(keccak256("newFunction()")),
            200,
            tenUses,
            new ParamCondition[](0)
        );
    }

    function test_modifyPermission_InvalidIndex() public {
        _testSetup();
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        uint256 invalidIndex = perms.length;
        vm.expectRevert(
            SessionKeyValidator.SKV_InvalidPermissionIndex.selector
        );
        sessionKeyValidator.modifyPermission(
            sessionKeyAddr,
            invalidIndex,
            address(0x1234),
            bytes4(keccak256("newFunction()")),
            200,
            tenUses,
            new ParamCondition[](0)
        );
    }

    function test_executeSingle() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation parameters
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode the call data for the counter function
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            uint256(4),
            true
        );
        // Set up a single user operation
        PackedUserOperation memory userOp = _setupSingleUserOp(
            address(mew),
            address(counter1),
            callData,
            execValidations,
            sessionKeyPrivate
        );
        // Expect event emit
        vm.expectEmit(false, false, false, true);
        emit ReceivedMultiTypeCall(address(alice), 4, true);
        // Execute the user operation
        _executeUserOp(userOp);
        // Verify that the counter has been updated correctly
    }

    function test_executeSingle_Native() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create and add new Permission for session key
        ParamCondition[] memory newConditions = new ParamCondition[](1);
        newConditions[0] = ParamCondition({
            offset: 0,
            rule: ComparisonRule.NOT_EQUAL,
            value: 0
        });
        Permission memory newPermission = Permission({
            target: address(receiver),
            selector: bytes4(0),
            payableLimit: 10 wei,
            uses: tenUses,
            paramConditions: newConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, newPermission);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation for native transfer
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode the user operation calldata for native transfer
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(receiver), 9 wei, "")
            )
        );
        // Set up the user operation
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        // Sign the user operation
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        // Encode execution validations and append to signature
        bytes memory encodedExecValidations = abi.encode(execValidations);
        userOp.signature = bytes.concat(signature, encodedExecValidations);
        // Execute the user operation
        _executeUserOp(userOp);
        // Verify that the receiver's balance has been updated correctly
        assertEq(
            receiver.balance,
            9 wei,
            "Receiver balance should match transferred amount"
        );
        // Verify that the session key uses has decreased
        uint256 usesLeft = sessionKeyValidator.getUsesLeft(sessionKeyAddr, 0);
        usesLeft = sessionKeyValidator.getUsesLeft(sessionKeyAddr, 1);
        assertEq(
            usesLeft,
            tenUses - 1,
            "Session key uses should be decremented"
        );
    }

    function test_executeSingle_callPayable() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create and add new Permission for session key
        ParamCondition[] memory newConditions = new ParamCondition[](1);
        newConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.GREATER_THAN,
            value: bytes32(uint256(7579))
        });
        Permission memory newPermission = Permission({
            target: address(counter1),
            selector: TestCounter.payableCall.selector,
            payableLimit: 87 wei,
            uses: tenUses,
            paramConditions: newConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, newPermission);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation for native transfer
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode the call data for the counter function
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.payableCall.selector,
            uint256(7580)
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(counter1), 86 wei, callData)
            )
        );
        // Set up the user operation
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        // Sign the user operation
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        // Encode execution validations and append to signature
        bytes memory encodedExecValidations = abi.encode(execValidations);
        userOp.signature = bytes.concat(signature, encodedExecValidations);
        // Execute the user operation
        vm.expectEmit(false, false, false, true);
        emit ReceivedPayableCall(uint256(7580), 86 wei);
        _executeUserOp(userOp);
        // Verify that the receiver's balance has been updated correctly
        assertEq(
            counter1.getCount(),
            uint256(7580),
            "Counter1 count value should be 7580"
        );
    }

    function test_executeSingle_RevertIf_NoPermissions() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Remove all permissions from the session key (only initialized with one)
        sessionKeyValidator.removePermission(sessionKeyAddr, 0);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation parameters
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode the call data for the counter function
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.changeCount.selector,
            1 ether
        );
        // Set up a single user operation
        PackedUserOperation memory userOp = _setupSingleUserOp(
            address(mew),
            address(counter1),
            callData,
            execValidations,
            sessionKeyPrivate
        );
        // Expect the operation to revert due to signature error (no permissions)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operation
        _executeUserOp(userOp);
    }

    function test_executeSingle_RevertIf_InvalidSessionKey() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation parameters
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode the call data for the counter function
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            4
        );
        // Set up a single user operation
        PackedUserOperation memory userOp = _setupSingleUserOp(
            address(mew),
            address(counter1),
            callData,
            execValidations,
            sessionKeyPrivate
        );
        // Create an array of user operations
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Disable the session key
        sessionKeyValidator.disableSessionKey(sessionKeyAddr);
        // Expect the operation to revert due to signature error (invalid session key)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operations
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_executeSingle_RevertIf_InvalidTarget() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation parameters
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode the call data for the counter function
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            4
        );
        // Set up a single user operation with an invalid target (alice)
        PackedUserOperation memory userOp = _setupSingleUserOp(
            address(mew),
            address(alice),
            callData,
            execValidations,
            sessionKeyPrivate
        );
        // Create an array of user operations
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the operation to revert due to signature error (invalid target)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operations
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_executeSingle_RevertIf_InvalidFunctionSelector() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation parameters
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode invalid call data with an unauthorized function selector
        bytes memory invalidCallData = abi.encodeWithSelector(
            TestCounter.invalid.selector,
            address(alice),
            uint256(1 ether)
        );
        // Set up a single user operation with invalid call data
        PackedUserOperation memory userOp = _setupSingleUserOp(
            address(mew),
            address(counter1),
            invalidCallData,
            execValidations,
            sessionKeyPrivate
        );
        // Create an array of user operations
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the operation to revert due to signature error (invalid function selector)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operations
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_executeSingle_RevertIf_NoUsesLeft() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation parameters
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode the call data for the counter function
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            4
        );
        // Set up a single user operation
        PackedUserOperation memory userOp = _setupSingleUserOp(
            address(mew),
            address(counter1),
            callData,
            execValidations,
            sessionKeyPrivate
        );
        // Create an array of user operations
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Set the remaining uses of the session key to 0
        sessionKeyValidator.updateUses(sessionKeyAddr, 0, 0);
        // Expect the operation to revert due to signature error (no uses left)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operations
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_executeSingle_maximumUsesForPermissionExceeded() public {
        uint256 maxUses = 3;
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        perms[0].uses = maxUses;
        harness.enableSessionKey(sd, perms);

        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation parameters
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            4,
            false
        );
        for (uint256 i; i < maxUses; ++i) {
            // Set up a single user operation
            PackedUserOperation memory userOp = _setupSingleUserOp(
                address(mew),
                address(counter1),
                callData,
                execValidations,
                sessionKeyPrivate
            );
            (bool success, , ) = harness.exposed_validateSessionKeyParams(
                sessionKeyAddr,
                userOp,
                execValidations
            );
            assertTrue(success, "Permission should be valid");
        }
        PackedUserOperation memory finalUserOp = _setupSingleUserOp(
            address(mew),
            address(counter1),
            callData,
            execValidations,
            sessionKeyPrivate
        );
        (bool finalSuccess, , ) = harness.exposed_validateSessionKeyParams(
            sessionKeyAddr,
            finalUserOp,
            execValidations
        );
        assertFalse(
            finalSuccess,
            "Permission should be invalid after maximum uses"
        );
    }

    function test_executeSingle_RevertIf_Paused() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation parameters
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode the call data for the counter function
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            4
        );
        // Set up a single user operation
        PackedUserOperation memory userOp = _setupSingleUserOp(
            address(mew),
            address(counter1),
            callData,
            execValidations,
            sessionKeyPrivate
        );
        // Create an array of user operations
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Set the remaining uses of the session key to 0
        sessionKeyValidator.toggleSessionKeyPause(sessionKeyAddr);
        // Expect the operation to revert due to signature error (no uses left)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operations
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_executeSingle_Native_RevertIf_InvalidAmount() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create and add new Permission for session key
        ParamCondition[] memory newConditions = new ParamCondition[](1);
        newConditions[0] = ParamCondition({
            offset: 0,
            rule: ComparisonRule.NOT_EQUAL,
            value: 0
        });
        Permission memory newPermission = Permission({
            target: address(receiver),
            selector: bytes4(0),
            payableLimit: 10 wei,
            uses: tenUses,
            paramConditions: newConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, newPermission);

        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation for native transfer
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode user operation calldata with an invalid amount (3 wei)
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(receiver), 11 wei, "")
            )
        );
        // Set up the user operation
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        // Sign the user operation
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        // Encode execution validations and append to signature
        bytes memory encodedExecValidations = abi.encode(execValidations);
        userOp.signature = bytes.concat(signature, encodedExecValidations);
        // Expect the operation to revert due to signature error (invalid amount)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operation
        _executeUserOp(userOp);
    }

    function test_executeBatch() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create a new permission and add to session key
        ParamCondition[] memory newConditions = new ParamCondition[](1);
        newConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(uint256(14))
        });
        Permission memory newPerm = Permission({
            target: address(counter2),
            selector: TestCounter.changeCount.selector,
            payableLimit: 0,
            uses: tenUses,
            paramConditions: newConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, newPerm);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](2);
        // Set up execution validations for changeCount and multiTypeCall functions
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        execValidations[1] = _setupExecutionValidation(uint48(2), uint48(4));
        // Encode call data for changeCount and multiTypeCall functions
        bytes memory multiCallData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            uint256(4),
            true
        );
        bytes memory countCallData = abi.encodeWithSelector(
            TestCounter.changeCount.selector,
            uint256(13)
        );
        // Create an array of executions
        Execution[] memory executions = new Execution[](2);
        Execution memory exec1 = Execution({
            target: address(counter1),
            value: 0,
            callData: multiCallData
        });
        Execution memory exec2 = Execution({
            target: address(counter2),
            value: 0,
            callData: countCallData
        });
        executions[0] = exec1;
        executions[1] = exec2;
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        // Expect event emit
        vm.expectEmit(false, false, false, true);
        emit ReceivedMultiTypeCall(address(alice), 4, true);
        // Execute the user operation
        _executeUserOp(userOp);
        // Verify that both counters have been updated correctly
        assertEq(counter2.getCount(), uint256(13), "Counter should be updated");
    }

    function test_executeBatch_payableCallAndNative() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create a new permission for native transfer and add to session key
        ParamCondition[] memory nativeConditions = new ParamCondition[](1);
        nativeConditions[0] = ParamCondition({
            offset: 0,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: 0
        });
        Permission memory nativePerm = Permission({
            target: address(receiver),
            selector: bytes4(0),
            payableLimit: 3 wei,
            uses: tenUses,
            paramConditions: nativeConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, nativePerm);
        // Create a new permission for payable call and add to session key
        ParamCondition[] memory payableConditions = new ParamCondition[](1);
        payableConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(uint256(1))
        });
        Permission memory payablePerm = Permission({
            target: address(counter2),
            selector: TestCounter.payableCall.selector,
            payableLimit: 1 wei,
            uses: tenUses,
            paramConditions: payableConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, payablePerm);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](2);
        // Set up execution validations for payableCall and native transfer functions
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        execValidations[1] = _setupExecutionValidation(uint48(2), uint48(4));
        // Encode call data for payableCall function
        bytes memory payableData = abi.encodeWithSelector(
            TestCounter.payableCall.selector,
            uint256(1)
        );
        // Create an array of executions
        Execution[] memory executions = new Execution[](2);
        Execution memory execNative = Execution({
            target: address(receiver),
            value: 3 wei,
            callData: ""
        });
        Execution memory execPayable = Execution({
            target: address(counter2),
            value: 1 wei,
            callData: payableData
        });
        executions[0] = execNative;
        executions[1] = execPayable;
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        // Execute the user operation
        _executeUserOp(userOp);
        // Verify that both counters have been updated correctly
        assertEq(counter2.getCount(), uint256(1), "Counter should be updated");
        assertEq(receiver.balance, 3 wei, "Receiver balance should be 3 wei");
    }

    function test_executeBatch_callAndNative() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create a new permission for native transfer and add to session key
        ParamCondition[] memory nativeConditions = new ParamCondition[](1);
        nativeConditions[0] = ParamCondition({
            offset: 0,
            rule: ComparisonRule.GREATER_THAN_OR_EQUAL,
            value: 0
        });
        Permission memory nativePerm = Permission({
            target: address(receiver),
            selector: bytes4(0),
            payableLimit: 13 wei,
            uses: tenUses,
            paramConditions: nativeConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, nativePerm);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](2);
        // Set up execution validations for call and native executions
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        execValidations[1] = _setupExecutionValidation(uint48(2), uint48(5));
        // Encode call data for multiTypeCall function
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            5,
            false
        );
        // Create an array of executions
        Execution[] memory executions = new Execution[](2);
        Execution memory execCall = Execution({
            target: address(counter1),
            value: 0,
            callData: callData
        });
        Execution memory execNative = Execution({
            target: address(receiver),
            value: 13 wei,
            callData: ""
        });
        executions[0] = execCall;
        executions[1] = execNative;
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        // Expect event emit
        vm.expectEmit(false, false, false, true);
        emit ReceivedMultiTypeCall(address(alice), 5, false);
        // Execute the user operation
        _executeUserOp(userOp);
        // Verify receiver received funds
        assertEq(receiver.balance, 13 wei, "Receiver balance should be 13 wei");
    }

    function test_executeBatch_decreasesPermissionUsesSamePermission() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](3);
        // Set up execution validations for changeCount and multiTypeCall functions
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        execValidations[1] = _setupExecutionValidation(uint48(2), uint48(4));
        execValidations[2] = _setupExecutionValidation(uint48(2), uint48(4));
        // Encode call data for changeCount and multiTypeCall functions
        bytes memory multiCallData1 = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            uint256(4),
            true
        );
        bytes memory multiCallData2 = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            uint256(3),
            true
        );
        bytes memory multiCallData3 = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            uint256(2),
            true
        );
        // Create an array of executions
        Execution[] memory executions = new Execution[](3);
        Execution memory exec1 = Execution({
            target: address(counter1),
            value: 0,
            callData: multiCallData1
        });
        Execution memory exec2 = Execution({
            target: address(counter1),
            value: 0,
            callData: multiCallData2
        });
        Execution memory exec3 = Execution({
            target: address(counter1),
            value: 0,
            callData: multiCallData3
        });
        executions[0] = exec1;
        executions[1] = exec2;
        executions[2] = exec3;
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        // Execute the user operation
        _executeUserOp(userOp);
        // Validate permission uses updates (10 - 3 = 7)
        assertEq(
            sessionKeyValidator.getUsesLeft(sessionKeyAddr, 0),
            7,
            "Should have decreased by 3"
        );
    }

    function test_executeBatch_decreasesPermissionUsesMultiplePermissions()
        public
    {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create a new permission and add to session key
        ParamCondition[] memory newConditions = new ParamCondition[](1);
        newConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(uint256(14))
        });
        Permission memory newPerm = Permission({
            target: address(counter2),
            selector: TestCounter.changeCount.selector,
            payableLimit: 0,
            uses: tenUses,
            paramConditions: newConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, newPerm);
        // Check session key now has 2 permissions
        Permission[] memory permissions = sessionKeyValidator
            .getSessionKeyPermissions(sessionKeyAddr);
        assertEq(
            permissions.length,
            2,
            "Session key should have 2 permissions"
        );
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](3);
        // Set up execution validations for changeCount and multiTypeCall functions
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        execValidations[1] = _setupExecutionValidation(uint48(2), uint48(4));
        execValidations[2] = _setupExecutionValidation(uint48(2), uint48(3));
        // Encode call data for changeCount and multiTypeCall functions
        bytes memory multiCallData1 = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            uint256(4),
            true
        );
        bytes memory multiCallData2 = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            uint256(2),
            false
        );
        bytes memory countCallData = abi.encodeWithSelector(
            TestCounter.changeCount.selector,
            uint256(13)
        );
        // Create an array of executions
        Execution[] memory executions = new Execution[](3);
        Execution memory exec1 = Execution({
            target: address(counter1),
            value: 0,
            callData: multiCallData1
        });
        Execution memory exec2 = Execution({
            target: address(counter1),
            value: 0,
            callData: multiCallData2
        });
        Execution memory exec3 = Execution({
            target: address(counter2),
            value: 0,
            callData: countCallData
        });
        executions[0] = exec1;
        executions[1] = exec2;
        executions[2] = exec3;
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        // Expect event emit
        // vm.expectEmit(true, false, false, true);
        // emit SKV_PermissionUsed(sessionKeyAddr, perms[0], 10, 9);
        // vm.expectEmit(true, false, false, true);
        // emit SKV_PermissionUsed(sessionKeyAddr, newPerm, 10, 9);
        // vm.expectEmit(true, false, false, true);
        // emit SKV_PermissionUsed(sessionKeyAddr, newPerm, 9, 8);
        // NOTE: It does emit these events in the stack trace but
        // due to UserOp its not picking them up in the test correctly
        // Execute the user operation
        _executeUserOp(userOp);
        // Verify that both counters have been updated correctly
        assertEq(counter2.getCount(), uint256(13), "Counter should be updated");
        // Validate permission uses updates
        assertEq(
            sessionKeyValidator.getUsesLeft(sessionKeyAddr, 0),
            8,
            "Should have decreased by 2"
        );
        assertEq(
            sessionKeyValidator.getUsesLeft(sessionKeyAddr, 1),
            9,
            "Should have decreased by 1"
        );
    }

    function test_executeBatch_RevertIf_InvalidTarget() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create a new permission for changeCount transfer and add to session key
        ParamCondition[] memory countConditions = new ParamCondition[](1);
        countConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.GREATER_THAN_OR_EQUAL,
            value: bytes32(uint256(99))
        });
        Permission memory countPerm = Permission({
            target: address(counter2),
            selector: TestCounter.changeCount.selector,
            payableLimit: 0,
            uses: tenUses,
            paramConditions: countConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, countPerm);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](2);
        // Set up execution validations for multiTypeCall and changeCount functions
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        execValidations[1] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode call data for multiTypeCall and changeCount functions
        bytes memory multiData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            4,
            true
        );
        bytes memory countData = abi.encodeWithSelector(
            TestCounter.changeCount.selector,
            100
        );
        // Create an array of executions with an invalid target
        Execution[] memory executions = new Execution[](2);
        Execution memory exec1 = Execution({
            target: address(counter1),
            value: 0,
            callData: multiData
        });
        Execution memory exec2 = Execution({
            target: address(alice), // Invalid target
            value: 0,
            callData: countData
        });
        executions[0] = exec1;
        executions[1] = exec2;
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        // Create an array of user operations
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the operation to revert due to signature error (invalid target)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operations
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_executeBatch_RevertIf_InvalidFunctionSelector() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validations for invalid function
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode invalid call data with unauthorized function selector
        bytes memory invalidData = abi.encodeWithSelector(
            TestCounter.invalid.selector,
            address(alice),
            uint256(1 ether)
        );
        // Create an array of executions with one valid and one invalid function call
        Execution[] memory executions = new Execution[](1);
        Execution memory exec1 = Execution({
            target: address(counter2),
            value: 0,
            callData: invalidData
        });
        executions[0] = exec1;
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        // Create an array of user operations
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Expect the operation to revert due to signature error (invalid function selector)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operations
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_validateUserOp_RevertIf_SessionKeyNotYetActive() public {
        // Set up the test environment
        _testSetup();
        // Define validity period for the session key
        uint48 _validAfter = uint48(3);
        uint48 _validUntil = uint48(4);
        // Set up a session key with future validity period
        SessionData memory sd = SessionData({
            sessionKey: sessionKeyAddr,
            validAfter: _validAfter,
            validUntil: _validUntil,
            live: false
        });
        ParamCondition[] memory conditions = new ParamCondition[](2);
        conditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(alice)))
        });
        conditions[1] = ParamCondition({
            offset: 36,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(uint256(5))
        });
        Permission[] memory perms = new Permission[](1);
        perms[0] = Permission({
            target: address(counter1),
            selector: TestCounter.multiTypeCall.selector,
            payableLimit: 100 wei,
            uses: tenUses,
            paramConditions: conditions
        });
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation parameters
        execValidations[0] = _setupExecutionValidation(uint48(2), _validUntil);
        // Encode the call data for the counter function
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            4,
            true
        );
        // Set up a single user operation
        PackedUserOperation memory userOp = _setupSingleUserOp(
            address(mew),
            address(counter1),
            callData,
            execValidations,
            sessionKeyPrivate
        );
        // Expect the operation to revert due to signature error (session key not yet active)
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operation
        _executeUserOp(userOp);
    }

    function test_validateUserOp_RevertIf_SessionKeyExpired() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Move the block timestamp past the expiration time
        vm.warp(block.timestamp + 1 days + 1);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation parameters
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode the call data for the counter function
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            4,
            true
        );
        // Set up a single user operation
        PackedUserOperation memory userOp = _setupSingleUserOp(
            address(mew),
            address(counter1),
            callData,
            execValidations,
            sessionKeyPrivate
        );
        // Expect the operation to revert due to expired session key
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA22 expired or not due"
            )
        );
        // Attempt to execute the user operation
        _executeUserOp(userOp);
    }

    function test_validateUserOp_RevertIf_InvalidSigner() public {
        // Set up the test environment
        _testSetup();
        vm.deal(owner1, 10 ether);
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Move the block timestamp past the expiration time
        vm.warp(block.timestamp + 1 days + 1);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        // Set up execution validation parameters
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode the call data for the counter function
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            4,
            true
        );
        // Set up a single user operation
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(counter1), 0, callData)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );
        userOp.nonce = getNonce(address(mew), address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            owner1Key,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory invalidSig = abi.encodePacked(r, s, v);
        bytes memory encodedExecValidations = abi.encode(execValidations);
        userOp.signature = bytes.concat(invalidSig, encodedExecValidations);
        // Expect the operation to revert due to expired session key
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        // Attempt to execute the user operation
        _executeUserOp(userOp);
    }

    /*//////////////////////////////////////////////////////////////
                      TESTS (INTERNAL FUNCTIONS)
    //////////////////////////////////////////////////////////////*/

    function test_exposed_extractExecutionValidationAndSignature() public {
        // Set up the test environment
        _testSetup();
        // Set up an ExecutionValidation struct
        ExecutionValidation memory execValidation = ExecutionValidation({
            validAfter: uint48(block.timestamp),
            validUntil: uint48(block.timestamp + 1 days)
        });
        // Set up signature components
        bytes32 r = bytes32(uint256(1));
        bytes32 s = bytes32(uint256(2));
        uint8 v = 27;
        // Create and encode an array of ExecutionValidations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        execValidations[0] = execValidation;
        bytes memory encodedExecValidations = abi.encode(execValidations);
        // Combine signature components and encoded ExecutionValidations
        bytes memory fullSignature = abi.encodePacked(
            r,
            s,
            v,
            encodedExecValidations
        );
        // Call the function to extract ExecutionValidation and signature components
        (
            ExecutionValidation[] memory resultExecDatas,
            bytes32 resultR,
            bytes32 resultS,
            uint8 resultV
        ) = harness.exposed_extractExecutionValidationAndSignature(
                fullSignature
            );
        // Assert the correctness of the extracted ExecutionValidation
        assertEq(
            resultExecDatas.length,
            1,
            "Incorrect number of ExecutionValidation"
        );
        assertEq(
            resultExecDatas[0].validAfter,
            execValidation.validAfter,
            "Incorrect validAfter"
        );
        assertEq(
            resultExecDatas[0].validUntil,
            execValidation.validUntil,
            "Incorrect validUntil"
        );
        // Assert the correctness of the extracted signature components
        assertEq(resultR, r, "Incorrect r value");
        assertEq(resultS, s, "Incorrect s value");
        assertEq(resultV, v, "Incorrect v value");
    }

    function test_exposed_validatePermission() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key with future validity period
        SessionData memory sd = SessionData({
            sessionKey: sessionKeyAddr,
            validAfter: validAfter,
            validUntil: validUntil,
            live: false
        });
        ParamCondition[] memory conditions = new ParamCondition[](2);
        conditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(alice)))
        });
        conditions[1] = ParamCondition({
            offset: 36,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(uint256(5))
        });
        Permission[] memory perms = new Permission[](1);
        perms[0] = Permission({
            target: address(counter1),
            selector: TestCounter.multiTypeCall.selector,
            payableLimit: 100 wei,
            uses: tenUses,
            paramConditions: conditions
        });
        harness.enableSessionKey(sd, perms); // Set up execution validation for a valid call
        ExecutionValidation memory execValidation = _setupExecutionValidation(
            uint48(1),
            uint48(3)
        );
        bytes memory callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            4,
            true
        );
        // Test valid permission
        bool result = harness.exposed_validatePermission(
            address(mew),
            sd,
            execValidation,
            address(counter1),
            0,
            callData
        );
        assertTrue(result, "Permission should be valid");
        // Test invalid target
        result = harness.exposed_validatePermission(
            address(mew),
            sd,
            execValidation,
            address(counter2),
            0,
            callData
        );
        assertFalse(result, "Permission should be invalid due to wrong target");
        // Test not compliance with ComparisonRule
        callData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            6,
            true
        );
        result = harness.exposed_validatePermission(
            address(mew),
            sd,
            execValidation,
            address(counter1),
            0,
            callData
        );
        assertFalse(
            result,
            "Permission should be invalid due to exceeded spending limit"
        );
        // Test native transfer
        ParamCondition[] memory nativeConditions = new ParamCondition[](1);
        nativeConditions[0] = ParamCondition({
            offset: 0,
            rule: ComparisonRule.GREATER_THAN_OR_EQUAL,
            value: 0
        });
        Permission memory nativePerm = Permission({
            target: address(receiver),
            selector: bytes4(0),
            payableLimit: 13 wei,
            uses: tenUses,
            paramConditions: nativeConditions
        });
        harness.addPermission(sessionKeyAddr, nativePerm);
        ExecutionValidation
            memory nativeExecValidation = _setupExecutionValidation(
                uint48(1),
                uint48(3)
            );
        bytes memory emptyCallData = new bytes(0);
        result = harness.exposed_validatePermission(
            address(mew),
            sd,
            nativeExecValidation,
            address(receiver),
            13 wei,
            emptyCallData
        );
        assertTrue(result, "Native transfer should be valid");
    }

    function test_exposed_validateSessionKeyParams() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        harness.enableSessionKey(sd, perms);
        // Set up new Permission and add to session key
        ParamCondition[] memory nativeConditions = new ParamCondition[](1);
        nativeConditions[0] = ParamCondition({
            offset: 0,
            rule: ComparisonRule.GREATER_THAN_OR_EQUAL,
            value: 0
        });
        Permission memory nativePerm = Permission({
            target: address(receiver),
            selector: bytes4(0),
            payableLimit: 13 wei,
            uses: tenUses,
            paramConditions: nativeConditions
        });
        harness.addPermission(sessionKeyAddr, nativePerm);

        // Create execution validations for two different operations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](2);
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        execValidations[1] = _setupExecutionValidation(uint48(2), uint48(6));
        // Encode the call data for the counter function
        bytes memory multiData = abi.encodeWithSelector(
            TestCounter.multiTypeCall.selector,
            address(alice),
            4,
            true
        );
        // Create execution structs for the batch operation
        Execution[] memory executions = new Execution[](2);
        Execution memory exec1 = Execution({
            target: address(counter1),
            value: 0,
            callData: multiData
        });
        Execution memory exec2 = Execution({
            target: address(receiver),
            value: 13 wei,
            callData: ""
        });

        executions[0] = exec1;
        executions[1] = exec2;
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        // Call the exposed function to validate session key parameters
        (bool success, uint48 _validAfter, uint48 _validUntil) = harness
            .exposed_validateSessionKeyParams(
                sessionKeyAddr,
                userOp,
                execValidations
            );
        // Assert that the validation succeeds
        assertTrue(success, "Validation should succeed");
        // Assert that validAfter matches the lowest value from executions
        assertEq(_validAfter, uint48(1), "ValidAfter should match lowest");
        // Assert that validUntil matches the highest value from executions
        assertEq(_validUntil, uint48(6), "ValidUntil should match highest");
    }

    function test_exposed_validateSessionKeyParams_InvalidCallType() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        harness.enableSessionKey(sd, perms);
        // Create a user operation with an invalid call type
        bytes memory callData = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encode(
                    CALLTYPE_STATIC,
                    EXECTYPE_DEFAULT,
                    MODE_DEFAULT,
                    ModePayload.wrap(0x00)
                ),
                ExecutionLib.encodeSingle(address(alice), 1 wei, "")
            )
        );
        PackedUserOperation memory userOp = PackedUserOperation({
            sender: address(mew),
            nonce: 0,
            initCode: bytes(""),
            callData: callData,
            accountGasLimits: bytes32(0),
            preVerificationGas: 0,
            gasFees: bytes32(0),
            paymasterAndData: bytes(""),
            signature: bytes("")
        });
        bytes32 userOpHash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            userOpHash
        );
        userOp.signature = abi.encodePacked(r, s, v);
        // Create execution validation
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        execValidations[0] = _setupExecutionValidation(0, 0);
        // Call the exposed function to validate session key parameters
        (bool success, uint48 _validAfter, uint48 _validUntil) = harness
            .exposed_validateSessionKeyParams(
                sessionKeyAddr,
                userOp,
                execValidations
            );
        // Assert that the validation fails
        assertFalse(success, "Validation should fail");
        assertEq(_validAfter, 0, "ValidAfter should be 0");
        assertEq(_validUntil, 0, "ValidUntil should be 0");
    }

    // _checkCondition internal function logic check tests
    function test_exposed_checkCondition_testEqualCondition() public {
        // Set up the test environment
        _testSetup();
        bytes32 param = bytes32(uint256(10));
        bytes32 value = bytes32(uint256(10));
        bool result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.EQUAL
        );
        assertTrue(result);
        param = bytes32(uint256(11));
        result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.EQUAL
        );
        assertFalse(result);
    }

    function test_exposed_checkCondition_testGreaterThanCondition() public {
        // Set up the test environment
        _testSetup();
        bytes32 param = bytes32(uint256(11));
        bytes32 value = bytes32(uint256(10));
        bool result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.GREATER_THAN
        );
        assertTrue(result);
        param = bytes32(uint256(10));
        result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.GREATER_THAN
        );
        assertFalse(result);
    }

    function test_exposed_checkCondition_testLessThanCondition() public {
        // Set up the test environment
        _testSetup();
        bytes32 param = bytes32(uint256(9));
        bytes32 value = bytes32(uint256(10));
        bool result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.LESS_THAN
        );
        assertTrue(result);
        param = bytes32(uint256(10));
        result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.LESS_THAN
        );
        assertFalse(result);
    }

    function test_exposed_checkCondition_testGreaterThanOrEqualCondition()
        public
    {
        // Set up the test environment
        _testSetup();
        bytes32 param = bytes32(uint256(10));
        bytes32 value = bytes32(uint256(10));
        bool result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.GREATER_THAN_OR_EQUAL
        );
        assertTrue(result);
        param = bytes32(uint256(11));
        result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.GREATER_THAN_OR_EQUAL
        );
        assertTrue(result);

        param = bytes32(uint256(9));
        result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.GREATER_THAN_OR_EQUAL
        );
        assertFalse(result);
    }

    function test_exposed_checkCondition_testLessThanOrEqualCondition() public {
        // Set up the test environment
        _testSetup();
        bytes32 param = bytes32(uint256(10));
        bytes32 value = bytes32(uint256(10));
        bool result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.LESS_THAN_OR_EQUAL
        );
        assertTrue(result);
        param = bytes32(uint256(9));
        result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.LESS_THAN_OR_EQUAL
        );
        assertTrue(result);

        param = bytes32(uint256(11));
        result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.LESS_THAN_OR_EQUAL
        );
        assertFalse(result);
    }

    function test_exposed_checkCondition_testNotEqualCondition() public {
        // Set up the test environment
        _testSetup();
        bytes32 param = bytes32(uint256(11));
        bytes32 value = bytes32(uint256(10));
        bool result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.NOT_EQUAL
        );
        assertTrue(result);
        param = bytes32(uint256(10));
        result = harness.exposed_checkCondition(
            param,
            value,
            ComparisonRule.NOT_EQUAL
        );
        assertFalse(result);
    }

    /*//////////////////////////////////////////////////////////////
                           ERC20 BATCH TEST
    //////////////////////////////////////////////////////////////*/

    function test_batchExecutionERC20() public {
        // Set up the test environment
        _testSetup();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        // Mint ERC20 tokens to the wallet
        uint256 mintAmount = 1000 * 10 ** 18; // 1000 tokens
        erc20.mint(address(mew), mintAmount);
        // Create permissions for ERC20 approve and transferFrom
        ParamCondition[] memory approveConditions = new ParamCondition[](2);
        approveConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(address(mew))))
        });
        approveConditions[1] = ParamCondition({
            offset: 36,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(mintAmount)
        });
        Permission memory approvePerm = Permission({
            target: address(erc20),
            selector: IERC20.approve.selector,
            payableLimit: 0,
            uses: tenUses,
            paramConditions: approveConditions
        });
        ParamCondition[] memory transferFromConditions = new ParamCondition[](
            3
        );
        transferFromConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(address(mew))))
        });
        transferFromConditions[1] = ParamCondition({
            offset: 36,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(address(receiver))))
        });
        transferFromConditions[2] = ParamCondition({
            offset: 68,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(mintAmount)
        });
        Permission memory transferFromPerm = Permission({
            target: address(erc20),
            selector: IERC20.transferFrom.selector,
            payableLimit: 0,
            uses: tenUses,
            paramConditions: transferFromConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, approvePerm);
        sessionKeyValidator.addPermission(sessionKeyAddr, transferFromPerm);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](2);
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        execValidations[1] = _setupExecutionValidation(uint48(2), uint48(4));
        // Encode call data for approve and transferFrom functions
        uint256 transferAmount = 500 * 10 ** 18; // 500 tokens
        bytes memory approveData = abi.encodeWithSelector(
            IERC20.approve.selector,
            address(mew),
            transferAmount
        );
        bytes memory transferFromData = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            receiver,
            transferAmount
        );
        // Create an array of executions
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution({
            target: address(erc20),
            value: 0,
            callData: approveData
        });
        executions[1] = Execution({
            target: address(erc20),
            value: 0,
            callData: transferFromData
        });
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        // Execute the user operation
        _executeUserOp(userOp);
        // Verify that the receiver's balance has been updated correctly
        assertEq(
            erc20.balanceOf(receiver),
            transferAmount,
            "Receiver should have received the tokens"
        );
        assertEq(
            erc20.balanceOf(address(mew)),
            mintAmount - transferAmount,
            "Wallet balance should be reduced"
        );
    }

    /*//////////////////////////////////////////////////////////////
                         UNISWAP SWAP TESTING
    //////////////////////////////////////////////////////////////*/

    function test_uniswap_swapExactTokensForTokens() public {
        // Set up the test environment
        _testSetup();
        TestWETH weth = new TestWETH();
        TestERC20 dai = new TestERC20();
        TestERC20 link = new TestERC20();
        uniswap = new TestUniswap(weth);
        // Mint tokens
        // weth.mint(address(mew), 100 ether);
        dai.mint(address(mew), 100 ether);
        link.mint(address(uniswap), 100 ether);
        // Approve Uniswap to spend tokens
        dai.approve(address(uniswap), type(uint256).max);
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        ParamCondition[] memory swapConditions = new ParamCondition[](5);
        swapConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.LESS_THAN_OR_EQUAL,
            value: bytes32(uint256(10 ether))
        });
        swapConditions[1] = ParamCondition({
            offset: 36,
            rule: ComparisonRule.GREATER_THAN_OR_EQUAL,
            value: bytes32(uint256(10 ether))
        });
        swapConditions[2] = ParamCondition({
            offset: 196,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(address(dai))))
        });
        swapConditions[3] = ParamCondition({
            offset: 228,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(address(link))))
        });
        swapConditions[4] = ParamCondition({
            offset: 100,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(address(mew))))
        });
        Permission memory swapPerm = Permission({
            target: address(uniswap),
            selector: TestUniswap.swapExactTokensForTokens.selector,
            payableLimit: 0,
            uses: tenUses,
            paramConditions: swapConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, swapPerm);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode call data for swap
        address[] memory paths = new address[](2);
        paths[0] = address(dai);
        paths[1] = address(link);
        bytes memory swapData = abi.encodeWithSelector(
            TestUniswap.swapExactTokensForTokens.selector,
            10 ether,
            10 ether,
            paths,
            address(mew),
            block.timestamp + 1000
        );
        // Create an array of executions
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(uniswap),
            value: 0,
            callData: swapData
        });
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        vm.expectEmit(false, false, false, true);
        emit MockUniswapExchangeEvent(
            10 ether,
            11 ether,
            address(dai),
            address(link)
        );
        // Execute the user operation
        _executeUserOp(userOp);
        assertEq(
            dai.balanceOf(address(mew)),
            90 ether,
            "Wallet DAI balance should decrease by 10 ether"
        );
        assertEq(
            link.balanceOf(address(mew)),
            11 ether,
            "Wallet LINK balance should increase by 11 ether"
        );
    }

    function test_uniswap_swapExactETHForTokens() public {
        // Set up the test environment
        _testSetup();
        TestWETH weth = new TestWETH();
        TestERC20 dai = new TestERC20();
        uniswap = new TestUniswap(weth);
        // Swap ETH for WETH
        weth.deposit{value: 10 ether}();
        // Approve Uniswap to spend tokens
        weth.approve(address(uniswap), type(uint256).max);
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        ParamCondition[] memory swapConditions = new ParamCondition[](4);
        swapConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.GREATER_THAN_OR_EQUAL,
            value: bytes32(uint256(10 ether))
        });
        swapConditions[1] = ParamCondition({
            offset: 164,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(address(weth))))
        });
        swapConditions[2] = ParamCondition({
            offset: 196,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(address(dai))))
        });
        swapConditions[3] = ParamCondition({
            offset: 68,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(address(mew))))
        });
        Permission memory swapPerm = Permission({
            target: address(uniswap),
            selector: TestUniswap.swapExactETHForTokens.selector,
            payableLimit: 10 ether,
            uses: tenUses,
            paramConditions: swapConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, swapPerm);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode call data for swap
        address[] memory paths = new address[](2);
        paths[0] = address(weth);
        paths[1] = address(dai);
        bytes memory swapData = abi.encodeWithSelector(
            TestUniswap.swapExactETHForTokens.selector,
            10 ether,
            paths,
            address(mew),
            block.timestamp + 1000
        );
        // Create an array of executions
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(uniswap),
            value: 10 ether,
            callData: swapData
        });
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        vm.expectEmit(false, false, false, true);
        emit MockUniswapExchangeEvent(
            10 ether,
            11 ether,
            address(weth),
            address(dai)
        );
        // Execute the user operation
        _executeUserOp(userOp);
        assertEq(
            weth.balanceOf(address(mew)),
            10 ether,
            "Wallet WETH balance should decrease by 10 ether"
        );
        assertEq(
            dai.balanceOf(address(mew)),
            11 ether,
            "Wallet LINK balance should increase by 11 ether"
        );
    }

    /*//////////////////////////////////////////////////////////////
                             NFT PURCHASE
    //////////////////////////////////////////////////////////////*/

    function test_buyingNFT() public {
        // Set up the test environment
        _testSetup();
        TestERC721 nft = new TestERC721();
        // Set up a session key and permissions
        (
            SessionData memory sd,
            Permission[] memory perms
        ) = _getDefaultSessionKeyAndPermissions(sessionKeyAddr);
        sessionKeyValidator.enableSessionKey(sd, perms);
        ParamCondition[] memory mintConditions = new ParamCondition[](1);
        mintConditions[0] = ParamCondition({
            offset: 4,
            rule: ComparisonRule.EQUAL,
            value: bytes32(uint256(uint160(address(alice))))
        });
        Permission memory mintPerm = Permission({
            target: address(nft),
            selector: TestERC721.purchaseNFTToWallet.selector,
            payableLimit: 0.05 ether,
            uses: tenUses,
            paramConditions: mintConditions
        });
        sessionKeyValidator.addPermission(sessionKeyAddr, mintPerm);
        // Create an array of execution validations
        ExecutionValidation[]
            memory execValidations = new ExecutionValidation[](1);
        execValidations[0] = _setupExecutionValidation(uint48(1), uint48(3));
        // Encode call data for swap
        bytes memory mintData = abi.encodeWithSelector(
            TestERC721.purchaseNFTToWallet.selector,
            address(alice)
        );
        // Create an array of executions
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(nft),
            value: 0.05 ether,
            callData: mintData
        });
        // Set up a batch user operation
        PackedUserOperation memory userOp = _setupBatchUserOp(
            address(mew),
            executions,
            execValidations,
            sessionKeyPrivate
        );
        // Get initial native balance of wallet
        uint256 balance = address(mew).balance;
        // Expect the NFT purchased event to be emitted
        vm.expectEmit(true, true, false, true);
        emit TestNFTPuchased(address(mew), address(alice), 1);
        // Execute the user operation
        _executeUserOp(userOp);
        // Varify that Alice has been minted NFT and that address(mew) paid for it
        assertEq(nft.balanceOf(address(alice)), 1, "Alice should have NFT");
        // Lt as tx cost
        assertLt(address(mew).balance, balance - 0.05 ether);
    }
}
