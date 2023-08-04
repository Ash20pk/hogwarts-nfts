const HogwartsNFT = artifacts.require("HogwartsNFT");

module.exports = function (deployer) {
  const vrfCoordinatorV2Address = "0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed"; // address of the VRFCoordinatorV2 contract
  const subId = 3795; // subscription ID for Chainlink VRF
  const keyHash = "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f"; // key hash for Chainlink VRF
  const callbackGasLimit = 500000; // gas limit for Chainlink VRF callback

  deployer.deploy(HogwartsNFT, vrfCoordinatorV2Address, subId, keyHash, callbackGasLimit);
};
