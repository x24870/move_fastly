# Pick up Move quickly
This repo organized several examples from Aptos ecosystem. 
Also, Aptos-cli commands are writen as shortcuts in Makefile. \
Play with these commands and query resources to see what happened on the local testnet. \
Then you can read the source code to know how move language imeplement these features, I added some comments to these examples. \
Hope this repo helps you to pick up move language quickly. 

## Local dev environment setup

### Pre-requirement
Make sure you have installed [aptos-cli](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)

**NOTE**: *Make commands in this document are shortcuts, you can check origin aptos-cli commands in the Makefile*

### Setup local testnet and profiles
Run a local testnet
```
make local_testnet
```
Open another terminal, Initialize profiles
```
make init_profiles
```
Fund accounts of these profiles
```
make fund
```

---
## Example 1 - Counter

### Compile and publish the counter module
Module owner compile the module
```
make compile_counter
```

Module owner publish the module
```
make publish_counter
```

User initialize a counter resource with value 0 and store it to his account global storage
```
make init_counter
```

User increase the count
```
make incr_counter
```

User check his counter resource, the value should increased
```
make query_user_resource
```

---
## Example 2 - Message Book

Module owner compile the module
```
make compile_message
```

Module owner publish the module
```
make publish_message
```

User set message of message holder resource under his account
```
make set_message
```

User check his message holder resource, should get the message 'ABC123' that we wrote in the *set_message* script
```
make query_user_resource
```

Or you can use this script to print user's message. \
Checkout the terminal that you run the local testnet, you shoud see the hex code of 'ABC123'
```
make print_message
```
---
## Example 3 - Bridge
This Bridge is for centralized brdige prototype example.
There would be another smart contract on another chain. \
You may needs to implement a service to query lock/unlock events that related to the contract on both chain. \
Everytime the lock event occurs on one chain, then the contract on another chain unlocks coins on that chain, vice versa.

Compile the bridge contract
```
make compile_bridge
```
Run test cases 
```
make test_bridge
```

---
## Example 4 - NFT
In Aptos, tokens are more like EIP721 or EIP1155 assets. You can find more details [here](https://aptos.dev/concepts/coin-and-token/aptos-token/#overview-of-nft)

Compile NFT contracts
```
make compile_nft
```
Run test cases
```
make test_nft
```
Publish NFT contract
```
make publish_nft
```
User execute mint NFT script
```
make claim_nft
```
Check the NFT exists under user's account
```
make query_user_resource
```

---
## Example 5 - Upgrade module
Let's say, we need a function to reset the count of counter. \
In this example, we will upgrade the counter module in example 1.

First, compile the upgraded counter module.
```
make compile_upgraded_counter
```

Then publish the module
```
make publish_upgraded_counter
```

Now, you can reset the counter
```
make reset_counter
```

Check the count has been set reset to 0
```
make query_user_resource
```

Upgrading module needs to comply with these  [policies](https://aptos.dev/guides/move-guides/upgrading-move-code/#upgrade-policies).
For example, the resource structure can't be modified.
Try to uncomment the **name** field *(at line 11)* of counter struct in **counter.move**. \
Remember to add a value for initialzing the struct.
I already add the code, just uncomment it *(at line 21)* \
Then compile and publish the module, you will get **BACKWARD_INCOMPATIBLE_MODULE_UPDATE** error.

Also, the function signature can't be modified.
There is another **reset_counter** function in **counter.move**.
Try to replace the currecnt **reset_counter** function with that function then upgrade the module. \
You will get **BACKWARD_INCOMPATIBLE_MODULE_UPDATE** error again.

---
### Example references:
[Counter](https://starcoinorg.github.io/starcoin-cookbook/docs/move/quick-start/) \
[Message](https://aptos.dev/tutorials/first-move-module/) \
[NFT](https://github.com/DreamXzxy/NFTR) \
[Upgrade module](https://aptos.dev/guides/move-guides/upgrading-move-code/)
