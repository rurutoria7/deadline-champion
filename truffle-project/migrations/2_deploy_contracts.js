const ERC721LAND = artifacts.require("ERC721LAND");

module.exports = function (deployer) {
  deployer.deploy(ERC721LAND, "deadline-champion", "dlc", "QwQ");
};
