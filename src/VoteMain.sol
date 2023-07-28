// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract VoteMain {

    enum Vote{ FOR, AGAINST } // Creating enums to denote two types of vote 

    // Structure of the proposal
    struct Proposal{
        string title;
        string description;
        uint256 forVotes;   
        uint256 againstVotes;
        uint256 createdTimestamp;
        uint256 votingPeriod;
    }


    mapping (uint256 => Proposal) proposals; // Mapping to store the proposals
    mapping (address => mapping(uint256 => bool)) votes; // Mapping to store the votes in order to prevent double voting


    address mailbox; // address of mailbox contract

    constructor(address _mailbox){
        mailbox = _mailbox;
    }

    // Modifier so that only mailbox can call particular functions
    modifier onlyMailbox(){
        require(msg.sender == mailbox, "Only mailbox can call this function !!!");
        _;
    }

    // Events to track out proposals and votes
    event ProposalCreated(uint256 indexed _proposalId, string _title, string _description, uint256 _createdTimestamp, uint256 _votingPeriod);
    event VoteCasted(uint256 indexed _proposalId, address indexed voter, Vote _voteType);

    // Function to create a new proposal
    function createProposal(string memory _title, string memory _description, uint256 _votingPeriod) external returns(uint256 proposalId){
        proposalId = uint256(keccak256(abi.encode(_title, _description, _votingPeriod)));
        require(proposals[proposalId].createdTimestamp == 0, "Proposal already created !!!");
        proposals[proposalId] = Proposal(_title, _description, 0, 0, block.timestamp, _votingPeriod);
        emit ProposalCreated(proposalId, _title, _description, block.timestamp, _votingPeriod);
    }

    // You can cast a vote directly by callin this function
    function voteProposal(uint256 _proposalId, Vote _voteType) external {
        _vote(_proposalId, msg.sender, _voteType);
    }

    // Internal voting function which holds the voting logic
    function _vote(uint256 _proposalId, address _voter, Vote _voteType) internal{
        require(proposals[_proposalId].createdTimestamp != 0, "Proposal doesn't exist !!!");
        require(proposals[_proposalId].createdTimestamp + proposals[_proposalId].votingPeriod >= block.timestamp, "Voting period already ended !!!");
        require(!votes[_voter][_proposalId], "Voter already voted !!!");
        if(_voteType == Vote.FOR){
            proposals[_proposalId].forVotes += 1;
        }else if(_voteType == Vote.AGAINST){
            proposals[_proposalId].againstVotes += 1;
        }
        votes[_voter][_proposalId] = true;
        emit VoteCasted(_proposalId, _voter, _voteType);
    }

    // handle function which is called by the mailbox to bridge votes from other chains
    function handle(uint32 _origin, bytes32 _sender, bytes memory _body) external onlyMailbox{
        (uint256 _proposalId, address _voter, Vote _voteType) = abi.decode(_body, (uint256, address, Vote));
        _vote(_proposalId, _voter, _voteType);
    }

    // function to get votes for a particular proposal
    function getVotes(uint256 _proposalId) external view returns(uint256 _for, uint256 _against){
        _for = proposals[_proposalId].forVotes;
        _against = proposals[_proposalId].againstVotes;
    }

}
