const dotenv = require('dotenv');
dotenv.config();

// .env file should contain CONTRACTS_PATH, which is ~/path/to/contracts

const LetterOfCredit = artifacts.require(process.env.CONTRACTS_PATH + "LetterOfCredit/LetterOfCredit.sol");
const { time } = require('openzeppelin-test-helpers');

contract('Letter of Credit base flow', async accounts => {
    
    const accs = {
        buyer: accounts[0],
        seller: accounts[1],
        shippingManager: accounts[2],
        attacker: accounts[3],
    }

    let letterOfCreditContract;

    let expectThrow = async(promise) => {
        try {
            await promise;
        } catch (error) {
            const invalidOpcode = error.message.search('invalid opcode') >= 0;
            const outOfGas = error.message.search('out of gas') >= 0;
            const revert = error.message.search('revert') >= 0;
            assert(
              invalidOpcode || outOfGas || revert,
              "Expected throw, got '" + error + "' instead",
            );
            return;
        }
        assert.fail('Expected throw not received');
    }
    
    before('deploying letter of credit contract', async() => {

        //deploy a contract
        letterOfCreditContract = await LetterOfCredit.new(accs.buyer, accs.seller, accs.shippingManager, { from: accs.buyer });
        console.log('[DEBUG] Deployed LetterOfCredit contract, address: ' + letterOfCreditContract.address)
    });

    it('creating bargain', async() => {
        let bargainSum = web3.utils.toWei("5", 'ether');
        
        let blocknumber = await web3.eth.getBlockNumber();
        let block = await web3.eth.getBlock(blocknumber);
        let bargainDeadline = block.timestamp + 1000;

        //only buyer can initialize it <- that's due to how letter of credit works in real life.
        await expectThrow(
            letterOfCreditContract.createBargain(bargainSum, bargainDeadline, 'description', { from: accs.attacker })
        );
        await expectThrow(
            letterOfCreditContract.createBargain(bargainSum, bargainDeadline, 'description', { from: accs.seller })
        );
        await expectThrow(
            letterOfCreditContract.createBargain(bargainSum, bargainDeadline, 'description', { from: accs.shippingManager })
        );

        //bargain sum should be gt 0
        await expectThrow(
            letterOfCreditContract.createBargain(0, bargainDeadline, 'description', { from: accs.buyer })
        );
        await expectThrow(
            letterOfCreditContract.createBargain(-100, bargainDeadline, 'description', { from: accs.buyer })
        );

        //msg.value should be equal to bargainSum
        await expectThrow(
            letterOfCreditContract.createBargain(bargainSum, bargainDeadline, 'description', { from: accs.buyer, value: web3.utils.toWei("10", "ether") })
        );

        //invalid bargain period
        await expectThrow(
            letterOfCreditContract.createBargain(bargainSum, bargainDeadline + 100000000000, 'description', { from: accs.buyer, value: bargainSum })
        );

        //Create valid letter of credit
        await letterOfCreditContract.createBargain(bargainSum, bargainDeadline, 'valid bargain', { from: accs.buyer, value: bargainSum});
        
        // INIT state
        let state = await letterOfCreditContract.bargainInitializedBy.call(accs.buyer);
        assert.equal(state.bargainState.valueOf(), 1);
    });

    it('buyer gets considired that seller could be trusted and changes state', async() => {
        /*
         Once a bargain created and contract state is set to INIT, buyer should consider that seller could be trusted, he has a wanted product/service. 
         When it's done, buyer changes state to VALIDATED. If doubts about seller occure, buyer can call cancelBargainBuyer and get his ether back.        
         For the base flow we would not test bargain cancellation.
         */
        
        // uint8 for State type in LetterOfCredit
        let VALIDATED = 2;
        let anyNonValidState = 5;

        await expectThrow(letterOfCreditContract.pushStateForwardTo(anyNonValidState, { from: accs.buyer }));
        await expectThrow(letterOfCreditContract.pushStateForwardTo(VALIDATED, { from: accs.attacker }));

        await letterOfCreditContract.pushStateForwardTo(VALIDATED, { from: accs.buyer });
        let state = await letterOfCreditContract.bargainInitializedBy.call(accs.buyer);
        assert.equal(state.bargainState.valueOf(), VALIDATED);
    });

    it('seller sends goods, shipping manager changes state', async() => {
        // Please read the 4th paragraph in README.md
        let SENT = 3;
        let anyNonValidState = 5;

        //invalid access
        await expectThrow(letterOfCreditContract.pushStateForwardTo(SENT, { from: accs.attacker }));

        //wrong state transition test
        await expectThrow(letterOfCreditContract.pushStateForwardTo(anyNonValidState, { from: accs.shippingManager }));

        await letterOfCreditContract.pushStateForwardTo(SENT, { from: accs.shippingManager });
        let state = await letterOfCreditContract.bargainInitializedBy.call(accs.buyer);
        assert.equal(state.bargainState.valueOf(), SENT);
    });

    it('buyer declines goods', async() => {
        let DECLINED = 5;

        // invalid access
        await expectThrow(letterOfCreditContract.pushStateForwardTo(DECLINED, { from: accs.attacker }));
        
        await letterOfCreditContract.pushStateForwardTo(DECLINED, { from: accs.buyer });        
    });

    it('seller gets his sum', async() => {
        let seller_balance_beforeTransfer = await web3.eth.getBalance(accs.seller);
        let buyer_balance_beforeTransfer = await web3.eth.getBalance(accs.buyer);

        let FINISHED = 6;
        
        await letterOfCreditContract.transferPaymentsToParties( {from: accs.attacker} );

        let seller_balance_afterTransfer = await web3.eth.getBalance(accs.seller);
        let buyer_balance_afterTransfer = await web3.eth.getBalance(accs.buyer);

        let bargain = await letterOfCreditContract.bargainInitializedBy.call(accs.buyer);
        let bargainSumSeller = bargain.bargainSum * 0.15;
        let bargainSumBuyer = bargain.bargainSum * 0.85;

        assert.equal(bargain.bargainState.valueOf(), FINISHED);
        assert.equal(Number(seller_balance_beforeTransfer) + Number(bargainSumSeller), seller_balance_afterTransfer.valueOf());
        assert.equal(Number(buyer_balance_beforeTransfer) + Number(bargainSumBuyer), buyer_balance_afterTransfer.valueOf());
    });

});