const LetterOfCredit = artifacts.require("./LetterOfCredit.sol");

module.exports = function(deployer) {
    deployer.deploy(LetterOfCredit, 5);
};