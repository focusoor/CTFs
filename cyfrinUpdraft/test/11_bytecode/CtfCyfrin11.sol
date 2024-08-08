// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

interface Challenge {
    function solveChallenge(string memory yourTwitterHandle, bytes calldata dataToUse) external;
}

/// @title Solution for challenge 11 for Cyfrin CTF
/// @author focusoor
///
/// @notice This challenge is part of Cytfin Updraft 'Assembly-evm-codes-formal-verification' course
/// @notice Link to course section: https://github.com/Cyfrin/assembly-evm-opcodes-and-formal-verification-course?tab=readme-ov-file#section-1-nft
contract CtfCyfrin11 is Test {
    string constant TWITTER_HANDLE = "focusoor";

    bytes4 constant ZERO_SELECTOR = 0xe18d4afd;
    bytes4 constant ONE_SELECTOR = 0x90949f11;
    bytes4 constant TWO_SELECTOR = 0x08949a76;
    bytes4 constant THREE_SELECTOR = 0x7aa9a7f9;

    uint256 public fork;

    Challenge challenge = Challenge(0x444aE92325dCE5D14d40c30d2657547513674dD6);

    address public unverifiedContractAddr = 0x4221EC0A43138CF0135b2Bd91Dd3b176E1E22908;

    /// @notice DECONSTRUCTED BYTECODE
    /// if slot_0 + msg.sender == calldata_slot_1:
    ///    if selector == 0xe18d4afd:
    ///        if slot_0 == 0:
    ///            store 1 in slot 0 and return 7
    ///        else revert
    ///    if selector == 0x90949f11:
    ///        if slot_0 == 1:
    ///            store 2 in slot 0 and return 7
    ///        else revert
    ///    if selector == 0x08949a76:
    ///        if slot_0 == 2:
    ///            store 3 in slot 0 and return 7
    ///        else revert
    ///    if selector == 0x7aa9a7f9:
    ///        if slot 0 == 3:
    ///            put 0 in storage and return 7
    ///        else revert
    /// else revert
    ///    
    /**
        PUSH1 0x24          // [0x24]
        CALLDATALOAD        // [calldata_slot_1]
        CALLER              // [msg.sender, calldata_slot_1]
        PUSH0               // [0, msg.sender, calldata_slot_1]
        SLOAD               // [sload_0, msg.sender, calldata_slot_1]
        ADD                 // [sload_0 + msg.sender, calldata_slot_1]
        EQ                  // [sload_0 + msg.sender == calldata_slot_1]
        ISZERO              // [eq==0]
        PUSH2 0x00a4        // [0x00a4, eq==0]
        JUMPI               //             
        PUSH0               // [0]
        CALLDATALOAD        // [calldata_slot_0] 
        PUSH1 0xe0          // [0xe0, calldata_slot_0]
        SHR                 // [selector]
        DUP1                // [selector, selector]
        PUSH4 0xe18d4afd    // [0xe18d4afd, selector, selector]
        EQ                  // [0xe18d4afd == selector, selector]
        PUSH2 0x003e.       // [0x003e, 0xe18d4afd == selector, selector]
        JUMPI
        DUP1
        PUSH4 0x90949f11
        EQ
        PUSH2 0x0057        // if sig == 0x90949f11
        JUMPI
        DUP1
        PUSH4 0x08949a76     
        EQ
        PUSH2 0x0071        // if sig == 0x08949a76
        JUMPI
        DUP1
        PUSH4 0x7aa9a7f9
        EQ
        PUSH2 0x008b        // if sig == 0x7aa9a7f9
        JUMPI
        JUMPDEST            // fn selector == 0xe18d4afd
        PUSH0               // [0x00, selector]
        SLOAD               // [sload_slot_0, selector]
        PUSH0               // [0, slot_0, selector]
        EQ                  // [0 == slot_0, selector]
        PUSH2 0x004a        // [0x004a, selector]
        JUMPI
        PUSH0
        PUSH0
        REVERT
        JUMPDEST            // if slot_0 == 0
        PUSH1 0x01          // [0x01]
        PUSH0               // [0, 1]
        SSTORE              // []   store 1 in store slot 0
        PUSH1 0x07          // [0x7]
        PUSH0               // [0, 0x7]
        MSTORE              // []        mem[0] = 7
        PUSH1 0x20          // [0x20]
        PUSH0               // [0x00, 0x20]
        RETURN              // return 7      GOAL
        JUMPDEST            // if fn == 0x90949f11
        PUSH0               // [0]
        SLOAD               // [slot_0]
        PUSH1 0x01          // [1, slot_0]
        EQ                  // [slot_0 == 1]
        PUSH2 0x0064      
        JUMPI
        PUSH0
        PUSH0
        REVERT
        JUMPDEST            // if sig==0x90949f11 & slot_0 == 1
        PUSH1 0x02          // [0x002]
        PUSH0               // [0, 0x2]
        SSTORE              // []  store 2 in store slot 0
        PUSH1 0x07          // [7]
        PUSH0               // [0, 7]
        PUSH1 0x20          // [0x20]
        PUSH0               // [0x00, 0x20]
        RETURN              // return 7 GOAL
        JUMPDEST            // if selector == 0x08949a76
        PUSH0               
        SLOAD            
        PUSH1 0x02
        EQ
        PUSH2 0x007e
        JUMPI               // if sload_0 == 2
        PUSH0
        PUSH0
        REVERT
        JUMPDEST            // if slod_0 == 2
        PUSH1 0x03          // [3]
        PUSH0               // [0, 3]
        SSTORE              // store_0 = 3
        PUSH1 0x07        
        PUSH0
        MSTORE
        PUSH1 0x20
        PUSH0
        RETURN              // return 7 GOAL
        JUMPDEST            // if slot 0 == 3
        PUSH0
        SLOAD
        PUSH1 0x03
        EQ
        PUSH2 0x0098        // if slot 0 == 3
        JUMPI
        PUSH0
        PUSH0
        REVERT
        JUMPDEST          
        PUSH0
        PUSH0
        SSTORE
        PUSH1 0x07
        PUSH0
        MSTORE
        PUSH1 0x20
        PUSH0
        RETURN              // put 0 in storage and return 7
        JUMPDEST            // not eq revert
        PUSH0
        PUSH0
        REVERT 
    */

    function setUp() public {
        fork = vm.createFork(vm.envString("SEPOLIA_URL"));
    }

    /// @dev To keep it simple, if solution is right, no error starting with S11__ should be thrown
    ///
    /// @notice Depending on the value at slot 0, we can craft calldata:
    /// @notice 1st word of calldata points to the right function selector
    /// @notice 2nd second word of calldata is value that corresponds to slot_0 + msg.sender (0x444aE92325dCE5D14d40c30d2657547513674dD6)
    function testSolveChallengeCtfCyfrin11() external {
        vm.selectFork(fork);
        // change this value depending on the slot_0 value, this can also be done programmatically
        // this assumes current slot_0 value is 3
        bytes memory callData = hex"7aa9a7f90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000444ae92325dce5d14d40c30d2657547513674dd9";
        challenge.solveChallenge(TWITTER_HANDLE, callData);
    }

    function testGetValueFromSlot0() external {
        vm.selectFork(fork);
        bytes32 slot0 = vm.load(unverifiedContractAddr, bytes32(0));
        console.log(uint256(slot0));
    }
}