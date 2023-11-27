// solhint-disable func-name-mixedcase

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";

import {IEntryPoint} from "@ERC4337/interfaces/IEntryPoint.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC721PresetMinterPauserAutoId} from "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import {IERC777Recipient} from "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import {SingleOwnerPlugin} from "../../src/ERC6900/plugins/SingleOwnerPlugin.sol";
import {TokenReceiverPlugin} from "../../src/ERC6900/plugins/TokenReceiverPlugin.sol";
import {EtherspotWalletV2} from "../../src/ERC6900/wallet/EtherspotWalletV2.sol";
import {MSCAFactoryFixture} from "../../src/ERC6900/wallet/MSCAFactoryFixture.sol";
import {ErrorsLib} from "../../src/ERC6900/libraries/ErrorsLib.sol";

import {FunctionReference} from "@ERC6900/src/libraries/FunctionReferenceLib.sol";
import {IPluginManager} from "@ERC6900/src/interfaces/IPluginManager.sol";

import {MockERC777} from "@ERC6900/test/mocks/MockERC777.sol";
import {MockERC1155} from "@ERC6900/test/mocks/MockERC1155.sol";

contract TokenReceiverPluginTest is Test, IERC1155Receiver {
    EtherspotWalletV2 public acct;
    TokenReceiverPlugin public plugin;

    ERC721PresetMinterPauserAutoId public t0;
    MockERC777 public t1;
    MockERC1155 public t2;

    // init dynamic length arrays for use in args
    address[] public defaultOperators;
    uint256[] public tokenIds;
    uint256[] public tokenAmts;
    uint256[] public zeroTokenAmts;

    uint256 internal constant _TOKEN_AMOUNT = 1 ether;
    uint256 internal constant _TOKEN_ID = 0;
    uint256 internal constant _BATCH_TOKEN_IDS = 5;

    function setUp() public {
        MSCAFactoryFixture factory = new MSCAFactoryFixture(
            IEntryPoint(address(0)),
            new SingleOwnerPlugin()
        );

        acct = factory.createAccount(address(this), 0);
        plugin = new TokenReceiverPlugin();

        t0 = new ERC721PresetMinterPauserAutoId("t0", "t0", "");
        t0.mint(address(this));

        t1 = new MockERC777();
        t1.mint(address(this), _TOKEN_AMOUNT);

        t2 = new MockERC1155();
        t2.mint(address(this), _TOKEN_ID, _TOKEN_AMOUNT);
        for (uint256 i = 1; i < _BATCH_TOKEN_IDS; i++) {
            t2.mint(address(this), i, _TOKEN_AMOUNT);
            tokenIds.push(i);
            tokenAmts.push(_TOKEN_AMOUNT);
            zeroTokenAmts.push(0);
        }
    }

    function _initPlugin() internal {
        bytes32 manifestHash = keccak256(abi.encode(plugin.pluginManifest()));

        acct.installPlugin(
            address(plugin),
            manifestHash,
            "",
            new FunctionReference[](0),
            new IPluginManager.InjectedHook[](0)
        );
    }

    function test_failERC721Transfer() public {
        vm.expectRevert(
            abi.encodePacked(
                ErrorsLib.UnrecognizedFunction.selector,
                IERC721Receiver.onERC721Received.selector,
                bytes28(0)
            )
        );
        t0.safeTransferFrom(address(this), address(acct), _TOKEN_ID);
    }

    function test_passERC721Transfer() public {
        _initPlugin();
        assertEq(t0.ownerOf(_TOKEN_ID), address(this));
        t0.safeTransferFrom(address(this), address(acct), _TOKEN_ID);
        assertEq(t0.ownerOf(_TOKEN_ID), address(acct));
    }

    function test_failERC777Transfer() public {
        vm.expectRevert(
            abi.encodePacked(
                ErrorsLib.UnrecognizedFunction.selector,
                IERC777Recipient.tokensReceived.selector,
                bytes28(0)
            )
        );
        t1.transfer(address(acct), _TOKEN_AMOUNT);
    }

    function test_passERC777Transfer() public {
        _initPlugin();

        assertEq(t1.balanceOf(address(this)), _TOKEN_AMOUNT);
        assertEq(t1.balanceOf(address(acct)), 0);
        t1.transfer(address(acct), _TOKEN_AMOUNT);
        assertEq(t1.balanceOf(address(this)), 0);
        assertEq(t1.balanceOf(address(acct)), _TOKEN_AMOUNT);
    }

    function test_failERC1155Transfer() public {
        // for 1155, reverts are caught in a try catch and bubbled up with a diff reason
        vm.expectRevert("ERC1155: transfer to non-ERC1155Receiver implementer");
        t2.safeTransferFrom(
            address(this),
            address(acct),
            _TOKEN_ID,
            _TOKEN_AMOUNT,
            ""
        );

        // for 1155, reverts are caught in a try catch and bubbled up with a diff reason
        vm.expectRevert("ERC1155: transfer to non-ERC1155Receiver implementer");
        t2.safeBatchTransferFrom(
            address(this),
            address(acct),
            tokenIds,
            tokenAmts,
            ""
        );
    }

    function test_passERC1155Transfer() public {
        _initPlugin();

        assertEq(t2.balanceOf(address(this), _TOKEN_ID), _TOKEN_AMOUNT);
        assertEq(t2.balanceOf(address(acct), _TOKEN_ID), 0);
        t2.safeTransferFrom(
            address(this),
            address(acct),
            _TOKEN_ID,
            _TOKEN_AMOUNT,
            ""
        );
        assertEq(t2.balanceOf(address(this), _TOKEN_ID), 0);
        assertEq(t2.balanceOf(address(acct), _TOKEN_ID), _TOKEN_AMOUNT);

        for (uint256 i = 1; i < _BATCH_TOKEN_IDS; i++) {
            assertEq(t2.balanceOf(address(this), i), _TOKEN_AMOUNT);
            assertEq(t2.balanceOf(address(acct), i), 0);
        }
        t2.safeBatchTransferFrom(
            address(this),
            address(acct),
            tokenIds,
            tokenAmts,
            ""
        );
        for (uint256 i = 1; i < _BATCH_TOKEN_IDS; i++) {
            assertEq(t2.balanceOf(address(this), i), 0);
            assertEq(t2.balanceOf(address(acct), i), _TOKEN_AMOUNT);
        }
    }

    function test_failIntrospection() public {
        bool isSupported;

        isSupported = acct.supportsInterface(type(IERC721Receiver).interfaceId);
        assertEq(isSupported, false);
        isSupported = acct.supportsInterface(
            type(IERC777Recipient).interfaceId
        );
        assertEq(isSupported, false);
        isSupported = acct.supportsInterface(
            type(IERC1155Receiver).interfaceId
        );
        assertEq(isSupported, false);
    }

    function test_passIntrospection() public {
        _initPlugin();

        bool isSupported;

        isSupported = acct.supportsInterface(type(IERC721Receiver).interfaceId);
        assertEq(isSupported, true);
        isSupported = acct.supportsInterface(
            type(IERC777Recipient).interfaceId
        );
        assertEq(isSupported, true);
        isSupported = acct.supportsInterface(
            type(IERC1155Receiver).interfaceId
        );
        assertEq(isSupported, true);
    }

    /**
     * NON-TEST FUNCTIONS - USED SO MINT DOESNT FAIL
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4) external pure override returns (bool) {
        return false;
    }
}
