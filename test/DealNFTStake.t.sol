// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DealNFT} from "../src/DealNFT.sol";
import {AccountV3TBD} from "../src/AccountV3TBD.sol";

import "multicall-authenticated/Multicall3.sol";
import "erc6551/ERC6551Registry.sol";
import "tokenbound/src/AccountGuardian.sol";

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {ERC20PresetFixedSupply} from "openzeppelin/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract DealNFTStake is Test {
    Multicall3 forwarder;
    ERC6551Registry public registry;
    AccountGuardian public guardian;

    DealNFT public deal;
    AccountV3TBD public implementation;
    IERC20 public escrowToken;

    uint256 tokenId = 0;
    uint256 amount = 10;
    address sponsor;
    address staker1;
    address staker2;

    function setUp() public {
        sponsor = vm.addr(1);
        staker1 = vm.addr(2);
        staker2 = vm.addr(3);

        escrowToken = new ERC20PresetFixedSupply(
            "escrow",
            "escrow",
            100,
            address(this)
        );
        registry = new ERC6551Registry();
        forwarder = new Multicall3();
        guardian = new AccountGuardian(address(this));

        implementation = new AccountV3TBD(
            address(1),
            address(forwarder),
            address(registry),
            address(guardian)
        );

        deal = new DealNFT(
            address(registry),
            payable(address(implementation)),
            sponsor,
            "https://test.com",
            "https://test.com",
            "https://x.com/@example",
            address(escrowToken),
            1 weeks
        );
        escrowToken.transfer(address(staker1), amount);
        escrowToken.transfer(address(staker2), amount);

        vm.prank(staker1);
        escrowToken.approve(address(deal), amount);
        vm.prank(staker2);
        escrowToken.approve(address(deal), amount);
    }

    function test_Stake() public {
        _configure();
        _approvals();

        vm.prank(staker1);
        deal.stake(amount);
        tokenId = 0;

        assertEq(deal.stakedAmount(tokenId), amount);
        assertEq(deal.totalStaked(), amount);
        assertEq(
            escrowToken.balanceOf(deal.getTokenBoundAccount(tokenId)),
            amount
        );
        assertEq(escrowToken.balanceOf(staker1), 0);
        assertEq(deal.ownerOf(tokenId), staker1);

        vm.prank(staker2);
        deal.stake(amount);
        tokenId = 1;

        assertEq(deal.stakedAmount(tokenId), amount);
        assertEq(deal.totalStaked(), amount * 2);
        assertEq(
            escrowToken.balanceOf(deal.getTokenBoundAccount(tokenId)),
            amount
        );
        assertEq(escrowToken.balanceOf(staker2), 0);
        assertEq(deal.ownerOf(tokenId), staker2);
    }

    function test_RevertWhen_StakeBeforeActive() public {
        assertEq(uint256(deal.state()), uint256(DealNFT.State.Configuration));
        vm.expectRevert("not an active deal");
        vm.prank(staker1);
        deal.stake(amount);
    }

    function test_RevertWhen_StakeAfterActive() public {
        _configure();
        skip(10 days);

        vm.expectRevert("not an active deal");
        vm.prank(staker1);
        deal.stake(amount);
    }

    function test_RevertWhen_StakeZero() public {
        _configure();
        vm.expectRevert("invalid amount");
        vm.prank(staker1);
        deal.stake(0);
    }

    function test_RevertWhen_NotApproved() public {
        _configure();
        vm.expectRevert("insufficient approval");
        vm.prank(staker1);
        deal.stake(amount);
    }

    function _configure() internal {
        vm.prank(sponsor);
        deal.configure("lorem ipsum", block.timestamp + 8 days, 0, 1000);
    }

    function _approvals() internal {
        vm.expectEmit(address(deal));
        emit DealNFT.StakerApproval(sponsor, staker1, amount);
        vm.prank(sponsor);
        deal.approveStaker(staker1, amount);

        vm.expectEmit(address(deal));
        emit DealNFT.StakerApproval(sponsor, staker2, amount);
        vm.prank(sponsor);
        deal.approveStaker(staker2, amount);
    }
}
