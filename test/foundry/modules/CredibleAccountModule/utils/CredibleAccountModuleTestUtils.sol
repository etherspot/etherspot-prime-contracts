// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {ModularEtherspotWallet} from "../../../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {CredibleAccountModuleHarness} from "../../../harnesses/CredibleAccountModuleHarness.sol";
import {TokenData} from "../../../../../src/modular-etherspot-wallet/common/Structs.sol";
import {TestERC20} from "../../../../../src/modular-etherspot-wallet/test/TestERC20.sol";
import {TestUSDC} from "../../../../../src/modular-etherspot-wallet/test/TestUSDC.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";
import {PackedUserOperation} from "../../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {CALLTYPE_SINGLE} from "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";
import {HookType} from "../../../../../src/modular-etherspot-wallet/modules/hooks/multiplexer/DataTypes.sol";

import "../../../TestAdvancedUtils.t.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CredibleAccountModuleTestUtils is TestAdvancedUtils {
    using ERC4337Utils for IEntryPoint;
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Contract instances
    ModularEtherspotWallet internal mew;
    CredibleAccountModuleHarness internal harness;
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
    address payable internal immutable dummySessionKey;

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

        dummySessionKey = payable(
            address(
                uint160(uint256(keccak256(abi.encodePacked("dummySessionKey"))))
            )
        );
    }

    function _testSetup() internal {
        // Set up contracts and wallet
        mew = setupMEWWithEmptyHookMultiplexer();
        harness = new CredibleAccountModuleHarness(
            address(proofVerifier),
            address(hookMultiPlexer)
        );
        dai = new TestERC20();
        uni = new TestERC20();
        usdc = new TestUSDC();
        aave = new TestERC20();
        // Set up test addresses and keys
        (alice, aliceKey) = makeAddrAndKey("alice");
        (sessionKey, sessionKeyPrivateKey) = makeAddrAndKey("sessionKey");
        vm.deal(beneficiary, 1 ether);
        _addCredibleAccountModuleAsSubHook();
        _installCredibleAccountModuleAsValidator();
        vm.startPrank(address(mew));
        // Set up test variables
        validAfter = uint48(block.timestamp);
        validUntil = uint48(block.timestamp + 1 days);
        tokens = [address(usdc), address(dai), address(uni)];
        amounts = [100e6, 200e18, 300e18];
        // Mint and approve tokens
        usdc.mint(address(mew), amounts[0]);
        usdc.approve(address(mew), amounts[0]);
        dai.mint(address(mew), amounts[1]);
        dai.approve(address(mew), amounts[1]);
        uni.mint(address(mew), amounts[2]);
        uni.approve(address(mew), amounts[2]);
    }

    function _addCredibleAccountModuleAsSubHook() internal {
        vm.startPrank(owner1);
        bool isEcdsaValidatorInstalled = mew.isModuleInstalled(
            MODULE_TYPE_VALIDATOR,
            address(ecdsaValidator),
            ""
        );
        bytes
            memory hookMultiPlexerInitData = _getHookMultiPlexerInitDataWithCredibleAccountModule();
        bytes memory hookMultiPlexerInitDataWithCredibleAccountModule = abi
            .encodeWithSelector(
                HookMultiPlexer.addHook.selector,
                address(credibleAccountModule),
                HookType.GLOBAL
            );
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(
                    address(hookMultiPlexer),
                    uint256(0),
                    hookMultiPlexerInitDataWithCredibleAccountModule
                )
            )
        );
        (
            bytes32 hash,
            PackedUserOperation memory userOp
        ) = _createUserOperationWithoutProof(
                address(mew),
                userOpCalldata,
                owner1Key
            );
        // Execute the user operation
        _executeUserOperation(userOp);
        vm.stopPrank();
    }

    function _installCredibleAccountModuleAsValidator() internal {
        vm.startPrank(owner1);
        Execution[] memory batchCall1 = new Execution[](1);
        batchCall1[0].target = address(mew);
        batchCall1[0].value = 0;
        batchCall1[0].callData = abi.encodeWithSelector(
            ModularEtherspotWallet.installModule.selector,
            uint256(1),
            address(credibleAccountModule),
            abi.encode(MODULE_TYPE_VALIDATOR)
        );
        defaultExecutor.execBatch(IERC7579Account(mew), batchCall1);
        vm.stopPrank();
    }

    function _getDefaultSessionData() internal view returns (bytes memory) {
        TokenData[] memory tokenAmounts = new TokenData[](tokens.length);
        for (uint256 i; i < tokens.length; ++i) {
            tokenAmounts[i] = TokenData(tokens[i], amounts[i]);
        }
        return abi.encode(sessionKey, validAfter, validUntil, tokenAmounts);
    }

    function _enableDefaultSessionKey() internal {
        bytes memory sessionData = _getDefaultSessionData();
        credibleAccountModule.enableSessionKey(sessionData);
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
        userOp.nonce = getNonce(_account, address(credibleAccountModule));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _signerKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        return (userOp, hash, v, r, s);
    }

    function _createUserOpWithSignatureWithDefaultValidator(
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

        userOp.nonce = getNonce(_account, address(ecdsaValidator));
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
        address _validator,
        uint256 _signerKey
    ) internal view returns (bytes32, PackedUserOperation memory) {
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            _account,
            _callData
        );
        userOp.nonce = getNonce(_account, _validator);
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _signerKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        if (_validator == address(credibleAccountModule)) {
            // append r, s, v of signature followed by Proof to the signature
            userOp.signature = abi.encodePacked(r, s, v, DUMMY_PROOF);
        } else {
            userOp.signature = abi.encodePacked(r, s, v);
        }
        return (hash, userOp);
    }

    function _createUserOperationWithoutProof(
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
        ) = _createUserOpWithSignatureWithDefaultValidator(
                _account,
                _callData,
                _signerKey
            );

        // append r, s, v of signature followed by merkleRoot and merkleProof to the signature
        userOp.signature = abi.encodePacked(r, s, v);

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
        // append r, s, v of signature followed by merkleRoot and merkleProof to the signature
        userOp.signature = abi.encodePacked(r, s, v, DUMMY_PROOF);
        return (hash, userOp);
    }

    function _executeUserOperation(
        PackedUserOperation memory _userOp
    ) internal {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = _userOp;
        entrypoint.handleOps(userOps, beneficiary);
    }

    function _claimTokensBySolver(
        uint256 _usdc,
        uint256 _dai,
        uint256 _uni
    ) internal {
        bytes memory usdcData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            _usdc
        );
        bytes memory daiData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            _dai
        );
        bytes memory uniData = _createTokenTransferFromExecution(
            address(mew),
            address(solver),
            _uni
        );
        Execution[] memory batch = new Execution[](3);
        Execution memory usdcExec = Execution({
            target: address(usdc),
            value: 0,
            callData: usdcData
        });
        Execution memory daiExec = Execution({
            target: address(dai),
            value: 0,
            callData: daiData
        });
        Execution memory uniExec = Execution({
            target: address(uni),
            value: 0,
            callData: uniData
        });
        batch[0] = usdcExec;
        batch[1] = daiExec;
        batch[2] = uniExec;
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(batch))
        );
        (, PackedUserOperation memory userOp) = _createUserOperation(
            address(mew),
            userOpCalldata,
            address(credibleAccountModule),
            sessionKeyPrivateKey
        );
        // Execute the user operation
        _executeUserOperation(userOp);
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
