const { expect } = require("chai");
// const { createChallenge, submitLevel } = require("./utils");

async function getChallenge() {
  const setupFactory = await ethers.getContractFactory(`contracts/hello/public/contracts/Setup.sol:Setup`);
  const helloFactory = await ethers.getContractFactory(`contracts/hello/public/contracts/Hello.sol:Hello`);
  const setup = await setupFactory.deploy();
  const hello = helloFactory.attach(await setup.hello());
  return { setup, hello };
}

it("Solves Hello", async function () {
  const { setup, hello } = await getChallenge();
  await hello.solve();

  expect(await setup.isSolved()).to.equal(true);
});
