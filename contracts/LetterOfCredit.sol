pragma solidity ^0.5.0;

import "./SafeMath.sol";

/**
* @title Accreditive
* @dev Base accreditive contract, an implemetation of a bank accreditive mechanism,
* but without financial intermediaries. Can be/should be modified on personal/specific purposes.
*/
contract LetterOfCredit{
    using SafeMath for uint;
    mapping (address => uint) public balances;
    mapping (address => mapping(address => Supplier)) public supplierState;
    uint fee;
    address owner;


    struct Supplier{
        bool dutyFulfilled;
        uint treatyPrice;
    }

    event AccreditiveConfirmed(address from, address to, uint amount);
    event AccreditiveCancelled(address customer, address supplier);

/*
    modifier owned() {
        require(msg.sender == owner, "only owner");
        _;
    }
*/

    constructor(uint feePercent) public {
        owner = msg.sender;
        balances[owner] = 0;
        fee = feePercent;
    }
    
    function() external payable{
        balances[msg.sender] = msg.value;
    }

    function getMyBalance() external view returns (uint) {
        return balances[msg.sender];
    }

    function getAgentBalance(address agentAddress) external view returns (uint) {
        require(balances[agentAddress] > 0, "no such agent with a gt 0 balance");
        return balances[agentAddress];
    }

    function openAccreditive(address reciever, uint accreditiveAmount) external {
        require(balances[msg.sender] > 0, "you should send funds to contract to open accreditive");
        require(supplierState[msg.sender][reciever].treatyPrice == 0, "there is already opened accreditive");
        supplierState[msg.sender][reciever] = Supplier(false, accreditiveAmount);
    }

    //Confrimation, sent by accreditive opener after recieving products from supplier
    function dutyStatusChange(address reciever) external {
        require(supplierState[msg.sender][reciever].treatyPrice != 0, "there isn't such accreditive");
        supplierState[msg.sender][reciever].dutyFulfilled = true;
        emit AccreditiveConfirmed(msg.sender, reciever, supplierState[msg.sender][reciever].treatyPrice);
    }
    
    //In case of customer refusing the agreement
    function closeAccreditive(address reciever) external {
        require(supplierState[msg.sender][reciever].treatyPrice != 0, "there isn't such accreditive");
        require(supplierState[msg.sender][reciever].dutyFulfilled == false, "you can't deny after confirmation");
        supplierState[msg.sender][reciever].treatyPrice = 0;
        emit AccreditiveCancelled(msg.sender, reciever);              
    }

    //Called by accreditive reciever, who is a product producer (supplies products to an accreditive opener)
    function transferAccreditive(address from, uint amount) external {
        require(supplierState[from][msg.sender].treatyPrice == amount && supplierState[from][msg.sender].dutyFulfilled == true);
        balances[msg.sender] = balances[msg.sender].add(amount);
        balances[from] = balances[from].sub(amount);
        supplierState[from][msg.sender].dutyFulfilled = false;
    // Fees paid to contract deployer
        balances[msg.sender] = balances[msg.sender].sub((amount.mul(fee)).div(100));
        balances[owner] = balances[owner].add((amount.mul(fee)).div(100));
    }

    function collectFunds() external {
        msg.sender.transfer(balances[msg.sender]);
        balances[msg.sender] = 0;
    }
}