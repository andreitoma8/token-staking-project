from brownie import Token, Staking, accounts, chain
import brownie


def test_main():
    # Set up SC
    owner = accounts[0]
    token = Token.deploy({"from": owner})
    staking = Staking.deploy(token.address, {"from": owner})
    token.setStakingSC(staking.address, {"from": owner})
    # Test Classic staking
    token.approve(staking.address, 1000 * 10 ** 18, {"from": owner})
    staking.stake(1000 * 10 ** 18, {"from": owner})
    user_info = staking.getUserInfo(owner.address)
    assert user_info[0] == 1000 * 10 ** 18
    assert user_info[1] < 100
    print(user_info)
    chain.mine(blocks=100, timedelta=86400)
    user_info = staking.getUserInfo(owner.address)
    print(user_info)
    expected_rewards = (1000 * 10 ** 18) * 86400 * 23 / 3600 / 10000000
    assert user_info[1] < (expected_rewards + 100000000000000) and user_info[1] > (
        expected_rewards - 100000000000000
    )
    # Test Token Locking
    token.approve(staking.address, 1000 * 10 ** 18, {"from": owner})
    staking.lockTokens(1000 * 10 ** 18, 0, {"from": owner})
    block_timestamp = chain.time()
    print(block_timestamp)
    user_info = staking.getUserInfo(owner.address)
    user_locks = user_info[2]
    user_lock_0 = user_locks[0]
    print(user_lock_0)
    assert (
        user_lock_0[0] > block_timestamp + 7889000
        and user_lock_0[0] < block_timestamp + 7890000
    )
    # balance_before = token.balanceOf(owner.address)
    # staking.unlockTokens(0, {"from": owner})
    # balance_after = token.balanceOf(owner.address)
    # assert balance_after == (balance_before + user_lock_0[1])
    chain.mine(blocks=100, timedelta=7890000)
    balance_before = token.balanceOf(owner.address)
    staking.unlockTokens(0, {"from": owner})
    balance_after = token.balanceOf(owner.address)
    assert balance_after == (balance_before + user_lock_0[1] + user_lock_0[3])
