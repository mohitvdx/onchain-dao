//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    function purchase(uint256 _tokenId) external payable;
    function getPrice() external view returns(uint256);
    function available (uint256 _tokenId) external view returns(bool);
}

interface ICryptoDevsNFT {
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}
contract CryptoDevsDAO is Ownable{

struct Proposal {
    uint256 nftTokenId;
    uint256 deadline;
    uint256 yayvotes;
    uint256 nayvotes;
    bool executed;
    mapping (uint256 => bool) voters;
}
mapping (uint256 => Proposal) public proposals;
uint256 public numProposals;

IFakeNFTMarketplace nftMarketplace;
ICryptoDevsNFT cryptoDevsNFT;

constructor(address _nftMarketplace, address _cryptoDevsNFT) payable {
    nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
    cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
}
modifier nftHolderOnly() {
    require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "You don't have any NFTs therefore not a member");
    _;
}
function createProposal(uint256 _nftTokenId)
external
nftHolderOnly
returns(uint256)
{
    require(nftMarketplace.available(_nftTokenId), "NFT is not available for sale");
    Proposal storage proposal = proposals[numProposals];
    proposal.nftTokenId = _nftTokenId;
    proposal.deadline = block.timestamp + 7 days;
    numProposals++;
    return numProposals-1;
}

modifier activeProposalOnly(uint256 proposalIndex) {
    require(proposals[proposalIndex].deadline > block.timestamp, "Proposal is not active");
    _;
    
}

enum Vote {Yay, Nay}
function voteOnProposal(uint256 proposalIndex, Vote vote)
    external
    nftHolderOnly
    activeProposalOnly(proposalIndex)
    {
        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numvotes= 0;

        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId= cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if(!proposals[proposalIndex].voters[tokenId]){
                numvotes++;
                proposals[proposalIndex].voters[tokenId] = true;
            }
        }
    
        require(numvotes > 0, "You have already voted on this proposal");
        if(vote == Vote.Yay){
            proposals[proposalIndex].yayvotes += numvotes;
        } else {
            proposals[proposalIndex].nayvotes += numvotes;
        }

}
modifier inactiveProposalOnly(uint256 proposalIndex) {
    require(proposals[proposalIndex].deadline < block.timestamp, "Proposal is not inactive");
    require(proposals[proposalIndex].executed == false, "Proposal has already been executed");
    _;
    
}
function executeProposal(uint256 proposalIndex)
external
nftHolderOnly
inactiveProposalOnly(proposalIndex)
{
    Proposal storage proposal = proposals[proposalIndex];
    if(proposal.yayvotes > proposal.nayvotes){
        uint256 nftPrice = nftMarketplace.getPrice();
        require(address(this).balance >= nftPrice, "Not enough funds to purchase NFT");
        nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
    }
    proposal.executed = true;
}
function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
}
receive() external payable {}
fallback() external payable {}
}