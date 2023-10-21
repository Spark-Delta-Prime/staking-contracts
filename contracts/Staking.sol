// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';

contract Staking is AxelarExecutable {
    mapping(address => uint) public balances;
    // mapping(address => uint) public supplyTime;
    // goerli
    address sparkPool = 0x26ca51Af4506DE7a6f0785D20CD776081a05fF6d;

    IAxelarGasService public immutable gasService;
	string public destinationChain = 'mantle';
    string public destinationAddress;

     // Event to emit when a deposit is made
    event Deposit(address indexed sender, uint amount, uint chainId);
    // Event to emit when a withdrawal is made
    event Withdrawal(address indexed receiver, uint amount);

    constructor(address gateway_, address gasReceiver_, address destinationAddress_) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
        destinationAddress = destinationAddress_;
    }
    
    function depositLiquidity(address token, uint supplyAmount) {
      IERC20(token).approve(aavePool, supplyAmount);
      IPool(sparkPool).supply(token, supplyAmount, address(this), 0);
      balances[msg.sender] += supplyAmount;

      emit Deposit(msg.sender, supplyAmount, chainId);
    }

    function delegateCredit(address delegatee, uint amount, address spToken) {
        // Sets the amount of allowance for delegatee to borrow of a particular debt token.
       IERC20(spToken).approveDelegation(delegatee, amount);
       bytes memory params = abi.encode(msg.sender, delegatee, amount);
       bytes memory payload = abi.encode('delegateCredit', params);
       gasService.payNativeGasForContractCall{value: msg.value}(
			address(this),
			destinationChain,
			destinationAddress,
			payload,
			msg.sender
		);
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    function Withdrawal(address token, uint amount) {
        balances[msg.sender] -= amount;
        IPool(sparkPool).withdraw(token, amount, msg.sender);
    }
}