# Copyright (c) Aptos
# SPDX-License-Identifier: Apache-2.0

import json, uuid

from aptos_sdk.account import Account
from aptos_sdk.client import FaucetClient, RestClient

from .common import NODE_URL

if __name__ == "__main__":
    # init clients
    rest_client = RestClient(NODE_URL)

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
    print(f"Alice: {creator.address()}")

    # token img url
    img_url = "https://lh3.googleusercontent.com/p/AF1QipNQrppi1F3Hr4NxEpTehRc_STG6N_L_MizPFBrP=w768-h768-n-o-v1"

    # get supply
    collection_supply =  rest_client.get_collection_supply(creator.address(), collection_name)
    print(
        f" --- Current supply of collection: {json.dumps(collection_supply, indent=4, sort_keys=True)}"
    ) 

    # create token
    txn_hash = rest_client.create_token(
        creator,
        collection_name,
        token_name + str(uuid.uuid4()),
        collection_desc,
        1,
        img_url,
        0,
    )
    rest_client.wait_for_transaction(txn_hash)

    #:!:>section_6
    collection_data = rest_client.get_collection(creator.address(), collection_name)
    print(
        f"Creator's collection: {json.dumps(collection_data, indent=4, sort_keys=True)}"
    )  # <:!:section_6

    #:!:>section_7
    balance = rest_client.get_token_balance(
        creator.address(), creator.address(), collection_name, token_name, property_version
    )
    print(f"Creator's token balance: {balance}")  # <:!:section_7
    #:!:>section_8
    token_data = rest_client.get_token_data(
        creator.address(), collection_name, token_name, property_version
    )
    print(
        f"Creator's token data: {json.dumps(token_data, indent=4, sort_keys=True)}"
    )  # <:!:section_8

    rest_client.close()
