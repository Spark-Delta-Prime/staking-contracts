// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { AxelarExecutable } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executable/AxelarExecutable.sol";
import { IAxelarGateway } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import { IAxelarGasService } from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGasService.sol";

contract Escrow is AxelarExecutable {
    mapping(address => uint) public waranty;
    // IERC20 public Ierc20;
    string public destinationAddress;
    IAxelarGasService public immutable gasService;

    constructor(address gateway_, address gasReceiver_, string memory destinationAddress_) AxelarExecutable(gateway_) {
        gasService = IAxelarGasService(gasReceiver_);
        destinationAddress = destinationAddress_;
    }

    function depositWaranty(uint _amount, address _token) public {
        IERC20(_token).approve(address(this), _amount);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        waranty[msg.sender] += _amount;
    }

    function executeLoan(uint _amount, string memory _chainDestination) public payable {
        require(waranty[msg.sender] > 0, 'No access to get loan');
        uint creditScore = 5;
        // send credit execution
        bytes memory params = abi.encode(msg.sender, _amount);
        bytes memory payload = abi.encode('getLoan', params);
        gasService.payNativeGasForContractCall{value: msg.value}(
            address(this),
            _chainDestination,
            destinationAddress,
            payload,
            msg.sender
        );
        gateway.callContract(_chainDestination, destinationAddress, payload);
    }
}