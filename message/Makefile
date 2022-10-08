PROFILE=local
ACCOUNT=local
FAUCET_URL=http://0.0.0.0:8081
REST_URL=http://0.0.0.0:8080

test:
	aptos move run-script --assume-yes --script-path scripts/test.move --sender-account=local --profile=local

compile:
	aptos move compile --named-addresses owner=${ACCOUNT},user=${ACCOUNT}

publish:
	aptos move publish --sender-account ${ACCOUNT}  --profile ${PROFILE} --named-addresses owner=${ACCOUNT},user=${ACCOUNT}

set_msg:
	aptos move run --function-id '${ACCOUNT}::message::set_message' --profile=${PROFILE} --args vector:letsgo