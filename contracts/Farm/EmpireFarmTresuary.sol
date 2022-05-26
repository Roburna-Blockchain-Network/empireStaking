// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IEmpireFarmTresuary.sol";
import "../Stake/IRewardWallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract EmpireFarmTresuary is Ownable {

    mapping(address => uint256) balance;
    address public farmContract;
    address public deployer;

    IERC20 public lpToken;

    event Deposit(address user, uint256 amount);
    event Withdrawal(address user, uint256 amount);
    event FarmContractUpdated(address oldFarmContract, address newFarmContract);
    event LpTokenUpdated(IERC20 oldLpToken, IERC20 newLpToken);
    event LogWithdrawalBNB(address account, uint256 amount);
    event LogWithdrawToken(address token, address account, uint256 amount);

    /** 
     * @dev Throws if called by any account other than the owner or deployer.
     */
    modifier onlyOwnerOrDeployer() {
        require(owner() == _msgSender() || deployer == _msgSender(), "Ownable: caller is not the owner or deployer");
        _;
    }

    constructor(address _farmContract, IERC20 _lpToken){
        deployer = _msgSender();
        lpToken = _lpToken;
        farmContract = _farmContract;
        
        transferOwnership(_farmContract);
    }

    function deposit(address staker, uint256 amount) external onlyOwner{
        require(lpToken.allowance(staker, address(this)) >= amount, "Insufficient allowance.");
        balance[staker] += amount;
        lpToken.transferFrom(staker, address(this), amount);
        emit Deposit(staker, amount);
    }

    function withdraw(address staker, uint256 amount) external onlyOwner{
        require(balance[staker] >= amount, "Insufficient balance");
        balance[staker] -= amount;
        lpToken.transfer(staker, amount);
        emit Withdrawal(staker, amount);
    }

    function updateFarmContract(address _farmContract) external onlyOwnerOrDeployer{
        emit FarmContractUpdated(farmContract, _farmContract);
        farmContract = _farmContract;
    }

    function updateLpToken(IERC20 _lpToken) external onlyOwnerOrDeployer{
        emit LpTokenUpdated(lpToken, _lpToken);
        lpToken = _lpToken;
    }

    function withdrawBNB(address payable account, uint256 amount) external onlyOwnerOrDeployer {
        require(amount <= (address(this)).balance, "Incufficient funds");
        account.transfer(amount);
        emit LogWithdrawalBNB(account, amount);
   }

    /**
     * @notice Should not be withdrawn scam token.
     */
    function withdrawToken(IERC20 token, address account, uint256 amount) external onlyOwnerOrDeployer {
        require(amount <= token.balanceOf(account), "Incufficient funds");
        require(token != lpToken, "Can't withdraw lpToken");
        
        require(token.transfer(account, amount), "Transfer Fail");

        emit LogWithdrawToken(address(token), account, amount);
    }

    function updateDeployerAddress(address newDeployer) external onlyOwnerOrDeployer{
        require(deployer != newDeployer, "The address is already set");
        deployer = newDeployer;
    }


}