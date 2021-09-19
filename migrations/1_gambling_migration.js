const Gambling = artifacts.require("Gambling");

module.exports = function (deployer, network, accounts) {
  deployer.deploy(Gambling, accounts[0], 3, web3.utils.toBN("10000000000000000"));
};
// kovan - 0x96C958B75F81A121Fd0Dc4A90B05e8587007077F