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

}