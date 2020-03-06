pragma solidity >= 0.5.16;

import {ERC20} from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import {Decirculate} from "./decirculate/Decirculate.sol";
import {FlashMint} from "./flash/FlashMint.sol";

contract FlashDecirculate is Decirculate, FlashMint, ERC20 {}
