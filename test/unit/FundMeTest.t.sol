// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    //? what can we do to work with addresses outside our system?
    //* 1.) Unit Test
    //*   - Testing a specific part of our code
    //* 2.) Integration Test
    //*   - Testing how our contract works with other contracts
    //* 3.) Forked
    //*   - Testing how our contract works in a real environment
    //* 4.) Staging
    //*   - Testing our code in a real enviroment that is not prod

    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //* us -> fundMeTest -> fundMe
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    //Unit Test
    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MININUM_USD(), 5e18);
    }

    //Unit Test
    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    //Integration Test
    function testPriceFeedVersionIsAccuarate() public view {
        uint256 version = fundMe.getVersion();
        console.log("Version: ", version);
        assertEq(version, 4);
    }

    function testFundsFailWithoutEnoughETH() public {
        vm.expectRevert(); //* This line should revert !
        //* assertEq(this tx fails/ reverts);
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        //? Sets the *next* call's `msg.sender` to be the input address.
        vm.prank(USER); //* The next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);

        assertEq(funder, USER);
    }

    //* This is a good practice to avoid writing the same code over and over again
    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //TODO Metodology to any test
        //? Arrange -> Setup the test
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //? Act -> Call the function or action we want to test
        // uint256 gasStart = gasleft(); //* gasleft() -> returns the amount of gas left in the current call
        // vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        //? Assert -> Check the result of the action
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawWithMultipleFunders() public funded {
        //* Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFounderIndex = 1;

        for (uint160 i = startingFounderIndex; i < numberOfFunders; i++) {
            //* vm.prank
            //* vm.deal
            //* hoax let you simulate an address and make vm.deal at the same time
            hoax(address(i), SEND_VALUE);

            //* fund the FundMe
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //* Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //* Assert
        assert(address(fundMe).balance == 0);
        //! Becareful with this assert because you spend gas withdrawing so,
        //! the OnwerBalance != startingOwnerBalance + startingFundMeBalance
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        //* Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFounderIndex = 1;

        for (uint160 i = startingFounderIndex; i < numberOfFunders; i++) {
            //* vm.prank
            //* vm.deal
            //* hoax let you simulate an address and make vm.deal at the same time
            hoax(address(i), SEND_VALUE);

            //* fund the FundMe
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //* Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        //* Assert
        assert(address(fundMe).balance == 0);
        //! Becareful with this assert because you spend gas withdrawing so,
        //! the OnwerBalance != startingOwnerBalance + startingFundMeBalance
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
