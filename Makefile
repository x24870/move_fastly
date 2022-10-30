PROFILE=local
ACCOUNT=local
FAUCET_URL=http://0.0.0.0:8081
REST_URL=http://0.0.0.0:8080
PACKAGE_DIR=counter

# env
local_testnet:
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
	aptos move publish --assume-yes --package-dir counter \
	--sender-account owner --named-addresses owner=owner --profile owner

init_counter:
	aptos move run --assume-yes --function-id owner::MyCounter::init_counter \
	--sender-account user --profile user

incr_counter:
	aptos move run --assume-yes --function-id owner::MyCounter::incr_counter \
	--sender-account user --profile user

# message
compile_message:
	aptos move compile --package-dir message --named-addresses owner=owner,user=user

publish_message:
	aptos move publish --assume-yes --package-dir message \
	--sender-account owner --named-addresses owner=owner,user=user --profile owner

set_message:
	aptos move run-script --assume-yes \
	--compiled-script-path message/build/Message/bytecode_scripts/set_message.mv \
	--sender-account=user --profile=user

print_message:
	aptos move run-script --assume-yes \
	--compiled-script-path message/build/Message/bytecode_scripts/print_message.mv \
	--sender-account=user --profile=user

# bridge
compile_bridge:
	aptos move compile --package-dir bridge --named-addresses BridgeOwner=owner,MoonCoinOwner=user

test_bridge:
	aptos move test --package-dir bridge --named-addresses BridgeOwner=owner,MoonCoinOwner=user

### nft
compile_nft:
	aptos move compile --package-dir nft --named-addresses owner=default

test_nft:
	aptos move test --package-dir nft --named-addresses owner=owner

publish_nft:
	aptos move publish --assume-yes --package-dir nft \
	--sender-account owner --named-addresses owner=owner --profile owner

claim_mint:
	aptos move run-script --assume-yes \
	--compiled-script-path nft/build/Moonkey/bytecode_scripts/claim_mint.mv \
	--sender-account=user --profile=user

query_user_resource:
	aptos account list --query resources --account user --profile user

# upgraded counter
compile_upgrade_counter:
	aptos move compile --package-dir upgrade_counter --named-addresses owner=owner

publish_upgrade_counter:
	aptos move publish --assume-yes --package-dir upgrade_counter \
	--sender-account owner --named-addresses owner=owner --profile owner

reset_counter:
	aptos move run --assume-yes --function-id owner::MyCounter::reset_counter \
	--sender-account user --profile user
	
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


