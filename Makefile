PROFILE=local
ACCOUNT=local
FAUCET_URL=http://0.0.0.0:8081
REST_URL=http://0.0.0.0:8080
PACKAGE_DIR=counter

dev_net:
	aptos init --profile default

local_net:
	aptos node run-local-testnet --with-faucet

local_cli:
	aptos init --profile ${PROFILE} --rest-url ${REST_URL} --faucet-url ${FAUCET_URL} 

acct_list:
	aptos account list --profile ${PROFILE}

fund:
	aptos account fund-with-faucet --profile ${PROFILE} --account ${PROFILE} --amount 99999999

compile_hello:
	# aptos move compile --package-dir hello_blockchain --named-addresses MyAddr=default
	aptos move compile --package-dir hello_blockchain --named-addresses MyAddr=default

compile_counter:
	aptos move compile --package-dir counter --named-addresses MyAddr="default"

init_counter:
	aptos move run --function-id '${ACCOUNT}::MyCounter::init_counter' --profile=${PROFILE}

incr_counter:
	aptos move run --function-id '${ACCOUNT}::MyCounter::incr_counter' --profile=${PROFILE}

script_incr_counter:
	aptos move run-script --script-path scripts/counter_incr.move --sender-account=${ACCOUNT} --profile=${PROFILE}

query_module:
	aptos account list --query modules --account ${ACCOUNT} --profile ${PROFILE}

query_resource:
	aptos account list --query resources --account ${ACCOUNT} --profile ${PROFILE}

publish_contract:
	aptos move publish --package-dir counter --sender-account default --named-addresses MyAddr=default  --profile default

publish_counter:
	aptos move publish --package-dir counter --sender-account ${ACCOUNT} --named-addresses MyAddr=${ACCOUNT} --profile ${PROFILE}

trasaction:
	aptos move run --function-id 9b1c945889a5be2b46140b3307eba15db4ca2c5d03b63aeca97769bda7fab65e::<Moudle_Name>::<Function_Name> --profile default

call_contract:
	aptos move run --function-id :::: --profile ${PROFILE}


