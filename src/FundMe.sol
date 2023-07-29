//Ge funds from users
//Withdraw funds
//Set a minimum funding value in USD

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

/*
 * @title A simple Funding Contract
 * @author Tega Osowa
 * @notice This contract is for the purpose of creating a simple fundme
 * @dev This implaments the price feed as library
 */

contract FundMe {
    //assigns the library to a type
    //attaches the PriceConverter library to all uint256
    using PriceConverter for uint256;

    //payable makes a function send money
    //ms.value provides the number of wei sent with the message
    //uint256 public myValue = 1;
    uint256 public constant MINIMUN_USD = 5e18;
    address[] private s_funders;
    mapping(address funder => uint256 amountFunded)
        private s_addressToAmountFunded;

    //using i_ to name an immutable variable
    address private immutable i_owner;
    AggregatorV3Interface private fund_priceFeed;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        fund_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        //1e18 = 1 ETH = 1000000000000000000 wei
        //require sets the least amount of wei to be sent with the message
        //myValue = myValue+2;
        //msg.value becomes the first parameter in the function
        //reverts is when an actions returns back to it's previous state
        //would revert an action if message.value is < 1 Ethereum
        require(
            msg.value.getConversionRate(fund_priceFeed) >= MINIMUN_USD,
            "didn't send enough ETH"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        return fund_priceFeed.version();
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (uint256 i = 0; i < fundersLength; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }

        s_funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            address funder = s_funders[i];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset array
        s_funders = new address[](0);

        //ways to withdraw money;
        //transfer
        //send
        //call

        //to transfer
        //msg.sender = address
        //payable(msg.sender) = payable address
        //payable(msg.sender).transfer(address(this).balance);

        //to send
        /*bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");*/

        //to call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    //modifiers helps set modifiers for functions and variables
    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Must be owner");
        if (msg.sender != i_owner) {
            /*Custom error handling*/
            revert FundMe__NotOwner();
        }
        _;
    }

    //fallback functions

    //receive
    //fallback

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
//forge install smartcontractkit/chainlink-brownie-contracts@0.6.1 --no-commit //github
//remappings is used to direct a lib from a text to a path
//forge test -m testPriceFeedVersionIsAccurate // run test on function
//forge test -vvv // debug
//forge test -vvv --fork-url $SEPOLIA_RPC_URL //test
// forge coverage --fork-url $SEPOLIA_RPC_URL //test
//forge test --match-test testPriceFeedVersionIsAccurate -vvv
//forge snapshot --match-test testPriceFeedVersionIsAccurate
//forge inspect FundMe storageLayout
//cast storage (contract address) index
//forge script script/Interactions.s.sol:FundFundMe
//forge script script/DeployFundMe.s.sol:DeployFundMe --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv

//make files
//build:; forge build
//make (command)
