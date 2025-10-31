Student Club Governance DAO

A decentralized autonomous organization (DAO) framework tailored for student clubs and university organizations. This project allows club members to create proposals, vote on initiatives, and govern club funds transparently using smart contracts on the Ethereum blockchain.

This DAO empowers student organizations to self-govern through:

Proposal submission by members

On-chain voting

Fund management and treasury control

Transparent governance records for all decisions

| Layer              | Tech / Tool                          |
| ------------------ | ------------------------------------ |
| Smart Contracts    | **Solidity**                         |
| Dev Framework      | **Hardhat**                          |
| Token Standard     | **ERC-20 / ERC-721 (Membership)**    |
| Voting System      | **OpenZeppelin Governor** (optional) |
| Wallets            | MetaMask, WalletConnect              |
| Frontend           | React + Ethers.js/Web3.js            |
| Storage (optional) | IPFS, NFT.Storage                    |
| Testing            | Mocha, Chai                          |
| Linting            | Solhint, Prettier                    |
| Deployment         | Alchemy / Infura + Hardhat           |


<--Smart Contract Modules-->

ClubDAO.sol
Main governance contract (handles proposals and voting)

Treasury.sol
Safely stores and disburses club funds (ETH or ERC-20)

ClubToken.sol (optional)
ERC-20 or ERC-721 token to represent voting power

Governor.sol (optional)
OpenZeppelin Governor-based logic for advanced governance

TimelockController.sol (optional)
Adds a delay to proposal execution for security



<--Short usage notes (quick)-->

Deploy with admin address and optional initial members.

Default voting: createProposal() => voting starts immediately and lasts votingPeriod seconds (set in constructor or updated later by admin).

Voting is one-member-one-vote. To vote: vote(proposalId, true|false).

After voting ends, anyone can call executeProposal() to mark it executed if quorum & support reached.

executeProposal in this version does not perform arbitrary calls/transfers (safer for student club). If you want proposals to perform on-chain actions, you must add targets, values, calldatas in Proposal and implement execute logic carefully (use timelock & admin multisig).



<--Suggestions & improvements (if you want next)-->

Use token-weighted voting (ERC20 snapshot) if membership has weighting (e.g., votes proportional to contribution).

Add targets + calldatas to proposals to perform on-chain actions and pair with a timelock contract for safety.

Add proposal types (budget request, event approval) and metadata.

Replace single admin with a multisig or DAO-controlled admin.

Add off-chain signature voting (EIP-712) for gas savings.
