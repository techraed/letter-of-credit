pragma solidity 0.5.10;


import "../../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";  /// delete "../../node_modules"


contract BaseLetterOfCredit {
    using SafeMath for uint256;

    modifier onlyParties {
        require(msg.sender == buyer || msg.sender == seller || msg.sender == shippingManager, "Invalid access");
        _;
    }

    modifier canInitializeBargain(uint256 _sum, uint256 _bargainDeadline) {
        require(msg.sender == buyer, "Invalid access");
        require(
            bargainInitializedBy[buyer].bargainState == States.ZS ||
            bargainInitializedBy[buyer].bargainState == States.FINISHED,
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

    enum States {ZS, INIT, VALIDATED, SENT, ACCEPTED, DECLINED, FINISHED}

    address public buyer;
    address public seller;
    address public shippingManager;

    struct Bargain {
        uint256 bargainSum;
        uint256 bargainDeadline;
        string description;
        States bargainState;
    }
    mapping(address => Bargain) public bargainInitializedBy;

    event StateChangedToBy(States, address);
    event BargainCancelledBy(address);

    constructor(address _buyer, address _seller) public {
        buyer = _buyer;
        seller = _seller;
    }

    function createBargain(uint256 _sum, uint256 _bargainDeadline, string calldata _description)
        external
        payable
        canInitializeBargain(_sum, _bargainDeadline)
        returns (bool)
    {
        Bargain memory newBargain = Bargain({
            bargainSum: _sum,
            bargainDeadline: _bargainDeadline,
            description: _description,
            bargainState: States.INIT
        });
        
        bargainInitializedBy[msg.sender] = newBargain;
    }

    function pushStateForwardTo(States _state) external onlyParties {
        changeStateTo(_state);
        emit StateChangedToBy(_state, msg.sender);
    }

    function cancelBargainBuyer() external {
        require(msg.sender == buyer, "Invalid access");

        changeStateTo(States.ZS);
        (, uint256 buyersRefund) = calculatePaymentsInState(States.INIT);
        
        msg.sender.transfer(buyersRefund);

        emit BargainCancelledBy(msg.sender);
    }

    function cancelBargainSeller() external {
        require(msg.sender == seller, "Invalid access");
        
        changeStateTo(States.ZS);
        (uint256 compensationToSeller, uint256 returnedToBuyer) = calculatePaymentsInState(States.SENT);
        
        msg.sender.transfer(compensationToSeller);
        address(uint160(buyer)).transfer(returnedToBuyer);
        
        emit BargainCancelledBy(msg.sender);
    }

    function transferPaymentsToParties() external {
        changeStateTo(States.FINISHED);
        (uint256 sumToSeller, uint256 sumToBuyer) = calculatePaymentsInState(bargainInitializedBy[buyer].bargainState);

        if (sumToBuyer != 0) {
            address(uint160(buyer)).transfer(sumToBuyer);
        }
        address(uint160(seller)).transfer(sumToSeller);
        
        emit StateChangedToBy(States.FINISHED, msg.sender);
    }

    function changeStateTo(States _state) private {
        if (_state == States.VALIDATED) {
            require(
                msg.sender == buyer ||
                bargainInitializedBy[msg.sender].bargainState == States.INIT
            );

            bargainInitializedBy[msg.sender].bargainState = States.VALIDATED;
        }

        if (_state == States.SENT) {
            require(
                msg.sender == shippingManager ||
                bargainInitializedBy[buyer].bargainState == States.VALIDATED
            );

            bargainInitializedBy[buyer].bargainState = States.SENT;
        }

        if (_state == States.ACCEPTED || _state == States.DECLINED) {
            require(
                msg.sender == buyer ||
                bargainInitializedBy[buyer].bargainState == States.SENT
            );

            bargainInitializedBy[msg.sender].bargainState = _state;
        }

        if (_state == States.ZS) {
            if (msg.sender == buyer) {
                require(
                    bargainInitializedBy[msg.sender].bargainState == States.INIT ||
                    (bargainInitializedBy[msg.sender].bargainState == States.VALIDATED && 
                    now > bargainInitializedBy[msg.sender].bargainDeadline),
                    "Not correct state for buyer cancellation"
                );
            }
            
            if (msg.sender == seller) {
                require(
                    bargainInitializedBy[buyer].bargainState == States.SENT &&
                    now > bargainInitializedBy[buyer].bargainDeadline,
                    "Not correct state for seller cancellation"
                );
            }

            bargainInitializedBy[buyer].bargainState = States.ZS;
        }

        if (_state == States.FINISHED) {
            require(
                bargainInitializedBy[buyer].bargainState == States.ACCEPTED ||
                bargainInitializedBy[buyer].bargainState == States.DECLINED,
                "Bargain wasn't accpeted, neither declined"
            );

            bargainInitializedBy[buyer].bargainState = States.FINISHED;
        }
    }

    function calculatePaymentsInState(States _state) private view returns(uint256 sumToSeller, uint256 sumToBuyer) {
        if (_state == States.INIT || _state == States.VALIDATED) {
            sumToBuyer = bargainInitializedBy[buyer].bargainSum;
            sumToSeller = 0;
        }
        if (_state == States.SENT) {
            sumToSeller = (bargainInitializedBy[buyer].bargainSum.mul(30)).div(100);
            sumToBuyer = (bargainInitializedBy[buyer].bargainSum).sub(sumToSeller);
        }
        if (_state == States.ACCEPTED) {
            sumToBuyer = 0;
            sumToSeller = bargainInitializedBy[buyer].bargainSum;
        }
        if (_state == States.DECLINED) {
            sumToSeller = (bargainInitializedBy[buyer].bargainSum.mul(15)).div(100);
            sumToBuyer = (bargainInitializedBy[buyer].bargainSum).sub(sumToSeller);
        }
    }
}