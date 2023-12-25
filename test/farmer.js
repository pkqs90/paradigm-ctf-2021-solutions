const { expect } = require("chai");

async function getChallenge() {
  const [deployer, player] = await ethers.getSigners();
  const setupFactory = await ethers.getContractFactory(`contracts/farmer/public/contracts/Setup.sol:Setup`);
  const setup = await setupFactory.deploy({value: ethers.parseEther("50")});
  return { setup, player };
}

it("Solves Farmer", async function () {
  const { setup, farmer, player } = await getChallenge();

  // This challenge sets up a farmer contract that consists of COMP tokens and performs a Comp -> WETH -> DAI trade.
  //
  // We can `frontrun` the trade by increasing the DAI/WETH price of uniswap, leading to the contract with less amount of DAI than
  // it was supposed to have.

  const attackerFactory = await ethers.getContractFactory(`contracts/farmer/public/contracts/FarmerAttacker.sol:FarmerAttacker`);
  const attacker = await attackerFactory.connect(player).deploy(await setup.getAddress());
  await attacker.attack({value: ethers.parseEther(`50`)});

  expect(await setup.isSolved()).to.equal(true);
});
