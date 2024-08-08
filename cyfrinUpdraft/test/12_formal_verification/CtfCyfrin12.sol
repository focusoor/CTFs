// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

interface Challenge {
    function solveChallenge(string memory yourTwitterHandle, uint256 value) external;
}
interface S12Helper {
    function exp2(uint256 x) external returns (uint256);
}

/// @title Solution for challenge 12 for Cyfrin CTF
/// @author focusoor
///
/// @notice This challenge is part of Cytfin Updraft 'Assembly-evm-codes-formal-verification' course
/// @notice Link to course section: https://github.com/Cyfrin/assembly-evm-opcodes-and-formal-verification-course?tab=readme-ov-file#section-2-nft
///
/// @dev This challenge can be solved in many ways, but readers are encouraged to try solving it using a formal verification tool. Here, Halmos is used.
contract CtfCyfrin12 is Test {
    string constant TWITTER_HANDLE = "focusoor";
    uint256 constant UNIT = 1e18;
    uint256 public fork;

    Challenge challenge = Challenge(0x3DbBF2F9AcFB9Aac8E0b31563dd75a2D69148D64);
    S12Helper helper = S12Helper(0xf2dde8E99f583b5354441EB7a141042419082596);

    /// @dev Comment out this setUp() before running halmos test 
    function setUp() public {
        fork = vm.createFork(vm.envString("SEPOLIA_URL"));
    }

    /// @dev To keep it simple, if solution is right, no error starting with S12__ should be thrown 
    function testSolveChallengeCtfCyfrin12() external {
        vm.selectFork(fork);
        // pick one of the values after running halmos
        uint256 valueThatBreaksProperty = 2859245331424980500628;
        challenge.solveChallenge(TWITTER_HANDLE, valueThatBreaksProperty);
    }

    function testGetRng() external {
        vm.selectFork(fork);
        uint256 rng = uint256(vm.load(address(helper), bytes32(0)));
        console.log("Rng atm:", rng);
    }

    /// @notice As there are a lot of counterexamples, foundry fuzzer can catch this one easily too
    function halmosTestExpLowerPartEqualExp2LowerPart(uint256 x) pure external {
        // To avoid using vm.load when running FV test, we can replace the value of rng with the current value found at 0 slot in helper contract
        uint256 rng = 28;
        uint256 exp = expLowerPart(x);
        uint256 exp2 = exp2LowerPart(x, rng);
        assert(exp == exp2);
        
        // run: halmos --function halmosTestExpLowerPartEqualExp2LowerPart
        // just a few counterexamples
        // Counterexample: 
        //     p_x_uint256 = 0x00000000000000000000000000000000000000000000009b0000000000000094 (2859245331424980500628)
        // Counterexample: 
        //     p_x_uint256 = 0x0000000000000000000000000000000000000000000000550000000000000093 (1567973246265311887507)
        // Counterexample: 
        //     p_x_uint256 = 0x00000000000000000000000000000000000000000000003e0000000000000092 (1143698132569992200338)
    }

    function expLowerPart(uint256 x) public pure returns (uint256 result) {
        unchecked {
            result = 0x800000000000000000000000000000000000000000000000;
            if (x & 0xFF > 0) {
                if (x & 0x80 > 0) {
                    result = (result * 0x10000000000000059) >> 64;
                }
                if (x & 0x40 > 0) {
                    result = (result * 0x1000000000000002C) >> 64;
                }
                if (x & 0x20 > 0) {
                    result = (result * 0x10000000000000016) >> 64;
                }
                if (x & 0x10 > 0) {
                    result = (result * 0x1000000000000000B) >> 64;
                }
                if (x & 0x8 > 0) {
                    result = (result * 0x10000000000000006) >> 64;
                }
                if (x & 0x4 > 0) {
                    result = (result * 0x10000000000000003) >> 64;
                }
                if (x & 0x2 > 0) {
                    result = (result * 0x10000000000000001) >> 64;
                }
                if (x & 0x1 > 0) {
                    result = (result * 0x10000000000000001) >> 64;
                }
            }
            result *= UNIT;
            result >>= (191 - (x >> 64));
        }
    }
    
    /// @notice as S12 helper is already verified we can see the part that differs, thanks Patrick ;)
    function exp2LowerPart(uint256 x, uint256 rng) public pure returns (uint256 result) {
        unchecked {
            result = 0x800000000000000000000000000000000000000000000000;
            if (x & 0xFF > 0) {
                if (x & 0x80 > 0) {
                    result = (result * (0x10000000000000059 + rng)) >> 64;
                }
                if (x & 0x40 > 0) {
                    result = (result * 0x1000000000000002C) >> 64;
                }
                if (x & 0x20 > 0) {
                    result = (result * 0x10000000000000016) >> 64;
                }
                if (x & 0x10 > 0) {
                    result = (result * 0x1000000000000000B) >> 64;
                }
                if (x & 0x8 > 0) {
                    result = (result * 0x10000000000000006) >> 64;
                }
                if (x & 0x4 > 0) {
                    result = (result * 0x10000000000000003) >> 64;
                }
                if (x & 0x2 > 0) {
                    result = (result * 0x10000000000000001) >> 64;
                }
                if (x & 0x1 > 0) {
                    result = (result * 0x10000000000000001) >> 64;
                }
            }
            result *= UNIT;
            result >>= (191 - (x >> 64));
        }
    }
}
