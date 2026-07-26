#!/usr/bin/env python3
import argparse
import datetime as dt
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE_DIR = ROOT / "evidence"
SCHEMA_PATH = EVIDENCE_DIR / "evidence.schema.json"
OUT_PATH = EVIDENCE_DIR / "evidence.json"


def run_command(command: str) -> tuple[int, str]:
    proc = subprocess.run(
        command,
        shell=True,
        cwd=ROOT,
        capture_output=True,
        text=True,
    )
    output = (proc.stdout or "") + ("\n" + proc.stderr if proc.stderr else "")
    return proc.returncode, output


def extract_foundry_version() -> str:
    code, output = run_command("forge --version")
    if code != 0:
        return "unknown"
    return output.strip().splitlines()[0]


def extract_solc_version() -> str:
    code, output = run_command("forge build")
    if code != 0:
        return "unknown"

    match = re.search(r"Solc\s+([0-9]+\.[0-9]+\.[0-9]+)", output)
    if match:
        return match.group(1)

    # Fallback when Forge output format changes.
    match = re.search(r"([0-9]+\.[0-9]+\.[0-9]+)", output)
    return match.group(1) if match else "unknown"


def parse_test_summary(output: str) -> tuple[int, int]:
    matches = re.findall(r"(\d+)\s+passed;\s+(\d+)\s+failed", output)
    if not matches:
        return 0, 0

    passed, failed = matches[-1]
    return int(passed), int(failed)


def sha256_for_glob(directory: Path, pattern: str) -> str:
    digest = hashlib.sha256()
    files = sorted(directory.rglob(pattern))

    for file_path in files:
        digest.update(file_path.relative_to(ROOT).as_posix().encode("utf-8"))
        digest.update(b"\0")
        digest.update(file_path.read_bytes())
        digest.update(b"\0")

    return "sha256:" + digest.hexdigest()


def validate_type(value: Any, expected: str) -> bool:
    if expected == "object":
        return isinstance(value, dict)
    if expected == "string":
        return isinstance(value, str)
    if expected == "boolean":
        return isinstance(value, bool)
    if expected == "integer":
        return isinstance(value, int) and not isinstance(value, bool)
    return True


def validate_against_schema(instance: Any, schema: dict[str, Any], path: str = "$") -> list[str]:
    errors: list[str] = []

    schema_type = schema.get("type")
    if schema_type and not validate_type(instance, schema_type):
        errors.append(f"{path}: expected type {schema_type}")
        return errors

    if "const" in schema and instance != schema["const"]:
        errors.append(f"{path}: expected constant value {schema['const']!r}")

    if isinstance(instance, str) and "minLength" in schema and len(instance) < schema["minLength"]:
        errors.append(f"{path}: string shorter than minLength={schema['minLength']}")

    if isinstance(instance, int):
        if "minimum" in schema and instance < schema["minimum"]:
            errors.append(f"{path}: value smaller than minimum={schema['minimum']}")

    if isinstance(instance, str) and "pattern" in schema:
        if not re.match(schema["pattern"], instance):
            errors.append(f"{path}: string does not match pattern {schema['pattern']}")

    if isinstance(instance, dict):
        required = schema.get("required", [])
        for key in required:
            if key not in instance:
                errors.append(f"{path}: missing required property {key}")

        properties = schema.get("properties", {})
        additional_allowed = schema.get("additionalProperties", True)

        for key, value in instance.items():
            if key not in properties:
                if not additional_allowed:
                    errors.append(f"{path}: additional property not allowed: {key}")
                continue

            child_path = f"{path}.{key}"
            errors.extend(validate_against_schema(value, properties[key], child_path))

    return errors


def build_evidence(command: str) -> tuple[dict[str, Any], str]:
    exit_code, test_output = run_command(command)
    passed, failed = parse_test_summary(test_output)

    evidence = {
        "schemaVersion": "1.0.0",
        "labId": "reentrancy-01",
        "toolchain": {
            "foundry": extract_foundry_version(),
            "solc": extract_solc_version(),
        },
        "execution": {
            "command": command,
            "exitCode": exit_code,
            "passed": passed,
            "failed": failed,
        },
        "assertions": {
            "exploitConfirmed": "[PASS] testExploitDrainsVault()" in test_output,
            "fixConfirmed": "[PASS] testFixedVaultRejectsExploit()" in test_output,
            "negativeControlConfirmed": "[PASS] testExploitAssumptionFailsWithoutVictimFunds()" in test_output,
        },
        "artifacts": {
            "sourceHash": sha256_for_glob(ROOT / "src", "*.sol"),
            "testHash": sha256_for_glob(ROOT / "test", "*.sol"),
        },
        "generatedAt": dt.datetime.now(dt.UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z"),
    }

    return evidence, test_output


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate and validate evidence for reentrancy-01")
    parser.add_argument("--command", default="forge test -vvv", help="Command used for test execution")
    parser.add_argument("--out", default=str(OUT_PATH), help="Output path for generated evidence")
    parser.add_argument(
        "--validate-only",
        default="",
        help="If provided, validates an existing evidence JSON file and exits",
    )
    args = parser.parse_args()

    schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))

    if args.validate_only:
        candidate_path = Path(args.validate_only)
        if not candidate_path.is_absolute():
            candidate_path = ROOT / candidate_path
        candidate = json.loads(candidate_path.read_text(encoding="utf-8"))
        errors = validate_against_schema(candidate, schema)
        if errors:
            print("Schema validation failed:")
            for err in errors:
                print(f"- {err}")
            return 1
        print(f"Schema validation passed: {candidate_path}")
        return 0

    evidence, test_output = build_evidence(args.command)
    errors = validate_against_schema(evidence, schema)
    if errors:
        print("Generated evidence did not validate against schema:")
        for err in errors:
            print(f"- {err}")
        return 1

    out_path = Path(args.out)
    if not out_path.is_absolute():
        out_path = ROOT / out_path
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")

    (EVIDENCE_DIR / "last-forge-test-output.log").write_text(test_output, encoding="utf-8")

    print(f"Evidence generated: {out_path}")
    print(f"Schema validation passed: {SCHEMA_PATH}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
