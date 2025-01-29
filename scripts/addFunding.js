#!/usr/bin/env node

import { message, createDataItemSigner, result, results } from "@permaweb/aoconnect";
import { fileURLToPath } from 'url';
import { readFileSync } from "fs";
import path from "path";
import dotenv from 'dotenv';

dotenv.config();

// Main function
async function main() {
  try {
    // Parse command-line arguments
    const [market, quantity, distribution] = process.argv.slice(2);
    if (!market || !quantity || !distribution) {
      console.error("Usage: ./add_funding.js market quantity distribution.\n\nExample: scripts/addFunding.js auNZO5LmwYKGUGPfaHDz0dnlYbEo8jD3ibbwqjtwOUo 10000000000000 '[60,40]'");
      process.exit(1);
    }
    // Print the arguments
    console.log("Market:", market);
    console.log("Quantity:", quantity);
    console.log("Distribution:", distribution);
    // Get the collateral token
    const collateralToken = process.env.DEV_MOCK_DAI
    console.log("Collateral Token:", collateralToken)
    // Get the current file path
    const __filename = fileURLToPath(import.meta.url);
    // Get the directory name of the current module
    const __dirname = path.dirname(__filename);
    // Load the wallet file
    const wallet = JSON.parse(
      readFileSync(path.join(__dirname, '../wallet.json')).toString(),
    )

    let messageId;

    // Send the message 
    await message({
      process: collateralToken,
      tags: [
        { name: "Action", value: "Transfer" },
        { name: "Recipient", value: market },
        { name: "Quantity", value: quantity },
        { name: "X-Action", value: "Add-Funding" },
        { name: "X-Distribution", value: distribution },
      ],
      signer: createDataItemSigner(wallet),
      data: "",
    })
      .then((id) => {
        messageId = id;
      })
      .catch((error) => {
        console.error("Error sending message:", error);
        process.exit(1);
      });

    // Retrieve the result 
    const { Messages, Error } = await result({
      message: messageId,
      process: collateralToken,
    });

    // Check for errors in the result
    if (Error) {
      console.error("Error in result:", Error);
      process.exit(1);
    }

    // Print the received messages
    console.log("Messages received:", JSON.stringify(Messages));
    // print message id
    console.log("Message ID:", messageId);
  } catch (err) {
    console.error("An unexpected error occurred:", err);
    process.exit(1);
  }
}

// Execute the script
main();
