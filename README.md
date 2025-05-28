# FundMe Smart Contract

## Table of Contents

- [About](#about)
- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
- [Usage](#usage)
  - [Deploy (Local)](#deploy-local)
  - [Testing](#testing)
    - [Test Coverage](#test-coverage)
  - [Compatibilities](#compatibilities)
- [Gas Optimization](#gas-optimization)
- [Deployment to Testnet/Mainnet](#deployment-to-testnet-mainnet)
- [Roles](#roles)
- [Known Issues](#known-issues)

## About

FundMe is a smart contract designed for decentralized crowdfunding. Users can fund the contract, and the owner can withdraw the collected funds. The contract uses Chainlink price feeds to convert ETH to USD.

## Getting Started

### Requirements

- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
  - Verify installation with `git --version`
- [Foundry](https://getfoundry.sh/)
  - Verify installation with `forge --version`

### Quickstart

```sh
git clone https://github.com/sheriefelhamy/foundry-fund-me-f23.git
cd foundry-fund-me-f23
forge install foundry-rs/forge-std --no-commit
forge build
```

## Usage

### Deploy (Local)

1. Start a local node

```sh
make anvil
```

2. Deploy the contract

```sh
make deploy
```

### Testing

Run unit tests with:

```sh
forge test
```

#### Test Coverage

To check test coverage:

```sh
forge coverage
```

For detailed debugging:

```sh
forge coverage --report debug
```

## Compatibilities

- **Solc Version**: 0.8.18
- **Chain(s) to deploy contract to**: Ethereum

## Gas Optimization

The contract underwent optimizations to reduce gas costs, primarily by reducing storage reads/writes and favoring memory-based operations where possible. Below are the key improvements:

- **testWithdrawFromAMultipleFunders**: Saved 3248 gas
- **testOnlyOwnerCanWithdraw**: Saved 2135 gas
- **testOwnerIsMsgSender**: Saved 2134 gas
- **testWithdrawFromASingleFunder**: Saved 1852 gas

These optimizations significantly improved contract efficiency by minimizing expensive storage operations and leveraging cheaper memory operations.

### Example: Optimized `withdraw()` Function

Before Optimization:
```solidity
function withdraw() public onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
        address funder = s_funders[funderIndex];
        s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);
 
    (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
    require(callSuccess, "Call failed");
}
```

After Optimization:
```solidity
function withdraw() public onlyOwner {
    uint256 fundersLength = s_funders.length;
    address[] memory _funders = s_funders;
    
    for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
        address funder = _funders[funderIndex];
        s_addressToAmountFunded[funder] = 0;
    }
    s_funders = new address[](0);

    (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
    require(callSuccess, "Call failed");
}
```
✅ **Improvement:** Storing `s_funders` in memory reduces redundant storage reads, leading to lower gas costs.

## Deployment to Testnet/Mainnet

### Setup Environment Variables
You'll want to set your `SEPOLIA_RPC_URL` and `PRIVATE_KEY` as environment variables. You can add them to a `.env` file, similar to what you see in `.env.example`.

- **PRIVATE_KEY**: The private key of your account (from Metamask). **Use a key that doesn't have real funds**.
- **SEPOLIA_RPC_URL**: The URL of the Sepolia testnet node (you can get one from [Alchemy](https://www.alchemy.com/)).
- **ETHERSCAN_API_KEY** (optional): Needed if you want to verify your contract on Etherscan.

### Get Testnet ETH
Go to [faucets.chain.link](https://faucets.chain.link/) and request testnet ETH. You should see it appear in your Metamask wallet.

### Deploy to Testnet
```sh
forge script script/DeployFundMe.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY
```

### Run Scripts
Once deployed, interact with your contract using the following commands:

#### Fund the contract
```sh
cast send <FUNDME_CONTRACT_ADDRESS> "fund()" --value 0.1ether --private-key $PRIVATE_KEY
```
OR
```sh
forge script script/Interactions.s.sol --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast
```

#### Withdraw funds
```sh
cast send <FUNDME_CONTRACT_ADDRESS> "withdraw()" --private-key $PRIVATE_KEY
```

### Estimate Gas Usage
Run the following command to estimate gas costs:
```sh
forge snapshot
```
This generates a `.gas-snapshot` file containing gas usage data.

### Code Formatting
To format your Solidity code, run:
```sh
forge fmt
```

## Roles

- **Owner**: The contract deployer who can withdraw funds
- **Funders**: Users who send ETH to the contract

## Known Issues

_No known issues reported._

