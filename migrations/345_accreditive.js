var Accreditive = artifacts.require("./Accreditive.sol");
var SafeMath = artifacts.require("./SafeMath.sol");

module.exports = function(deployer) {
    deployer.deploy(SafeMath);
    deployer.link(SafeMath, Accreditive);
    deployer.deploy(Accreditive);
};