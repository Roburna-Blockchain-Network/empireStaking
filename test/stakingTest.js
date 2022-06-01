const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking", function () {

  before(async function () {
    this.Iridium = await ethers.getContractFactory("Iridium")
    this.Staking = await ethers.getContractFactory("EmpireStaking")
    this.Empire = await ethers.getContractFactory("EmpireToken")
    this.Tresuary = await ethers.getContractFactory("EmpireStakingTresuary")
    this.Rewardwallet = await ethers.getContractFactory("RewardWallet")
    this.ReflectionsDistributor = await ethers.getContractFactory("ReflectionsDistributor")
    this.signers = await ethers.getSigners()
    this.owner = this.signers[0]
    this.vault1 = this.signers[5]
    this.vault2 = this.signers[3]
    this.farm = this.signers[4]
    this.alice = this.signers[2]
    this.bob = this.signers[1]
    this.charlie = this.signers[6]
    this.marketing = this.signers[7]
    this.team = this.signers[8]
    this.provider = await ethers.provider
    this.burnWallet = "0x000000000000000000000000000000000000dEaD"
    //this.factory = await ethers.getContractAt("IUniswapV2Factory", '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f')
    //this.router = await new ethers.Contract('0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D', ['function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity)'], this.provider)
    this.router = await new ethers.Contract('0x10ED43C718714eb63d5aA57B78B54704E256024E', ['function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity)', 'function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts)', 'function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts)', 'function swapExactTokensForETHSupportingFeeOnTransferTokens( uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external'], this.provider)     
  

    this.iridium = await this.Iridium.deploy(this.router.address, this.vault1.address, this.vault2.address)
    await this.iridium.deployed()   

    this.empire = await this.Empire.deploy(this.marketing.address, this.team.address, this.vault2.address)
    await this.empire.deployed   

    this.reflectionsDistributor = await this.ReflectionsDistributor.deploy(this.empire.address)
    await this.reflectionsDistributor.deployed()

    this.staking = await this.Staking.deploy(this.empire.address)
    await this.staking.deployed()   

    this.tresuary = await this.Tresuary.deploy(this.staking.address, this.empire.address, this.reflectionsDistributor.address)
    await this.tresuary.deployed()

    this.rewardwallet = await this.Rewardwallet.deploy(this.iridium.address, this.staking.address)
    await this.tresuary.deployed() 
 
   
     
    const RouterWSigner = await this.router.connect(this.owner)   
    
    await this.iridium.approve('0x10ED43C718714eb63d5aA57B78B54704E256024E', ethers.utils.parseEther("9000000000"));
    await RouterWSigner.addLiquidityETH(
      this.iridium.address,
      ethers.utils.parseEther("90000"),
      ethers.utils.parseEther("90000"),
      ethers.utils.parseEther("200"),
      this.owner.address ,
      Math.floor(Date.now() / 1000) + 60 * 10,
      {value : ethers.utils.parseEther("200")}
    );   

    await this.empire.approve('0x10ED43C718714eb63d5aA57B78B54704E256024E', ethers.utils.parseEther("9000000000"));
    await RouterWSigner.addLiquidityETH(
      this.empire.address,
      90000000000000,
      90000000000000,
      ethers.utils.parseEther("200"),
      this.owner.address ,
      Math.floor(Date.now() / 1000) + 60 * 10,
      {value : ethers.utils.parseEther("200")}
    );   

     
    await this.empire.enableTrading()
    await this.empire.excludeFromFee(this.staking.address)
    await this.empire.excludeFromFee(this.reflectionsDistributor.address)
    await this.empire.excludeFromFee(this.tresuary.address)
     
    await this.empire.transfer(this.alice.address, 900000000000000)
    await this.empire.transfer(this.bob.address, 900000000000000)
    await this.empire.transfer(this.charlie.address, 900000000000000)
    //await this.empire.transfer(this.tresuary.address, 900000000000000)
  })

  it("RewardWallet handles deposits correctly ", async function () {
    await this.iridium.approve(this.rewardwallet.address, ethers.utils.parseEther("10000000"))
    await this.rewardwallet.deposit(ethers.utils.parseEther("1000000"))  

    expect(await this.rewardwallet.getTotalDeposited()).to.equal(ethers.utils.parseEther("1000000"))
  })

  it("Make sure it sets reward wallet and treasury correctly", async function () {
    await this.staking.setTresuary(this.tresuary.address)
    await this.staking.setRewardWallet(this.rewardwallet.address) 

    expect(await this.staking.tresuary()).to.equal(this.tresuary.address)
    expect(await this.staking.rewardWallet()).to.equal(this.rewardwallet.address)
  })



  it("should handle deposits correctly", async function () {
    await this.empire.connect(this.alice).approve(this.tresuary.address, 100000000000000)
    await this.staking.connect(this.alice).stake(3000000000000)
    await this.staking.connect(this.alice).stake(3000000000000) 
    await this.empire.connect(this.bob).approve(this.tresuary.address, 100000000000000)
    await this.staking.connect(this.bob).stake(300000000000)
    
  })

  it("should withdraw rewards correctly", async function () {
    await this.staking.connect(this.alice).withdrawRewards()

    let alicebal = await this.iridium.balanceOf(this.alice.address)
    let bal = ethers.utils.formatEther(alicebal)
    console.log(bal)

  })

  it("should handle withdrawals correctly", async function () {
    await this.staking.connect(this.alice).unstake(10000000000)
    let alicebal = await this.empire.balanceOf(this.alice.address)
    let bal = ethers.utils.formatEther(alicebal)
    console.log(bal)
    await this.staking.setRewardRate(3000)
  })


  it(" Make sure it calculates rewards after updated reward rate correctly ", async function () {
    await this.staking.connect(this.alice).withdrawRewards()

    let alicebal = await this.iridium.balanceOf(this.alice.address)
    let bal = ethers.utils.formatEther(alicebal)
    console.log(bal)


  })

  it("Returns correct rewardrate", async function (){
    let rate = await this.staking.getRewardRate()
    expect(rate).to.equal(3000)
  })

  it("Set's isStaking to false if user balance 0", async function (){
    await this.staking.connect(this.bob).unstake(300000000000)
    expect(await this.staking.isStaking(this.bob.address)).to.equal(false)
  })


})  