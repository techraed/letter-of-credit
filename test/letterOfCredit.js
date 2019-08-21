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

    let letterOfCredit_contractAddress;

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
        letterOfCredit_contractAddress = await LetterOfCredit.new(accs.buyer, accs.seller, { from: accs.buyer });
        console.log('[DEBUG] Deployed LetterOfCredit contract, address: ' + letterOfCredit_contractAddress.address)
    });

    it('mock', async() => {
        return true;
    });

});