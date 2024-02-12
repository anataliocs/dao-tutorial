pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";


/**
 * Minimal interface for SpheronDevsNFT containing only two functions
 * that we are interested in
 */
interface ISpheronDevsNFT {
    /// @dev balanceOf returns the number of NFTs owned by the given address
    /// @param owner - address to fetch number of NFTs for
    /// @return Returns the number of NFTs owned
    function balanceOf(address owner) external view returns (uint256);

    /// @dev tokenOfOwnerByIndex returns a tokenID at given index for owner
    /// @param owner - address to fetch the NFT TokenID for
    /// @param index - index of NFT in owned tokens array to fetch
    /// @return Returns the TokenID of the NFT
    function tokenOfOwnerByIndex(address owner, uint256 index)
    external
    view
    returns (uint256);
}

contract SpheronDevsDAO is Ownable {
    struct Proposal {

        // deadline - the UNIX timestamp until which this proposal is active. Proposal can be executed after the deadline has been exceeded.
        uint256 deadline;
        // yayVotes - number of yay votes for this proposal
        uint256 yayVotes;
        // nayVotes - number of nay votes for this proposal
        uint256 nayVotes;
        // executed - whether or not this proposal has been executed yet. Cannot be executed before the deadline has been exceeded.
        bool executed;
        // voters - a mapping of SpheronDevsNFT tokenIDs to booleans indicating whether that NFT has already been used to cast a vote or not
        mapping(uint256 => bool) voters;
    }

    event DeployEvent(string msg);

    // Create a mapping of ID to Proposal
    mapping(uint256 => Proposal) public proposals;
    // Number of proposals that have been created
    uint256 public numProposals;

    ISpheronDevsNFT spheronDevsNFT;

    // Create a payable constructor which initializes the contract
    // instance SpheronDevsNFT
    // The payable allows this constructor to accept an ETH deposit when it is being deployed
    constructor(address _spheronDevsNFT) payable {
        spheronDevsNFT = ISpheronDevsNFT(_spheronDevsNFT);
    }

    // Create a modifier which only allows a function to be
    // called by someone who owns at least 1 CryptoDevsNFT
    modifier nftHolderOnly() {
        require(spheronDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    /// @dev createProposal allows a SpheronDevsNFT holder to create a new proposal in the DAO
    /// @return Returns the proposal index for the newly created proposal
    function createProposal()
    external
    nftHolderOnly
    returns (uint256)
    {

        Proposal storage proposal = proposals[numProposals];

        // Set the proposal's voting deadline to be (current time + 5 minutes)
        proposal.deadline = block.timestamp + 5 minutes;

        numProposals++;

        return numProposals - 1;
    }

    // Create a modifier which only allows a function to be
    // called if the given proposal's deadline has not been exceeded yet
    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    // Create an enum named Vote containing possible options for a vote
    enum Vote {
        YAY, // YAY = 0
        NAY // NAY = 1
    }

    /// @dev voteOnProposal allows a SpheronDevsNFT holder to cast their vote on an active proposal
    /// @param proposalIndex - the index of the proposal to vote on in the proposals array
    /// @param vote - the type of vote they want to cast
    function voteOnProposal(uint256 proposalIndex, Vote vote)
    external
    nftHolderOnly
    activeProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        uint256 voterNFTBalance = spheronDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        // Calculate how many NFTs are owned by the voter
        // that haven't already been used for voting on this proposal
        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = spheronDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.YAY) {
            proposal.yayVotes += numVotes;
        } else {
            proposal.nayVotes += numVotes;
        }
    }

    // Create a modifier which only allows a function to be
    // called if the given proposals' deadline HAS been exceeded
    // and if the proposal has not yet been executed
    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            proposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            proposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    /// @dev executeProposal allows any SpheronDevsNFT holder to execute a proposal after it's deadline has been exceeded
    /// @param proposalIndex - the index of the proposal to execute in the proposals array
    function executeProposal(uint256 proposalIndex)
    external
    nftHolderOnly
    inactiveProposalOnly(proposalIndex)
    {
        Proposal storage proposal = proposals[proposalIndex];

        // If the proposal has more YAY votes than NAY votes
        // purchase the NFT from the FakeNFTMarketplace
        if (proposal.yayVotes > proposal.nayVotes) {
            emit DeployEvent("Deploy");
        }
        proposal.executed = true;
    }

    /// @dev withdrawEther allows the contract owner (deployer) to withdraw the ETH from the contract
    function withdrawEther() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw, contract balance empty");
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "FAILED_TO_WITHDRAW_ETHER");
    }

    // The following two functions allow the contract to accept ETH deposits
    // directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}
}
