const hre = require("hardhat");
const { SPHERONDEVS_NFT_CONTRACT_ADDRESS } = require("../constants");

async function main() {

  // Now deploy the SpheronDevsDAO contract
  const SpheronDevsDAO = await ethers.getContractFactory("SpheronDevsDAO");
  const spheronDevsDAO = await SpheronDevsDAO.deploy(
      SPHERONDEVS_NFT_CONTRACT_ADDRESS,
      {
        // This assumes your metamask account has at least 1 ETH in its account
        // Change this value as you want
        value: ethers.utils.parseEther("0.48"),
      }
  );
  await spheronDevsDAO.deployed();

  console.log("SpheronDevsDAO deployed to: ", spheronDevsDAO.address);
}

// Async Sleep function
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
