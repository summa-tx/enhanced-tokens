pragma solidity >= 0.5.16;

import {AbstractERC20} from "../AbstractERC20.sol";
import {OwnerMintsAndBurns} from "../OwnerMintsAndBurns.sol";

import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Distribute is AbstractERC20 {

    using SafeMath for uint256;

    uint256 internal constant pointMultiplier = 10 ** 18;

    uint256 internal _totalPoints;
    mapping (address => uint256) internal _distributionPoints;

    function _unclaimed() internal view returns (uint256);
    function _distribute(address _account, uint256 _outstanding) internal;
    function _ensureFunding(uint256 _amount) internal;

    //
    // Adding Distribution funds
    //

    function sendDistributionFunds(uint _amount) public payable {
        _ensureFunding(_amount);
        _totalPoints = _totalPoints.add(_amount.mul(pointMultiplier).div(totalSupply()));
    }

    //
    // Distribution Logic
    //

    /* TODO: better mental model of this*/
    function _outstandingPoints(address _account) internal view returns (uint256) {
        if(_account == address(this)) {
            return 0;
        }
        uint256 _outstanding = _totalPoints.sub(_distributionPoints[_account]);
        return (balanceOf(_account).mul(_outstanding)).div(pointMultiplier);
    }


    function _runDistributions(address _account) internal {
        uint256 _outstanding = _outstandingPoints(_account);
        if(_outstanding > 0) {
            /* NB: This is the part where we actually distribute */
            _distributionPoints[_account] = _totalPoints;
            _distribute(_account, _outstanding);
        }
    }

    //
    // Extend ERC20 to avoid bricking things
    //

    // make sure that errors in _distribution issuance can't lock an account
    function transferDividend(address _recipient) public returns (bool) {
        uint256 _outstanding = _outstandingPoints(msg.sender);
        _distributionPoints[msg.sender] = _totalPoints;
        _distribute(_recipient, _outstanding);
    }

    //
    // ERC20 functions wrapped with _runDistributions()
    //

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _runDistributions(msg.sender);
        _runDistributions(recipient);
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _runDistributions(sender);
        _runDistributions(recipient);
        _transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        _runDistributions(account);
        return AbstractERC20._mint(account, amount);
    }

    function _burn(address account, uint256 value) internal {
        _runDistributions(account);
        return AbstractERC20._burn(account, value);
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}
