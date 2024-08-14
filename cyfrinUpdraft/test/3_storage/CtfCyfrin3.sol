// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {console} from "forge-std/Test.sol";
import {Base} from "../Base.sol";

interface Challenge {
    function solveChallenge(uint256 valueAtStorageLocationSevenSevenSeven, string memory yourTwitterHandle) external;
}

/// @title Solution for challenge 3 for Cyfrin CTF
/// @author focusoor
///
/// @notice This challenge is part of Cytfin Updraft 'Assembly-evm-codes-formal-verification' course
/// @notice Link to course section: https://github.com/Cyfrin/security-and-auditing-full-course-s23?tab=readme-ov-file#section-3-nft
contract CtfCyfrin3 is Base {
    Challenge challenge = Challenge(CHALLENGE_3);

    function setUp() public override {
        Base.setUp();
    }

    function testSolveChallengeCtfCyfrin3() external {
        vm.selectFork(sepoliaFork);

        uint256 valueAtStorageSlot777 = uint256(vm.load(CHALLENGE_3, bytes32(uint256(777))));

        vm.prank(BOB);
        vm.expectEmit();
        emit ChallengeSolved(BOB, address(challenge), TWITTER_HANDLE);
        challenge.solveChallenge(valueAtStorageSlot777, TWITTER_HANDLE);
    }
}
