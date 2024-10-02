// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {ModularEtherspotWallet} from "../../../../../src/modular-etherspot-wallet/wallet/ModularEtherspotWallet.sol";
import {SessionKeyValidator} from "../../../../../src/modular-etherspot-wallet/modules/validators/SessionKeyValidator.sol";
import {ExecutionValidation, ParamCondition, Permission, SessionData} from "../../../../../src/modular-etherspot-wallet/common/Structs.sol";
import {ComparisonRule} from "../../../../../src/modular-etherspot-wallet/common/Enums.sol";
import {SessionKeyValidatorHarness} from "../../../harnesses/SessionKeyValidatorHarness.sol";
import {TestCounter} from "../../../../../src/modular-etherspot-wallet/test/TestCounter.sol";
import "../../../../../src/modular-etherspot-wallet/erc7579-ref-impl/test/dependencies/EntryPoint.sol";
import {PackedUserOperation} from "../../../../../account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import "../../../TestAdvancedUtils.t.sol";
import "../../../../../src/modular-etherspot-wallet/utils/ERC4337Utils.sol";

contract SessionKeyTestUtils is TestAdvancedUtils {
    using ERC4337Utils for IEntryPoint;
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                              VARIABLES
    //////////////////////////////////////////////////////////////*/

    // Contract instances
    ModularEtherspotWallet internal mew;
    SessionKeyValidatorHarness internal harness;
    TestCounter internal counter1;
    TestCounter internal counter2;

    // Test variables
    uint48 internal immutable validAfter = uint48(block.timestamp);
    uint48 internal immutable validUntil = uint48(block.timestamp + 1 days);
    uint256 internal immutable numberPermissions = 4;
    uint256 internal immutable tenUses = 10;

    // Test addresses and keys
    address internal alice;
    uint256 internal aliceKey;
    address payable internal beneficiary;

    /*//////////////////////////////////////////////////////////////
                        TEST HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _testSetup() internal {
        harness = new SessionKeyValidatorHarness();
        counter1 = new TestCounter();
        counter2 = new TestCounter();
        (alice, aliceKey) = makeAddrAndKey("alice");
        beneficiary = payable(address(makeAddr("beneficiary")));
        vm.deal(beneficiary, 1 ether);
        mew = setupMEWWithSessionKeys();
        vm.startPrank(address(mew));
    }

    function _getDefaultSessionKeyAndPermissions(
        address _sessionKey
    ) internal view returns (SessionData memory, Permission[] memory) {
        SessionData memory sd = SessionData({
            sessionKey: _sessionKey,
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
        return (sd, perms);
    }

    function _setupExecutionValidation(
        uint48 _validAfter,
        uint48 _validUntil
    ) internal pure returns (ExecutionValidation memory) {
        return
            ExecutionValidation({
                validAfter: _validAfter,
                validUntil: _validUntil
            });
    }

    function _setupSingleUserOp(
        address _sender,
        address _target,
        bytes memory _callData,
        ExecutionValidation[] memory _execValidations,
        uint256 _privateKey
    ) internal view returns (PackedUserOperation memory) {
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecutionLib.encodeSingle(_target, 0, _callData)
            )
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            _sender,
            userOpCalldata
        );
        userOp.nonce = getNonce(_sender, address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _privateKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes memory encodedExecValidations = abi.encode(_execValidations);
        userOp.signature = bytes.concat(signature, encodedExecValidations);
        return userOp;
    }

    function _setupBatchUserOp(
        address _sender,
        Execution[] memory _executions,
        ExecutionValidation[] memory _execValidations,
        uint256 _privateKey
    ) internal view returns (PackedUserOperation memory) {
        bytes memory userOpCalldata = abi.encodeCall(
            IERC7579Account.execute,
            (ModeLib.encodeSimpleBatch(), ExecutionLib.encodeBatch(_executions))
        );
        PackedUserOperation memory userOp = entrypoint.fillUserOp(
            _sender,
            userOpCalldata
        );
        userOp.nonce = getNonce(_sender, address(sessionKeyValidator));
        bytes32 hash = entrypoint.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            _privateKey,
            ECDSA.toEthSignedMessageHash(hash)
        );
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes memory encodedExecValidations = abi.encode(_execValidations);
        userOp.signature = bytes.concat(signature, encodedExecValidations);
        return userOp;
    }

    function _executeUserOp(PackedUserOperation memory _userOp) internal {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = _userOp;
        entrypoint.handleOps(userOps, beneficiary);
    }

    function _getPrevValidator(
        address _validator
    ) internal view returns (address) {
        for (uint256 i = 1; i < 20; ++i) {
            (address[] memory validators, ) = mew.getValidatorPaginated(
                address(0x1),
                i
            );
            if (validators[validators.length - 1] == _validator) {
                return validators[validators.length - 2];
            }
        }
        return address(0);
    }
}
