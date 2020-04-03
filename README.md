## Enhanced ERC20

This is a menagerie of inheritable ERC20 contracts with advanced functionality.

So far we provide 3 features:

1. Distributions to token holders via `./contracts/distributions/`
1. Flash minting via `./contracts/flash/`
1. MKR-style buy-and-burn auctions via `./contracts/decirculate/`

Contracts are designed to be easy to use. For example the following 5 line file
is a complete, ready-to-use token with auctions and flash minting. It only
needs an initial distribution.

Future feature ideas:

1. Issuance curve
1. Issuance by bounded, fixed-price sale
1. Issuance by abstract sale terms


```
pragma solidity >= 0.5.16;

import {ERC20} from "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import {Decirculate} from "./decirculate/Decirculate.sol";
import {FlashMint} from "./flash/FlashMint.sol";

contract FlashDecirculate is Decirculate, FlashMint, ERC20 {}
```

## Important Note

It is not always safe to mix features! For example, `DistributeERC20` MUST NOT
be used with `FlashMint` or `Decirculate`. And `DistributeETH` MUST NOT be used
with `FlashMint`, but MAY be used with `Decirculate`. In the future, we will
maintain a compatibility chart, as well as add features to prevent
inappropriate combinations from being deployed.

## Design

Contracts inherit from `AbstractERC20`, and are abstract until an underlying
implementation implements its methods. `AbstractERC20` is concretely
implemented by Open Zeppelin's standard `ERC20` contract, but it is easy to
envision other concrete implementations. This means that you can inherit from
any number of Abstract contracts from this library and then "finish" them with
a concrete implementation.


## Developing

```
$ npm i
$ npm run test
```
