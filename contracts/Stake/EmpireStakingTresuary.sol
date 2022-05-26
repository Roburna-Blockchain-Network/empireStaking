//SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEmpireStakingTresuary.sol";
import "./IReflectionsDistributor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EmpireStakingTresuary is Ownable, IEmpireStakingTresuary{
    

    mapping(address => uint256) balance;
    address public stakingContract;
    address public deployer;
    uint256 public totalBalance;
    uint256 numTokenReflectionsToDistribute;
    address public reflectionsDistributorAddress;
    

    IERC20 public empireToken;
    IReflectionsDistributor public reflectionsDistributor;

    event Deposit(address user, uint256 amount);
    event Withdrawal(address user, uint256 amount);
    event StakingContractUpdated(address oldStakingContract, address newStakingContract);
    event stakingTokenUpdated(IERC20 oldToken, IERC20 newToken);

    /** 
     * @dev Throws if called by any account other than the owner or deployer.
     */
    modifier onlyOwnerOrDeployer() {
        require(owner() == _msgSender() || deployer == _msgSender(), "Ownable: caller is not the owner or deployer");
        _;
    }

    constructor(address _stakingContract, IERC20 _empireToken, IReflectionsDistributor _reflectionsDistributor){
        deployer = _msgSender();
        empireToken = _empireToken;
        stakingContract = _stakingContract;
        reflectionsDistributor = _reflectionsDistributor;
        
        transferOwnership(_stakingContract);
    }

    function deposit(address staker, uint256 amount) external onlyOwner{
        require(empireToken.allowance(staker, address(this)) >= amount, "Insufficient allowance.");
        balance[staker] += amount;
        totalBalance += amount;

        uint256 contractBalance = getTotalBalance();
        uint256 contractBalanceWReflections = empireToken.balanceOf(address(this));

        /** 
         * @notice Transfers accumulated reflections to the reflectionsDistributor 
         * if the amount is reached
         */
        if(contractBalanceWReflections - contractBalance >= numTokenReflectionsToDistribute){
           empireToken.transfer(reflectionsDistributorAddress, numTokenReflectionsToDistribute);
        }

        reflectionsDistributor.deposit(staker, amount);
        empireToken.transferFrom(staker, address(this), amount);
        emit Deposit(staker, amount);
    }

    function withdraw(address staker, uint256 amount) external onlyOwner{
        require(balance[staker] >= amount, "Insufficient balance");
        balance[staker] -= amount;
        totalBalance -= amount;
        empireToken.transfer(staker, amount);

        uint256 contractBalance = getTotalBalance();
        uint256 contractBalanceWReflections = empireToken.balanceOf(address(this));

        /** 
         * @notice Transfers accumulated reflections to the reflectionsDistributor 
         * if the amount is reached
         */
        if(contractBalanceWReflections - contractBalance >= numTokenReflectionsToDistribute){
           empireToken.transfer(reflectionsDistributorAddress, numTokenReflectionsToDistribute);
        }
        
        reflectionsDistributor.withdraw(staker, amount);
        emit Withdrawal(staker, amount);
    }

    function updateStakingContract(address _stakingContract) external onlyOwnerOrDeployer{
        emit StakingContractUpdated(stakingContract, _stakingContract);
        stakingContract = _stakingContract;
    }

    function updateLpToken(IERC20 _empireToken) external onlyOwnerOrDeployer{
        emit stakingTokenUpdated(empireToken, _empireToken);
        empireToken = _empireToken;
    }

    function getTotalBalance() public view returns(uint256){
        return totalBalance;
    }

    function updateNumTokenReflectionsToDistribute(uint256 _numTokenReflectionsToDistribute) external onlyOwnerOrDeployer{
        numTokenReflectionsToDistribute = _numTokenReflectionsToDistribute;
    }

    function updateDeployerAddress(address newDeployer) external onlyOwnerOrDeployer{
        require(deployer != newDeployer, "The address is already set");
        deployer = newDeployer;
    }

}