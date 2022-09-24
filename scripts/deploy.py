from brownie import SolidityStorage, accounts, network, config


def main():
    # requires brownie account to have been created
    if network.show_active() == 'development':
        # add these accounts to metamask by importing private key
        owner = accounts[0]
        SolidityStorage.deploy({'from': accounts[0]})

    elif network.show_active() == 'kovan':
        # add these accounts to metamask by importing private key
        owner = accounts.add(config['wallets']['from_key'])
        SolidityStorage.deploy({'from': owner})
