// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Swadowx} from "./Swadowx.sol";

contract SwadowxFactory {
    address public owner;
    uint256 public nextMatchId = 1;

    struct GameDetails {
        address gameAddress;
        address player1;
        address player2;
        address winner;
        address loser;
        uint256 totalPot;
        uint256 entryFee;
        uint256 entrytcore;
        bool gameActive;
    }

    mapping(uint256 => GameDetails) public games;
    mapping(address => uint256[]) public playerGames;

    event GameCreated(uint256 indexed matchId, address gameAddress);
    event MatchRecorded(uint256 indexed matchId, address winner, address loser, uint256 totalPot);
    event EntryFeeUpdated(uint256 indexed matchId, uint256 newEntryFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createGame(uint256 _entryFee) external returns (address) {
        uint256 matchId = nextMatchId++;

        Swadowx newGame = new Swadowx(matchId, _entryFee, address(this));

        games[matchId] = GameDetails({
            gameAddress: address(newGame),
            player1: address(0),
            player2: address(0),
            winner: address(0),
            loser: address(0),
            totalPot: 0,
            entryFee: _entryFee * 1e18,
             entrytcore:_entryFee ,
            gameActive: false
        });

        emit GameCreated(matchId, address(newGame));
        return address(newGame);
    }

    function recordMatch(
        uint256 matchId,
        address player1,
        address player2,
        address winner,
        address loser,
        uint256 totalPot
    ) external {
        require(games[matchId].gameAddress != address(0), "Game not found");
        require(msg.sender == games[matchId].gameAddress, "Unauthorized");

        games[matchId].player1 = player1;
        games[matchId].player2 = player2;
        games[matchId].winner = winner;
        games[matchId].loser = loser;
        games[matchId].totalPot = totalPot;
        games[matchId].gameActive = false;

        playerGames[player1].push(matchId);
        playerGames[player2].push(matchId);

        emit MatchRecorded(matchId, winner, loser, totalPot);
    }

    function updateEntryFee(uint256 _matchId, uint256 _newFee) external onlyOwner {
        require(games[_matchId].gameAddress != address(0), "Game not found");

        Swadowx(games[_matchId].gameAddress).setEntryFee(_newFee);
        games[_matchId].entryFee = _newFee * 1e18;

        emit EntryFeeUpdated(_matchId, _newFee);
    }

function getGameDetails(uint256 _matchId) 
        external 
        view 
        returns (
            address, address, address, address, address, uint256, uint256, uint256, bool
        ) 
    {
        GameDetails memory game = games[_matchId];
        return (
            game.gameAddress,
            game.player1,
            game.player2,
            game.winner,
            game.loser,
            game.totalPot,
            game.entryFee,
            game.entrytcore, // Fixed issue here
            game.gameActive
        );
    }
    function getPlayerGames(address _player) external view returns (uint256[] memory) {
        return playerGames[_player];
    }
}