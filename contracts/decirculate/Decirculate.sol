pragma solidity >= 0.5.16;

import {AbstractERC20} from "../AbstractERC20.sol";

import {ERC20} from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";
import {SafeERC20} from "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";


interface IDecirculate {
    function start(address asset, uint256 bidAmount) external;
    function bid(address asset, uint256 id, uint256 bidAmount) external;
    function extend(address asset, uint256 id) external;
    function resolve(address asset, uint256 id) external;
}

contract Decirculate is IDecirculate, AbstractERC20 {

    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    event Started(
        address indexed asset,
        uint256 id,
        uint256 indexed saleAmount,
        uint256 indexed bidAmount
    );
    event NewBid(
        address indexed asset,
        uint256 id,
        uint256 indexed saleAmount,
        uint256 indexed bidAmount
    );
    event Extended(
        address indexed asset,
        uint256 id,
        uint256 indexed saleAmount
    );
    event Resolved(
        address indexed asset,
        uint256 id,
        uint256 indexed saleAmount,
        uint256 indexed bidAmount
    );

    // Assuming 15 second blocks
    uint256 public constant AUCTION_DURATION = 2 * 24 * 60 * 4;
    uint256 public constant BID_DURATION = 3 * 60 * 4;

    // NB: Bids must increase by 105%
    //     This ratio is 105%
    uint256 public constant BID_INCREASE_NUMERATOR = 105 * 10 ** 18;
    uint256 public constant BID_INCREASE_DENOMINATOR = 100 * 10 ** 18;

    struct Auction {
        uint256 saleAmount;
        uint256 endBlock;

        address bidder;
        uint256 bidAmount;
        uint256 resolveBlock;
    }

    mapping (address => uint256) public next;
    mapping (bytes32 => Auction) public auctions;

    constructor () public {}

    function internalID(address asset, uint256 id) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(asset, id));
    }

    // start a new auction
    function start(address asset, uint256 bidAmount) public {
        uint256 id = next[asset];
        ERC20 token = ERC20(asset);
        uint256 tokenBalance = token.balanceOf(address(this));

        require(token.balanceOf(address(this)) > 0, "Decirculate/start - no asset owned");
        require(auctions[internalID(asset, id - 1)].saleAmount == 0, "Decirculate/start - active auction for asset");

        next[asset] = id.add(1);

        Auction storage auc = auctions[internalID(asset, id)];
        auc.saleAmount = token.balanceOf(address(this));
        auc.endBlock = block.number.add(AUCTION_DURATION);
        auc.bidder = msg.sender;
        auc.bidAmount = bidAmount;

        _transfer(msg.sender, address(this), bidAmount);
        emit Started(asset, id, tokenBalance, bidAmount);
    }

    // bid in an active auction
    function bid(address asset, uint256 id, uint256 bidAmount) public {
        Auction storage auc = auctions[internalID(asset, id)];

        require(auc.endBlock > block.number, "Decirculate/bid - auction has ended");
        require(auc.bidder != address(0), "Decirculate/bid - no existing bid");
        require(auc.resolveBlock == 0 || auc.resolveBlock > block.number, "Decirculate/bid - auction should resolve");

        require(bidAmount >= _minNextBid(auc.bidAmount), "Decirculate/bid - insufficient increase");

        _transfer(msg.sender, address(this), bidAmount);  // escrow new bid
        _transfer(msg.sender, auc.bidder, auc.bidAmount); // return previous bid

        auc.bidder = msg.sender;
        auc.bidAmount = bidAmount;
        auc.resolveBlock = block.number.add(BID_DURATION);

        emit NewBid(asset, id, auc.saleAmount, bidAmount);
    }

    function _minNextBid(uint256 bidAmount) internal pure returns (uint256) {
        return bidAmount.mul(BID_INCREASE_NUMERATOR).div(BID_INCREASE_DENOMINATOR);
    }

    // Extend an auction with no bids
    function extend(address asset, uint256 id) public {
        Auction storage auc = auctions[internalID(asset, id)];
        require(auc.resolveBlock == 0, "Decirculate/extend - has a bid");
        require(auc.endBlock < block.number, "Decirculate/extend - not yet over");

        auc.endBlock = block.number.add(AUCTION_DURATION);
        emit Extended(asset, id, auc.saleAmount);
    }

    // Resolve an auction by paying the winner
    function resolve(address asset, uint256 id) public {
        Auction storage auc = auctions[internalID(asset, id)];

        require(auc.resolveBlock != 0, "Decirculate/resolve - no existing bid");
        require(auc.resolveBlock < block.number || auc.endBlock < block.number);

        // Transfer the saleAmount to the winner
        ERC20(asset).safeTransfer(auc.bidder, auc.saleAmount);
        // Burn the bid
        _burn(address(this), auc.bidAmount);

        emit Resolved(asset, id, auc.saleAmount, auc.bidAmount);
        delete auctions[internalID(asset, id)];
    }
}

contract DecirculateERC20 is IDecirculate, Decirculate, ERC20 {}
