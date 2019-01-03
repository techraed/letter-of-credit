"use strict";

const LOC = artifacts.require("./LetterOfCredit.sol");

const DEPLOYER_ADDRESS = "0x627306090abaB3A6e1400e9345bC60c78a8BEf57";
const AGENT_ONE = "0xf17f52151EbEF6C7334FAD080c5704D77216b732";
const AGENT_TWO = "0xC5fdf4076b8F3A5357c5E395ab970B5B54098Fef";
const AGENT_THREE = "0x0d1d4e623D10F9FBA5Db95830F7d3839406C6AF2";

contract("Letter of credit tests", async () => {
    it("setting contract balances for 2 agents", async () => {
        let instance = await LOC.deployed();

        await instance.sendTransaction({from: AGENT_ONE, value: 10});
        await instance.sendTransaction({from: AGENT_TWO, value: 10});

        let balanceAgentOne = await instance.getAgentBalance(AGENT_ONE);
        let balanceAgentTwo = await instance.getAgentBalance(AGENT_TWO);

        let testBalanceAgentOne = await instance.getMyBalance({from: AGENT_ONE});

        assert.equal(balanceAgentOne.valueOf(), 10);
        assert.equal(balanceAgentTwo.valueOf(), 10);
        assert.equal(testBalanceAgentOne.valueOf(), 10);
    });

    it("opening accreditive", async () => {
        let instance = await LOC.deployed();

        await instance.openAccreditive(AGENT_TWO, 5, {from: AGENT_ONE});
        let supplierOneState2 = await instance.supplierState.call(AGENT_ONE, AGENT_TWO);

        await instance.openAccreditive(AGENT_THREE, 5, {from: AGENT_ONE});
        let supplierOneState3 = await instance.supplierState.call(AGENT_ONE, AGENT_THREE);

        assert.equal(supplierOneState2.treatyPrice.valueOf(), 5);
        assert.equal(supplierOneState3.treatyPrice.valueOf(), 5);
    });

    it("changing accreditives statuses", async () => {
        let instance = await LOC.deployed();

        await instance.dutyStatusChange(AGENT_TWO, {from: AGENT_ONE});
        await instance.closeAccreditive(AGENT_THREE, {from: AGENT_ONE});

        let supplierOneState2 = await instance.supplierState.call(AGENT_ONE, AGENT_TWO);
        let supplierOneDutyStatus2 = supplierOneState2.dutyFulfilled;

        let supplierOneState3 = await instance.supplierState.call(AGENT_ONE, AGENT_THREE);
        let supplierOneDutyStatus3 = supplierOneState3.treatyPrice.valueOf();

        assert.equal(supplierOneDutyStatus2, true);
        assert.equal(supplierOneDutyStatus3, 0);
    });

    it("finishing letter of credit mechanism", async() => {
        let instance = await LOC.deployed();

        await instance.transferAccreditive(AGENT_ONE, 5, {from: AGENT_TWO});

        let balanceAgentOne = await instance.getMyBalance({from: AGENT_ONE});
        let balanceAgentTwo = await instance.getMyBalance({from: AGENT_TWO});

        assert.equal(balanceAgentOne.valueOf(), 5);
        assert.equal(balanceAgentTwo.valueOf(), 15);
    });

    it("collect funds", async() => {
        let instance = await LOC.deployed();

        await instance.collectFunds({from: AGENT_TWO});
        let balanceAgentTwo = await instance.getMyBalance({from: AGENT_TWO});

        assert.equal(balanceAgentTwo.valueOf(), 0);

    });


})
