pragma solidity >= 0.5.16;

import {Distribute} from "./Distribute.sol";

contract DistributeETH is Distribute {

    uint256 _lastBalance = 0;

    function _unclaimed() internal view returns (uint256) {
        return address(this).balance;
    }

    function _distribute(address _account, uint256 _owing) internal {
        address payable _payableAccount = address(bytes20(_account));
        _payableAccount.transfer(_owing);
    }

    function _ensureFunding(uint256 _amount) internal {
        require(address(this).balance >= _amount + _lastBalance, "no ETH received");
        _lastBalance = address(this).balance;
    }
}
