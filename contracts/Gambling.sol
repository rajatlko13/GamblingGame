// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import './Context.sol';
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import './SafeMath.sol';

contract Gambling is Context, VRFConsumerBase {
    
    using SafeMath for uint256;

    uint immutable public N;        // stores total players allowed in the game
    uint immutable public minStake; // minimum amount in wei that a user needs to stake
    address public owner;
    address public winner;          // stores the winner address after gambling ends
    address[] public playerAddress; // array that stores all the registered addresses
    mapping (address => bool) public playerReg;     // boolean mapping to check whether an address is regosterd or not
    mapping (address => uint256) public playerStake; // it mappes the amount staked by an address
    uint8 public gameStage = 0;     // Game has two stages: 0 - staking is ON, 1 - stacking is completed and winner has been announced

    bytes32 internal keyHash;
    uint256 internal fee;   // fee to pay the chainlink oracle for getting random no.
    
    // event that will be emitted when winner is announced
    event WinnerRevealed(address);
    
    constructor(address _owner, uint _N, uint _minStake) VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ) 
    {
        owner = _owner;
        N = _N;
        minStake = _minStake;   // value in wei
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }
    
    // Users can call this function stake their amount and register in the game
    // It can be called again by the same user for staking more amount
    function stake() public payable {
        require((playerStake[_msgSender()]).add(msg.value) >= minStake, "Insufficient stake amount");
        if(playerReg[_msgSender()] == false) {
            require(playerAddress.length < N, "No more players allowed");
            playerAddress.push(_msgSender());
            playerReg[_msgSender()] = true;
        }
        (playerStake[_msgSender()]).add(msg.value);
    }
    
    // to get the contract balance in wei
    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    // Users can call it to get their extra stake amount back. 
    // Only minimum stake amount will then be kept by the contract.
    function getRefund() public {
        require(gameStage == 0, "Game has already ended");
        require(playerStake[_msgSender()] > minStake, "Refund not available");
        payable(_msgSender()).transfer((playerStake[_msgSender()]).sub(minStake));
        playerStake[_msgSender()] = minStake;
    }

    // Fuction to declare the winner when all the users have registered
    // It will call the chainlink oracle to get the random no.
    function getWinner() public returns(bytes32 requestId) {
        require(gameStage == 0, "Game has already over");
        require(playerAddress.length == N, "Players are yet to stake");

        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }
    
    // Callback function to get the winner and transfer 99% of the stake prize to his/her account address
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        winner = playerAddress[randomness.mod(N)];
        payable(winner).transfer((address(this).balance).mul(99).div(100));
        gameStage = 1;                          // game over
        emit WinnerRevealed(winner);
    }

    // owner can call this function to get 1% of his/her share of the total staked amount
    function getOwnerFund() public {
        require(gameStage == 1, "Staking is not finished yet");
        require(_msgSender() == owner, "Only owner allowed");
        payable(owner).transfer(address(this).balance);
    }
    
    receive() external payable {}
    
}