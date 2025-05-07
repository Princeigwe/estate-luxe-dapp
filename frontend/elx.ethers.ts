import dotenv from "dotenv";
dotenv.config();

import { ethers } from "ethers";
import { elxContractABI } from "./elx.contract.abi";

// Load and validate environment variables
const contractAddress = process.env.CONTRACT_ADDRESS?.trim();
const providerUrl = process.env.PROVIDER_URL?.trim();
const desiredWalletAddress = process.env.WORKING_WALLET_ADDRESS?.trim();
let desiredWalletPrivateKey = process.env.WORKING_WALLET_PRIVATE_KEY?.trim();
const recipientAddress = process.env.RECIPIENT_ADDRESS?.trim();

// Sanity check for required env vars
if (!contractAddress || !providerUrl || !desiredWalletPrivateKey) {
  throw new Error("Missing required environment variables");
}

// Ensure private key is correctly prefixed with '0x'
if (!desiredWalletPrivateKey.startsWith("0x")) {
  desiredWalletPrivateKey = `0x${desiredWalletPrivateKey}`;
}

// Optional: Validate private key format
if (!/^0x[0-9a-fA-F]{64}$/.test(desiredWalletPrivateKey)) {
  throw new Error("Invalid private key format");
}

// Initialize provider and wallet
const provider = new ethers.JsonRpcProvider(providerUrl);
const wallet = new ethers.Wallet(desiredWalletPrivateKey, provider);

// Connect wallet to contract
const elxContract = new ethers.Contract(contractAddress, elxContractABI, wallet);

class ElxInteractions {
  async getNftNameAndSymbol() {
    try {
      const tokenName = await elxContract.name();
      const tokenSymbol = await elxContract.symbol();
      console.log(`Token name: ${tokenName}, Symbol: ${tokenSymbol}`);
    } catch (err) {
      console.error("Failed to fetch token name/symbol:", err);
    }
  }

  async createListing(location: string, description: string, price: number, image: string) {
    // Implement contract call logic here
  }
}

const elxInteractions = new ElxInteractions();
elxInteractions.getNftNameAndSymbol();
