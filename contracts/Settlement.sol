// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "hardhat/console.sol";
import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";

contract Settlement is AxelarExecutable {
    struct CreditDelegation {
        address supplier;
        address delegatee;
        uint delegatedAmount;
    }
    mapping(address => CreditDelegation) public delegators;
    bytes32 internal constant SELECTOR_ADD_DELEGATE = keccak256('delegateCredit');
    bytes32 internal constant SELECTOR_WITHDRAW_DELEGATE = keccak256('withdrawDelegation');
    IAxelarGasService public immutable gasService;
    address public destinationAddress;
    
    constructor(address gateway_, address gasReceiver_, address destinationAddress_) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
        destinationAddress = destinationAddress_;
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload_
    ) internal override {
		
		(bytes memory functionName, bytes memory params) = abi.decode(payload_, (bytes, bytes));

		if (keccak256(functionName) == SELECTOR_ADD_DELEGATE) {
            (address _supplier, address _delegatee, uint amount) = abi.decode(params, (address, address, uint));
            addDelegation(_supplier, _delegatee, amount);
        } else if(keccak256(functionName) == SELECTOR_WITHDRAW_DELEGATE) {
            (address _supplier, uint amount) = abi.decode(params, (address, uint));
            withdrawDelegation(_supplier, amount);
        } else {
            revert('Invalid function name');
        }
    }

    function addDelegation(address _supplier, address _delegatee, uint _amount) internal {
        delegators[_supplier] = CreditDelegation(_supplier, _delegatee, _amount); // add registry
    }

    function withdrawDelegation(address _supplier, uint _amount) internal {
        delegators[_supplier].delegatedAmount -= _amount;
    }

    function getDelegatee(address _supplier, address _delegate) public view returns(uint) {
        return delegators[_supplier].delegatedAmount;
    }
}
