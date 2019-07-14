pragma solidity 0.5.10;


import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract BaseLetterOfCredit {
    using SafeMath for uint256;

    modifier onlyParties {
        require(msg.sender == firstParty || msg.sender == secondParty, "Invalid access");
        _;
    }

    modifier onlyShippingManager {
        require(msg.sender == shippingManager, "Invalid access");
        _;
    }

    modifier canInitializeBargain(uint256 _sum, uint256 _bargainDeadline) {
        require(
            bargainInitializedBy[msg.sender].bargainState == States.ZS ||
            bargainInitializedBy[msg.sender].bargainState == States.FINISHED,
            "You can't initialize a new bargain"
        );
        require(_sum > 0, "Bargain sum can't be less than 0");
        require(_sum == msg.value, "Bargain sum should equal to the amount of ether sent");
        require(
            _bargainDeadline > now && _bargainDeadline < now + 3600 * 24 * 30 * 12 * 2,
            "Invalid bargain period"
        );
        _;
    }

    enum States{ZS, INIT, VALIDATED, SENT, ACCEPTED, DECLINED, FINISHED}

    address public firstParty;
    address public secondParty;
    address public shippingManager;

    struct Bargain {
        uint256 bargainSum;
        string description;
        uint256 bargainDeadline;
        States bargainState;
    }
    mapping(address => Bargain) public bargainInitializedBy;

    constructor(address _firstParty, address _secondParty) public {
        firstParty = _firstParty;
        secondParty = _secondParty;
    }

    ///FROM STATE 0 TO STATE 1
    function createBargain(uint256 _sum, uint256 _bargainDeadline, string calldata _description)
        external
        payable
        onlyParties
        canInitializeBargain(_sum, _bargainDeadline)
        returns (bool)
    {
        ///address _recepient = getOtherParty(msg.sender);
        Bargain memory newBargain = Bargain({ // это дешево? а в одну строку на 72 строчке?
            bargainSum: _sum,
            bargainDeadline: _bargainDeadline,
            description: _description,
            bargainState: States.INIT
        });
        
        bargainInitializedBy[msg.sender] = newBargain;
    }

    /// FROM STATE 1 AND 2 TO STATE 0
    function cancelBargainBuyer() external onlyParties {
        require(
            bargainInitializedBy[msg.sender].bargainState == States.INIT ||
            (bargainInitializedBy[msg.sender].bargainState == States.VALIDATED && 
            now > bargainInitializedBy[msg.sender].bargainDeadline),
            "Not correct state for buyer cancellation"
        );

        bargainInitializedBy[msg.sender].bargainState = States.ZS;
        msg.sender.transfer(bargainInitializedBy[msg.sender].bargainSum);
    }

    function cancelBargainSeller() external onlyParties {
        require(
            bargainInitializedBy[getOtherParty(msg.sender)].bargainState == States.SENT &&
            now > bargainInitializedBy[getOtherParty(msg.sender)].bargainDeadline,
            "Not correct state for seller cancellation"
        );

        bargainInitializedBy[getOtherParty(msg.sender)].bargainState = States.ZS;
        //msg.sender.transfer(generalFee);
    }

    /// FROM STATE 1 TO STATE 2
    function getReadyToPay() external onlyParties {
        require(bargainInitializedBy[msg.sender].bargainState == States.INIT, "Wrong state");

        bargainInitializedBy[msg.sender].bargainState = States.VALIDATED;
        //emit
    }

    /// SELLER MOVES FROM STATE 2 TO STATE 3  <-- TRUST REQUIRED!
    function shipBargain(address shippedTo) external onlyShippingManager {
        require(bargainInitializedBy[shippedTo].bargainState == States.VALIDATED, "Wrong state");

        bargainInitializedBy[shippedTo].bargainState = States.SENT;
    }

    function acceptBargain() external onlyParties {
        require(bargainInitializedBy[msg.sender].bargainState == States.SENT, "Wrong state");

        bargainInitializedBy[msg.sender].bargainState = States.ACCEPTED;
    }

    function declineBargain() external onlyParties {
        require(bargainInitializedBy[msg.sender].bargainState == States.SENT, "Wrong state");

        bargainInitializedBy[msg.sender].bargainState = States.DECLINED;
    }

    function getPayment() external onlyParties {
        require(
            bargainInitializedBy[getOtherParty(msg.sender)].bargainState == States.ACCEPTED ||
            bargainInitializedBy[getOtherParty(msg.sender)].bargainState == States.DECLINED,
            "Bargain wasn't accpeted, neither declined"
        );

        //вызов метода оплаты
    }

    function getOtherParty(address _sender) private view returns (address) {
        return _sender == firstParty ? secondParty : firstParty;
    }

    /**
    С переходом на стэйт РЭДИ, мы не видим возможности для атак: покупателю бессмысленно выходить, так как товар
    он еще не получил, а продавец вообще не получит деньги. Случайный уход продавца может обеспечить обратное получение
    денег для покупателя. Уход покупателя в данном случае мог бы повредить продавцу.  Если продавец не понял, что 
    покупатель ушел, то он оффчейном готовит продукцию и идет в стэйт SENT (тут же готовит коммит-хэш а мб и без него, мол отправил че-то
    там покупателю и жду его ответа). Проблема в том, что если здесь покупатель свалит, то продавец несет расходы на транспортировку. - НЕДОБРОСОВЕСТНЫЙ ПОКУПАТЕЛЬ

    проблема решается с помощью cancelSellerFee -> выход из сделки сэллера после срока с уплатой ему 30% премии или транспортэйшн fee, введенного в bargain

    Здесь же другая проблема: нужен протокол оффчейн обработки качества пришедшего -> акцепт полученного должен быть тогда и только тогда, 
    когда с качеством полученного действительно согласны. опять же, если изменения стэйта на акцепт не будет, то пусть оплачивает штраф или транспортэйшн fee, введенного в bargain.

    к слову, лучше сделать разными fee transportation и fee за неверное поведение!!!

    Смена стэйта на ACCEPT -> продавец забирает средства, а стэйт их сделки меняется на финишд.

    НАРИСУЙ СХЕМУ ДЛЯ СЕБЯ ЕЩЕ РАЗ


     */

}