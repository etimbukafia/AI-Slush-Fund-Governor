const ethers = require("ethers");
const axios = require("axios");
const dotenv = require("dotenv");
const ABI = require("../abi.json");

dotenv.config();

const PORT = process.env.PORT;
const SIGNER_KEY = process.env.PRIVATE_KEY
const SLUSH_FUND_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
const RPC_URL = "http://127.0.0.1:8545";

// Reconnection configuration
const INITIAL_RETRY_DELAY = 1000; // Start with 1 second
const MAX_RETRY_DELAY = 60000;    // Max 1 minute
const MAX_RETRIES = 5;            // Maximum number of retries per cycle

async function setupEventListener(provider, signer, retryCount = 0) {
    try {
        const slushFund = new ethers.Contract(SLUSH_FUND_ADDRESS, ABI, signer);

        console.log("Setting up withdrawal request listener...");

        slushFund.on("WithdrawalRequested", async (requestId, member, amount, purpose, event) => {
            const withdrawalRequestEvent = {
                requestId: typeof requestId === 'bigint' ? requestId.toString() : requestId,
                member: member,
                amount: typeof amount === 'bigint' ? amount.toString() : amount,
                purpose: purpose,
                eventData: JSON.parse(JSON.stringify(event, (key, value) =>
                    typeof value === 'bigint' ? value.toString() : value
                ))
            };

            console.log(JSON.stringify(withdrawalRequestEvent, null, 4));

            try {
                const response = await axios.post(`http://0.0.0.0:${PORT}/decide`, {
                    requestData: withdrawalRequestEvent
                });
                console.log('Decision:', response.data);

                try {
                    const contractWithSigner = slushFund.connect(signer);
                    const tx = await contractWithSigner.handleWithdrawalRequest(
                        requestId,
                        response.data.decision
                    );

                    console.log('Transaction sent:', tx.hash);

                    // Waiting for transaction to be mined
                    const receipt = await tx.wait();
                    console.log('Transaction confirmed:', receipt);

                } catch (contractError) {
                    console.error('Error sending transaction:', contractError);
                }

                return response.data;
            } catch (error) {
                console.error('Error sending request:',
                    error.response?.data || error.message
                );
            }
        });

        // Return the contract instance
        return slushFund;
    } catch (error) {
        console.error("Error setting up event listener:", error);
        throw error;
    }
}

async function reconnect(provider, currentContract, retryCount = 0) {
    try {
        // Clean up existing listeners if any
        if (currentContract) {
            currentContract.removeAllListeners();
        }

        // Calculate delay with exponential backoff
        const delay = Math.min(
            INITIAL_RETRY_DELAY * Math.pow(2, retryCount),
            MAX_RETRY_DELAY
        );

        console.log(`Attempting to reconnect in ${delay / 1000} seconds... (Attempt ${retryCount + 1})`);

        await new Promise(resolve => setTimeout(resolve, delay));

        // Try to reconnect to the network
        await provider.getNetwork();

        // If successful, reset the contract listener
        const newContract = await setupEventListener(provider, signer);
        console.log("Successfully reconnected!");

        return newContract;

    } catch (error) {
        console.error("Reconnection attempt failed:", error);

        if (retryCount < MAX_RETRIES) {
            return reconnect(provider, signer, currentContract, retryCount + 1);
        } else {
            console.error(`Failed to reconnect after ${MAX_RETRIES} attempts. Exiting...`);
            process.exit(1);
        }
    }
}

async function getWithdrawalRequest() {
    try {
        const provider = new ethers.JsonRpcProvider(RPC_URL);
        const signer = new ethers.Wallet(SIGNER_KEY, provider);
        await provider.getNetwork(); // Verify initial connection


        let currentContract = await setupEventListener(provider, signer);
        console.log("Listening for WithdrawalRequested events...");

        // Handle provider errors and connection issues
        provider.on("error", async (error) => {
            console.error("Provider error:", error);
            currentContract = await reconnect(provider, signer, currentContract);
        });

        // Handle network change events
        provider.on("network", async (newNetwork, oldNetwork) => {
            if (oldNetwork) {
                console.log("Network changed. Reconnecting...");
                currentContract = await reconnect(provider, signer, currentContract);
            }
        });

        // Proper cleanup on process termination
        process.on('SIGINT', async () => {
            console.log('Cleaning up...');
            if (currentContract) {
                currentContract.removeAllListeners();
            }
            provider.removeAllListeners();
            process.exit(0);
        });

    } catch (error) {
        console.error("Initial setup failed:", error);
        process.exit(1);
    }
}

getWithdrawalRequest().catch(console.error);