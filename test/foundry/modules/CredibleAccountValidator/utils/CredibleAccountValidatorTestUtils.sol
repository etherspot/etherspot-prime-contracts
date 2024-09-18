// TODO: WIP

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {ModularEtherspotWallet} from "../../../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {ICredibleAccountValidator} from "../../../../../src/modular-etherspot-wallet/interfaces/ICredibleAccountValidator.sol";
import {CredibleAccountValidatorHarness} from "../../../harnesses/CredibleAccountValidatorHarness.sol";
import {TestERC20} from "../../../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import {TestUSDC} from "../../../../../src/modular-etherspot-wallet/test/TestUSDC.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";
import {PackedUserOperation} from "../../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {CALLTYPE_SINGLE} from "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";
import "../../../TestAdvancedUtils.t.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CredibleAccountValidatorTestUtils is TestAdvancedUtils {
    using ERC4337Utils for IEntryPoint;
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Contract instances
    ModularEtherspotWallet internal mew;
    CredibleAccountValidatorHarness internal credibleAccountValidatorHarness;
    TestERC20 internal dai;
    TestERC20 internal uni;
    TestUSDC internal usdc;
    TestERC20 internal aave;

    // Test addresses and keys
    address internal alice;
    uint256 internal aliceKey;
    address internal sessionKey;
    uint256 internal sessionKeyPrivateKey;
    address internal invalidSessionKey;
    address payable internal immutable beneficiary;
    address payable internal immutable receiver;

    // Test variables
    address internal immutable solver = address(0xdeadbeef);
    uint48 internal validAfter;
    uint48 internal validUntil;
    address[3] internal tokens;
    uint256 internal constant TOKENS_LENGTH = 3;
    uint256[3] internal amounts;
    uint256 internal constant AMOUNTS_LENGTH = 3;

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
        mew = setupMEWWithCredibleAccountValidator();
        credibleAccountValidatorHarness = new CredibleAccountValidatorHarness();
        dai = new TestERC20();
        uni = new TestERC20();
        usdc = new TestUSDC();
        aave = new TestERC20();
        // Set up test addresses and keys
        (alice, aliceKey) = makeAddrAndKey("alice");
        (sessionKey, sessionKeyPrivateKey) = makeAddrAndKey("sessionKey");
        vm.deal(beneficiary, 1 ether);
        vm.startPrank(address(mew));
        // Set up test variables
        validAfter = uint48(block.timestamp);
        validUntil = uint48(block.timestamp + 1 days);
        tokens = [address(usdc), address(dai), address(uni)];
        amounts = [(100 * 10 ** 6), (200 * 10 ** 18), (300 * 10 ** 18)];
    }

    function _getDefaultSessionData(
        bytes4 _functionSelector
    ) internal view returns (bytes memory) {
        return
            abi.encodePacked(
                sessionKey,
                solver,
                _functionSelector,
                validAfter,
                validUntil,
                TOKENS_LENGTH,
                tokens,
                AMOUNTS_LENGTH,
                amounts
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

    function _createTokenTransferFromExecution(
        address _from,
        address _recipient,
        uint256 _amount
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                _from,
                _recipient,
                _amount
            );
    }

    function _enableSessionKeyAndValidate(
        ModularEtherspotWallet _modularWallet,
        bytes4 _functionSelector
    ) public returns (address, ICredibleAccountValidator.SessionData memory) {
        usdc.mint(address(_modularWallet), amounts[0]);
        assertEq(usdc.balanceOf(address(_modularWallet)), amounts[0]);
        usdc.approve(address(_modularWallet), amounts[0]);

        dai.mint(address(_modularWallet), amounts[1]);
        assertEq(dai.balanceOf(address(_modularWallet)), amounts[1]);
        dai.approve(address(_modularWallet), amounts[1]);

        uni.mint(address(_modularWallet), amounts[2]);
        assertEq(uni.balanceOf(address(_modularWallet)), amounts[2]);
        uni.approve(address(_modularWallet), amounts[2]);

        // Enable session
        bytes memory sessionData = _getDefaultSessionData(_functionSelector);
        credibleAccountValidator.enableSessionKey(sessionData);
        ICredibleAccountValidator.SessionData
            memory sessionDataQueried = credibleAccountValidator
                .getSessionKeyData(sessionKey);
        assertEq(credibleAccountValidator.getAssociatedSessionKeys().length, 1);
        assertEq(sessionDataQueried.validUntil, validUntil);
        assertEq(sessionDataQueried.validAfter, validAfter);
        assertEq(sessionDataQueried.funcSelector, _functionSelector);
        assertEq(sessionDataQueried.tokens.length, tokens.length);
        assertEq(sessionDataQueried.amounts.length, amounts.length);
        assertEq(sessionDataQueried.solverAddress, solver);
        assertEq(
            uint256(sessionDataQueried.status),
            uint256(ICredibleAccountValidator.SessionKeyStatus.Live)
        );
        return (sessionKey, sessionDataQueried);
    }

    function _disableSessionKeyAndValidate(
        ModularEtherspotWallet _modularWallet,
        address _sessionKey
    ) public {
        vm.expectEmit(true, true, true, true);
        emit ICredibleAccountValidator
            .CredibleAccountValidator_SessionKeyDisabled(
                _sessionKey,
                address(_modularWallet)
            );
        credibleAccountValidator.disableSessionKey(_sessionKey);
        ICredibleAccountValidator.SessionData
            memory sessionData = credibleAccountValidator.getSessionKeyData(
                _sessionKey
            );
        assertEq(sessionData.validUntil, 0);
        assertEq(sessionData.validAfter, 0);
        assertEq(sessionData.funcSelector, bytes4(0));
        assertEq(sessionData.tokens.length, 0);
        assertEq(sessionData.amounts.length, 0);
    }

    function _createUserOpWithSignature(
        address _account,
        bytes memory _callData,
        uint256 _signerKey
    )
        internal
        view
        returns (PackedUserOperation memory, bytes32, uint8, bytes32, bytes32)
    {
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            _account,
            _callData
        );
        userOp.nonce = getNonce(_account, address(credibleAccountValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _signerKey,
            ECDSA.toEthSignedMessageHash(hash)
        );

        return (userOp, hash, v, r, s);
    }

    function _createUserOperation(
        address _account,
        bytes memory _callData,
        uint256 _signerKey
    ) internal view returns (bytes32, PackedUserOperation memory) {
        (
            PackedUserOperation memory userOp,
            bytes32 hash,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = _createUserOpWithSignature(_account, _callData, _signerKey);

        (
            bytes32 merkleRoot,
            bytes32[] memory merkleProof
        ) = getDummyMerkleRootAndProof();

        // append r, s, v of signature followed by merkleRoot and merkleProof to the signature
        userOp.signature = abi.encodePacked(
            r,
            s,
            v,
            uint48(block.timestamp),
            merkleRoot,
            merkleProof
        );

        return (hash, userOp);
    }

    function _createUserOperationWithInvalidMessageProof(
        address _account,
        bytes memory _callData,
        uint256 _signerKey
    ) internal view returns (bytes32, PackedUserOperation memory) {
        (
            PackedUserOperation memory userOp,
            bytes32 hash,
            uint8 v,
            bytes32 r,
            bytes32 s
        ) = _createUserOpWithSignature(_account, _callData, _signerKey);

        (
            bytes32 merkleRoot,
            bytes32[] memory merkleProof
        ) = getDummyMerkleRootAndProof();

        // append r, s, v of signature followed by merkleRoot and merkleProof to the signature
        userOp.signature = abi.encodePacked(
            r,
            s,
            v,
            uint48(block.timestamp),
            merkleRoot,
            merkleProof
        );

        return (hash, userOp);
    }

    function _executeUserOperation(
        PackedUserOperation memory _userOp
    ) internal {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = _userOp;
        entrypoint.handleOps(userOps, beneficiary);
    }

    function _getPrevValidator(
        address _validator
    ) internal view returns (address) {
        // Presuming that wallet won't have more than 20 different validators installed
        for (uint256 i = 1; i <= 20; i++) {
            (address[] memory validators, ) = mew.getValidatorPaginated(
                address(0x1),
                i
            );
            if (validators.length > 0) {
                if (validators[validators.length - 1] == _validator) {
                    return
                        validators.length > 1
                            ? validators[validators.length - 2]
                            : address(0x1);
                }
            }
        }
        revert("Validator not found");
    }
}
