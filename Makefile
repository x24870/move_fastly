PROFILE=local
ACCOUNT=local
FAUCET_URL=http://0.0.0.0:8081
REST_URL=http://0.0.0.0:8080
PACKAGE_DIR=counter

# env
local_net:
	aptos node run-local-testnet --with-faucet

init_profiles:
	aptos init --profile local --rest-url ${REST_URL} --faucet-url ${FAUCET_URL}
	aptos init --profile owner --rest-url ${REST_URL} --faucet-url ${FAUCET_URL}
	aptos init --profile user --rest-url ${REST_URL} --faucet-url ${FAUCET_URL}

acct_list:
	aptos account list --profile ${PROFILE}

fund:
	aptos account fund-with-faucet --profile ${PROFILE} --account local --amount 99999999
	aptos account fund-with-faucet --profile ${PROFILE} --account owner --amount 99999999
	aptos account fund-with-faucet --profile ${PROFILE} --account user --amount 99999999

# counter
compile_counter:
	aptos move compile --package-dir counter --named-addresses owner=owner

publish_counter:
	aptos move publish --assume-yes --package-dir counter --sender-account owner --named-addresses owner=owner --profile owner

init_counter:
	aptos move run --assume-yes --function-id owner::MyCounter::init_counter --sender-account user --profile user

incr_counter:
	aptos move run --assume-yes --function-id owner::MyCounter::incr_counter --sender-account user --profile user

# hello
compile_hello:
	aptos move compile --package-dir hello_blockchain --named-addresses owner=owner,user=user

init_hello:
	aptos move run-script --compiled-script-path hello_blockchain/build/Examples/bytecode_scripts/get_msg.mv --sender-account=local --profile=local

# bridge
compile_bridge:
	aptos move compile --package-dir bridge  --named-addresses MoonCoin=${ACCOUNT}

test_bridge:
	aptos move test --package-dir bridge --named-addresses MoonCoin=default

# query
query_module:
	aptos account list --query modules --account ${ACCOUNT} --profile ${PROFILE}

query_user_resource:
	aptos account list --query resources --account user --profile user

publish_hello:
	aptos move publish --package-dir hello_blockchain --sender-account local --named-addresses owner=local,user=user  --profile ${PROFILE}

trasaction:
	aptos move run --function-id 9b1c945889a5be2b46140b3307eba15db4ca2c5d03b63aeca97769bda7fab65e::<Moudle_Name>::<Function_Name> --profile default


### execute move scripts
script_incr_counter:
	poetry run python -m examples.incr_counter

### nft
create_collection:
	poetry run python -m examples.create_collection

create_token:
	poetry run python -m examples.create_token

transfer:
	echo "todo"
