// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../../../src/modular-etherspot-wallet/modules/validators/SessionKeyValidator.sol";
import "../../../src/modular-etherspot-wallet/modules/validators/MultipleOwnerECDSAValidator.sol";
import "../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import "../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import "../../../src/modular-etherspot-wallet/modules/executors/ERC20Actions.sol";
import "../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";
import {PackedUserOperation} from "../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {VALIDATION_FAILED} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Module.sol";
import "../TestAdvancedUtils.t.sol";
import "../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {Bootstrap} from "../../../src/modular-etherspot-wallet/erc7579-ref-impl/utils/Bootstrap.sol";
import {IEntryPoint} from "../../../account-abstraction/contracts/interfaces/IEntryPoint.sol";
import {TestUniswapAction} from "../../../src/modular-etherspot-wallet/test/TestUniswapAction.sol";

using ERC4337Utils for IEntryPoint;

contract GenericSessionKeyValidatorTest is TestAdvancedUtils {
    using ECDSA for bytes32;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                  VARIABLES               */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    address constant ENTRYPOINT_ADDR =
        0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    address public constant UNISWAP_SWAP_ROUTER =
        0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant MAINNET_DAI_HOLDER =
        0x837c20D568Dfcd35E74E5CC0B8030f9Cebe10A28;
    uint24 public constant POOL_FEE = 3000;

    ModularEtherspotWallet mew;
    SessionKeyValidator validator;
    TestERC20 erc20;
    ERC20Actions erc20Action;
    ISwapRouter swapRouter;
    IERC20 daiToken;
    IERC20 wethToken;
    IEntryPoint ep;
    TestUniswapAction uniswapAction;

    address alice;
    uint256 aliceKey;
    address bob;
    uint256 bobKey;
    address payable beneficiary;
    address sessionKeyAddr;
    uint256 sessionKeyPrivate;
    address sessionKey1Addr;
    uint256 sessionKey1Private;
    address dummyTarget;

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                   EVENTS                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    event SKV_ModuleInstalled(address wallet);
    event SKV_ModuleUninstalled(address wallet);
    event SKV_SessionKeyEnabled(address sessionKey, address wallet);
    event SKV_SessionKeyDisabled(address sessionKey, address wallet);
    event SKV_SessionKeyPaused(address sessionKey, address wallet);
    event SKV_SessionKeyUnpaused(address sessionKey, address wallet);

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*             HELPER FUNCTIONS              */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function _getPrevValidator(
        address _validator
    ) internal view returns (address) {
        // presuming that wallet wont have gt 20 different validators installed
        for (uint256 i = 1; i < 20; i++) {
            (address[] memory validators, ) = mew.getValidatorPaginated(
                address(0x1),
                i
            );
            if (validators[validators.length - 1] == _validator) {
                return validators[validators.length - 2];
            }
        }
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    SETUP                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function setUp() public override {
        super.setUp();
        mainnetFork = vm.createFork(vm.envString("ETHEREUM_RPC_URL"));
        ep = EntryPoint(payable(ENTRYPOINT_ADDR));
        swapRouter = ISwapRouter(UNISWAP_SWAP_ROUTER);
        daiToken = IERC20(DAI);
        wethToken = IERC20(WETH);
        validator = new SessionKeyValidator();
        (sessionKeyAddr, sessionKeyPrivate) = makeAddrAndKey("session_key");
        (sessionKey1Addr, sessionKey1Private) = makeAddrAndKey("session_key_1");
        (alice, aliceKey) = makeAddrAndKey("alice");
        (bob, bobKey) = makeAddrAndKey("bob");
        dummyTarget = address(makeAddr("dummy_target"));
        beneficiary = payable(address(makeAddr("beneficiary")));
        vm.deal(beneficiary, 1 ether);
    }

    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/
    /*                    TESTS                  */
    /*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*§*/

    function test_selectFork() public {
        vm.selectFork(mainnetFork);
        assertEq(vm.activeFork(), mainnetFork);
    }

    function test_installModule() public {
        mew = setupMEW();
        vm.startPrank(owner1);
        // install another validator module for total of 3
        Execution[] memory batchCall1 = new Execution[](1);
        batchCall1[0].target = address(mew);
        batchCall1[0].value = 0;
        batchCall1[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(genericSessionKeyValidator),
            hex""
        );
        // check emitted event
        vm.expectEmit(false, false, false, true);
        emit SKV_ModuleInstalled(address(mew));
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall1);
        // should be 3 validator modules installed
        assertTrue(
            mew.isModuleInstalled(1, address(genericSessionKeyValidator), "")
        );
    }

    function test_uninstallModule() public {
        mew = setupMEWWithGenericSessionKeys();
        vm.startPrank(address(mew));
        // install another validator module for total of 3
        Execution[] memory batchCall1 = new Execution[](1);
        batchCall1[0].target = address(mew);
        batchCall1[0].value = 0;
        batchCall1[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(defaultValidator),
            hex""
        );
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall1);
        // should be 3 validator modules installed
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertTrue(
            mew.isModuleInstalled(1, address(genericSessionKeyValidator), "")
        );
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        // check associated session keys == 1
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            erc20.approve.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        genericSessionKeyValidator.enableSessionKey(sessionData);
        assertEq(
            genericSessionKeyValidator.getAssociatedSessionKeys().length,
            1
        );
        // get previous validator to pass into uninstall
        // required for linked list
        address prevValidator = _getPrevValidator(
            address(genericSessionKeyValidator)
        );
        // uninstall session key validator
        Execution[] memory batchCall2 = new Execution[](1);
        batchCall2[0].target = address(mew);
        batchCall2[0].value = 0;
        batchCall2[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.uninstallModule.selector,
            uint256(1),
            address(genericSessionKeyValidator),
            abi.encode(prevValidator, hex"")
        );
        // check emitted event
        vm.expectEmit(false, false, false, true);
        emit SKV_ModuleUninstalled(address(mew));
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall2);
        // check session key validator is uninstalled
        assertTrue(mew.isModuleInstalled(1, address(ecdsaValidator), ""));
        assertFalse(
            mew.isModuleInstalled(1, address(genericSessionKeyValidator), "")
        );
        assertTrue(mew.isModuleInstalled(1, address(defaultValidator), ""));
        assertFalse(genericSessionKeyValidator.isInitialized(address(mew)));
        assertEq(
            genericSessionKeyValidator.getAssociatedSessionKeys().length,
            0
        );
        vm.stopPrank();
    }

    function test_pass_enableSessionKey() public {
        vm.startPrank(alice);
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        // check emitted event
        vm.expectEmit(false, false, false, true);
        emit SKV_SessionKeyEnabled(sessionKeyAddr, address(alice));
        validator.enableSessionKey(sessionData);
        // Session should be enabled
        assertFalse(
            validator.getSessionKeyData(sessionKeyAddr).validUntil == 0
        );
        vm.stopPrank();
    }

    function test_fail_enableSessionKey_InvalidSessionKey_SessionKeyZeroAddress()
        public
    {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            address(0),
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidSessionKey.selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_SessionKeyAlreadyExists() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_SessionKeyAlreadyExists.selector,
                sessionKeyAddr
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_InvalidTarget() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(0),
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidTarget.selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_InvalidFunctionSelector() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            bytes4(0),
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidFunctionSelector.selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_InvalidSpendingLimit() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(0),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidSpendingLimit.selector
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_fail_enableSessionKey_InvalidDuration() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp),
            uint48(block.timestamp)
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                SessionKeyValidator.SKV_InvalidDuration.selector,
                block.timestamp,
                block.timestamp
            )
        );
        validator.enableSessionKey(sessionData);
    }

    function test_pass_disableSessionKey() public {
        vm.startPrank(alice);
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        assertEq(validator.getAssociatedSessionKeys().length, 1);
        // Session should be enabled
        assertFalse(
            validator.getSessionKeyData(sessionKeyAddr).validUntil == 0
        );
        // check emitted event
        vm.expectEmit(false, false, false, true);
        emit SKV_SessionKeyDisabled(sessionKeyAddr, address(alice));

        // Disable session
        validator.disableSessionKey(sessionKeyAddr);
        // Session should now be disabled
        assertTrue(validator.getSessionKeyData(sessionKeyAddr).validUntil == 0);
        assertEq(validator.getAssociatedSessionKeys().length, 0);
        vm.stopPrank();
    }

    function test_pass_rotateSessionKey() public {
        // Enable session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        assertFalse(
            validator.getSessionKeyData(sessionKeyAddr).validUntil == 0
        );
        // Rotate session key
        bytes memory newSessionData = abi.encodePacked(
            sessionKey1Addr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(2),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        validator.rotateSessionKey(sessionKeyAddr, newSessionData);
        assertFalse(
            validator.getSessionKeyData(sessionKey1Addr).validUntil == 0
        );
        assertTrue(validator.getSessionKeyData(sessionKeyAddr).validUntil == 0);
    }

    function test_pass_toggleSessionKeyPause() public {
        // Enable session
        vm.startPrank(alice);
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        validator.enableSessionKey(sessionData);
        // Session should be enabled
        assertFalse(validator.checkSessionKeyPaused(sessionKeyAddr));
        // Disable session
        vm.expectEmit(false, false, false, true);
        emit SKV_SessionKeyPaused(sessionKeyAddr, alice);
        validator.toggleSessionKeyPause(sessionKeyAddr);
        // Session should now be disabled
        assertTrue(validator.checkSessionKeyPaused(sessionKeyAddr));
        vm.expectEmit(false, false, false, true);
        emit SKV_SessionKeyUnpaused(sessionKeyAddr, alice);
        validator.toggleSessionKeyPause(sessionKeyAddr);
        vm.stopPrank();
    }

    function test_pass_getAssociatedSessionKeys() public {
        bytes memory sessionData1 = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            uint48(block.timestamp + 1),
            uint48(block.timestamp + 1 days)
        );
        bytes memory sessionData2 = abi.encodePacked(
            sessionKey1Addr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(2),
            uint48(block.timestamp + 2 days),
            uint48(block.timestamp + 3 days)
        );
        validator.enableSessionKey(sessionData1);
        validator.enableSessionKey(sessionData2);
        address[] memory sessionKeys = validator.getAssociatedSessionKeys();
        assertEq(sessionKeys.length, 2);
    }

    function test_pass_getSessionKeyData() public {
        uint48 validAfter = uint48(block.timestamp);
        uint48 validUntil = uint48(block.timestamp + 1 days);

        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            dummyTarget,
            IERC20.transferFrom.selector,
            uint256(100),
            validAfter,
            validUntil
        );

        validator.enableSessionKey(sessionData);
        SessionKeyValidator.GenericSessionData memory data = validator
            .getSessionKeyData(sessionKeyAddr);
        assertEq(data.target, dummyTarget);
        assertEq(data.selector, IERC20.transferFrom.selector);
        assertEq(data.validAfter, validAfter);
        assertEq(data.validUntil, validUntil);
    }

    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /// TESTS BELOW HERE ARE BROKEN  ////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////
    /////////////////////////////////////

    // Current status of test_pass_validateUserOp:
    // transferring DAI tokens to the fallback handler (TestUniswapAction)
    // from the wallet causes test to work
    // not sure if this is exactly testing the validation of the UserOp though
    // SwapRouter tries to transfer tokens from the TestUniswapAction contract
    // if we dont transfer tokens, we get an STF error from Uniswap
    // Also we dont check the target address in verifySessionKeyParams

    function test_pass_validateUserOp() public {
        // start fork
        vm.selectFork(mainnetFork);
        // roll fork to a block
        vm.rollFork(20121000);
        // setups up deploying all required contracts on fork and deploys new MEW
        mew = setupMainnetForkDeployementAndCreateAccount();
        // deploys fallback for Uniswap swap
        uniswapAction = new TestUniswapAction();
        // pranks holder of DAI on mainnet fork to transfer tokens to MEW
        vm.prank(address(MAINNET_DAI_HOLDER));
        daiToken.transferFrom(MAINNET_DAI_HOLDER, address(mew), 10 ether);
        // check DAI tokens trasnferred successfully
        uint256 mewDaiBalance = daiToken.balanceOf(address(mew));
        console2.log("DAI balance (should be 10):", mewDaiBalance / 1e18);
        // prank created MEW
        vm.startPrank(address(mew));
        // approve this contract to spend DAI
        daiToken.approve(address(this), 2 ether);
        vm.stopPrank();
        // prank the TestUniswapAction contract to approve SwapRouter to transfer tokens from it
        // transfer DAI from MEW to TestUniswapAction contract for swapping
        // not sure about whether this approach is correct for testing
        vm.prank(address(uniswapAction));
        daiToken.approve(address(swapRouter), 2 ether);
        IERC20(DAI).transferFrom(address(mew), address(uniswapAction), 2 ether);
        // prank created MEW
        vm.startPrank(address(mew));
        // setup and install Uniswap Fallback handler
        address[] memory allowedCallers = new address[](1);
        allowedCallers[0] = address(ep);

        mew.installModule(
            MODULE_TYPE_FALLBACK,
            address(uniswapAction),
            abi.encode(
                TestUniswapAction.swapSingle.selector,
                CALLTYPE_SINGLE,
                allowedCallers,
                ""
            )
        );

        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(swapRouter),
            TestUniswapAction.swapSingle.selector,
            uint256(1 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        genericSessionKeyValidator.enableSessionKey(sessionData);

        // generate Uniswap SwapRouter params
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(daiToken),
                tokenOut: address(wethToken),
                fee: POOL_FEE,
                recipient: address(mew),
                deadline: block.timestamp + 50000,
                amountIn: 1 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            TestUniswapAction.swapSingle.selector,
            address(swapRouter),
            swapParams
        );

        PackedUserOperation memory userOp = getDefaultUserOp();
        userOp.sender = address(mew);
        userOp.callData = data;
        userOp.nonce = getNonce(
            address(mew),
            address(genericSessionKeyValidator)
        );
        bytes32 hash = ep.getUserOpHash(userOp);
        // sign with session key private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        userOp.signature = signature;

        // Validation should succeed
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        ep.handleOps(userOps, beneficiary);
        // check DAI and WETH tokens transferred successfully
        uint256 mewDaiBalanceAfter = daiToken.balanceOf(address(mew));
        uint256 mewWethBalance = wethToken.balanceOf(address(mew));
        assertEq(mewDaiBalanceAfter, 8 ether);
        assertGt(mewWethBalance, 0); // > 0 as not sure on amount of WETH received
        // possibly can check using events emitted from Uniswap SwapRouter
    }

    ////////////////////////////////////
    ////////////////////////////////////
    // TODO: BELOW STILL TO BE TESTED //
    ////////////////////////////////////
    ////////////////////////////////////
    function test_fail_validateUserOp_invalidSessionKey() public {
        // start fork
        vm.selectFork(mainnetFork);
        mew = setupMainnetForkDeployementAndCreateAccount();

        vm.prank(address(MAINNET_DAI_HOLDER));
        daiToken.transfer(address(mew), 100 ether);
        uint256 mewDaiBalance = daiToken.balanceOf(address(mew));
        console2.log("DAI balance (should be 100):", mewDaiBalance / 1e18);
        vm.startPrank(address(mew));

        // approve this contract to spend DAI
        IERC20(DAI).approve(address(this), 50 ether);

        // address[] memory allowedCallers = new address[](2);
        // allowedCallers[0] = address(entrypoint);
        // allowedCallers[1] = address(mew);

        // mew.installModule(
        //     MODULE_TYPE_FALLBACK,
        //     address(erc20Action),
        //     abi.encode(
        //         ERC20Actions.transferERC20Action.selector,
        //         CALLTYPE_SINGLE,
        //         allowedCallers,
        //         ""
        //     )
        // );

        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(swapRouter),
            ISwapRouter.exactInputSingle.selector,
            uint256(50 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );

        genericSessionKeyValidator.enableSessionKey(sessionData);
        // Construct user op data
        // generate Uniswap SwapRouter params
        ISwapRouter.ExactInputSingleParams memory swapParams = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(daiToken),
                tokenOut: address(wethToken),
                fee: POOL_FEE,
                recipient: address(mew),
                deadline: block.timestamp,
                amountIn: 50 ether,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        // Construct user op data
        bytes memory data = abi.encodeWithSelector(
            ISwapRouter.exactInputSingle.selector,
            swapParams
        );

        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            data
        );
        userOp.nonce = getNonce(
            address(mew),
            address(genericSessionKeyValidator)
        );
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        // Validation should fail
        genericSessionKeyValidator.disableSessionKey(sessionKeyAddr);
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }

    function test_fail_validateUserOp_invalidFunctionSelector() public {
        mew = setupMainnetForkDeployementAndCreateAccount();
        vm.startPrank(address(mew));
        // Enable valid session
        bytes memory sessionData = abi.encodePacked(
            sessionKeyAddr,
            address(swapRouter),
            ISwapRouter.exactInputSingle.selector,
            uint256(50 ether),
            uint48(block.timestamp),
            uint48(block.timestamp + 1 days)
        );
        genericSessionKeyValidator.enableSessionKey(sessionData);
        // Construct invalid selector user op data
        bytes memory data = abi.encodeWithSelector(
            IERC20.transferFrom.selector,
            address(erc20),
            address(bob),
            address(mew),
            uint256(5 ether)
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            address(mew),
            data
        );
        address sessionKeyValidatorAddr = address(genericSessionKeyValidator);
        userOp.nonce = uint256(uint160(sessionKeyValidatorAddr)) << 96;
        bytes32 hash = entrypoint.getUserOpHash(userOp);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            sessionKeyPrivate,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        vm.expectRevert(
            abi.encodeWithSelector(
                IEntryPoint.FailedOp.selector,
                0,
                "AA24 signature error"
            )
        );
        entrypoint.handleOps(userOps, beneficiary);
    }
}
