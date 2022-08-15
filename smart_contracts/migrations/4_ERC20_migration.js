const ERC20 = artifacts.require("dappToken");

module.exports = function (deployer) {
  deployer.deploy(ERC20, 10, "TEST2", "T2");
};

/*

*/
