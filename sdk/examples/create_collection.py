# Copyright (c) Aptos
# SPDX-License-Identifier: Apache-2.0

import json

from aptos_sdk.account import Account
from aptos_sdk.client import FaucetClient, RestClient

from .common import FAUCET_URL, NODE_URL

if __name__ == "__main__":
    # init clients
    rest_client = RestClient(NODE_URL)
    faucet_client = FaucetClient(FAUCET_URL, rest_client)  # <:!:section_1

    # creat an account for creator
    creator_priv_key = "0x600f4338e648dcaebfa32d852586095016778ba5ad278794e2a0ce713538c3b0"
    creator = Account.load_key(creator_priv_key)

    # collection info
    collection_name = "Cool collections"
    collection_desc = "Cool description"
    collection_uri = "https://0xcool.com"
    token_name = "Cool first token"
    property_version = 0

    print("\n=== Addresses ===")
    print(f"Creator: {creator.address()}")

    # fund creator's account
    faucet_client.fund_account(creator.address(), 100_000_000)

    print("\n=== Initial Coin Balances ===")
    print(f"Creator: {rest_client.account_balance(creator.address())}")

    print("\n=== Creating Collection ===")

    # create collection
    txn_hash = rest_client.create_collection(
        creator, collection_name, collection_desc, collection_uri
    )
    rest_client.wait_for_transaction(txn_hash)

    # #:!:>section_5
    # txn_hash = rest_client.create_token(
    #     creator,
    #     collection_name,
    #     token_name,
    #     "Alice's simple token",
    #     1,
    #     "https://aptos.dev/img/nyan.jpeg",
    #     0,
    # )  # <:!:section_5
    # rest_client.wait_for_transaction(txn_hash)

    # print("**********SECOND TOKEN****************")
    # txn_hash = rest_client.create_token(
    #     creator,
    #     collection_name,
    #     token_name+"2",
    #     "Alice's simple token",
    #     1,
    #     "https://aptos.dev/img/nyan.jpeg",
    #     0,
    # )  # <:!:section_5
    # rest_client.wait_for_transaction(txn_hash)

    # print("**********THIRD TOKEN****************")
    # txn_hash = rest_client.create_token(
    #     alice,
    #     collection_name,
    #     token_name+"3",
    #     "Alice's simple token",
    #     1,
    #     "https://aptos.dev/img/nyan.jpeg",
    #     0,
    # )  # <:!:section_5
    # rest_client.wait_for_transaction(txn_hash)

    # #:!:>section_6
    # collection_data = rest_client.get_collection(alice.address(), collection_name)
    # print(
    #     f"Alice's collection: {json.dumps(collection_data, indent=4, sort_keys=True)}"
    # )  # <:!:section_6

    # #:!:>section_7
    # balance = rest_client.get_token_balance(
    #     alice.address(), alice.address(), collection_name, token_name, property_version
    # )
    # print(f"Alice's token balance: {balance}")  # <:!:section_7
    # #:!:>section_8
    # token_data = rest_client.get_token_data(
    #     alice.address(), collection_name, token_name, property_version
    # )
    # print(
    #     f"Alice's token data: {json.dumps(token_data, indent=4, sort_keys=True)}"
    # )  # <:!:section_8

    # print("\n=== Transferring the token to Bob ===")
    # #:!:>section_9
    # txn_hash = rest_client.offer_token(
    #     alice,
    #     bob.address(),
    #     alice.address(),
    #     collection_name,
    #     token_name,
    #     property_version,
    #     1,
    # )  # <:!:section_9
    # rest_client.wait_for_transaction(txn_hash)

    # #:!:>section_10
    # txn_hash = rest_client.claim_token(
    #     bob,
    #     alice.address(),
    #     alice.address(),
    #     collection_name,
    #     token_name,
    #     property_version,
    # )  # <:!:section_10
    # rest_client.wait_for_transaction(txn_hash)

    # balance = rest_client.get_token_balance(
    #     alice.address(), alice.address(), collection_name, token_name, property_version
    # )
    # print(f"Alice's token balance: {balance}")
    # balance = rest_client.get_token_balance(
    #     bob.address(), alice.address(), collection_name, token_name, property_version
    # )
    # print(f"Bob's token balance: {balance}")

    # print("\n=== Transferring the token back to Alice using MultiAgent ===")
    # #:!:>section_11
    # txn_hash = rest_client.direct_transfer_token(
    #     bob, alice, alice.address(), collection_name, token_name, 0, 1
    # )  # <:!:section_11
    # rest_client.wait_for_transaction(txn_hash)

    # balance = rest_client.get_token_balance(
    #     alice.address(), alice.address(), collection_name, token_name, property_version
    # )
    # print(f"Alice's token balance: {balance}")
    # balance = rest_client.get_token_balance(
    #     bob.address(), alice.address(), collection_name, token_name, property_version
    # )
    # print(f"Bob's token balance: {balance}")

    rest_client.close()
