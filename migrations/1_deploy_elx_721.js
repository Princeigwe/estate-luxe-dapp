
var EstateLuxe = artifacts.require("EstateLuxe");

module.exports = function (deployer) {
  deployer.deploy(EstateLuxe, "EstateLuxe", "ELX");
};