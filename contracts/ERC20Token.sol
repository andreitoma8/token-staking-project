// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20, ERC20Burnable, Pausable, Ownable {
    // The state of fees on transaction. If true, fees are paid on transfers
    bool public taxState;

    // The fee paid on transfers
    uint256 public fee = 800; // 10000 = 100% and 800 = 8%

    // Minimum amount to stake
    uint256 public minStake = 100 * 10**18;

    // Flexible stake rewards per hour. A fraction calculated as x/10.000.000 to get the percentage
    uint256 public flexStakeRPH = 246; // 0.00246%/h or 21.56% APR

    // Three months lock APR
    uint256 public threeMonthsRPH = 246; // 0.00246%/h or 21.56% APR

    // Three months lock APR
    uint256 public sixMonthsRPH = 246; // 0.00246%/h or 21.56% APR

    // Three months lock APR
    uint256 public twelveMonthsRPH = 246; // 0.00246%/h or 21.56% APR

    // Three months lock APR
    uint256 public twentyFourMonthsRPH = 246; // 0.00246%/h or 21.56% APR

    // Stake Types
    enum StakeType {
        THREE_MONTHS,
        SIX_MONTHS,
        TWELVE_MONTHS,
        TWENTY_FOUR_MONTHS
    }

    // Staker info struct
    struct Staker {
        // The deposited tokens of the Staker
        uint256 deposited;
        // Last time of details update for Deposit
        uint256 timeOfLastUpdate;
        // Calculated, but unclaimed rewards. These are calculated each time
        // a user writes to the contract.
        uint256 unclaimedRewards;
        // Time when pople can withdraw with rewards
        uint256 timeOfRewardsEligibility;
    }

    // Struct for token lock info
    struct TokenLock {
        uint256 timeOfUnlock;
        uint256 amount;
    }

    // Mapping of staker address to staker info
    mapping(address => Staker) public stakers;

    // Mapping of address to token locks
    mapping(address => TokenLock[]) public userLocks;

    // Mapping of addresses that are excluded from paying fees
    mapping(address => bool) public excludedFromFee;

    constructor() ERC20("Token", "TKN") {
        _mint(msg.sender, 10000000000 * 10**decimals());
        excludedFromFee[msg.sender] = true;
        excludedFromFee[address(this)] = true;
    }

    // If address has no Staker struct, initiate one. If address already was a stake,
    // calculate the rewards and add them to unclaimedRewards, reset the last time of
    // deposit and then add _amount to the already deposited amount.
    // REceive the amount staked.
    function stake(uint256 _amount) external {
        require(_amount >= minStake, "Amount smaller than minimimum deposit");
        require(
            balanceOf(msg.sender) >= _amount,
            "Can't stake more than you own"
        );
        if (stakers[msg.sender].deposited == 0) {
            stakers[msg.sender].deposited = _amount;
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
            stakers[msg.sender].unclaimedRewards = 0;
        } else {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
            stakers[msg.sender].deposited += _amount;
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        }
        transferFrom(msg.sender, address(this), _amount);
    }

    // Compound the rewards and reset the last time of update for Deposit info
    function stakeRewards() external {
        require(stakers[msg.sender].deposited > 0, "You have no deposit");
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].deposited += rewards;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        _mint(address(this), rewards);
    }

    // Send rewards for msg.sender
    function claimRewards() external {
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards");
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        _mint(msg.sender, rewards);
    }

    // Withdraw specified amount of staked tokens
    function withdraw(uint256 _amount) external {
        require(
            stakers[msg.sender].deposited >= _amount,
            "Can't withdraw more than you have"
        );
        uint256 _rewards = calculateRewards(msg.sender);
        stakers[msg.sender].deposited -= _amount;
        if (_amount == stakers[msg.sender].deposited) {
            stakers[msg.sender].timeOfLastUpdate = 0;
        } else {
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        }
        stakers[msg.sender].unclaimedRewards = _rewards;
        transfer(msg.sender, _amount);
    }

    // Lock tokens to gain a better APR
    function lockTokens(uint256 _amount, StakeType _stakeType) external {}

    // Allows the owner to pause token transfers
    function pause() external onlyOwner {
        _pause();
    }

    // Allows the owner to unpause token transfers
    function unpause() external onlyOwner {
        _unpause();
    }

    // Allows the owner to mint tokens
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    // Set tax state
    function setTaxState(bool _taxState) external onlyOwner {
        taxState = _taxState;
    }

    // Set fee on token transfer (with 2 decimals)
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    // Exclude address form paying fee
    function excludeFromFee(address _address) external onlyOwner {
        excludedFromFee[_address] = true;
    }

    // Inlcude address to pay fee
    function includeToFee(address _address) external onlyOwner {
        excludedFromFee[_address] = false;
    }

    // Calculate the rewards since the last update on Deposit info
    function calculateRewards(address _staker)
        internal
        view
        returns (uint256 rewards)
    {
        if (stakers[_staker].timeOfLastUpdate == 0) {
            return 0;
        } else {
            return (((((block.timestamp - stakers[_staker].timeOfLastUpdate) *
                stakers[_staker].deposited) * flexStakeRPH) / 3600) / 10000000);
        }
    }

    // Override to implement pause functionality on token transfers
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    // Override to implement tax on token transfer
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (!taxState) {
            super._transfer(from, to, amount);
        } else {
            if (excludedFromFee[from] || excludedFromFee[to]) {
                super._transfer(from, to, amount);
            } else {
                uint256 _fee = (amount * fee) / 10000;
                uint256 _amountAfterFee = amount - _fee;
                super._transfer(from, to, _amountAfterFee);
                super._transfer(from, owner(), _fee);
            }
        }
    }
}