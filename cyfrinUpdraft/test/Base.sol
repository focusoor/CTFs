// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

interface IERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4);
}

contract Base is Test {
    string constant TWITTER_HANDLE = "focusoor";
    address constant BOB = address(0xbb);

    address constant CHALLENGE_1 = address(0x76D2403b80591d5F6AF2b468BC14205fa5452AC0);
    address constant CHALLENGE_2 = address(0x34d130B174F4a30A846FED7C02FCF53A19a4c2B6);
    address constant CHALLENGE_3 = address(0xA2626bE06C11211A44fb6cA324A67EBDBCd30B70);
    address constant CHALLENGE_4 = address(0xf988Ebf9D801F4D3595592490D7fF029E438deCa);
    address constant CHALLENGE_5 = address(0xdeB8d8eFeF7049E280Af1d5FE3a380F3BE93B648);
    address constant CHALLENGE_6 = address(0xcf4fbA490197452Bd414E16D563623253eFb57D3);
    address constant CHALLENGE_7 = address(0x33ee14Fb8816c92fe401165330bbE29706942183);

    address constant HELPER_11 = address(0x4221EC0A43138CF0135b2Bd91Dd3b176E1E22908);
    address constant CHALLENGE_11 = address(0x444aE92325dCE5D14d40c30d2657547513674dD6);

    address constant HELPER_12 = address(0xf2dde8E99f583b5354441EB7a141042419082596);
    address constant CHALLENGE_12 = address(0x3DbBF2F9AcFB9Aac8E0b31563dd75a2D69148D64);
    
    address constant CHALLENGE_13 = address(0x7D4a746Cb398e5aE19f6cBDC08473664ADBc6da5);

    uint256 public sepoliaFork;

    event ChallengeSolved(address solver, address challenge, string twitterHandle);

    function setUp() public virtual {
        sepoliaFork = vm.createFork(vm.envString("SEPOLIA_URL"));
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
