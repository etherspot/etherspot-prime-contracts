// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ModeSelector} from "../erc7579-ref-impl/libs/ModeLib.sol";

// ModeSelectors
ModeSelector constant MODE_SELECTOR_MTSKV = ModeSelector.wrap(
    bytes4(keccak256("etherspot.multitokensessionkeyvalidator"))
);
