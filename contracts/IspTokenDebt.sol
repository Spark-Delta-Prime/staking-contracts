// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IspTokenDebt {
    function approveDelegation(address delegatee, uint amount) external;
}