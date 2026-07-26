// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {FixedVault} from "../src/FixedVault.sol";
import {VulnerableVault} from "../src/VulnerableVault.sol";

contract ReentrancyHardeningTest is Test {
    VulnerableVault internal vulnerableVault;
    FixedVault internal fixedVault;

    function setUp() public {
        vulnerableVault = new VulnerableVault();
        fixedVault = new FixedVault();
    }

    function testVulnerableRejectsZeroDeposit() public {
        vm.expectRevert("zero deposit");
        vulnerableVault.deposit{value: 0}();
    }

    function testFixedRejectsZeroDeposit() public {
        vm.expectRevert("zero deposit");
        fixedVault.deposit{value: 0}();
    }

    function testVulnerableRejectsZeroWithdraw() public {
        vm.expectRevert("zero amount");
        vulnerableVault.withdraw(0);
    }

    function testFixedRejectsZeroWithdraw() public {
        vm.expectRevert("zero amount");
        fixedVault.withdraw(0);
    }

    function testVulnerableRejectsOverWithdraw() public {
        _deposit(vulnerableVault, address(this), 1 ether);

        vm.expectRevert("insufficient balance");
        vulnerableVault.withdraw(2 ether);
    }

    function testFixedRejectsOverWithdraw() public {
        _deposit(fixedVault, address(this), 1 ether);

        vm.expectRevert("insufficient balance");
        fixedVault.withdraw(2 ether);
    }

    function testFixedSupportsIndependentAccountingForTwoUsers() public {
        address userA = makeAddr("userA");
        address userB = makeAddr("userB");

        _deposit(fixedVault, userA, 4 ether);
        _deposit(fixedVault, userB, 6 ether);

        vm.prank(userA);
        fixedVault.withdraw(1 ether);

        assertEq(fixedVault.balances(userA), 3 ether, "userA balance mismatch");
        assertEq(fixedVault.balances(userB), 6 ether, "userB balance mismatch");
        assertEq(address(fixedVault).balance, 9 ether, "vault accounting mismatch");
    }

    function testFuzzFixedDepositWithdrawRoundTrip(uint256 userPk, uint96 rawAmount) public {
        uint256 boundedPk = bound(userPk, 1, SECP256K1_ORDER - 1);
        address user = vm.addr(boundedPk);

        uint256 amount = bound(uint256(rawAmount), 1, 50 ether);
        vm.deal(user, amount);

        uint256 before = user.balance;
        vm.startPrank(user);
        fixedVault.deposit{value: amount}();
        fixedVault.withdraw(amount);
        vm.stopPrank();

        assertEq(user.balance, before, "user funds should round-trip");
        assertEq(fixedVault.balances(user), 0, "user internal balance should reset");
        assertEq(address(fixedVault).balance, 0, "vault should finish empty");
    }

    function testFuzzVulnerableDepositWithdrawRoundTripWithoutAttack(uint256 userPk, uint96 rawAmount) public {
        uint256 boundedPk = bound(userPk, 1, SECP256K1_ORDER - 1);
        address user = vm.addr(boundedPk);

        uint256 amount = bound(uint256(rawAmount), 1, 50 ether);
        vm.deal(user, amount);

        uint256 before = user.balance;
        vm.startPrank(user);
        vulnerableVault.deposit{value: amount}();
        vulnerableVault.withdraw(amount);
        vm.stopPrank();

        assertEq(user.balance, before, "user funds should round-trip");
        assertEq(vulnerableVault.balances(user), 0, "user internal balance should reset");
        assertEq(address(vulnerableVault).balance, 0, "vault should finish empty");
    }

    function _deposit(FixedVault vault, address user, uint256 amount) internal {
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
    }

    function _deposit(VulnerableVault vault, address user, uint256 amount) internal {
        vm.deal(user, amount);
        vm.prank(user);
        vault.deposit{value: amount}();
    }

}