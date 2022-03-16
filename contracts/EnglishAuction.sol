// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint _nftId
    ) external;
}

contract EnglishAuction {
    event Start();
    event Bid(address indexed sender, uint amount);
    event Withdraw(address indexed bidder, uint amount);
    event End(address highestBidder, uint amount);

    IERC721 public immutable nft;
    uint public immutable nftId;

    address payable public immutable seller;
    uint32 public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bids;

    constructor(address _nft, uint _nftId, uint _startingBid) {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.seller);
        highestBid = _startingBid;
    }

    function start() external {
        require(msg.sender == seller, "Only seller can start the auction!");
        require(!started, "Auction already started!");
        started = true;
        endAt = uint32(block.timestamp + 60); // 60 seconds
        nft.transferFrom(seller, address(this), nftId);

        emit Start();
    }

    function bid() external payable {
        require(started, "Auction has not started");
        require(block.timestamp < endAt, "Auction has ended");
        require(msg.value > highestBid, "Placed bid is less then the highest bid!");

        if (highestBidder != address(0)) { // if someone bid on the NFT
            bids[highestBidder] += highestBid; // keeps tracks of all bids that were outbid, so that later on they can withdraw their eth
        }

        highestBid = msg.value;
        highestBidder = msg.sender;


        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        uint bal = bids[msg.sender];
        bids[msg.sender] = 0; // this is placed before transfering funds for protection against reentry attacks
        payable(msg.sender).transfer(bal);
        emit Withdraw(msg.sender, bal);
    }

    function end() external {
        require(started, "Auction has not started");
        require(!ended, "ended");
        require(block.timestamp >= endAt, "Auction has ended");

        ended = true;
        if (highestBidder != address(0)) { // if someone bid on the NFT
            nft.transferFrom(address(this), highestBidder, nftId);
            seller.transfer(highestBid);
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        emit End(highestBidder, highestBid);

    }

}
