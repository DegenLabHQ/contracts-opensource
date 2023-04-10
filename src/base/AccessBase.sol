// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import {IRebornDefination} from "src/interfaces/IRebornPortal.sol";
import {RebornPortalStorage} from "src/RebornPortalStorage.sol";
import {CommonError} from "src/lib/CommonError.sol";

contract AccessBase is IRebornDefination, RebornPortalStorage {
    modifier onlySigner() {
        if (!signers[msg.sender]) {
            revert CommonError.NotSigner();
        }
        _;
    }
}
