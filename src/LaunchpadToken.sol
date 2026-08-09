//SPDX-License_Identifier: MIT

pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract LaunchpadToken is ERC20, ERC20Capped, ERC20Burnable, Ownable {
    constructor(string memory name, string memory symbol, uint256 cap, uint256 initialSupply, address initialOwner)
        ERC20(name, symbol)
        ERC20Capped(cap)
        Ownable(initialOwner)
    {
        _mint(initialOwner, initialSupply);
    }

    function mint(address to, uint256 value) public onlyOwner {
        _mint(to, value);
    }

    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Capped) {
        super._update(from, to, value);
    }
}
