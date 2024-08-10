// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

contract Base is Test {
    string constant TWITTER_HANDLE = "focusoor";
    address constant BOB = address(0xbb);

    address constant CHALLENGE_13 = address(0x7D4a746Cb398e5aE19f6cBDC08473664ADBc6da5);

    uint256 public sepoliaFork;

    event ChallengeSolved(address solver, address challenge, string twitterHandle);

    function setUp() public virtual {
        sepoliaFork = vm.createFork(vm.envString("SEPOLIA_URL"));
    }
}
