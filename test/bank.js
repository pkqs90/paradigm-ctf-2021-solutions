const { expect } = require("chai");

async function getChallenge() {
  const [deployer, player] = await ethers.getSigners();
  const setupFactory = await ethers.getContractFactory(`contracts/bank/public/contracts/Setup.sol:Setup`);
  const setup = await setupFactory.deploy({value: ethers.parseEther(`50`)});
  return { setup, player };
}


it("Solves Bank", async function () {
  const { setup, player } = await getChallenge();

  // See explaination in `BankAttacker.sol`. This is a pretty hard challenge.
  // In short, there are two steps:
  //   1) Use re-entrancy attack to allow array.length underflow to uint256_max.
  //   2) Use storage slot to modify account balance.

  const attackerFactory = await ethers.getContractFactory(`contracts/bank/public/contracts/BankAttacker.sol:BankAttacker`);
  const attacker = await attackerFactory.connect(player).deploy(await setup.getAddress());
  await attacker.attack();

  expect(await setup.isSolved()).to.equal(true);
});
