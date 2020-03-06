pragma solidity >= 0.5.16;

import {AbstractERC20} from "../AbstractERC20.sol";
import {OwnerMintsAndBurns} from "../OwnerMintsAndBurns.sol";

import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract TokenWithDividends is AbstractERC20, OwnerMintsAndBurns {

    using SafeMath for uint256;

    uint256 internal constant pointMultiplier = 10 ** 18;

    uint256 internal _totalDividendPoints;
    mapping (address => uint256) internal _dividendPoints;

    function _unclaimed() internal view returns (uint256);
    function _distributeDividend(address _account, uint256 _outstanding) internal;
    function _ensureFunding(uint256 _amount) internal;

    function init(address _own) public {
        OwnerMintsAndBurns.init(_own);
    }

    //
    // Adding dividend funds
    //

    function sendDividendFunds(uint _amount) public payable {
        _ensureFunding(_amount);
        _totalDividendPoints = _totalDividendPoints.add(_amount.mul(pointMultiplier).div(totalSupply()));
    }

    //
    // Distribution Logic
    //

    /* TODO: better mental model of this*/
    function _outstandingPoints(address _account) internal view returns (uint256) {
        if(_account == address(this)) {
            return 0;
        }
        uint256 _outstanding = _totalDividendPoints.sub(_dividendPoints[_account]);
        return (balanceOf(_account).mul(_outstanding)).div(pointMultiplier);
    }


    function _distributeDividends(address _account) internal {
        uint256 _outstanding = _outstandingPoints(_account);
        if(_outstanding > 0) {
            /* NB: This is the part where we actually dividend */
            _dividendPoints[_account] = _totalDividendPoints;
            _distributeDividend(_account, _outstanding);
        }
    }

    //
    // Extend ERC20 to avoid bricking things
    //

    // make sure that errors in dividend issuance can't lock an account
    function transferDividend(address _recipient) public returns (bool) {
        uint256 _outstanding = _outstandingPoints(msg.sender);
        _dividendPoints[msg.sender] = _totalDividendPoints;
        _distributeDividend(_recipient, _outstanding);
    }

    //
    // ERC20 functions wrapped with _distributeDividends()
    //

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _distributeDividends(msg.sender);
        _distributeDividends(recipient);
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _distributeDividends(sender);
        _distributeDividends(recipient);
        _transfer(sender, recipient, amount);
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        _distributeDividends(account);
        return AbstractERC20._mint(account, amount);
    }

    function _burn(address account, uint256 value) internal {
        _distributeDividends(account);
        return AbstractERC20._burn(account, value);
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }
}
