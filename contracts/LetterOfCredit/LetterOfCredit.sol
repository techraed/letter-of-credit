pragma solidity 0.5.10;


import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract BaseLetterOfCredit {
    using SafeMath for uint256;

    modifier onlyParties {
        require(msg.sender == firstParty || msg.sender == secondParty, "Invalid access");
        _;
    }

    address public firstParty;
    address public secondParty;

    struct Bargain {
        uint256 bargainSum;
        uint256 bargainPeriod;
        string description;
    }
    mapping(address => Bargain) public bargainInitializedBy;

    constructor(address _firstParty, address _secondParty) public {
        firstParty = _firstParty;
        secondParty = _secondParty;
    }

    function createBargain(uint256 _sum, uint256 _bargainPeriod, string calldata description)
        external
        payable
        onlyParties
        returns (bool)
    {
        require(!isActiveBargain(msg.sender), "You have unclosed bargains");
        require(_sum > 0, "Bargain sum can't be less than 0");
        require(_sum == msg.value, "Bargain sum should equal to the amount of ether sent");
        require(_bargainPeriod > 0 && _bargainPeriod < 3600 * 24 * 30 * 12 * 5, "Invalid bargain period");

        Bargain memory newBargain = Bargain(_sum,  _bargainPeriod, description);
        bargainInitializedBy[msg.sender] = newBargain;
    }

    function approveBargain() external returns (bool) {
        /**
         * проблема в том, что если второй сольется, то мы это быстро решим позволив любому вызвать метод транзакции в пользу второго
         * ну а если сольется первый? в таком случае решением является участие третьего лица
         */ 
    }

    function isActiveBargain(address _initializer) private view returns (bool) {
        if (bargainInitializedBy[_initializer].bargainSum != 0) {
            return true;
        }
        return false;
    }
}