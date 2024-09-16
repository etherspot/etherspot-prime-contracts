// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ModeSelector} from "../erc7579-ref-impl/libs/ModeLib.sol";

/*//////////////////////////////////////////////////////////////
                      CUSTOM MODE SELECTORS
//////////////////////////////////////////////////////////////*/
ModeSelector constant MODE_SELECTOR_CREDIBLE_ACCOUNT = ModeSelector.wrap(
    bytes4(keccak256("etherspot.credibleaccount.action"))
);

enum SessionKeyStatus {
    NotImplemented,
    Live,
    Claimed,
    Expired
}
