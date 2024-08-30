// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {ModularEtherspotWallet} from "../../../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {TokenLockHook} from "../../../../../src/modular-etherspot-wallet/modules/hooks/TokenLockHook.sol";
import {TokenLockHookHarness} from "../../../harnesses/TokenLockHookHarness.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";
import {PackedUserOperation} from "../../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import {CALLTYPE_SINGLE} from "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/libs/ModeLib.sol";
import "../../../TestAdvancedUtils.t.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenLockHookTestUtils is TestAdvancedUtils {
    using ERC4337Utils for IEntryPoint;
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Contract instances
    ModularEtherspotWallet internal mew;
    TokenLockHookHarness internal harness;

    // Test addresses and keys
    address internal alice;
    uint256 internal aliceKey;
    address payable internal beneficiary;
    address payable internal receiver;

    /*//////////////////////////////////////////////////////////////
                                ENUMS
    //////////////////////////////////////////////////////////////*/

    enum SelectMode {
        SINGLE_MODE,
        BATCH_MODE,
        LOCKING_MODE
    }

    /*//////////////////////////////////////////////////////////////
                        TEST HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _testSetup() internal {
        // Set up the Modular Etherspot Wallet
        mew = setupMEWWithTokenLockHook();
        harness = new TokenLockHookHarness();
        (alice, aliceKey) = makeAddrAndKey("alice");
        beneficiary = payable(address(makeAddr("beneficiary")));
        receiver = payable(address(makeAddr("receiver")));
        vm.deal(beneficiary, 1 ether);
        vm.startPrank(address(mew));
    }

    function _getLockingMode(
        CallType _callType
    ) internal pure returns (ModeCode) {
        ModeCode mode = ModeCode.wrap(
            bytes32(
                abi.encodePacked(
                    _callType,
                    ExecType.wrap(0x00),
                    bytes4(0),
                    ModeSelector.wrap(
                        bytes4(
                            keccak256("etherspot.multitokensessionkeyvalidator")
                        )
                    ),
                    bytes22(0)
                )
            )
        );
        return mode;
    }

    function _singleLockTokenInHook(
        address _wallet,
        address _to,
        address _token,
        uint256 _amount,
        uint256 _signingKey,
        SelectMode _mode
    ) internal view returns (bytes32, PackedUserOperation[] memory) {
        ModeCode mode;
        if (_mode == SelectMode.SINGLE_MODE)
            mode = ModeLib.encodeSimpleSingle();
        if (_mode == SelectMode.LOCKING_MODE)
            mode = _getLockingMode(CALLTYPE_SINGLE);
        // Set up calldata
        bytes memory callData = abi.encodeWithSelector(
            IERC20.transfer.selector,
            _to,
            _amount
        );
        // Set up UserOperation
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (mode, ExecutionLib.encodeSingle(_token, 0, callData))
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            _wallet,
            userOpCalldata
        );
        userOp.nonce = getNonce(_wallet, address(ecdsaValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _signingKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        userOp.signature = abi.encodePacked(r, s, v);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;
        return (hash, userOps);
    }
}
