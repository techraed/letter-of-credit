"use strict";

const LOC = artifacts.require("./LetterOfCredit.sol");

const DEPLOYER_ADDRESS = "0x39770f90A657953Ec562DaC2b2Bd6350b6dF0271";
const AGENT_ONE = "0x0cA6Fc87e5a70FcDCd3f15197C467bCa85D79330";
const AGENT_TWO = "0xe71eF9f14FD26a074436f05952Adc6d1E792df74";
const AGENT_THREE = "0x9cb50b54BC413fC1eb5D067d5bdfaDe6B43ee341";

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
