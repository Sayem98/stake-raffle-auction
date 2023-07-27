// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool approved) external;

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

interface Staking {
    function getRewards(address account) external view returns (uint256);

    function removePoints(address _to, uint val) external;
}

contract Auction is Ownable {
    struct AuctionInfo {
        uint256 tokenId;
        address tokenAddress;
        uint256 startingPrice;
        uint256 endingPrice;
        uint256 duration;
        uint256 startedAt;
        // keep track of the highest bid
        uint256 highestBid;
        mapping(address => uint256) bids;
    }

    mapping(uint256 => AuctionInfo) public auctions;
    uint public totalAuctions;

    address public staking;
    address public nft;

    constructor(address _nft, address _staking) Ownable(msg.sender) {
        nft = _nft;
        staking = _staking;
    }

    function createAuction(
        uint256 _tokenId,
        address _tokenAddress,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    ) external {
        require(_duration >= 1 minutes, "Duration should be at least 1 minute");
        require(
            _duration <= 30 days,
            "Duration should be less than or equal to 30 days"
        );
        require(
            _startingPrice > 0 && _endingPrice > 0,
            "Price should be greater than 0"
        );
        require(
            _startingPrice > _endingPrice,
            "Starting price should be greater than ending price"
        );

        AuctionInfo storage auction = auctions[totalAuctions];
        auction.tokenId = _tokenId;
        auction.tokenAddress = _tokenAddress;
        auction.startingPrice = _startingPrice;
        auction.endingPrice = _endingPrice;
        auction.duration = _duration;
        auction.startedAt = block.timestamp;

        totalAuctions++;
    }

    function bid(uint _auctionId) external {
        AuctionInfo storage auction = auctions[_auctionId];
        require(auction.tokenId != 0, "Auction does not exist");
        require(
            auction.startedAt + auction.duration > block.timestamp,
            "Auction has ended"
        );
        require(auction.highestBid < auction.endingPrice, "Auction has ended");

        uint256 bidAmount = auction.bids[msg.sender] + 1;
        require(
            bidAmount > auction.highestBid,
            "Bid amount should be greater than highest bid"
        );

        auction.bids[msg.sender] = bidAmount;
        auction.highestBid = bidAmount;
    }
}
