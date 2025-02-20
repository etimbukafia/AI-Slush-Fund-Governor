const ethers = require("ethers");
const axios = require("axios");
const dotenv = require("dotenv");
const ABI = require("../abi.json");

dotenv.config();

const PORT = dotenv.config.PORT;

async function getWithdrawalRequest() {
    const slushFundAddress = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";
    const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");

    const slushFund = new ethers.Contract(slushFundAddress, ABI, provider);

    console.log("Listening for WithdrawalRequested events...");

    slushFund.on("WithdrawalRequested", async (requestId, member, amount, purpose, event) => {
        let withdrawalRequestEvent = {
            requestId: requestId.toString(),
            member: member,
            amount: amount.toString(),
            purpose: purpose,
            eventData: event
        };

        console.log(JSON.stringify(withdrawalRequestEvent, null, 4));

        const payload = { requestData: withdrawalRequestEvent };

        try {
            const response = await axios.post('http://0.0.0.0:PORT/decide', payload);
            console.log('Decison:', response.data)
        } catch (error) {
            console.error('Error sending request:', error.response?.data || error.message);
            throw new Error(`Upsert failed: ${error.message}`);
        }
    });
}

getWithdrawalRequest();

process.stdin.resume(); // Keeps script running