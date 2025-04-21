// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ISwadowxFactory {
    function recordMatch(
        uint256 matchId,
        address player1,
        address player2,
        address winner,
        address loser,
        uint256 totalPot
    ) external;
}

contract Swadowx {
    uint256 public matchId;
    uint256 public entryFee;
    uint256 public entrytcore;
    address public player1;
    address public player2;
    bool public gameActive;
    uint256 public totalPot;
    address public factory;

    mapping(address => bool) public hasDeposited;

    event GameStarted(uint256 indexed matchId, address player1, address player2, uint256 totalPot);
    event WinnerDeclared(uint256 indexed matchId, address winner, uint256 totalPot);
    event FundsTransferred(uint256 indexed matchId, address winner, uint256 amount);
    event EntryFeeUpdated(uint256 newEntryFee);

    modifier onlyWhenActive() {
        require(gameActive, "Game not active");
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can update");
        _;
    }

    modifier onlyPlayers() {
        require(msg.sender == player1 || msg.sender == player2, "Only players can call");
        _;
    }

    constructor(uint256 _matchId, uint256 _entryFee, address _factory) {
        matchId = _matchId;
        entrytcore=_entryFee;
        entryFee = _entryFee * 1e18;
        factory = _factory;
    }

    function deposit() external payable {
        require(msg.value == entryFee, "Incorrect entry fee");
        require(player1 == address(0) || player2 == address(0), "Game full");
        require(!hasDeposited[msg.sender], "Already deposited");

        if (player1 == address(0)) {
            player1 = msg.sender;
        } else {
            player2 = msg.sender;
        }

        hasDeposited[msg.sender] = true;
        totalPot += msg.value;

        if (player1 != address(0) && player2 != address(0)) {
            gameActive = true;
            emit GameStarted(matchId, player1, player2, totalPot);
        }
    }

    function declareWinner(address _winner) external onlyWhenActive onlyPlayers {
        require(_winner == player1 || _winner == player2, "Invalid winner address");

        address loser = (_winner == player1) ? player2 : player1;
        gameActive = false;

        ISwadowxFactory(factory).recordMatch(matchId, player1, player2, _winner, loser, totalPot);

        (bool success, ) = payable(_winner).call{value: totalPot}("");
        require(success, "Transfer failed");

        emit WinnerDeclared(matchId, _winner, totalPot);
        emit FundsTransferred(matchId, _winner, totalPot);
    }

    function setEntryFee(uint256 _newFee) external onlyFactory {
        entryFee = _newFee * 1e18;
        emit EntryFeeUpdated(entryFee);
    }

    function getGameDetails() external view returns (uint256, address, address, uint256, bool) {
        return (matchId, player1, player2, totalPot, gameActive);
    }
}