// scripts/deployStudentClubDAO.js

/**
 * Hardhat deployment script for StudentClubDAO.sol
 * Usage: npx hardhat run scripts/deployStudentClubDAO.js --network <network-name>
 */

const { ethers } = require("hardhat");

async function main() {
    // 1. Get the Signer (Deployer/Admin)
    const [deployer] = await ethers.getSigners();
    const deployerAddress = deployer.address;

    console.log("---------------------------------------------------------");
    console.log("🗳️ Deploying StudentClubDAO contract...");
    console.log(`👤 Deploying with account: ${deployerAddress}`);
    
    // --- CONSTRUCTOR ARGUMENTS ---

    // 1. Admin: The primary administrator (can be the deployer or another address)
    // NOTE: If you use the deployer's address, you should be able to call admin-only functions immediately.
    const _initialAdmin = deployerAddress; 

    // 2. Initial Members: List of initial members' addresses
    // IMPORTANT: Replace these placeholder addresses with real ones.
    const _initialMembers = [
        deployerAddress, // Making the admin an initial member too
        "0x280e8D05e8d893E6a75f0f353B943d00234e4C3F", // Member 1
        "0x5B5A10A2B992b8F523b1853874971c6E46a9a066", // Member 2
    ];

    // 3. Voting Period: How long a proposal is active (e.g., 7 days in seconds)
    // 7 days * 24 hours/day * 60 minutes/hour * 60 seconds/minute = 604800 seconds
    const _votingPeriodSeconds = 604800; 

    // 4. Quorum BPS: Minimum total votes to pass (e.g., 2000 = 20% of total members)
    const _quorumBps = 2000; 

    // 5. Pass Threshold BPS: Minimum 'for' votes relative to total votes cast (e.g., 5001 = 50.01%)
    const _passThresholdBps = 5001; 

    console.log(`\n⚙️ Initial Parameters:`);
    console.log(`- Admin: ${_initialAdmin}`);
    console.log(`- Initial Members: ${_initialMembers.length}`);
    console.log(`- Voting Period: ${_votingPeriodSeconds} seconds`);
    console.log(`- Quorum: ${_quorumBps / 100}% of members`);
    console.log(`- Pass Threshold: ${_passThresholdBps / 100}% support`);

    // 2. Deploy the Contract
    const StudentClubDAOFactory = await ethers.getContractFactory("StudentClubDAO");
    
    const studentClubDAO = await StudentClubDAOFactory.deploy(
        _initialAdmin,
        _initialMembers,
        _votingPeriodSeconds,
        _quorumBps,
        _passThresholdBps
    );

    // Wait for the deployment transaction to be mined
    await studentClubDAO.waitForDeployment();
    
    const contractAddress = await studentClubDAO.getAddress();
    
    console.log(`\n✅ StudentClubDAO deployed to: ${contractAddress}`);
    console.log("---------------------------------------------------------");
}

// Standard Hardhat error handling
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
