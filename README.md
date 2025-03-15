# AI Slush Fund Governor

The AI Slush Fund Governor is a decentralized application (dApp) prototype designed to simplify and secure collective fund management on-chain. 

It consists of two main components :

- On-chain Slush Fund Contract:
  Allows members to contribute ERC-20 tokens to a shared fund.
  Tracks member contributions and enables withdrawals by authorized members.
  Provides functions for deposits, withdrawals, and membership management.

- AI Governor:
  Integrates with an off-chain AI endpoint to automatically validate withdrawal requests.
  Evaluates a withdrawal request’s purpose against a set of valid categories (e.g., Operational Expenses, Development & Maintenance, Community & Member Benefits, Emergency & Unplanned Expenses).
  Updates the state on-chain based on the AI's decision (approve, reject, or manual voting required).

## Features

- Secure Contributions:
  Members can deposit tokens (using ERC-20's transferFrom) into the fund after approving the contract.

- Withdrawal Request Management:
  Members submit withdrawal requests that are stored on-chain. The request includes details such as amount, purpose, and the member’s address.

- AI-Based Validation:
  An off-chain event listener captures withdrawal events, sends the request details to an AI endpoint for evaluation, and then calls a governor function on-chain (e.g., handleWithdrawalRequest) to approve or reject the request based on the AI's decision.

- Event-Driven Architecture:
  The system uses event listeners (via ethers.js and Foundry scripts) to monitor and react to on-chain events, bridging the gap between off-chain AI analysis and on-chain execution.

- Resilient Reconnection Logic:
  Includes logic to automatically reconnect to the network in case of temporary RPC failures using exponential backoff.

## Getting Started

### Prerequisites

- Node.js and npm
- Foundry (install via Foundryup)
- Anvil (Foundry’s local blockchain)

## Installation
1. Clone the Repository:
```
git clone https://github.com/yourusername/ai-slush-fund-governor.git
cd ai-slush-fund-governor
```

2. Install Node Dependencies:
```
npm install
```

3. Install OpenZeppelin Contracts using Foundry:
```
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

4. Set Up Environment Variables:

Create a .env file in the root directory with at least:
```
PORT=3000
PRIVATE_KEY=your_anvil_private_key
```

## Deployment

### Deploying the ERC-20 Mock Token

Use Foundry to deploy your mock token. For example:
```
forge create --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY contracts/MockERC20.sol:MockERC20 --constructor-args
```

Note: If using the mint function, ensure the mock token has been modified to expose a public mint (or use onlyOwner restrictions as needed).

### Deploying the Slush Fund Contract

Deploy your slush fund contract with the mock token’s address as the constructor argument:

```
forge create --rpc-url http://127.0.0.1:8545 --private-key $PRIVATE_KEY contracts/slushFund.sol:SlushFund --constructor-args <MOCK_TOKEN_ADDRESS>
```
### Running the Event Listener

The off-chain event listener (written in Node.js with ethers.js) listens for the WithdrawalRequested event and:
- Logs event data.
- Sends the request object to your AI endpoint for decision-making.
- Calls the on-chain AI governor function (e.g., handleWithdrawalRequest) to update the request state.

```
node src/eventListener.js
```

Ensure your local Anvil node is running:
```
anvil
```

P.S. If you encounter any issues or have any suggestions or recommendations, please feel free to contact me. 
