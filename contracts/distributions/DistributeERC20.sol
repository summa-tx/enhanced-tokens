pragma solidity ^0.5.0;

import {ERC20} from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import {SafeERC20} from "openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

import {Distribute} from "./Distribute.sol";


contract DistributeERC20 is Distribute {

    using SafeERC20 for ERC20;

    ERC20 internal distributionToken = ERC20(address(0));

    function init(address _distributionToken) public {
        require(address(distributionToken) == address(0), "already init");
        distributionToken = ERC20(_distributionToken);
    }

    function _unclaimed() internal view returns (uint256) {
        return distributionToken.balanceOf(address(this));
    }

    function _distributeDividend(address _account, uint256 _outstanding) internal {
        distributionToken.safeTransfer(_account, _outstanding);
    }

    function _ensureFunding(uint256 _amount) internal {
        distributionToken.safeTransferFrom(msg.sender, address(this), _amount);
    }
}
