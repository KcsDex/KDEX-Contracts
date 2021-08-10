// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract KdexICO is Ownable {
    using SafeMath for uint256;

    IERC20 private kdexToken;
    address public kdexAddress;
    uint256 public kdexSoldAmount;

    mapping(address=>bool) private whitelist;  // can't be sold in this address
    mapping(address=>uint256) private salesBalance;  // when sale is over, the balance will be claimed
    uint256 public kdexPrice = 100;  // 100 kdex /1 kcs
    bool public saleIsOver = false;  // sale is over, token will be distributed when it is true
    bool public icoPaused = true;  // ico start after this is false;

    constructor (address _kdexAddress) {
        kdexAddress = _kdexAddress;
        kdexToken = IERC20(_kdexAddress);
        kdexSoldAmount = 0;
    }

    function kdexBalance() public view returns(uint256) {
        return kdexToken.balanceOf(address(this));
    }

    function kcsBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function withdrawKCS() public onlyOwner {
        payable(msg.sender).transfer(kcsBalance());
    }

    function withdrawKDEX() public onlyOwner {
        kdexToken.transfer(address(msg.sender), kdexBalance());
    }

    receive () external payable {
        require(!icoPaused, "Token sale is stopped!");
        require(!saleIsOver, "Token sale is over!");
        require(msg.value > 0, "You should send positive amount!");
        uint256 tokenAmount = kdexPrice.mul(msg.value);
        require(kdexBalance() > kdexSoldAmount + tokenAmount, "Token is not enough!");
        kdexSoldAmount += tokenAmount;
        salesBalance[msg.sender] += tokenAmount;
    }

    function claimKDEX() public {
        require(saleIsOver, "Token saling is not over yet!");
        uint256 accountBalance = salesBalance[msg.sender];
        require(accountBalance > 0, "You didn't purchase any amount of token!");
        require(kdexBalance() >= accountBalance, "Balance is not enough for your claim, please wait!");
        salesBalance[msg.sender] = 0;
        kdexToken.transfer(address(msg.sender), accountBalance);
    }

    function startSale() public onlyOwner {
        icoPaused = false;
    }

    function endSale() public onlyOwner {
        saleIsOver = true;
    }
}
