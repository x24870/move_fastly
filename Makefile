PROFILE=local
FAUCET_URL=http://0.0.0.0:8081
REST_URL=http://0.0.0.0:8080
PACKAGE_DIR=hello_blockchain

dev_net:
	aptos init --profile default

local_net:
	aptos node run-local-testnet --with-faucet

local_cli:
	aptos init --profile ${PROFILE} --rest-url ${REST_URL} --faucet-url ${FAUCET_URL} 

acct_list:
	aptos account list --profile ${PROFILE}

fund:
	aptos account fund-with-faucet --profile ${PROFILE} --account ${PROFILE}

compile:
	aptos move compile --package-dir ${PACKAGE_DIR} --named-addresses hello_blockchain=default

deploy_contract:
	aptos move publish --package-dir ${PACKAGE_DIR} --profile ${PROFILE}

call_contract:
	aptos move run --function-id :::: --profile ${PROFILE}


