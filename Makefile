SHELL := /bin/sh

.PHONY: install build test gas-report evidence validate clean

install:
	forge install foundry-rs/forge-std

build:
	forge build

test:
	forge test -vvv

gas-report:
	forge test --gas-report > evidence/gas-report.txt

evidence:
	python3 scripts/generate_evidence.py

validate:
	python3 scripts/generate_evidence.py --validate-only evidence/evidence.json

clean:
	rm -rf out cache broadcast coverage evidence/evidence.json evidence/last-forge-test-output.log
