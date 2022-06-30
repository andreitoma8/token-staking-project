from brownie import Token, Staking, accounts, config


def main():
    owner = accounts.add(config["wallets"]["from_key"])
    token = Token.deploy({"from": owner}, publish_source=True)
    staking = Staking.deploy(token.address, {"from": owner}, publish_source=True)
    token.setStakingSC(staking.address, {"from": owner})
