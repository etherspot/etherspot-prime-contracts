// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../src/modular-etherspot-wallet/modules/validators/TokenLockSessionKeyValidator.sol";
import "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import "../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import "../../../src/modular-etherspot-wallet/test/TestUSDC.sol";
import "../../../src/modular-etherspot-wallet/test/TestDAI.sol";
import "../../../src/modular-etherspot-wallet/test/TestUNI.sol";
import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {VALIDATION_FAILED} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../TestAdvancedUtils.t.sol";
import "../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";

using ERC4337Utils for IEntryPoint;

contract TokenLockSessionKeyValidatorTest is TestAdvancedUtils {
    using ECDSA for bytes32;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                  VARIABLES               */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    ModularEtherspotWallet mew;
    TokenLockSessionKeyValidator tokenLockSessionKeyValidator;
    TestERC20 erc20;
    TestUSDC usdc;
    TestDAI dai;
    TestUNI uni;

    address alice;
    uint256 aliceKey;
    address bob;
    uint256 bobKey;
    address solver;
    uint256 solverKey;
    address payable beneficiary;
    address sessionKeyAddr;
    uint256 sessionKeyPrivate;
    address sessionKey1Addr;
    uint256 sessionKey1Private;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   EVENTS                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    event TLSKV_ModuleInstalled(address wallet);
    event TLSKV_ModuleUninstalled(address wallet);
    event TLSKV_SessionKeyEnabled(address sessionKey, address wallet);
    event TLSKV_SessionKeyDisabled(address sessionKey, address wallet);
    event TLSKV_SessionKeyPaused(address sessionKey, address wallet);
    event TLSKV_SessionKeyUnpaused(address sessionKey, address wallet);

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*             HELPER FUNCTIONS              */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function _getPrevValidator(
        address _validator
    ) internal view returns (address) {
        (address[] memory validators, ) = mew.getValidatorPaginated(
                address(0x1),
                10
            );
        // Presuming that wallet wont have gt 20 different validators installed
        for (uint256 i = 1; i < 20; i++) {
            if (validators[i] == _validator) {
                return validators[i - 1];
            }
        }
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    SETUP                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function setUp() public override {
        super.setUp();
        tokenLockSessionKeyValidator = new TokenLockSessionKeyValidator();
        erc20 = new TestERC20();
        usdc = new TestUSDC();
        dai = new TestDAI();
        uni = new TestUNI();

        (sessionKeyAddr, sessionKeyPrivate) = makeAddrAndKey("session_key");
        (sessionKey1Addr, sessionKey1Private) = makeAddrAndKey("session_key_1");
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
        (solver, solverKey) = makeAddrAndKey("solver");
        beneficiary = payable(address(makeAddr("beneficiary")));
        vm.deal(beneficiary, 1 ether);
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    TESTS                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function test_install_TKSKV_Module() public {
        mew = setupMEW();
        vm.startPrank(owner1);
        // Install another tokenLockSessionKeyValidator module for total of 3
        Execution[] memory batchCall1 = new Execution[](1);
        batchCall1[0].target = address(mew);
        batchCall1[0].value = 0;
        batchCall1[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(tokenLockSessionKeyValidator),
            hex""
        );
        // Check emitted event
        vm.expectEmit(false, false, false, true);
        emit TLSKV_ModuleInstalled(address(mew));
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall1);
        assertTrue(mew.isModuleInstalled(1, address(tokenLockSessionKeyValidator), ""));
    }

    function test_Uninstall_TKSKV_Module() public {
        mew = setupMEWWithSessionKeys();
        vm.startPrank(address(mew));
        // Install another tokenLockSessionKeyValidator module for total of 3
       
        Execution[] memory batchCall1 = new Execution[](1);
        batchCall1[0].target = address(mew);
        batchCall1[0].value = 0;
        batchCall1[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(tokenLockSessionKeyValidator),
            hex""
        );
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall1);

        Execution[] memory batchCall0 = new Execution[](1);
        batchCall0[0].target = address(mew);
        batchCall0[0].value = 0;
        batchCall0[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(defaultValidator),
            hex""
        );
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall0);

        // Should be 3 Validator modules installed
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(tokenLockSessionKeyValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        
        address[] memory tokens = new address[](3);
        tokens[0] = address(usdc);
        tokens[1] = address(dai);
        tokens[2] = address(uni);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 * 10**6;
        amounts[1] = 200 * 10**18;
        amounts[2] = 300 * 10**18;

        uint48 validAfter = uint48(block.timestamp);
        uint48 validUntil = uint48(block.timestamp + 1 days);

        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            solver,
            IERC20.transfer.selector,
            validAfter,
            validUntil,
            tokens.length,
            tokens,
            amounts.length,
            amounts
        );

        tokenLockSessionKeyValidator.enableSessionKey(sessionData);
        assertEq(tokenLockSessionKeyValidator.getAssociatedSessionKeys().length, 1);

        // Get previous tokenLockSessionKeyValidator to pass into uninstall (required for linked list)
        address prevValidator = _getPrevValidator(address(tokenLockSessionKeyValidator));
        // Uninstall session key tokenLockSessionKeyValidator
        Execution[] memory batchCall2 = new Execution[](1);
        batchCall2[0].target = address(mew);
        batchCall2[0].value = 0;
        batchCall2[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.uninstallModule.selector,
            uint256(1),
            address(tokenLockSessionKeyValidator),
            abi.encode(prevValidator, hex"")
        );
        // Check emitted event
        vm.expectEmit(false, false, false, true);
        emit TLSKV_ModuleUninstalled(address(mew));
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall2);
        // Check session key tokenLockSessionKeyValidator is uninstalled
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertFalse(mew.isModuleInstalled(1, address(tokenLockSessionKeyValidator), ""));
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        assertFalse(tokenLockSessionKeyValidator.isInitialized(address(mew)));
        assertEq(tokenLockSessionKeyValidator.getAssociatedSessionKeys().length, 0);
        vm.stopPrank();
    }

    function test_pass_TLSKV_enableSessionKey() public {
        vm.startPrank(alice);

        address[] memory tokens = new address[](3);
        tokens[0] = address(usdc);
        tokens[1] = address(dai);
        tokens[2] = address(uni);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 * 10**6;
        amounts[1] = 200 * 10**18;
        amounts[2] = 300 * 10**18;

        uint48 validAfter = uint48(block.timestamp);
        uint48 validUntil = uint48(block.timestamp + 1 days);

        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            solver,
            IERC20.transfer.selector,
            validAfter,
            validUntil,
            tokens.length,
            tokens,
            amounts.length,
            amounts
        );
        // Check emitted event
        vm.expectEmit(false, false, false, true);
        emit TLSKV_SessionKeyEnabled(sessionKeyAddr, address(alice));
        tokenLockSessionKeyValidator.enableSessionKey(sessionData);
        // Session should be enabled
        assertFalse(
            tokenLockSessionKeyValidator.getSessionKeyData(sessionKeyAddr).validUntil == 0
        );
        vm.stopPrank();
    }

    function test_pass_TLSKV_validateUserOp() public {
        mew = setupMEW();

        vm.startPrank(owner1);
        // Install another tokenLockSessionKeyValidator module for total of 3
        Execution[] memory batchCall1 = new Execution[](1);
        batchCall1[0].target = address(mew);
        batchCall1[0].value = 0;
        batchCall1[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(tokenLockSessionKeyValidator),
            hex""
        );
        // Check emitted event
        vm.expectEmit(false, false, false, true);
        emit TLSKV_ModuleInstalled(address(mew));
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall1);
        vm.stopPrank();

        // Enable valid session
        
        address[] memory tokens = new address[](3);
        tokens[0] = address(usdc);
        tokens[1] = address(dai);
        tokens[2] = address(uni);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = 100 * 10**6;
        amounts[1] = 200 * 10**18;
        amounts[2] = 300 * 10**18;

        vm.deal(address(mew), 1 ether);
        vm.startPrank(address(mew));
        
        usdc.mint(address(mew), amounts[0]);
        assertEq(usdc.balanceOf(address(mew)), amounts[0]);
        usdc.approve(address(bob), amounts[0]);
        usdc.approve(address(mew), amounts[0]);

        dai.mint(address(mew), amounts[1]);
        assertEq(dai.balanceOf(address(mew)), amounts[1]);
        dai.approve(address(bob), amounts[1]);

        uni.mint(address(mew), amounts[2]);
        assertEq(uni.balanceOf(address(mew)), amounts[2]);
        uni.approve(address(bob), amounts[2]);

        uint48 validAfter = uint48(block.timestamp);
        uint48 validUntil = uint48(block.timestamp + 1 days);

        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            solver,
            IERC20.transferFrom.selector,
            validAfter,
            validUntil,
            tokens.length,
            tokens,
            amounts.length,
            amounts
        );

        tokenLockSessionKeyValidator.enableSessionKey(sessionData);
        assertEq(tokenLockSessionKeyValidator.getAssociatedSessionKeys().length, 1);

        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(mew),
            address(bob),
            amounts[0]
        );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(address(usdc), uint256(0), data)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            userOpCalldata
        );

        userOp.nonce = getNonce(address(mew), address(tokenLockSessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;
        // Validation should succeed
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        entrypoint.handleOps(userOps, beneficiary);
        assertEq(usdc.balanceOf(address(bob)), amounts[0]);
    }
}
