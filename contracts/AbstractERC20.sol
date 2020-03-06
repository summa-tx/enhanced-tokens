pragma solidity >= 0.5.16;

import {IERC20} from "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

/// An abstract version of the OpenZeppelin ERC20
contract AbstractERC20 is IERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address account) public view returns (uint256);
    function transfer(address recipient, uint256 amount) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool);

    function _transfer(address sender, address recipient, uint256 amount) internal;
    function _mint(address account, uint256 amount) internal;
    function _burn(address account, uint256 amount) internal;
    function _approve(address owner, address spender, uint256 amount) internal;
    function _burnFrom(address account, uint256 amount) internal;
}
