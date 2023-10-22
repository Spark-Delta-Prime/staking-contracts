// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";
import "./IspTokenDebt.sol";

contract Staking is AxelarExecutable {
    mapping(address => uint) public balances;
    mapping(address => uint) public borrowedAmount;
    // mapping(address => uint) public supplyTime;
    // goerli
    address sparkPool = 0x26ca51Af4506DE7a6f0785D20CD776081a05fF6d;

    IAxelarGasService public immutable gasService;
	string public destinationChain = 'mantle';
    string public destinationAddress;
    bytes32 internal constant SELECTOR_GET_LOAN = keccak256('getLoan');
    address public spToken = 0xD72630D78157E1a2feD7A329873Bfd496704403D;
    IspTokenDebt interfaceDebtToken = IspTokenDebt(spToken);

     // Event to emit when a deposit is made
    event Deposit(address indexed sender, uint amount);
    // Event to emit when a withdrawal is made
    event Withdrawal(address indexed receiver, uint amount);

    constructor(address gateway_, address gasReceiver_, string memory destinationAddress_) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
        destinationAddress = destinationAddress_;
    }
    
    function depositLiquidity(address token, uint supplyAmount) public {
      IERC20(token).approve(sparkPool, supplyAmount);
      IPool(sparkPool).supply(token, supplyAmount, address(this), 0);
      balances[msg.sender] += supplyAmount;

      emit Deposit(msg.sender, supplyAmount);
    }

    function delegateCredit(address delegatee, uint amount) public payable {
        // Sets the amount of allowance for delegatee to borrow of a particular debt token.
       interfaceDebtToken.approveDelegation(delegatee, amount);
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

    function getLoan(address _delegatee, uint _amount) internal {
        require(_delegatee != address(0) || _delegatee != address(this), 'Invalid Delegate');
        require(_amount > 0, 'Invalid amount');
        IPool(sparkPool).borrow(0xD72630D78157E1a2feD7A329873Bfd496704403D, _amount, 1, 0, _delegatee);
        borrowedAmount[_delegatee] += _amount;
    }

    function Withdraw(address token, uint amount) public {
        balances[msg.sender] -= amount;
        IPool(sparkPool).withdraw(token, amount, msg.sender);
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload_
    ) internal override {
		
		(bytes memory functionName, bytes memory params) = abi.decode(payload_, (bytes, bytes));

		if (keccak256(functionName) == SELECTOR_GET_LOAN) {
            (address _delegatee, uint amount) = abi.decode(params, (address, uint));
            getLoan(_delegatee, amount);
        } else {
            revert('Invalid function name');
        }
    }

}
