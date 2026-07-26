// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract VulnerableVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        require(msg.value > 0, "zero deposit");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(amount > 0, "zero amount");
        require(balances[msg.sender] >= amount, "insufficient balance");

        // Vulnerable flow: external call before balance update.
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "transfer failed");

        // Intentionally unchecked to preserve exploitability in Solidity >=0.8.
        unchecked {
            balances[msg.sender] -= amount;
        }
    }

    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
