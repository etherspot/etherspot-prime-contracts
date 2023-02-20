// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Utils} from "../foundry/utils/Utils.sol";
import {UserOperationHelper} from "../foundry/utils/UserOp.sol";
import {EntryPoint} from "../../src/core/EntryPoint.sol";
import {Whitelist} from "../../src/Whitelist.sol";
import {EtherspotAccount} from "../../src/EtherspotAccount.sol";
import {EtherspotPaymaster} from "../../src/TEST_EtherspotPaymaster.sol";
import {EtherspotAccountFactory} from "../../src/samples/EtherspotAccountFactory.sol";
import {UserOperation} from "../../src/interfaces/UserOperation.sol";

contract EtherspotPaymasterTest is Test {
    Utils internal utils;
    UserOperationHelper internal userop;
    EntryPoint public ep;
    EtherspotAccount public account;
    EtherspotPaymaster public paym;
    EtherspotAccountFactory public accf;

    address payable[] internal users;
    address internal alice;
    address internal bob;
    address internal charlie;
    address internal deployer;
    address internal offchain_signer;
    EtherspotAccount internal aliceEA;

    event AddedToWhitelist(address paymaster, address account);
    event RemovedFromWhitelist(address paymaster, address account);

    function setUp() public {
        utils = new Utils();
        userop = new UserOperationHelper();
        users = utils.createUsers(5);
        deployer = vm.addr(1);
        offchain_signer = vm.addr(2);
        alice = vm.addr(3);
        bob = vm.addr(4);
        charlie = vm.addr(5);

        ep = new EntryPoint();
        paym = new EtherspotPaymaster(EntryPoint(ep));
        accf = new EtherspotAccountFactory(EntryPoint(ep));

        aliceEA = accf.createAccount(alice, 1234);

        paym.addStake{value: 1}(1);
        ep.depositTo{value: 1}(address(paym));
    }

    // check Whitelist integration
    function test_Success_WhitelistIntegration() public {
        vm.startPrank(alice);
        paym.add(address(bob));
        assertTrue(paym.check(address(alice), address(bob)));
        paym.remove(address(bob));
        assertFalse(paym.check(address(alice), address(bob)));
    }

    // #validatePaymasterOp
    function test_Revert_NoSignature() public {
        // add Alice's EA account to offchain_signer as a sponsee for gas payments
        vm.prank(offchain_signer);
        paym.add(address(aliceEA));
        assertTrue(paym.check(address(offchain_signer), address(aliceEA)));

        // get default UserOp - pass in alice EtherspotAccount as userOp.sender
        UserOperation memory userOp = userop.helper_DefaultUserOpGen(
            address(aliceEA)
        );

        //hex paym addr and data and concat
        string memory a = utils.stringToHex(
            abi.encodePacked(address(paym), "0x1234")
        );
        userOp.paymasterAndData = bytes(a);

        // get hash of userop
        bytes32 hash = ep.getUserOpHash(userOp);
        console.logBytes32(hash);

        // sign - sender is Alice's AA, signer is offchain_signer
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, hash);
        userOp.signature = abi.encodePacked(r, s, v);
        assertEq(address(offchain_signer), ecrecover(hash, v, r, s));

        // expect revert message
        vm.expectRevert("invalid signature length in paymasterAndData");

        // simulate
        ep.simulateValidation(userOp);

        // TODO:
        // INCORRECT REVERTION - AA30: paymaster not deployed.
        // from EntryPoint.sol - _simulateFindAggregator (l509) - paymaster.code.length = 0 (not same addr as deployed paymaster)
        // paymaster addr from revert: 0x3539393161326466313561386636613235366433 - NOT correct:
        // issue I think is coming from paymasterAndData assignment (l79)
        // userOp.paymasterAndData = 0x35393931613264663135613866366132353664336563353165393932353463643366623537366139333037383331333233333334
    }

    function test_Revert_InvalidSignature() public {
        // add Alice's EA account to offchain_signer as a sponsee for gas payments
        vm.prank(offchain_signer);
        paym.add(address(aliceEA));
        assertTrue(paym.check(address(offchain_signer), address(aliceEA)));

        // get default UserOp - pass in alice EtherspotAccount as userOp.sender
        UserOperation memory userOp = userop.helper_DefaultUserOpGen(
            address(aliceEA)
        );

        //hex paym addr and data and concat
        string memory a = utils.stringToHex(
            abi.encodePacked(address(paym), utils.makeInvalidSig("00", 65))
        );
        userOp.paymasterAndData = bytes(a);

        // get hash of userop
        bytes32 hash = ep.getUserOpHash(userOp);
        console.logBytes32(hash);

        // sign - sender is Alice's AA, signer is offchain_signer
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, hash);
        userOp.signature = abi.encodePacked(r, s, v);
        assertEq(address(offchain_signer), ecrecover(hash, v, r, s));

        // expect revert message
        vm.expectRevert("ECDSA: invalid signature");

        // simulate
        ep.simulateValidation(userOp);
    }

    // TODO:
    // Not sure this can be tested as it would required checking tx receipt logs to see the sigFailed value
    function test_Revert_WrongSignature() public {
        // add Alice's EA account to offchain_signer as a sponsee for gas payments
        vm.prank(offchain_signer);
        paym.add(address(aliceEA));
        assertTrue(paym.check(address(offchain_signer), address(aliceEA)));

        // get default UserOp - pass in alice EtherspotAccount as userOp.sender
        UserOperation memory userOp = userop.helper_DefaultUserOpGen(
            address(aliceEA)
        );

        // sign - sender is Alice's AA, signer is offchain_signer
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, "0xdead");
        userOp.signature = abi.encodePacked(r, s, v);
        assertEq(address(offchain_signer), ecrecover("0xdead", v, r, s));

        //hex paym addr and data and concat
        string memory a = utils.stringToHex(
            abi.encodePacked(address(paym), userOp.signature)
        );
        userOp.paymasterAndData = bytes(a);

        // expect revert message
        vm.expectRevert();

        // simulate
        ep.simulateValidation(userOp);
    }

    // it('succeed with valid signature', async () => {
    //   const userOp1 = await fillAndSign(
    //     {
    //       sender: account.address,
    //     },
    //     accountOwner,
    //     entryPoint
    //   );
    //   const hash = await paymaster.getHash(userOp1);
    //   const sig = await offchainSigner.signMessage(arrayify(hash));
    //   const userOp = await fillAndSign(
    //     {
    //       ...userOp1,
    //       paymasterAndData: hexConcat([paymaster.address, sig]),
    //     },
    //     accountOwner,
    //     entryPoint
    //   );
    //   await entryPoint.callStatic
    //     .simulateValidation(userOp)
    //     .catch(simulationResultCatch);
    // });

    function test_Success_ValidSig() public {
        // add Alice's EA account to offchain_signer as a sponsee for gas payments
        vm.prank(offchain_signer);
        paym.add(address(aliceEA));
        assertTrue(paym.check(address(offchain_signer), address(aliceEA)));

        // get default UserOp - pass in alice EtherspotAccount as userOp.sender
        UserOperation memory userOp = userop.helper_DefaultUserOpGen(
            address(aliceEA)
        );

        // get hash of userop
        bytes32 hash = ep.getUserOpHash(userOp);

        // sign - sender is Alice's AA, signer is offchain_signer
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(2, hash);
        bytes memory sig = abi.encodePacked(r, s, v);
        userOp.signature = sig;
        assertEq(address(offchain_signer), ecrecover(hash, v, r, s));

        //hex paym addr and data and concat
        string memory a = utils.stringToHex(
            abi.encodePacked(address(paym), sig)
        );
        userOp.paymasterAndData = bytes(a);

        // simulate
        ep.simulateValidation(userOp);
    }
}
