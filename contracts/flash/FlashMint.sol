pragma solidity >= 0.5.16;

import {AbstractERC20} from "../AbstractERC20.sol";

import {ERC20} from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import {SafeMath} from "openzeppelin-solidity/contracts/math/SafeMath.sol";

interface ArbGuy {
    function flashMintCallback() external;
}

interface IFlashMint {
    function flashMint() external;
}

contract FlashMint is AbstractERC20 {

    // Underlying implementation MUST ENFORCE NO OVERFLOWS
    function flashMint() external {
        _mint(msg.sender, 2 ** 250);  // probably enough.
        ArbGuy(msg.sender).flashMintCallback();
        _burn(msg.sender, 2 ** 250);
    }
}

contract FlashMintERC20 is IFlashMint, FlashMint, ERC20 {}
