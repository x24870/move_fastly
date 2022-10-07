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
## Compile and publish your module
### Compile the Counter module
```
aptos move compile --package-dir counter --named-addresses MyAddr="local"
```

### Publish the Counter module
```
aptos move publish --package-dir counter --sender-account local --named-addresses MyAddr=local --profile local
```

### Checkout the published module in your account
```
aptos account list --query modules --account local --profile local
```

---
## Interact with the on-chain module
### Init a counter resource in the account
```
aptos move run --function-id 'local::MyCounter::init_counter' --profile local
```

### Increase the count by 1
```
aptos move run --function-id 'local::MyCounter::incr_counter' --profile local
```

### Check out the count number of counter in your accout
```
aptos account list --query resources --account local --profile local
```

### Use script to interact with the Counter module 
(seems aptos-cli run-script not include the stdlib, still figuring out how to use stdlib...)
```
aptos move run-script --script-path scripts/counter_incr.move --sender-account local --profile local
```
