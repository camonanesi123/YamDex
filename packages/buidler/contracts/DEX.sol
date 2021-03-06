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
//计算价格 扔进去好多数目的A 出来好多数目的B
function price(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256) {
  uint256 input_amount_with_fee = input_amount.mul(997);
  // 1000 * 997 = 997000

  //x*y = k （numerator) const

  // (x+delta(x)) * (y-delta(y)) = x*y
  // calculate delta(y) = y - x*y/(x+delta(x))
  // gained = (y*x+y*delta(x)-x*y)/(x+delta(x))
  // = y*delta(x) / (x+delta(x))

  // assign numerator = y*delta(x)
  uint256 numerator = input_amount_with_fee.mul(output_reserve);
  //997000*1000000

  //流动性池里面的input_reserve + 需要换的input_amount_with_fee
  uint256 denominator = input_reserve.mul(1000).add(input_amount_with_fee);
  //1000000*1000+997000

 // gained = numerator / denominator;
  return numerator / denominator;
  //997000*1000000/1000000*1000+997000

}
//用ETH购买山寨币
function ethToToken() public payable returns (uint256) {
  //统计交易所里面保留的山寨币数目
  uint256 token_reserve = token.balanceOf(address(this));

  //计算能买多少山寨币(买的ETH数量，交易所现存以太坊数量,交易所现存山寨币数量)
  //现存ETH量= 合约中的ETH总量 - 本次转账的量
  uint256 tokens_bought = price(msg.value, address(this).balance.sub(msg.value), token_reserve);

  //把购买到的山寨币转给发送交易指令的钱包
  require(token.transfer(msg.sender, tokens_bought));
  return tokens_bought;
}
//用山寨币购买ETH
function tokenToEth(uint256 tokens) public returns (uint256) {
  //交易所合约地址中山寨币的量
  uint256 token_reserve = token.balanceOf(address(this));
  //可以买到的ETH量 
  uint256 eth_bought = price(tokens, token_reserve, address(this).balance);
  msg.sender.transfer(eth_bought);
  require(token.transferFrom(msg.sender, address(this), tokens));
  return eth_bought;
}

//提供流动性
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

//取出流动性
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
