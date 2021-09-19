const Gambling = artifacts.require('Gambling');

const chai = require('chai');
const BN = require('bn.js');

chai.use(require('chai-bn')(BN))
	.use(require("chai-as-promised"))
	.should();

contract('Gambling', (accounts) => {
	const _owner = accounts[0];
	const _N = 3;
    const _minStake = web3.utils.toBN("10000000000000000");   // value in wei

    beforeEach(async () => {
    	this.gambling = await Gambling.new(_owner, _N, _minStake);
    });

    describe('Testing the contract', () => {

    	it('Checking the contructor params', async () => {
    		const owner = await this.gambling.owner();
    		const N = await this.gambling.N();
    		const minStake = await this.gambling.minStake();
    		assert.equal(owner, accounts[0]);
    		assert.equal(N, _N);
    		minStake.should.be.a.bignumber.that.equals(_minStake);
    	});

    	it('Checking registration status for sufficient stake amount', async () => {
    		await this.gambling.stake({value: web3.utils.toWei('0.01', 'ether'), from: accounts[1]});
    		const regStatus = await this.gambling.playerReg(accounts[1]);
    		assert.isTrue(regStatus);
    	});

    	it('Staking less amount than minimum stake', async () => {
    		await this.gambling.stake({value: web3.utils.toWei('0.00001', 'ether'), from: accounts[1]}).should.be.rejected;
    	});

    	it('Owner trying to get the fund before gambling ends', async () => {
    		await this.gambling.getOwnerFund({from: _owner}).should.be.rejectedWith("Staking is not finished yet");
    	});

		it('Declaring the winner before all the users have registered', async () => {
    		await this.gambling.getWinner().should.be.rejectedWith("Players are yet to stake");
    	});

    })

})