// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import { AxelarExecutable } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol';
import { IAxelarGateway } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol';
import { IAxelarGasService } from '@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol';

contract Settlement is AxelarExecutable {
    struct CreditDelegation {
        address supplier;
        address delegatee;
        uint delegatedAmount;
    }
    mapping(address => CreditDelegation) public delegators;
    bytes32 internal constant SELECTOR_ADD_DELEGATE = keccak256('delegateCredit');
    
    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload_
    ) internal override {
		
		(bytes memory functionName, bytes memory params) = abi.decode(payload_, (bytes, bytes));

		if (keccak256(functionName) == SELECTOR_ADD_DELEGATE) {
            addDelegation();
        } else {
            revert('Invalid function name');
        }
    }

    function addDelegation(bytes params) public {
        
    }
}
