const Router = artifacts.require("Router");

module.exports = function (deployer) {
  deployer.deploy(
    Router,
    "0xd395735B05eE52A2543Fb6740837840D1be06327",
    "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2"
  );
};

/*
  router -> 0xa4c70b9e1b3a90b339E430669a4d4745D7340ca0
  WETH -> 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2
*/
