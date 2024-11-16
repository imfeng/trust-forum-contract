
import { ethers } from "hardhat";

import type { TrustForum } from "../../types";
import { getSigners } from "../signers";

export async function deployTrustForumFixture(): Promise<TrustForum> {
  const signers = await getSigners();

  const contractFactory = await ethers.getContractFactory("TrustForum");
  const contract = await contractFactory.connect(signers.alice).deploy();
  await contract.waitForDeployment();
  console.log("TrustForum Contract Address is:", await contract.getAddress());

  return contract;
}
