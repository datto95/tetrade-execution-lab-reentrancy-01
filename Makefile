SHELL := /bin/sh

.PHONY: install build test evidence validate clean

install:
	forge install foundry-rs/forge-std

build:
	forge build

test:
	forge test -vvv

evidence:
	python3 scripts/generate_evidence.py

validate:
	python3 scripts/generate_evidence.py --validate-only evidence/evidence.json

clean:
	rm -rf out cache broadcast coverage evidence/evidence.json evidence/last-forge-test-output.log
