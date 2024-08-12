// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Base} from "../Base.sol";

interface Challenge {
    function solveChallenge(bytes4 selectorOne, bytes memory inputData, string memory yourTwitterHandle) external;
    function getHelperContract() external view returns (address);
}
interface S1Helper {
    function returnTrue() external pure returns (bool);
    function returnTrueWithGoodValues(uint256 nine, address contractAddress) external view returns (bool);
}

/// @title Solution for challenge 1 for Cyfrin CTF
/// @author focusoor
/// @notice This challenge is part of Cytfin Updraft 'Smart Contract Security' course
/// @notice Link to course section: https://github.com/Cyfrin/security-and-auditing-full-course-s23?tab=readme-ov-file#section-1-nft
contract CtfCyfrin1 is Base {

    Challenge challenge = Challenge(CHALLENGE_1);

    function setUp() public override {
        Base.setUp();
    }

    function testSolveChallengeCtfCyfrin1() external {
        vm.selectFork(sepoliaFork);

        bytes4 selectorOne = S1Helper.returnTrue.selector;
        bytes memory inputData = abi.encodeWithSelector(
            S1Helper.returnTrueWithGoodValues.selector,
            uint256(9),
            challenge.getHelperContract()
        );

        vm.prank(BOB);
        vm.expectEmit();
        emit ChallengeSolved(BOB, address(challenge), TWITTER_HANDLE);
        challenge.solveChallenge(selectorOne, inputData, TWITTER_HANDLE);
    }
}
