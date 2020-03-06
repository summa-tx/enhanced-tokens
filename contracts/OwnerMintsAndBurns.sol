pragma solidity >=0.5.16;

import {AbstractERC20} from "./AbstractERC20.sol";

contract OwnerMintsAndBurns is AbstractERC20 {
    address internal _owner;

    function init(address _own) public {
        require(_owner == address(0), "already init");
        _owner = _own;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "onlyOwner");
        _;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(address account, uint256 value) public onlyOwner {
        _burn(account, value);
    }
}
