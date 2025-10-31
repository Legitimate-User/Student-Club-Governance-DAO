// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// title StudentClubDAO
/// Simple governance contract for a student club: members create proposals and vote.
contract StudentClubDAO {

    /* ========== EVENTS ========== */
    event MemberAdded(address indexed member);
    event MemberRemoved(address indexed member);
    event ProposalCreated(uint256 indexed id, address indexed proposer, string description, uint256 startTime, uint256 endTime);
    event Voted(uint256 indexed proposalId, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed proposalId);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    /* ========== STRUCTS ========== */
    struct Proposal {
        address proposer;
        string description;      // human-readable description of proposal
        uint256 startTime;       // timestamp when voting starts
        uint256 endTime;         // timestamp when voting ends
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    /* ========== STATE ========== */

    address public admin;               // admin/chair who can manage membership (can be multisig in real deployments)
    mapping(address => bool) public isMember;
    uint256 public memberCount;

    uint256 public votingPeriod;        // in seconds
    uint256 public quorumBps;           // quorum in basis points relative to memberCount (10000 = 100%)
    uint256 public passThresholdBps;    // support threshold in basis points relative to votes cast (e.g., 5000 = 50%)

    Proposal[] private proposals;

    /* ========== MODIFIERS ========== */

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier onlyMember() {
        require(isMember[msg.sender], "Only member");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    ///  _initialAdmin address of initial admin/chair
    ///  _initialMembers list of initial members (can be empty)
    ///  _votingPeriodSeconds default voting period in seconds
    ///  _quorumBps quorum in basis points (0..10000)
    ///  _passThresholdBps passing threshold in basis points (0..10000)
    constructor(
        address _initialAdmin,
        address[] memory _initialMembers,
        uint256 _votingPeriodSeconds,
        uint256 _quorumBps,
        uint256 _passThresholdBps
    ) {
        require(_initialAdmin != address(0), "admin 0");
        require(_quorumBps <= 10000 && _passThresholdBps <= 10000, "bps out of range");
        admin = _initialAdmin;
        votingPeriod = _votingPeriodSeconds;
        quorumBps = _quorumBps;
        passThresholdBps = _passThresholdBps;

        // add initial members
        for (uint256 i = 0; i < _initialMembers.length; i++) {
            address m = _initialMembers[i];
            if (m != address(0) && !isMember[m]) {
                isMember[m] = true;
                memberCount++;
                emit MemberAdded(m);
            }
        }
    }

    /* ========== ADMIN / MEMBERSHIP ========== */

    /// Change admin/chair
    function changeAdmin(address _newAdmin) external onlyAdmin {
        require(_newAdmin != address(0), "new admin 0");
        emit AdminChanged(admin, _newAdmin);
        admin = _newAdmin;
    }

    /// Add a new member (only admin)
    function addMember(address _member) external onlyAdmin {
        require(_member != address(0), "member 0");
        require(!isMember[_member], "already member");
        isMember[_member] = true;
        memberCount++;
        emit MemberAdded(_member);
    }

    /// Remove a member (only admin)
    function removeMember(address _member) external onlyAdmin {
        require(isMember[_member], "not a member");
        isMember[_member] = false;
        memberCount--;
        emit MemberRemoved(_member);
    }

    /// Update governance parameters (only admin)
    function updateGovernanceParams(uint256 _votingPeriod, uint256 _quorumBps, uint256 _passThresholdBps) external onlyAdmin {
        require(_quorumBps <= 10000 && _passThresholdBps <= 10000, "bps out of range");
        votingPeriod = _votingPeriod;
        quorumBps = _quorumBps;
        passThresholdBps = _passThresholdBps;
    }

    /* ========== PROPOSALS ========== */

    /// Create a new proposal. description should explain what the proposal does.
    /// Voting starts immediately and lasts votingPeriod seconds.
    function createProposal(string calldata _description) external onlyMember returns (uint256) {
        require(memberCount > 0, "no members");
        Proposal storage p;
        uint256 id = proposals.length;
        // push empty then use storage pointer to map-initialize mapping
        proposals.push();
        p = proposals[id];
        p.proposer = msg.sender;
        p.description = _description;
        p.startTime = block.timestamp;
        p.endTime = block.timestamp + votingPeriod;
        p.forVotes = 0;
        p.againstVotes = 0;
        p.executed = false;

        emit ProposalCreated(id, msg.sender, _description, p.startTime, p.endTime);
        return id;
    }

    /// Vote on a proposal. support = true for 'for', false for 'against'.
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        require(_proposalId < proposals.length, "invalid id");
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp >= p.startTime, "not started");
        require(block.timestamp <= p.endTime, "voting ended");
        require(!p.hasVoted[msg.sender], "already voted");

        p.hasVoted[msg.sender] = true;
        if (_support) {
            p.forVotes += 1;
        } else {
            p.againstVotes += 1;
        }

        emit Voted(_proposalId, msg.sender, _support);
    }

    /// Check if a proposal has reached quorum and passed. Can be called after voting end.
    function state(uint256 _proposalId) public view returns (string memory) {
        require(_proposalId < proposals.length, "invalid id");
        Proposal storage p = proposals[_proposalId];

        if (block.timestamp <= p.endTime) {
            return "Active";
        }
        if (p.executed) {
            return "Executed";
        }

        uint256 totalVotes = p.forVotes + p.againstVotes;
        // quorum check: totalVotes * 10000 >= memberCount * quorumBps
        if (memberCount == 0) {
            return "NoMembers";
        }
        if (totalVotes * 10000 < memberCount * quorumBps) {
            return "Failed (Quorum not reached)";
        }
        // pass threshold: forVotes * 10000 >= totalVotes * passThresholdBps
        if (p.forVotes * 10000 >= totalVotes * passThresholdBps) {
            return "Succeeded";
        } else {
            return "Failed (Not enough support)";
        }
    }

    /// Execute a passed proposal (this contract doesn't encode arbitrary actions).
    /// For a simple student-club DAO, "execution" is just a flag — real effects (transfers, calls)
    /// would require proposals to include target/call data; that is left out for safety/simple example.
    function executeProposal(uint256 _proposalId) external {
        require(_proposalId < proposals.length, "invalid id");
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp > p.endTime, "voting not ended");
        require(!p.executed, "already executed");

        // require passed
        uint256 totalVotes = p.forVotes + p.againstVotes;
        require(memberCount > 0, "no members");
        require(totalVotes * 10000 >= memberCount * quorumBps, "quorum not reached");
        require(p.forVotes * 10000 >= totalVotes * passThresholdBps, "not enough support");

        p.executed = true;
        emit ProposalExecuted(_proposalId);

        // NOTE: no external action is performed here. For safety, DAO could emit event and off-chain officers implement.
    }

    /* ========== VIEWS ========== */

    /// Number of proposals created
    function proposalCount() external view returns (uint256) {
        return proposals.length;
    }

    /// Get basic data of a proposal (note: mapping fields like hasVoted can't be returned in a single tuple)
    function getProposalBasic(uint256 _proposalId) external view returns (
        address proposer,
        string memory description,
        uint256 startTime,
        uint256 endTime,
        uint256 forVotes,
        uint256 againstVotes,
        bool executed
    ) {
        require(_proposalId < proposals.length, "invalid id");
        Proposal storage p = proposals[_proposalId];
        return (
            p.proposer,
            p.description,
            p.startTime,
            p.endTime,
            p.forVotes,
            p.againstVotes,
            p.executed
        );
    }

    /// Check if an address has voted on a proposal
    function hasVoted(uint256 _proposalId, address _voter) external view returns (bool) {
        require(_proposalId < proposals.length, "invalid id");
        return proposals[_proposalId].hasVoted[_voter];
    }
}
