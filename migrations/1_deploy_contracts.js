const MyToken = artifacts.require("MyToken");
const Staking = artifacts.require("Staking");
const RaffleAuction = artifacts.require("RaffleAuction");

module.exports = function (deployer) {

    deployer.deploy(MyToken).then(function(instance) {
        console.log("MyToken address: ", instance.address);
        return deployer.deploy(Staking, instance.address).then(function(instance) {
            console.log("Staking address: ", instance.address);
            return deployer.deploy(RaffleAuction, instance.address);
        });
    });
    
}