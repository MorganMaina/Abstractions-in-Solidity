// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///  A Simple Smart Wallet with EIP-4337 Simulation
/// This contract simulates basic EIP-4337 behavior with owner validation, a nonce, and optional gas sponsorship.

interface IERC20 {
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

contract SmartWallet {
    address public owner; // Wallet owner
    uint256 public nonce; // Used to prevent replay attacks

    event Executed(address to, uint256 value, bytes data);
    event Validated(address sender, uint256 nonce);

    constructor(address _owner) {
        owner = _owner;
        nonce = 0;
    }

    /// Validates a user operation (simulated signature check)
    /// @dev For demo purposes only – not secure for production
    function validateUserOp(
        address sender,
        uint256 _nonce,
        bytes calldata signature
    ) external view returns (bool) {
        // Simulate a signature check: owner must be the sender and nonce must match
        require(sender == owner, "Not owner");
        require(_nonce == nonce, "Invalid nonce");
        // Signature check would normally happen here
        return true;
    }

    /// @notice Executes a call to another address (can send ETH or call contracts)
    function execute(address to, uint256 value, bytes calldata data) external {
        require(msg.sender == owner, "Only owner");
        
        // Prevent replay by incrementing nonce
        nonce++;

        // Perform the call
        (bool success, ) = to.call{value: value}(data);
        require(success, "Call failed");

        emit Executed(to, value, data);
    }

    ///  Allows receiving ETH
    receive() external payable {}

    /// Batch execution of multiple transactions
    function batchExecute(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas) external {
        require(msg.sender == owner, "Only owner");
        require(targets.length == values.length && values.length == datas.length, "Array length mismatch");

        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, ) = targets[i].call{value: values[i]}(datas[i]);
            require(success, "Batch call failed");
        }

        nonce += targets.length;
    }

    /// Allows gas payments using ERC20 instead of ETH
    function payGasInToken(address token, address to, uint256 amount) external {
        require(msg.sender == owner, "Only owner");
        require(IERC20(token).transferFrom(owner, to, amount), "Token transfer failed");
    }
}

/// @title Paymaster Contract
/// Logs when it sponsors a transaction
contract Paymaster {
    event Sponsored(address user, uint256 gasAmount);

    /// Dummy function to simulate gas sponsorship
    function sponsor(address user, uint256 gasAmount) external {
        emit Sponsored(user, gasAmount);
    }
}

