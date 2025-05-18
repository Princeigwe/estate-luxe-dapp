import dotenv from "dotenv";
dotenv.config();

import { ethers } from "ethers";
import { elxContractABI } from "./elx.contract.abi";


const contractAddress = process.env.CONTRACT_ADDRESS?.trim();
const providerUrl = process.env.PROVIDER_URL?.trim();

// this is just to identify the wallet I'm working
const desiredWalletAddress = process.env.WORKING_WALLET_ADDRESS?.trim();
let desiredWalletPrivateKey = process.env.WORKING_WALLET_PRIVATE_KEY?.trim();


const recipientAddress = process.env.RECIPIENT_ADDRESS?.trim();

if (!contractAddress || !providerUrl || !desiredWalletPrivateKey) {
  throw new Error("Missing required environment variables");
}

// ensuring private key is correctly prefixed with '0x'
if (!desiredWalletPrivateKey.startsWith("0x")) {
  desiredWalletPrivateKey = `0x${desiredWalletPrivateKey}`;
}

// validate private key format
if (!/^0x[0-9a-fA-F]{64}$/.test(desiredWalletPrivateKey)) {
  throw new Error("Invalid private key format");
}

// initializing provider and wallet
const provider = new ethers.JsonRpcProvider(providerUrl);
const wallet = new ethers.Wallet(desiredWalletPrivateKey, provider);

// connecting  wallet to contract
const elxContract = new ethers.Contract(contractAddress, elxContractABI, wallet);

class ElxInteractions {
  async getNftNameAndSymbol() {
    try {
      const tokenName = await elxContract.name();
      const tokenSymbol = await elxContract.symbol();
      console.log(`Token name: ${tokenName}, Symbol: ${tokenSymbol}`);
    } catch (error) {
      console.error("Failed to fetch token name/symbol:", error);
    }
  }

  async createListing(location: string, description: string, price: number, image: string, tokenCid: string) {
    try {
      const createListing = await elxContract.createListing(location, description, price, image, tokenCid)
      console.log("Listing minted:", createListing)
    } catch (error) {
      console.error("Failed to create realty listing:", error)
    }
  }


  async getMyRealties() {
    try {
      const myRealties = await elxContract.getMyRealties()
      console.log("Realties tokens:", myRealties)
    } catch (error) {
      console.error("Error fetching realties token:", error)
    }
  }

  async getTokenUri(tokenId: number) {
    try {
      const tokenUri = await elxContract.getTokenUri(tokenId)
      console.log("Token metadata URI:", tokenUri)
    } catch (error) {
      console.error("Error fetching uri:", error)
    }
  }
}

const elxInteractions = new ElxInteractions();


// elxInteractions.getNftNameAndSymbol();

const location = "Califonia, US"
const description = "white and brown concrete building under blue sky during daytime"
const nftImage = "ipfs://bafybeihq27jrbhh4kmaeruqej7nld267p6ojayw7f5z5m7qrx65glxzkqq"
const tokenCid = "bafkreif67z5t3wwrtyr2b4ice7o5qzxdcaa3apgxwnfeui43qembigmdua"
const ethPrice = 3

// elxInteractions.createListing(location, description, ethPrice, nftImage, tokenCid)

elxInteractions.getMyRealties()

// elxInteractions.getTokenUri(1)