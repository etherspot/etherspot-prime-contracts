// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IMSA} from "../erc7579-ref-impl/interfaces/IMSA.sol";
import {IAccessController} from "./IAccessController.sol";

interface IModularEtherspotWallet is IMSA, IAccessController
{
  error OnlyProxy();
}
