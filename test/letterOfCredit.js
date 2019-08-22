const dotenv = require('dotenv');
dotenv.config();

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
        letterOfCreditContract = await LetterOfCredit.new(accs.buyer, accs.seller, { from: accs.buyer });
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


    });

});