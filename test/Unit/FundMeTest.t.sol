// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    DeployFundMe deployFundMe;
    address USER = makeAddr("USER");
    uint256 constant SEND_VALUE = 10 ether;
    uint256 constant STARTING_BALANCE = 100 ether;

    modifier funded() {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();
        assert(address(fundMe).balance > 0);
        _;
    }

    function setUp() external {
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testAyHaga() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
        console.log("MINIMUM_USD: ", fundMe.MINIMUM_USD());
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        if (block.chainid == 1) {
            assertEq(version, 6);
        } else {
            assertEq(version, 4);
        }
    }

    function testExpectRevert() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testAmountFunded() public funded {
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunder() public funded {
        // arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(fundMe.getAddressToAmountFunded(USER), 0);
        vm.expectRevert(); // funder is removed from the array; empty array
        assertEq(fundMe.getFunder(0), address(0));
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromAMultipleFunders() public funded {
        // arrange
        uint160 totalFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i < totalFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(fundMe.getAddressToAmountFunded(USER), 0);
        vm.expectRevert(); // funder is removed from the array; empty array
        assertEq(fundMe.getFunder(0), address(0));
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
        assertEq(totalFunders * SEND_VALUE, fundMe.getOwner().balance - startingOwnerBalance);
    }
}
