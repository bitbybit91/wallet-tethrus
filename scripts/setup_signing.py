#!/usr/bin/env python3
"""
setup_signing.py — Materialize Android signing keys from Codemagic environment variables.

Required environment variables:
  CM_KEYSTORE          Base64-encoded .jks keystore file
  CM_KEY_ALIAS         Key alias inside the keystore
  CM_KEY_PASSWORD      Password for the private key
  CM_KEYSTORE_PASSWORD Password for the keystore file
  CM_KEYSTORE_PATH     (Optional) Destination path; defaults to release.keystore

Optional environment variables (btctestnet signing):
  CM_TESTNET_KEYSTORE          Base64-encoded .jks keystore for testnet
  CM_TESTNET_KEY_ALIAS         Key alias inside the testnet keystore
  CM_TESTNET_KEY_PASSWORD      Password for the testnet private key
  CM_TESTNET_KEYSTORE_PASSWORD Password for the testnet keystore file
  CM_TESTNET_KEYSTORE_PATH     (Optional) Destination path; defaults to testnet-release.keystore

The script writes a keys.properties file at the repository root that is read by
build.gradle during the Gradle signing configuration phase.
"""

import base64
import os
import sys
from pathlib import Path


def require_env(name: str) -> str:
    """Return the value of an environment variable or exit with a clear error."""
    value = os.environ.get(name)
    if not value:
        print(
            f"\n[ERROR] Required environment variable '{name}' is missing or empty.\n"
            f"        Make sure it is set in your Codemagic environment group.\n",
            file=sys.stderr,
        )
        sys.exit(1)
    return value


def optional_env(name: str, default: str = "") -> str:
    return os.environ.get(name, default)


def decode_keystore(b64_data: str, dest_path: Path, label: str) -> None:
    """Decode a base64 keystore and write it to dest_path."""
    try:
        raw = base64.b64decode(b64_data)
    except Exception as exc:
        print(
            f"\n[ERROR] Failed to base64-decode '{label}' keystore: {exc}\n"
            f"        Ensure the value is a valid base64-encoded .jks file.\n",
            file=sys.stderr,
        )
        sys.exit(1)

    dest_path.parent.mkdir(parents=True, exist_ok=True)
    dest_path.write_bytes(raw)
    print(f"[OK] {label} keystore written to: {dest_path} ({len(raw)} bytes)")


def write_keys_properties(props: dict, dest: Path) -> None:
    """Write key=value pairs to a .properties file."""
    lines = [f"{k}={v}" for k, v in props.items()]
    dest.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"[OK] keys.properties written to: {dest}")


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent

    # ── prodnet (release) signing ──────────────────────────────────────────────
    prod_ks_b64 = require_env("CM_KEYSTORE")
    prod_key_alias = require_env("CM_KEY_ALIAS")
    prod_key_password = require_env("CM_KEY_PASSWORD")
    prod_ks_password = require_env("CM_KEYSTORE_PASSWORD")
    prod_ks_path = Path(
        optional_env("CM_KEYSTORE_PATH", str(repo_root / "release.keystore"))
    )

    decode_keystore(prod_ks_b64, prod_ks_path, "prodnet release")

    # Validate the keystore is a valid ZIP/JKS magic-byte file
    with prod_ks_path.open("rb") as fh:
        header = fh.read(4)
    if header not in (b"\xfe\xed\xfe\xed", b"PK\x03\x04"):
        print(
            f"\n[WARNING] Unexpected keystore file header: {header.hex()}\n"
            f"          Expected a JKS (\\xfeed\\xfeed) or PKCS12 (PK) keystore.\n"
            f"          The build may fail if the keystore format is incorrect.\n",
            file=sys.stderr,
        )

    props: dict = {
        "prodKeyStore": str(prod_ks_path.relative_to(repo_root)),
        "prodKeyAlias": prod_key_alias,
        "prodKeyStorePassword": prod_ks_password,
        "prodKeyAliasPassword": prod_key_password,
    }

    # ── btctestnet (optional) signing ──────────────────────────────────────────
    testnet_ks_b64 = optional_env("CM_TESTNET_KEYSTORE")
    if testnet_ks_b64:
        testnet_key_alias = require_env("CM_TESTNET_KEY_ALIAS")
        testnet_key_password = require_env("CM_TESTNET_KEY_PASSWORD")
        testnet_ks_password = require_env("CM_TESTNET_KEYSTORE_PASSWORD")
        testnet_ks_path = Path(
            optional_env(
                "CM_TESTNET_KEYSTORE_PATH",
                str(repo_root / "testnet-release.keystore"),
            )
        )
        decode_keystore(testnet_ks_b64, testnet_ks_path, "btctestnet release")
        props.update(
            {
                "testKeyStore": str(testnet_ks_path.relative_to(repo_root)),
                "testKeyAlias": testnet_key_alias,
                "testKeyStorePassword": testnet_ks_password,
                "testKeyAliasPassword": testnet_key_password,
            }
        )
    else:
        print(
            "[INFO] CM_TESTNET_KEYSTORE not set — btctestnet will use the debug "
            "keystore (unsigned release)."
        )

    write_keys_properties(props, repo_root / "keys.properties")
    print("\n[OK] Signing setup complete.")


if __name__ == "__main__":
    main()
