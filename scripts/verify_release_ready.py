#!/usr/bin/env python3
"""
verify_release_ready.py — Pre-flight checks before a release build.

Run this script locally or in CI before invoking Gradle to confirm that
all required preconditions for a signed release build are satisfied.

Exit codes:
  0 — all checks passed
  1 — one or more checks failed (details printed to stderr)
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path


REQUIRED_ENV_VARS = [
    "CM_KEYSTORE",
    "CM_KEY_ALIAS",
    "CM_KEY_PASSWORD",
    "CM_KEYSTORE_PASSWORD",
]

MIN_JAVA_MAJOR = 17  # 17 is the minimum; 21 is preferred
REQUIRED_GRADLE_WRAPPER = Path(__file__).resolve().parent.parent / "gradlew"
REQUIRED_SUBMODULES = [
    "wallet-android-modularization-tools",
    "fiosdk_kotlin",
]


def check(name: str, condition: bool, detail: str = "") -> bool:
    status = "PASS" if condition else "FAIL"
    symbol = "✓" if condition else "✗"
    msg = f"  [{status}] {symbol} {name}"
    if not condition and detail:
        msg += f"\n         → {detail}"
    print(msg)
    return condition


def java_major_version() -> int:
    """Return the major version number of the active JDK."""
    try:
        result = subprocess.run(
            ["java", "-version"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        for line in (result.stdout + result.stderr).splitlines():
            if "version" in line:
                # e.g. 'openjdk version "21.0.3" 2024-04-16'
                # or   'java version "17.0.11" 2024-04-16'
                parts = line.strip().split('"')
                if len(parts) >= 2:
                    version_str = parts[1]
                    major = int(version_str.split(".")[0])
                    return major
    except Exception:
        pass
    return 0


def submodule_initialized(path: str) -> bool:
    repo_root = Path(__file__).resolve().parent.parent
    sm_path = repo_root / path
    # A submodule is initialized if its directory is non-empty
    return sm_path.is_dir() and any(sm_path.iterdir())


def main() -> None:
    repo_root = Path(__file__).resolve().parent.parent
    failures: list[str] = []

    print("\n=== Release Pre-flight Checks ===\n")

    # ── 1. Java version ───────────────────────────────────────────────────────
    java_ver = java_major_version()
    ok = check(
        f"Java version ≥ {MIN_JAVA_MAJOR} (found {java_ver})",
        java_ver >= MIN_JAVA_MAJOR,
        f"Install JDK {MIN_JAVA_MAJOR}+ and ensure it is on PATH.",
    )
    if not ok:
        failures.append("Java version")

    # ── 2. Gradle wrapper exists ──────────────────────────────────────────────
    ok = check(
        "Gradle wrapper script (gradlew) present",
        REQUIRED_GRADLE_WRAPPER.exists(),
        f"Expected: {REQUIRED_GRADLE_WRAPPER}",
    )
    if not ok:
        failures.append("Gradle wrapper missing")

    # ── 3. Android SDK / ANDROID_HOME ─────────────────────────────────────────
    android_home = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    ok = check(
        "ANDROID_HOME / ANDROID_SDK_ROOT set",
        bool(android_home),
        "Set ANDROID_HOME or ANDROID_SDK_ROOT to your Android SDK location.",
    )
    if not ok:
        failures.append("ANDROID_HOME not set")

    # ── 4. Signing environment variables ──────────────────────────────────────
    for var in REQUIRED_ENV_VARS:
        val = os.environ.get(var)
        ok = check(
            f"Env var {var} is set",
            bool(val),
            f"Set {var} in your Codemagic environment group 'wallet_tethrus_signing'.",
        )
        if not ok:
            failures.append(f"Missing env var: {var}")

    # ── 5. keys.properties exists (may not yet — setup_signing.py creates it) ─
    keys_props = repo_root / "keys.properties"
    if keys_props.exists():
        check("keys.properties present", True)
    else:
        check(
            "keys.properties present (will be created by setup_signing.py)",
            True,  # not a hard failure; setup_signing.py creates it
        )

    # ── 6. Submodules initialized ─────────────────────────────────────────────
    for sm in REQUIRED_SUBMODULES:
        ok = check(
            f"Submodule '{sm}' initialized",
            submodule_initialized(sm),
            "Run: git submodule update --init --recursive",
        )
        if not ok:
            failures.append(f"Submodule not initialized: {sm}")

    # ── 7. google-services.json for mbw ──────────────────────────────────────
    gservices = repo_root / "mbw" / "google-services.json"
    check(
        "mbw/google-services.json present",
        gservices.exists(),
        "Required for Firebase-enabled flavors (prodnet, btctestnet). "
        "Not needed for the fdroid flavor.",
    )
    # Not added to failures — fdroid builds don't need it

    # ── 8. Python 3 available ─────────────────────────────────────────────────
    python_path = shutil.which("python3")
    ok = check(
        "python3 available on PATH",
        python_path is not None,
        "Install Python 3.8+ and ensure it is on PATH.",
    )
    if not ok:
        failures.append("python3 not on PATH")

    # ── Summary ───────────────────────────────────────────────────────────────
    print()
    if failures:
        print(
            f"[FAILED] {len(failures)} check(s) failed:\n"
            + "\n".join(f"  • {f}" for f in failures),
            file=sys.stderr,
        )
        print(
            "\nFix the issues above before running the release build.\n",
            file=sys.stderr,
        )
        sys.exit(1)
    else:
        print("[OK] All pre-flight checks passed. Ready to build.\n")


if __name__ == "__main__":
    main()
