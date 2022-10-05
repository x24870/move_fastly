# Pick up Move quickly

## Local dev environment setup

### Pre-requirement
Make sure you have installed [aptos-cli](https://aptos.dev/cli-tools/aptos-cli-tool/install-aptos-cli/)

### Start a local testnet
```
 aptos node run-local-testnet --with-faucet
```
Default REST API endpoind would be:
`http://0.0.0.0:8080`

Default faucet endpoint would be:
`http://0.0.0.0:8081`

### initialze a profile on local testnet
Open another terminal and initialze an local account
```
aptos init --profile local --rest-url "http://0.0.0.0:8080" --faucet-url "http://0.0.0.0:8081"
```

Fund your account
```
aptos account fund-with-faucet --profile local --account local --amount 99999999
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
