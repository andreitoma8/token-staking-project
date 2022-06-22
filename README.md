# Token Smart Contract

## Functionality:

- Mint tokens (Only owner)
- Burn tokens (Anyone)
- Fee on transfer(Disabled by default but can be enabled by Owner)
- Exclude address from paying fee(Only owner)
- Include address to pay fee(Only owner)
- Set the on trasfer fee(Only owner)
- Enable/Disable tax on transfer(Only Owner)
- Pause token transfers(Only Owner)
- ++ All the classic ERC20 Functionality

### Stats functions

- This Smart Contract also has a function `getStatistics()` that will return:
    - The total supplu
    - The total circulating supply
    - The total amount staked
    - The total rewards paid

## Functionality explained:

#### Deploying:
- To change the name and the ticker of the Smart Contract, look for the constructor function and change the strings between the double quotes:
```solidity
constructor() ERC20("Name", "TICKER") {
    _mint(msg.sender, 10000000000 * 10**decimals());
    excludedFromFee[msg.sender] = true;
}
```
- When deplying the Smart Contract it will automatically mint 10 billion tokens to the owner and it will exclude the owner from paying the transfer tax
- The fees on transfer are desabled to start with
- The contract is unpaused by default
- The Token will have 18 decimals(same as ETH and almost every other popular Token)

#### Minting:

- To ming tokens the owner of the Smart Contract will have to call the `mint()` function with two parrameters: `addres of the wallet to mint to` and `the amount to mint` (the amount to mint will need to have 18 decimals, so 1 = 1000000000000000000). You can do this kind of conversion by multiplying the amoun to tokens you want to mint to 10 to the power of 18.

#### Burning:
- To burn tokens anyone can call the function `burn()` in the SC with one parameter: `the amount of tokens the person wants to burn from their wallet`.

#### Set the transfer fee:
- To set the transfer fee the owner of the SC will need to call the function `setFee()` with one parameter: `the fee expressed as number with 2 decimals` (so 10000 = 100% 1000 = 10%, 100 = 1%)

#### Enable/Disable fees
- To Enable or Disable the fees, the owner of the SC will have to call the function `setTaxState()` with one parameter: `true or false` (where true = fees are enabled and false = fees are disabled)

#### Set an address as whitelisted:
- Setting an address as whitelisted will make it not pay the fees even if they are enabled. To do this, the owner of the SC will have to call the `excludeFromFee()` function with one parameter: `the address to be whitelisted`

#### Remove an address form whitelist:
- To remove an address from the whitelist the owner of the SC will have to call the function `includeToFee()` with one parameter: `the address to be excluded from whitelist`

#### Pause token transfers:
- To pause token transfers the owner of the SC will have to call the function `pause()`

#### UnPause token transfers
- To unpause token transfers the owner of the SC will have to call the function `unpause()`


# Staking Smart Contract

## Functionality:

### For users:

- Stake tokens with a fixed APR of 2%
- Claim rewards
- Compound rewards
- Lock tokens for one of the 4 periods available and earn interest on the deposit
- Unlock their tokens prior to unlock time (losing any rewards)
- Unlock their tokens after the period of time passes along with the rewards


### For onwer:

- Pause deposits
- Unpause deposits
- Set the rewards % for each of the 4 tipes of locks available



## Functionality explained:

#### Deploying:

- When deplying the Smart Contract the constructor function will require the Address of the Token Smart Contract as an parameter:

```solidity
constructor(IToken _token) {
    token = _token;
}
```

- The default values for APR are as follows:
    - Flexible Staking: 2% APR
    - 3 Months Lock: 3%
    - 6 Months Lock: 4%
    - 12 Months Lock: 6%
    - 24 Months Lock: 8%

#### Staking

- To stake the users will have to call the `stake()` function with one parameter: `the amount to stake expressed with 18 deciamls` (so 1 token = 1 * 10**18 or 1 token = 1000000000000000000)

#### Claiming rewards

- To claim rewards the users will have to wait two weeks from the first time they stake. After that they will have to call the `claimRewards()` function in the SC.

#### Compound rewards

- To compound their rewards the users will have to call the `stakeRewards()` function in the SC. To be able to do this they will also have to wait 2 weeks from the first time they stake.

#### Withdraw stake

- To withdraw their stake the users will have to call the `withdraw()` function in the SC with one parameter: `the amount to withdraw expressed with 18 decimals` (so 1 token = 1 * 10**18 or 1 token = 1000000000000000000).

#### Lock tokens

- To lock tokens the users will have to call the `lockTokens()` function in the SC with two parameters: `the amount of tokens to be locked expressed with 18 deciamls` and `the type of lock respresented as a number`, where:
    - 3 Months is represented by 0
    - 6 Months is represented by 1
    - 12 Months is represented by 2
    - 24 Months is represented by 3

#### Unlock tokens

- To unlock tokens, the users will have to call the `unlockTokens()` function in the SC with one parameter: ` the index of the lock they wish to withdraw`.
- If the user calls this function before the locking period is over he will only receive his initial lock and will lose all rewards


#### Pause Staking and Locking deposits
- To pause Staking and Locking deposits the owner of the SC will have to call the function `pause()`

#### UnPause Staking and Locking deposits
- To unpause Staking and Locking deposits the owner of the SC will have to call the function `unpause()`

#### Set the Locking rewards for each period
- To set the rewards awarded for Locks, owner will have to call one of the 4 functions:
    - `setRewardsThreeMonths()`
    - `setRewardsSixMonths()`
    - `setRewardsTwelveMonths()`
    - `setRewardsTwentyFourMonths`
- Each function will take one parameter: `the rewards awarded after the lock is over`, expressed as a number with 2 decimals. (so 1% = 100, 10% = 1000, 20% = 2000). !!This is the % after the period lock, not APR!!(So, to set the APR as 4% for Six Months Locks, the parameter will be 200, the equivalent of 2% || To set the APR as 8% for 24 Moths, the parameter will be 1600, the equivalent of 16%)

