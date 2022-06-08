const Exchange = artifacts.require("Exchange");

module.exports = function (deployer) {
  deployer.deploy(Exchange, "Deadline-champion", "DLC", "DLC-Land", "DLCL", "");
};
