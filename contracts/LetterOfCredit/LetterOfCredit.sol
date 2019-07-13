pragma solidity 0.5.10;


import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";


contract BaseLetterOfCredit {
    using SafeMath for uint256;

    modifier onlyParties {
        require(msg.sender == firstParty || msg.sender == secondParty, "Invalid access");
        _;
    }

    modifier canInitializeBargain(uint256 _sum, uint256 _controlledPaymentDeadline) {
        require(
            bargainInitializedBy[msg.sender].bargainState == States.ZS ||
            bargainInitializedBy[msg.sender].bargainState == States.FINISHED,
            "You can't initialize a new bargain"
        );
        require(_sum > 0, "Bargain sum can't be less than 0");
        require(_sum == msg.value, "Bargain sum should equal to the amount of ether sent");
        require(
            _controlledPaymentDeadline > now && _controlledPaymentDeadline < now + 3600 * 24 * 30 * 12 * 2,
            "Invalid bargain period"
        );
        _;
    }

    modifier canCancelBargain {
        require(
            bargainInitializedBy[msg.sender].bargainState == States.INIT ||
            (bargainInitializedBy[msg.sender].bargainState == States.READY && 
            now > bargainInitializedBy[msg.sender].controlledPaymentDeadline),
            "Not correct state for cancellation"
        );
        _;
    }

    enum States{ZS, INIT, READY, SENT, ACCEPT, FINISHED}

    address public firstParty;
    address public secondParty;

    struct Bargain {
        uint256 bargainSum;
        uint256 controlledPaymentDeadline;
        string description;
        States bargainState;
        address recepient;
    }
    mapping(address => Bargain) public bargainInitializedBy;

    constructor(address _firstParty, address _secondParty) public {
        firstParty = _firstParty;
        secondParty = _secondParty;
    }

    function createBargain(uint256 _sum, uint256 _controlledPaymentDeadline, string calldata _description)
        external
        payable
        onlyParties
        canInitializeBargain(_sum, _controlledPaymentDeadline)
        returns (bool)
    {
        address _recepient = getOtherParty(msg.sender);
        Bargain memory newBargain = Bargain({ // это дешево? а в одну строку на 72 строчке?
            recepient: _recepient,
            bargainSum: _sum,
            controlledPaymentDeadline: _controlledPaymentDeadline,
            description: _description,
            bargainState: States.INIT
        });
        
        bargainInitializedBy[msg.sender] = newBargain;
    }

    /// init and ready state only
    function cancelBargain() external onlyParties canCancelBargain {
        bargainInitializedBy[msg.sender].bargainState = States.ZS;
        msg.sender.transfer(bargainInitializedBy[msg.sender].bargainSum);
    }

    function gettingReadyToPay() external onlyParties {
        require(bargainInitializedBy[msg.sender].bargainState == States.INIT, "Wrong state");

        bargainInitializedBy[msg.sender].bargainState = States.READY;
        //emit
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