# Pick up Move quickly

## Local dev environment setup

### Pre-requirement
Make sure you have installed [aptos-cli](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)

**NOTE**: *Make commands in this document are shortcuts, you can check origin aptos cli commands in the Makefile*

### Setup local testnet and profiles
Run a local testnet
```
make local_net
```
Default REST API endpoind would be:
`http://0.0.0.0:8080`

Default faucet endpoint would be:
`http://0.0.0.0:8081`

Init profiles
```
make init_profiles
```

fund accounts of these profiles
```
make fund
```

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

Or you can use this script to print user's message. Checkout the terminal that you run the local testnet, you shoud see the hex code of 'ABC123'
```
make print_message
```