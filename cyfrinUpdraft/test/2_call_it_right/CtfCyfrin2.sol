// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";
import {Base} from "../Base.sol";

interface Challenge {
    function solveChallenge(bool weCallItSecurityReview, string memory yourTwitterHandle) external;
}

/// @title Solution for challenge 2 for Cyfrin CTF
/// @author focusoor
///
/// @notice This challenge is part of Cytfin Updraft 'Smart Contract Security' course
/// @notice Link to course section: https://github.com/Cyfrin/security-and-auditing-full-course-s23?tab=readme-ov-file#section-2-nft
/// @notice hardest one so far
contract CtfCyfrin2 is Base {
    Challenge challenge = Challenge(CHALLENGE_2);

    function setUp() public override {
        Base.setUp();
    }

    function testSolveChallengeCtfCyfrin2() external {
        vm.selectFork(sepoliaFork);

        bool callItSecurityReviewAndNotAudit = true;
        
        vm.prank(BOB);
        vm.expectEmit();
        emit ChallengeSolved(BOB, address(challenge), TWITTER_HANDLE);
        challenge.solveChallenge(callItSecurityReviewAndNotAudit, TWITTER_HANDLE);
    }
}
