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
}
