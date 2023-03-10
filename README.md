
## Well-being service

### Introduction

This is a simple implementation for a well-being service on Ethereum.

**Disclaimer**: All the smart contracts are for demonstration purposes. Many security measurements and gas optimizations are not taken into consideration.

### Smart contracts:

1. [Identity.sol](https://github.com/peterblockman/well-being-service/blob/main/contracts/Identity.sol)

    An implementation of the ERC725Y standard that allows users to create a decentralized identity

2. [IdentityRegistry.sol](https://github.com/peterblockman/well-being-service/blob/main/contracts/IdentityRegistry.sol)

    It stores a mapping of identity smart contract addresses to a boolean value indicating whether or not the identity exists. It also stores a mapping of user wallet addresses to identify the owner of the identity.

3. [SocialGraph.sol](https://github.com/peterblockman/well-being-service/blob/main/contracts/SocialGraph.sol)

    A social graph implementation on Ethereum. it allows users to create and maintain a social graph on the Ethereum blockchain. It allows users to connect with each other and rate the impact of these connections

4. [DataExchange.sol](https://github.com/peterblockman/well-being-service/blob/main/contracts/DataExchange.sol)

    A marketplace for buying and selling data. It also includes a simple reputation system to help buyers and sellers evaluate each other's trustworthiness.
5. [Helper.sol](https://github.com/peterblockman/well-being-service/blob/main/contracts/Helper.sol)

    It has a single function called "hash". The function takes a string as an input and returns the Keccak-256 hash of the string. This function can be useful when we need to convert a string to a hash for use as input in other smart contracts, such as the `DataExchange` contract on Remix. 

## Test 
Use [Remix](https://remix.ethereum.org/)
### Flow
 1. Use [DGIT](https://medium.com/remix-ide/github-in-remix-ide-356de378f7da) to connect Remix with this repo.
 2. Deploy `IdentityRegistry` smart contract
 3. Deploy 2 `Identity` smart contracts, and grab their addresses
 4. Deploy `SocialGraph` and `DataExchange`
 5. Use the identity addresses in the `SocialGraph` smart contract and `DataExchange` smart contract
