# ORB Token

One token, for every human. ORB is the first token on World Chain, distributed equally to every human. ORB claims are open forever and never expire. Universal distribution powered by World ID.

## Overview

ORB is an ERC20 token with a unique distribution model:
- Every human can claim exactly 1,000 ORB tokens
- Claims can only be made once per human, verified by World ID
- Claims are open forever and never expire

## Technical Details

The contract uses World ID's proof of personhood system to ensure:
1. Only real humans can claim tokens
2. Each human can only claim once

## Development

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/en/) (>= v16)

### Setup

1. Clone the repository
2. Install dependencies: `forge install && npm install`
3. Run tests: `forge test`

## Build

```bash
forge build
```

## Testing

```bash
forge test
```

## Deployment

Deploy to different networks using npm scripts:

```bash
# Deploy to Optimism Sepolia (testnet)
npm run deploy:opsepolia

# Deploy to Optimism Mainnet
npm run deploy:opmainnet

# Deploy to World Chain Sepolia (testnet)
npm run deploy:wcsepolia

# Deploy to World Chain Mainnet
npm run deploy:wcmainnet
```

Make sure to set up your environment variables in `.env` before deploying:
- `OPTIMISM_SEPOLIA_RPC_URL`
- `OPTIMISM_MAINNET_RPC_URL`
- `WORLDCHAIN_SEPOLIA_RPC_URL`
- `WORLDCHAIN_MAINNET_RPC_URL`
- `PRIVATE_KEY`

