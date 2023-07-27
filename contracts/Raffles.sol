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

contract Raffles is Ownable {
    mapping(address => uint256) public points; // this will we get leter.
    address public nft;
    address public staking;

    // raffle id => raffle
    struct Raffle {
        uint nftId; // NFT ID
        uint price; // Price of the ticket
        uint tickets; // Total tickets
        uint ticketsSold; // Total tickets sold
        uint start; // Start time
        uint end; // End time
        address[] participants; // Participants
        bool isLimied; // Is limited
        uint maxTicketsPerUser; // Max tickets per user
        mapping(address => uint) ticketsPerUser; // Tickets per user
    }

    // raffle id => raffle
    mapping(uint => Raffle) public raffles;

    uint public totalRaffles;

    constructor(address _nft, address _staking) Ownable(msg.sender) {
        nft = _nft;
        staking = _staking;
    }

    /*

    @dev create a new raffle draw

*/

    function createRaffle(
        uint _nftId,
        uint _price,
        uint _tickets,
        uint _start,
        uint _end,
        bool _isLimied,
        uint _maxTicketsPerUser
    ) external onlyOwner {
        require(_nftId >= 0, "Invalid NFT ID");
        require(_price > 0, "Invalid price");
        require(_tickets > 0, "Invalid tickets");
        require(_start > 0, "Invalid start time");
        require(_end > 0, "Invalid end time");
        require(_end > _start, "Invalid end time");

        Raffle storage _raffle = raffles[totalRaffles];

        _raffle.nftId = _nftId;
        _raffle.price = _price;
        _raffle.tickets = _tickets;
        _raffle.ticketsSold = 0;
        _raffle.start = _start;
        _raffle.end = _end;
        _raffle.participants = new address[](0);
        _raffle.isLimied = _isLimied;
        _raffle.maxTicketsPerUser = _maxTicketsPerUser;
        totalRaffles++;
    }

    function buyTicket(uint _raffleId, uint _amount) external {
        require(_raffleId >= 0, "Invalid raffle ID");
        require(_amount > 0, "Invalid amount");

        Raffle storage raffle = raffles[_raffleId];

        require(raffle.start <= block.timestamp, "Raffle not started");
        require(raffle.end >= block.timestamp, "Raffle ended");
        require(raffle.ticketsSold < raffle.tickets, "Raffle sold out");

        if (raffle.isLimied) {
            require(
                raffle.maxTicketsPerUser >= raffle.ticketsPerUser[msg.sender],
                "Max tickets per user reached"
            );
        }

        uint totalCost = _amount * raffle.price;

        require(points[msg.sender] >= totalCost, "Not enough points"); // --------------------------------------------->> 1. check if user has enough points (testing)
        points[msg.sender] = points[msg.sender] - totalCost; // --------------------------------------------->> 2. remove points from user (testing)
        // require(
        //     Staking(staking).getRewards(msg.sender) >= totalCost,
        //     "Not enough points"
        // );

        // if (totalCost > 0) {
        //     Staking(staking).removePoints(msg.sender, totalCost);
        // }

        for (uint i = 0; i < _amount; i++) {
            raffle.participants.push(msg.sender);
        }

        raffle.ticketsSold += _amount;
    }

    function random(uint _length) internal view returns (uint) {
        return
            uint(
                keccak256(
                    abi.encodePacked(block.timestamp, block.difficulty, _length)
                )
            ) % _length;
    }

    function draw(uint _raffleId) external onlyOwner {
        require(_raffleId >= 0, "Invalid raffle ID");

        Raffle storage raffle = raffles[_raffleId];

        require(raffle.end <= block.timestamp, "Raffle not ended");
        require(raffle.ticketsSold > 0, "Raffle not sold out");

        uint winner = random(raffle.participants.length);

        IERC721(nft).transferFrom(
            address(this),
            raffle.participants[winner],
            raffle.nftId
        );
    }

    function getParticipants(
        uint _raffleId
    ) external view returns (address[] memory) {
        require(_raffleId >= 0, "Invalid raffle ID");

        Raffle storage raffle = raffles[_raffleId];

        return raffle.participants;
    }

    function getMyTickets(uint _raffleId) external view returns (uint) {
        require(_raffleId >= 0, "Invalid raffle ID");

        Raffle storage raffle = raffles[_raffleId];

        return raffle.ticketsPerUser[msg.sender];
    }
}
