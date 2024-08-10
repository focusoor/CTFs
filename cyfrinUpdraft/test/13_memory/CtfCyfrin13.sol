// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Base} from "../Base.sol";

interface Challenge {
    function solveChallenge(string memory yourTwitterHandle, uint256 memoryLocation) external;
}

/// @title Solution for challenge 13 for Cyfrin CTF
/// @author focusoor
/// @notice This challenge is part of Cytfin Updraft 'Assembly-evm-codes-formal-verification' course
/// @notice Link to course section: https://github.com/Cyfrin/assembly-evm-opcodes-and-formal-verification-course?tab=readme-ov-file#section-3-nft
contract CtfCyfrin13 is Base {

    Challenge challenge = Challenge(CHALLENGE_13);

    // Code from the challenge
    /**
    function solveChallenge(string memory yourTwitterHandle, uint256 memoryLocation) external {
        uint256 myVale;
        assembly {
            mstore(0xc0, 0x0320)
            mstore(0x40, 0x2542)
        }

        uint256[4] memory x = [uint256(2564), uint256(9538), uint256(3345), uint256(52_634)];

        assembly {
            myVale := mload(memoryLocation)
        }

        if (myVale == 0x2542) {
            _updateAndRewardSolver(yourTwitterHandle);
        } else {
            revert();
        }
    }
    */
    // MEMORY
    // 0x00
    // 0x20
    // 0x40 -> 0x2542
    // 0x60 
    // 0x80
    // 0xa0
    // 0xc0 -> 0x0320
    // ...
    // ...
    // Because 'x' is static array, we can embed its size in compilation time, meaning we don't need any additonal memory slot to store the size
    // So, memory layout for 'x' is starting on next free memory pointer stored in 0x40:
    // 0x2542 -> 0x0000000000000000000000000000000000000000000000000000000000000a04 - 2564 in dec
    // 0x2562 -> 0x0000000000000000000000000000000000000000000000000000000000002542 - 9538 in dec
    // 0x2582 -> 0x0000000000000000000000000000000000000000000000000000000000000d11 - 3345 in dec
    // 0x25a2 -> 0x000000000000000000000000000000000000000000000000000000000000cd9a - 52634 in dec
    // .... no need to look further as 0x2542 is value we are looking for which is stored at offset: 0x2562 -> in dec: 9570

    function setUp() public override {
        Base.setUp();
    }

    function testSolveChallengeCtfCyfrin13() external {
        vm.selectFork(sepoliaFork);

        uint256 answer = 9570;
        
        vm.prank(BOB);
        vm.expectEmit();
        emit ChallengeSolved(BOB, CHALLENGE_13, TWITTER_HANDLE);
        challenge.solveChallenge(TWITTER_HANDLE, answer);
    }
}
