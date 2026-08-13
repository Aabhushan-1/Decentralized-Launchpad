//SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {LaunchpadToken} from "../src/LaunchpadToken.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Capped} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract LaunchpadTokenTests is Test {
    LaunchpadToken launchpadToken;
    address owner = makeAddr("owner");
    address user = makeAddr("user");

    string _name = "LaunchpadToken";
    string _symbol = "LPT";
    uint256 _cap = 1000;
    uint256 _initialSupply = 100;
    address _initialOwner = owner;

    function setUp() public {
        launchpadToken = new LaunchpadToken(_name, _symbol, _cap, _initialSupply, _initialOwner);
    }

    function test_initialSupply_Is_Minted_To_initialOwner() public view {
        assertEq(launchpadToken.balanceOf(owner), _initialSupply);
    }

    function test_Mint_Reverts_If_Not_Owner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        launchpadToken.mint(user, _initialSupply);
    }

    function test_mint_Reverts_Beyond_Cap() public {
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(ERC20Capped.ERC20ExceededCap.selector, _initialSupply + (_cap + 1), _cap)
        );
        launchpadToken.mint(user, _cap + 1);
    }

    function test_mint_Reverts_If_Receiver_Is_Zero() public {
        address receiver = address(0);
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InvalidReceiver.selector, receiver));
        launchpadToken.mint(receiver, _initialSupply);
    }

    function test_Owner_Can_Mint() public {
        uint256 initialUserBalance = launchpadToken.balanceOf(user);
        vm.prank(owner);
        launchpadToken.mint(user, _initialSupply);
        uint256 finalUserBalance = launchpadToken.balanceOf(user);

        assertEq(finalUserBalance, initialUserBalance + _initialSupply);
    }

    function test_update_Reverts_If_Insufficient_Balance() public {
        uint256 balanceOfOwner = launchpadToken.balanceOf(owner);
        vm.prank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector, owner, balanceOfOwner, balanceOfOwner + 1
            )
        );
        bool success = launchpadToken.transfer(user, balanceOfOwner + 1);
        assertEq(success, false);
    }

    function test_Burn_Works() public {
        uint256 initialbalanceOfOwner = launchpadToken.balanceOf(owner);
        uint256 amountBurned = initialbalanceOfOwner;

        vm.prank(owner);
        launchpadToken.burn(amountBurned);

        uint256 finalbalanceOfOwner = launchpadToken.balanceOf(owner);

        assertEq(finalbalanceOfOwner, initialbalanceOfOwner - amountBurned);
    }

    function test_Transfer_Works() public {
        uint256 initialBalanceOfOwner = launchpadToken.balanceOf(owner);
        uint256 initialBalanceOfUser = launchpadToken.balanceOf(user);
        uint256 allowance = _initialSupply;

        vm.prank(owner);
        bool success = launchpadToken.transfer(user, allowance);
        assertEq(success, true);

        uint256 finalBalanceOfOwner = launchpadToken.balanceOf(owner);
        uint256 finalBalanceOfUser = launchpadToken.balanceOf(user);

        assertEq(finalBalanceOfOwner, initialBalanceOfOwner - allowance);
        assertEq(finalBalanceOfUser, initialBalanceOfUser + allowance);
    }

    function test_TransferFrom_Works() public {
        uint256 initialBalanceOfOwner = launchpadToken.balanceOf(owner);
        uint256 initialBalanceOfUser = launchpadToken.balanceOf(user);
        uint256 allowance = _initialSupply;

        vm.prank(owner);
        launchpadToken.approve(user, allowance);

        vm.prank(user);
        bool success = launchpadToken.transferFrom(owner, user, allowance);
        assertEq(success, true);

        uint256 finalBalanceOfOwner = launchpadToken.balanceOf(owner);
        uint256 finalBalanceOfUser = launchpadToken.balanceOf(user);

        assertEq(finalBalanceOfOwner, initialBalanceOfOwner - allowance);
        assertEq(finalBalanceOfUser, initialBalanceOfUser + allowance);
    }

    function test_TransferFrom_Reverts_If_Exceeds_Allowance() public {
        uint256 allowance = _initialSupply;

        vm.prank(owner);
        launchpadToken.approve(user, allowance);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, user, allowance, allowance + 1)
        );
        bool success = launchpadToken.transferFrom(owner, user, allowance + 1);
        assertEq(success, false);
    }

    function test_Name_Symbol_Decimals_Are_Set_Correctly() public view {
        assertEq(launchpadToken.name(), _name);
        assertEq(launchpadToken.symbol(), _symbol);
        assertEq(launchpadToken.decimals(), 18);
    }
}
