// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

// to check our math
//dont allow overflow to occur

// import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//here we are importing from the npm package in github
//this is the code we are importing
interface AggregatorV3Interface {
    //we need the interfaces to recognize the contracts that we dont have and to interact with them
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

//this contract have to accept some type of payment
contract FundMe {


    //applying the safe math contract
    using SafeMathChainlink for uint256;

    AggregatorV3Interface public priceFeed;

    address[] public funders;

    //we want to keep track of who sent us funding
    //create a new mapping between addresses and value

    mapping(address => uint256) public addressToAmountFunded;
    address owner;

    //establish the admin of the contract
    constructor (address _priceFeed) public{
        
        priceFeed = AggregatorV3Interface(_priceFeed);

        owner = msg.sender;
    }

    function fund() public payable {
        addressToAmountFunded[msg.sender] += msg.value;
        //msg.sender is the address of the person who call the function
        //or do the transaction, what means that within it is a value in eth that he sends
        //this value are the funds that will be mapped with the address.
        //the funds sent will be owned by the contract.

        //we want to establish a minimum fund that the contract accept
        //so we have to do the conversion between eth and usd

        uint256 minimumUSD = 5 * 10**18;
        //we multiply 10**18 the msg.value is in wei
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "CHUPALA BYRON MMVERGA"
        );

        //now we have to withdraw the money

        //conversion
        //what ETH => USD conversion rate is
        //in order to get the conversion rate we need to ask it to a decentralized oracle network
        //first we need to import the chainlink code that provides us the conexion to the newtwork
        //import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
        funders.push(msg.sender);
    }

    //this is a function that calls another function
    function getVersion() public view returns (uint256) {
        /*
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        */
        //this means that we have a contract with the properties of the Agg interface located at that address
        //this address is from a contract that is a oracle network that has it. One network node will send you the contract.
        return priceFeed.version();
        //here we can access to the version function
    }

    function getPrice() public view returns (uint256) {
        /*
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        */
        
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
        //we multiply here 10000000000 in order to match the usd price with the wei standard
        //Make everything have 18 decimals as wei, this is not a rule
        //254089262502
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        //adjust it by dividing to that number because each of the tow values have 10 raised to the 18 tacked on them. (10**18)
        return ethAmountInUsd;
        //return 2529536691550
        //it has 18 decimals, so we divided it
        // $ 0.000002529536691550, so this is 1 gwei of eth in usd
        // using the actual prince in dollars of eth
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 5 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
        //this _; means that the require line will be excecuted before
        //the code in which this modifier will be.
    }

    function withdraw() public payable onlyOwner {
        //only want the contract admin/owner
        //require msg.sender = owner
        require(msg.sender == owner);
        payable(msg.sender).transfer(payable(address(this)).balance);
        //whoever call the withdraw function (msg.sender), transfer them all of our money
        //after we withdraw the address, we need to reset the balances of the people who fund to zero
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}
