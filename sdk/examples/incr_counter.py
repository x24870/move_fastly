from typing import Counter
from aptos_sdk.account import Account
from aptos_sdk.account_address import AccountAddress
from aptos_sdk.client import FaucetClient, RestClient
from aptos_sdk.transactions import (
    EntryFunction,
    TransactionArgument,
    TransactionPayload,
)
from aptos_sdk.type_tag import StructTag, TypeTag
from .common import FAUCET_URL, NODE_URL


class CounterClient(RestClient):
    def incr_counter(self, contract_address: AccountAddress, sender: Account) -> str:
        payload = EntryFunction.natural(
            "eff76c60635b2cbb70fc85e9cd226a1c6110311de5cbc831e2c45edc57573495::MyCounter",
            "incr_counter",
            # [TypeTag(StructTag.from_str(f"{contract_address}::MyCounter::Counter"))],
            [],
            [],
        )
        signed_transaction = self.create_single_signer_bcs_transaction(
            sender, TransactionPayload(payload)
        )
        return self.submit_bcs_transaction(signed_transaction)

if __name__ == "__main__":
    alice_priv_key = "0x600f4338e648dcaebfa32d852586095016778ba5ad278794e2a0ce713538c3b0"
    alice = Account.load_key(alice_priv_key)
    print("--------TRY TO INCR COUNTER------")

    rest_client = CounterClient(NODE_URL)
    txn_hash = rest_client.incr_counter(alice.address(), alice)
    rest_client.wait_for_transaction(txn_hash)
    print(
        f"increase counter---\n"
    )
