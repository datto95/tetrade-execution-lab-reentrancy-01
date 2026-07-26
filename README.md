# reentrancy-01

Didactic proof of concept for the Tétrade execution lab.

This lab demonstrates, with executable tests, a reentrancy exploit against a vulnerable vault and a corrected vault that blocks the same attack.

## What this lab proves

1. A real exploit can drain a vulnerable vault.
2. The same exploit attempt fails against a corrected vault.
3. A negative control prevents false positives.
4. Execution evidence is generated in structured JSON.
5. The workflow is reproducible from a clean environment.

## Project structure

- `src/VulnerableVault.sol`: intentionally vulnerable educational vault.
- `src/FixedVault.sol`: corrected vault using checks-effects-interactions plus a reentrancy guard.
- `src/Attacker.sol`: attacker contract used by the tests.
- `test/ReentrancyExploit.t.sol`: exploit, fix, and negative-control tests.
- `scripts/generate_evidence.py`: generates `evidence/evidence.json`.
- `evidence/evidence.schema.json`: JSON schema for the evidence payload.
- `evidence/example.evidence.json`: example payload.

## Prerequisites

- Foundry installed and available in `PATH` (`forge`, `cast`, `anvil`)
- Python 3.10+ installed

## Quick start

```bash
git clone <repo-url>
cd tetrade-execution-lab/labs/reentrancy-01
forge install foundry-rs/forge-std
forge build
forge test -vvv
python3 scripts/generate_evidence.py
python3 scripts/generate_evidence.py --validate-only evidence/evidence.json
```

## Useful commands

```bash
make install
make build
make test
make evidence
make validate
```

## Expected test signals

The exploit and defenses are validated only by deterministic test output:

- `[PASS] testExploitDrainsVault()`
- `[PASS] testFixedVaultRejectsExploit()`
- `[PASS] testExploitAssumptionFailsWithoutVictimFunds()`

## Notes

- This is a didactic vault pattern inspired by common reentrancy incidents.
- It is not a reproduction of Euler Finance internals.
- Integration with Tétrade Engineering is intentionally out of scope for this first PoC.
