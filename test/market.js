const { expect } = require("chai");

async function getChallenge() {
  const [deployer, player] = await ethers.getSigners();
  const setupFactory = await ethers.getContractFactory(`contracts/market/public/contracts/Setup.sol:Setup`);
  const setup = await setupFactory.deploy({value: ethers.parseEther(`50`)});
  return { setup, player };
}


it("Solves Market", async function () {
  const { setup, player } = await getChallenge();

  // See the explaination of the hack in `MarketAttacker.sol`. Basically it uses the bug that storage does not check for token validity,
  // and does not wipe token data completely upon selling, so we can perform a double-sell.

  const attackerFactory = await ethers.getContractFactory(`contracts/market/public/contracts/MarketAttacker.sol:MarketAttacker`);
  const attacker = await attackerFactory.connect(player).deploy(await setup.getAddress());
  await attacker.attack({value: ethers.parseEther(`500`)});

  expect(await setup.isSolved()).to.equal(true);
});
