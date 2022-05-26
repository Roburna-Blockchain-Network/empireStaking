// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardWallet is Ownable {
   
   uint256 public totalDeposited; 
   address public deployer;
   IERC20 public rewardsToken;

   event Deposit(address user, uint256 amount);
   event Withdrawal(address user, uint256 amount);
   event LogWithdrawalBNB(address account, uint256 amount);
   event LogWithdrawToken(address token, address account, uint256 amount);
   
   /** 
     * @dev Throws if called by any account other than the owner or deployer.
     */
   modifier onlyOwnerOrDeployer() {
       require(owner() == _msgSender() || deployer == _msgSender(), "Ownable: caller is not the owner or deployer");
       _;
   }

   constructor(IERC20 _rewardsToken, address _stakingContract){
      deployer = _msgSender();
      rewardsToken = _rewardsToken;
      //transferOwnership
      transferOwnership(_stakingContract);
   }

   function deposit(uint256 amount) external{
      require(rewardsToken.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance.");
      totalDeposited += amount;
      rewardsToken.transferFrom(msg.sender, address(this), amount);

      emit Deposit(msg.sender, amount);
   }

   function transfer(address account, uint256 amount) external onlyOwner{
      require(amount <= totalDeposited, "Insufficient funds");
      totalDeposited -= amount;
      rewardsToken.transfer(account, amount);

      emit Withdrawal(account, amount);
   }

   function getTotalDeposited() external view returns(uint256){
      return totalDeposited;
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
        require(token.transfer(account, amount), "Transfer Fail");

        emit LogWithdrawToken(address(token), account, amount);
   }

   function updateDeployerAddress(address newDeployer) external onlyOwnerOrDeployer{
        require(deployer != newDeployer, "The address is already set");
        deployer = newDeployer;
   }
}