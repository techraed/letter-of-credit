pragma solidity ^"0.4.24";

import "./SafeMath.sol";


/**
* @title Accreditive
* @dev Base accreditive contract, an implemetation of a bank accreditive mechanism,
* but without financial intermediaries. Can be/should be modified on personal/specific purposes.
*/
contract LetterOfCredit{
    using SafeMath for uint;
    mapping (address => uint) public balances;
    mapping (address => mapping(address => supplier)) public supplierState;
    uint fee;
    address owner;


    struct supplier{
        bool dutyFulfilled;
        uint treatyPrice;
    }

    event AccreditiveConfirmed(address from, address to, uint amount);
    event AccreditiveCancelled(address customer, address supplier);

    modifier owned() {
        require(msg.sender == owner);
        _;
    }

    constructor(uint feePercent) public {
        owner = msg.sender;
        balances[owner] = 0;
        fee = feePercent;
        }
    
    function() external payable{
        balances[msg.sender] = msg.value;
    }

    function getBalance() view external returns (uint) {return balances[msg.sender];}

    function openAccreditive(address reciever, uint accreditiveAmount) external {
        supplierState[msg.sender][reciever].treatyPrice = supplierState[msg.sender][reciever].treatyPrice.add(accreditiveAmount);
        supplierState[msg.sender][reciever].dutyFulfilled = false;
    }

    //Confrimation, sent by accreditive opener after recieving products from supplier
    function dutyStatusChange(address reciever) external {
        supplierState[msg.sender][reciever].dutyFulfilled = true;
        emit AccreditiveConfirmed(msg.sender, reciever, supplierState[msg.sender][reciever].treatyPrice);
    }
    
    //In case of customer refusing the agreement
    function closeAccreditive(address reciever) external {
        require(supplierState[msg.sender][reciever].treatyPrice != 0);
        supplierState[msg.sender][reciever].treatyPrice = 0;
        supplierState[msg.sender][reciever].dutyFulfilled = false;
        emit AccreditiveCancelled(msg.sender, reciever);              
    }

    function transferAccreditive(address from, address to, uint amount) external {
        require(supplierState[from][to].treatyPrice == amount && supplierState[from][to].dutyFulfilled == true);
        balances[to] = balances[to].add(amount);
        balances[from] = balances[from].sub(amount);
        supplierState[from][to].dutyFulfilled = false;
    // Fees paid to contract deployer
        balances[to] = balances[to].sub(amount.mul(fee).div(100));
        balances[owner] = balances[owner].add(amount.mul(fee).div(100));
    }

    function collectFees() external owned {
        owner.transfer(balances[owner]);
    }

}