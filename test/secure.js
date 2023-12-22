const { expect } = require("chai");

async function getChallenge() {
  const [deployer, player] = await ethers.getSigners();
  const setupFactory = await ethers.getContractFactory(`contracts/secure/public/contracts/Setup.sol:Setup`);
  const walletFactory = await ethers.getContractFactory(`contracts/secure/public/contracts/Wallet.sol:Wallet`);
  const setup = await setupFactory.deploy({value: ethers.parseEther("50")});
  const wallet = walletFactory.attach(await setup.wallet());
  return { setup, wallet, player };
}

it("Solves Secure", async function () {
  const { setup, wallet, player } = await getChallenge();

  // During the CTF, the player initially has 5000 ETH in balance. In order to pass the challenge, we can simply
  // swap some WETH and send to the setup contract.

  const interface = ethers.Interface.from([
    "function deposit()",
    "function transfer(address dst, uint qty) public returns (bool)",
  ]);
  await player.sendTransaction({
    to: setup.WETH(),
    data: interface.encodeFunctionData("deposit", []),
    value: ethers.parseEther("50")
  });
  await player.sendTransaction({
    to: setup.WETH(),
    data: interface.encodeFunctionData("transfer", [await setup.getAddress(), ethers.parseEther("50")]),
  });

  expect(await setup.isSolved()).to.equal(true);
});
