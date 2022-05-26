// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IReflectionsDistributor {
    function deposit(address _user, uint256 _amount) external ;
    function withdraw(address _user, uint256 _amount) external ;
}