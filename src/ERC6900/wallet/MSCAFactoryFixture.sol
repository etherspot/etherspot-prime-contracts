// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IEntryPoint} from "../../../account-abstraction/contracts/interfaces/IEntryPoint.sol";

import {EtherspotWalletV2} from "./EtherspotWalletV2.sol";
import {MultipleOwnerPlugin} from "../plugins/MultipleOwnerPlugin.sol";
import {GuardianPlugin} from "../plugins/GuardianPlugin.sol";

/**
 * @title MSCAFactoryFixture
 * @dev a factory that initializes EtherspotWalletV2s with a single plugin, MultipleOwnerPlugin
 * intended for unit tests and local development, not for production.
 */
contract MSCAFactoryFixture {
    EtherspotWalletV2 public accountImplementation;
    MultipleOwnerPlugin public multipleOwnerPlugin;
    GuardianPlugin public guardianPlugin;
    bytes32 private immutable _PROXY_BYTECODE_HASH;

    uint32 public constant UNSTAKE_DELAY = 1 weeks;

    IEntryPoint public entryPoint;

    address public self;

    bytes32 public multipleOwnerPluginManifestHash;
    bytes32 public guardianPluginManifestHash;

    constructor(
        IEntryPoint _entryPoint,
        MultipleOwnerPlugin _multipleOwnerPlugin,
        GuardianPlugin _guardianPlugin
    ) {
        entryPoint = _entryPoint;
        accountImplementation = new EtherspotWalletV2(_entryPoint);
        _PROXY_BYTECODE_HASH = keccak256(
            abi.encodePacked(
                type(ERC1967Proxy).creationCode,
                abi.encode(address(accountImplementation), "")
            )
        );
        multipleOwnerPlugin = _multipleOwnerPlugin;
        guardianPlugin = _guardianPlugin;
        self = address(this);
        // The manifest hash is set this way in this factory just for testing purposes.
        // For production factories the manifest hashes should be passed as a constructor argument.
        multipleOwnerPluginManifestHash = keccak256(
            abi.encode(multipleOwnerPlugin.pluginManifest())
        );
        guardianPluginManifestHash = keccak256(
            abi.encode(guardianPlugin.pluginManifest())
        );
    }

    /**
     * create an account, and return its address.
     * returns the address even if the account is already deployed.
     * Note that during UserOperation execution, this method is called only if the account is not deployed.
     * This method returns an existing account address so that entryPoint.getSenderAddress() would work even after
     * account creation
     */
    function createAccount(
        address owner,
        uint256 salt
    ) public returns (EtherspotWalletV2) {
        address addr = Create2.computeAddress(
            getSalt(owner, salt),
            _PROXY_BYTECODE_HASH
        );

        // short circuit if exists
        if (addr.code.length == 0) {
            address[] memory plugins = new address[](2);
            plugins[0] = address(multipleOwnerPlugin);
            plugins[1] = address(guardianPlugin);
            bytes32[] memory pluginManifestHashes = new bytes32[](2);
            pluginManifestHashes[0] = keccak256(
                abi.encode(multipleOwnerPlugin.pluginManifest())
            );
            pluginManifestHashes[1] = keccak256(
                abi.encode(guardianPlugin.pluginManifest())
            );
            bytes[] memory pluginInitData = new bytes[](2);
            pluginInitData[0] = abi.encode(owner);
            pluginInitData[1] = abi.encode(owner);
            // not necessary to check return addr since next call will fail if so
            new ERC1967Proxy{salt: getSalt(owner, salt)}(
                address(accountImplementation),
                ""
            );

            // point proxy to actual implementation and init plugins
            EtherspotWalletV2(payable(addr)).initialize(
                plugins,
                pluginManifestHashes,
                pluginInitData
            );
        }

        return EtherspotWalletV2(payable(addr));
    }

    /**
     * calculate the counterfactual address of this account as it would be returned by createAccount()
     */
    function getAddress(
        address owner,
        uint256 salt
    ) public view returns (address) {
        return
            Create2.computeAddress(getSalt(owner, salt), _PROXY_BYTECODE_HASH);
    }

    function addStake() external payable {
        entryPoint.addStake{value: msg.value}(UNSTAKE_DELAY);
    }

    function getSalt(
        address owner,
        uint256 salt
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, salt));
    }
}
