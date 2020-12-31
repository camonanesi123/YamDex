pragma solidity ^0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX {

  using SafeMath for uint256;
  IERC20 token;
  uint256 public totalLiquidity;
mapping (address => uint256) public liquidity;

  constructor(address token_addr) public {
    token = IERC20(token_addr);
  }
function init(uint256 tokens) public payable returns (uint256) {
  //如果没有流动性 抛出错误
  require(totalLiquidity==0,"DEX:init - already has liquidity");
  //流动性等于 当前地址的所有balance 之和
  totalLiquidity = address(this).balance;
  liquidity[msg.sender] = totalLiquidity;
  require(token.transferFrom(msg.sender, address(this), tokens));
  return totalLiquidity;
}
//计算价格 “price” is basically how much of the resulting output asset you will get if you put in a certain amount of the input asset.
function price(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256) {
  uint256 input_amount_with_fee = input_amount.mul(997);
  //x*y = k （numerator) const
  uint256 numerator = input_amount_with_fee.mul(output_reserve);
  uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
  return numerator / denominator;
}
//用ETH购买山寨币
function ethToToken() public payable returns (uint256) {
  //统计交易所里面保留的山寨币数目
  uint256 token_reserve = token.balanceOf(address(this));
  //计算能买多少山寨币
  uint256 tokens_bought = price(msg.value, address(this).balance.sub(msg.value), token_reserve);
  //把购买到的山寨币转给发送交易指令的钱包
  require(token.transfer(msg.sender, tokens_bought));
  return tokens_bought;
}
//用山寨币购买ETH
function tokenToEth(uint256 tokens) public returns (uint256) {
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 eth_bought = price(tokens, token_reserve, address(this).balance);
  msg.sender.transfer(eth_bought);
  require(token.transferFrom(msg.sender, address(this), tokens));
  return eth_bought;
}

function deposit() public payable returns (uint256) {
  uint256 eth_reserve = address(this).balance.sub(msg.value);
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 token_amount = (msg.value.mul(token_reserve) / eth_reserve).add(1);
  uint256 liquidity_minted = msg.value.mul(totalLiquidity) / eth_reserve;
  liquidity[msg.sender] = liquidity[msg.sender].add(liquidity_minted);
  totalLiquidity = totalLiquidity.add(liquidity_minted);
  require(token.transferFrom(msg.sender, address(this), token_amount));
  return liquidity_minted;
}
function withdraw(uint256 amount) public returns (uint256, uint256) {
  uint256 token_reserve = token.balanceOf(address(this));
  uint256 eth_amount = amount.mul(address(this).balance) / totalLiquidity;
  uint256 token_amount = amount.mul(token_reserve) / totalLiquidity;
  liquidity[msg.sender] = liquidity[msg.sender].sub(eth_amount);
  totalLiquidity = totalLiquidity.sub(eth_amount);
  msg.sender.transfer(eth_amount);
  require(token.transfer(msg.sender, token_amount));
  return (eth_amount, token_amount);
}
}
