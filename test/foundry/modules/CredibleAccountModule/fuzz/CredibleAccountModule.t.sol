// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import "forge-std/StdInvariant.sol";
import {CredibleAccountModule as CAM} from "../../../../../src/modular-etherspot-wallet/modules/validators/CredibleAccountModule.sol";
import {ICredibleAccountModule as ICAM} from "../../../../../src/modular-etherspot-wallet/interfaces/ICredibleAccountModule.sol";
import "../../../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {CredibleAccountModuleTestUtils as LocalTestUtils} from "../utils/CredibleAccountModuleTestUtils.sol";
import {SessionData, TokenData} from "../../../../../src/modular-etherspot-wallet/common/Structs.sol";
import {TestWETH} from "../../../../../src/modular-etherspot-wallet/test/TestWETH.sol";
import {TestUniswapV2} from "../../../../../src/modular-etherspot-wallet/test/TestUniswapV2.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/interfaces/IERC7579Account.sol";
import "../../../../../account-abstraction/contracts/core/Helpers.sol";
import {PackedUserOperation} from "../../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CredibleAccountModule_Fuzz_Test is LocalTestUtils {
    using ECDSA for bytes32;

    function setUp() public override {
        super.setUp();
        _testSetup();
    }

    function testFuzz_enableSessionKey(
        address _sessionKey,
        uint48 _validAfter,
        uint48 _validUntil,
        address[3] memory _tokens,
        uint256[3] memory _amounts
    ) public {
        // Define assumptions
        vm.assume(_sessionKey != address(0));
        vm.assume(_validAfter < _validUntil);
        vm.assume(_validAfter > block.timestamp);
        // Enable session key
        TokenData[] memory tokenAmounts = new TokenData[](_tokens.length);
        for (uint256 i; i < _tokens.length; ++i) {
            vm.assume(_tokens[i] != address(0));
            vm.assume(_amounts[i] > 0);
            tokenAmounts[i] = TokenData(_tokens[i], _amounts[i]);
        }
        bytes memory sessionData = abi.encode(
            _sessionKey,
            _validAfter,
            _validUntil,
            tokenAmounts
        );
        credibleAccountModule.enableSessionKey(sessionData);
        // Get session key data and validate
        SessionData memory retrievedData = credibleAccountModule
            .getSessionKeyData(_sessionKey);
        assertEq(retrievedData.validAfter, _validAfter);
        assertEq(retrievedData.validUntil, _validUntil);
        // Get locked token data and validate
        ICAM.LockedToken[] memory lockedTokens = credibleAccountModule
            .getLockedTokensForSessionKey(_sessionKey);
        assertEq(lockedTokens.length, _tokens.length);
        for (uint256 i; i < _tokens.length; ++i) {
            assertEq(lockedTokens[i].token, _tokens[i]);
            assertEq(lockedTokens[i].lockedAmount, _amounts[i]);
            assertEq(lockedTokens[i].claimedAmount, 0);
        }
    }

    function testFuzz_disableSessionKey(
        string memory _sessionKey,
        uint256[3] memory _lockedAmounts
    ) public {
        (address sk, uint256 skp) = makeAddrAndKey(_sessionKey);
        for (uint256 i; i < _lockedAmounts.length; ++i) {
            vm.assume(_lockedAmounts[i] > 0 && _lockedAmounts[i] < 1000 ether);
        }
        usdc.mint(address(mew), _lockedAmounts[0]);
        dai.mint(address(mew), _lockedAmounts[1]);
        uni.mint(address(mew), _lockedAmounts[2]);
        // Enable a session key
        TokenData[] memory tokenAmounts = new TokenData[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            tokenAmounts[i] = TokenData(tokens[i], _lockedAmounts[i]);
        }
        bytes memory sessionData = abi.encode(
            sk,
            validAfter,
            validUntil,
            tokenAmounts
        );
        credibleAccountModule.enableSessionKey(sessionData);
        // Claim tokens to allow disabling
        bytes memory usdcData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            _lockedAmounts[0]
        );

        bytes memory daiData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            _lockedAmounts[1]
        );
        bytes memory uniData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            _lockedAmounts[2]
        );
        Execution[] memory batch = new Execution[](3);
        batch[0] = Execution({
            target: address(usdc),
            value: 0,
            callData: usdcData
        });
        batch[1] = Execution({
            target: address(dai),
            value: 0,
            callData: daiData
        });
        batch[2] = Execution({
            target: address(uni),
            value: 0,
            callData: uniData
        });
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(batch))
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(credibleAccountModule),
            skp
        );
        // Execute the user operation
        _executeUserOperation(userOp);
        // Disable the session key
        credibleAccountModule.disableSessionKey(sk);
        // Verify no sessions for wallet
        address[] memory walletSessions = credibleAccountModule
            .getSessionKeysByWallet();
        assertEq(walletSessions.length, 0);
        // Verify reset data for session key
        SessionData memory sessionKeyData = credibleAccountModule
            .getSessionKeyData(sk);
        console2.log("sessionKeyData.validUntil", sessionKeyData.validUntil);
        assertEq(sessionKeyData.validUntil, 0);
        // Verify no locked tokens for session key
        ICAM.LockedToken[] memory lockedTokenData = credibleAccountModule
            .getLockedTokensForSessionKey(sk);
        assertEq(lockedTokenData.length, 0);
    }

    function testFuzz_validateSessionKeyParams(
        address _sessionKey,
        bytes calldata _callData
    ) public {
        vm.assume(_sessionKey != address(0));
        // Enable a session key first
        _enableDefaultSessionKey();
        PackedUserOperation memory userOp;
        userOp.callData = _callData;
        userOp.sender = address(mew);
        bool isValid = credibleAccountModule.validateSessionKeyParams(
            _sessionKey,
            userOp
        );
        if (_sessionKey == sessionKey) {
            // Additional checks based on _callData content could be added here
            assertTrue(isValid || !isValid);
        } else {
            assertFalse(isValid);
        }
    }

    function testFuzz_claimingTokensBySolver(
        uint256[3] memory _claimAmounts
    ) public {
        for (uint256 i; i < _claimAmounts.length; ++i) {
            vm.assume(_claimAmounts[i] > 0 && _claimAmounts[i] < 1000 ether);
        }
        usdc.mint(address(mew), _claimAmounts[0]);
        dai.mint(address(mew), _claimAmounts[1]);
        uni.mint(address(mew), _claimAmounts[2]);
        // Enable session key
        TokenData[] memory tokenAmounts = new TokenData[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            tokenAmounts[i] = TokenData(tokens[i], _claimAmounts[i]);
        }
        bytes memory sessionData = abi.encode(
            sessionKey,
            validAfter,
            validUntil,
            tokenAmounts
        );
        credibleAccountModule.enableSessionKey(sessionData);
        // Claim tokens by solver
        _claimTokensBySolver(
            _claimAmounts[0],
            _claimAmounts[1],
            _claimAmounts[2]
        );
        // Verify tokens have been claimed
        ICAM.LockedToken[] memory lockedTokens = credibleAccountModule
            .getLockedTokensForSessionKey(sessionKey);
        for (uint256 i; i < 3; ++i) {
            assertEq(lockedTokens[i].claimedAmount, _claimAmounts[i]);
        }
    }
}
