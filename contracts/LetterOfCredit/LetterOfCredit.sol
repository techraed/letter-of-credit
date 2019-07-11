pragma solidity 0.5.10;


import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract BaseLetterOfCredit {
    using SafeMath for uint256;

    modifier onlyParties {
        require(msg.sender == firstParty || msg.sender == secondParty);
        _;
    }

    address public firstParty;
    address public secondParty;

    struct Bargain {
        uint256 bargainSum;
        uint256 lockTime; // we need an arbiter in case on of parties leaves during or after lock
        string description;   // update: we don't need him if withdraw could be provided by any of addresses.
    }
    mapping(address => Bargain) public bargainInitializedBy;
    
    constructor(address _firstParty, address _secondParty) public {
        firstParty = _firstParty;
        secondParty = _secondParty;
    }

    function createBargain(uint256 _sum) external payable onlyParties returns (bool) {
        require(_sum > 0, "Bargain sum can't be less than 0");
        require(_sum == msg.value, "Bargain sum should equal to the amount of ether sent");
        require(!isActiveBargain(msg.sender), "You have unclosed bargains");


    }

    function isActiveBargain(address _initializer) private view returns (bool) {
        if (bargainInitializedBy[_initializer].bargainSum != 0) {
            return true;
        }
        return false;
    }
}