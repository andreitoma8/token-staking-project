// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IToken is IERC20 {
    function mintForRewards(address to, uint256 amount) external;
}

contract Staking is Ownable, Pausable {
    // Address and Interface to the Token
    IToken public token;

    // Minimum amount to stake
    uint256 public minStake = 100 * 10**18;

    // Flexible stake rewards per hour. A fraction calculated as x/10.000.000 to get the percentage
    uint256 public flexStakeRPH = 23; // 0.00022%/h or 2.156% APR

    // Three months lock rewards as % with 2 decimals(10% = 1000)
    uint256 public threeMonthsRPL = 75; // 0.75% (or 3% APR)

    // Three months lock rewards as % with 2 decimals(10% = 1000)
    uint256 public sixMonthsRPL = 200; // 2% (or 4% APR)

    // Three months lock rewards as % with 2 decimals(10% = 1000)
    uint256 public twelveMonthsRPL = 600; // 50% (or 6% APR)

    // Three months lock rewards as % with 2 decimals(10% = 1000)
    uint256 public twentyFourMonthsRPL = 1600; // 16% (or 8% APR)

    // Total amount of tokens staked
    uint256 public totalTokensStaked;

    // Total rewards paid trough staking
    uint256 public totalRewardsPaid;

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
        StakeType typeOfStake;
        uint256 rewards;
    }

    // Mapping of staker address to staker info
    mapping(address => Staker) public stakers;

    // Mapping of address to token locks
    mapping(address => TokenLock[]) public userLocks;

    constructor(IToken _token) {
        token = _token;
    }

    // If address has no Staker struct, initiate one. If address already has a stake,
    // calculate the rewards and add them to unclaimedRewards, reset the last time of
    // deposit and then add _amount to the already deposited amount.
    // Receive the amount staked.
    function stake(uint256 _amount) external whenNotPaused {
        require(_amount >= minStake, "Amount smaller than minimimum deposit");
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Can't stake more than you own"
        );
        if (stakers[msg.sender].deposited == 0) {
            stakers[msg.sender].deposited = _amount;
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
            stakers[msg.sender].unclaimedRewards = 0;
            stakers[msg.sender].timeOfRewardsEligibility =
                block.timestamp +
                1209600;
        } else {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
            stakers[msg.sender].deposited += _amount;
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        }
        token.transferFrom(msg.sender, address(this), _amount);
        totalTokensStaked += _amount;
    }

    // Compound the rewards and reset the last time of update for Deposit info
    function stakeRewards() external whenNotPaused {
        require(
            block.timestamp > stakers[msg.sender].timeOfRewardsEligibility,
            "Two weeks have not passed from your first stake"
        );
        require(stakers[msg.sender].deposited > 0, "You have no deposit");
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].deposited += rewards;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        token.mintForRewards(address(this), rewards);
        totalTokensStaked += rewards;
    }

    // Mint rewards for msg.sender
    function claimRewards() external {
        require(
            block.timestamp > stakers[msg.sender].timeOfRewardsEligibility,
            "Two weeks have not passed from your first stake"
        );
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards");
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        token.mintForRewards(msg.sender, rewards);
        totalRewardsPaid += rewards;
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
        token.transfer(msg.sender, _amount);
        totalTokensStaked -= _amount;
    }

    // Lock tokens to gain a better APR
    // User can select a amount to lock and a period to lock for
    function lockTokens(uint256 _amount, StakeType _stakeType)
        external
        whenNotPaused
    {
        TokenLock memory _lock;
        _lock.amount = _amount;
        _lock.typeOfStake;
        if (_stakeType == StakeType.THREE_MONTHS) {
            _lock.timeOfUnlock = block.timestamp + 7889231;
            _lock.rewards = (_amount * threeMonthsRPL) / 10000;
        } else if (_stakeType == StakeType.SIX_MONTHS) {
            _lock.timeOfUnlock = block.timestamp + 15778463;
            _lock.rewards = (_amount * sixMonthsRPL) / 10000;
        } else if (_stakeType == StakeType.TWELVE_MONTHS) {
            _lock.timeOfUnlock = block.timestamp + 31556926;
            _lock.rewards = (_amount * twelveMonthsRPL) / 10000;
        } else {
            _lock.timeOfUnlock = block.timestamp + 63113852;
            _lock.rewards = (_amount * twentyFourMonthsRPL) / 10000;
        }
        userLocks[msg.sender].push(_lock);
        token.transferFrom(msg.sender, address(this), _amount);
        totalTokensStaked += _amount;
    }

    // Users can unlock their deposits after the locked time and get the rewards
    // or can unlock their deposits before, without getting any rewards
    function unlockTokens(uint256 _tokenLockIndex) external {
        require(
            _tokenLockIndex < userLocks[msg.sender].length,
            "Index out of range!"
        );
        TokenLock memory _lock = userLocks[msg.sender][_tokenLockIndex];
        uint256 _rewards;
        if (_lock.timeOfUnlock <= block.timestamp) {
            _rewards = _lock.rewards;
        }
        userLocks[msg.sender][_tokenLockIndex] = userLocks[msg.sender][
            userLocks[msg.sender].length - 1
        ];
        userLocks[msg.sender].pop();
        token.transfer(msg.sender, _lock.amount);
        if (_rewards > 0) {
            token.mintForRewards(msg.sender, _rewards);
            totalRewardsPaid += _rewards;
        }
        totalTokensStaked -= _lock.amount;
    }

    // Allows the owner to pause token transfers
    function pause() external onlyOwner {
        _pause();
    }

    // Allows the owner to unpause token transfers
    function unpause() external onlyOwner {
        _unpause();
    }

    // Set rewards for token locking as % for the whole lock with 2 decimals(10% = 1000)
    function setRewardsThreeMonths(uint256 _rewards) external onlyOwner {
        threeMonthsRPL = _rewards;
    }

    // Set rewards for token locking as % for the whole lock with 2 decimals (10% = 1000)
    function setRewardsSixMonths(uint256 _rewards) external onlyOwner {
        sixMonthsRPL = _rewards;
    }

    // Set rewards for token locking as % for the whole lock with 2 decimals (10% = 1000)
    function setRewardsTwelveMonths(uint256 _rewards) external onlyOwner {
        twelveMonthsRPL = _rewards;
    }

    // Set rewards for token locking as % for the whole lock with 2 decimals (10% = 1000)
    function setRewardsTwentyFourMonths(uint256 _rewards) external onlyOwner {
        twentyFourMonthsRPL = _rewards;
    }

    // Get total rewards paid
    function getTotalRewardsPaid() external view returns (uint256) {
        return totalRewardsPaid;
    }

    // Get total amount staked
    function getTotalAmountStaked() external view returns (uint256) {
        return totalTokensStaked;
    }

    // Function useful for fron-end that returns user stake, rewards and token locks by address
    function getUserInfo(address _user)
        public
        view
        returns (
            uint256 _stake,
            uint256 _rewards,
            TokenLock[] memory _tokenLocks
        )
    {
        _stake = stakers[_user].deposited;
        _rewards = calculateRewards(_user) + stakers[_user].unclaimedRewards;
        return (_stake, _rewards, userLocks[_user]);
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
}
