#!/usr/bin/env python3
"""
verify_release_ready.py — Pre-flight readiness check for wallet-tethrus (native Android).

Checks:
  1. Python version (requires 3.8+)
  2. Java version (requires 17+)
  3. gradlew executable bit set
  4. Gradle wrapper version (requires 8.0+)
  5. gradle/libs.versions.toml SDK versions meet Google Play requirements
  6. codemagic.yaml present
  7. mbw/build.gradle signing config references expected properties
  8. keys.properties present and complete
  9. keystore.jks present
  10. No hardcoded secrets in key build files
  11. AndroidManifest.xml: required attributes present
  12. ./gradlew :mbw:assembleProdnetRelease --dry-run

Exit 0 if ALL checks pass, exit 1 otherwise.
"""

import os
import re
import subprocess
import sys
from pathlib import Path
from typing import List, Optional, Tuple

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
REPO_ROOT = Path(__file__).resolve().parent.parent
MBW_BUILD_GRADLE = REPO_ROOT / "mbw" / "build.gradle"
VERSIONS_TOML = REPO_ROOT / "gradle" / "libs.versions.toml"
MANIFEST_PATH = REPO_ROOT / "mbw" / "src" / "main" / "AndroidManifest.xml"
KEYS_PROPERTIES = REPO_ROOT / "keys.properties"
KEYSTORE_PATH = REPO_ROOT / "keystore.jks"
GRADLEW = REPO_ROOT / "gradlew"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
PASS = "✅"
FAIL = "❌"
WARN = "⚠️ "

results: List[Tuple[str, str, str]] = []   # (status, check_name, message)


def record(ok: bool, name: str, msg: str = "") -> bool:
    status = PASS if ok else FAIL
    results.append((status, name, msg))
    return ok


def run_cmd(cmd: List[str], cwd: Optional[Path] = None, timeout: int = 120) -> Tuple[int, str, str]:
    """Run a subprocess, return (returncode, stdout, stderr)."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=str(cwd or REPO_ROOT),
            timeout=timeout,
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", f"Command timed out after {timeout}s"
    except FileNotFoundError as exc:
        return -1, "", str(exc)


# ---------------------------------------------------------------------------
# Individual checks
# ---------------------------------------------------------------------------

def check_python_version() -> bool:
    major, minor = sys.version_info.major, sys.version_info.minor
    ok = (major, minor) >= (3, 8)
    return record(ok, "Python version", f"Python {major}.{minor} ({'OK' if ok else 'need 3.8+'})")


def check_java_version() -> bool:
    rc, stdout, stderr = run_cmd(["java", "-version"])
    output = (stdout + stderr).strip()
    # java -version writes to stderr: 'openjdk version "17.0.x"'
    match = re.search(r'version "(\d+)[\._]', output)
    if not match:
        return record(False, "Java version", f"Could not parse: {output!r}")
    major = int(match.group(1))
    ok = major >= 17
    return record(ok, "Java version", f"Java {major} detected ({'OK' if ok else 'need 17+'})")


def check_gradlew_executable() -> bool:
    ok = GRADLEW.exists() and os.access(GRADLEW, os.X_OK)
    return record(ok, "gradlew executable", str(GRADLEW))


def check_gradle_version() -> bool:
    wrapper_props = REPO_ROOT / "gradle" / "wrapper" / "gradle-wrapper.properties"
    if not wrapper_props.exists():
        return record(False, "Gradle wrapper", "gradle-wrapper.properties not found")
    content = wrapper_props.read_text(encoding="utf-8")
    match = re.search(r"gradle-(\d+\.\d+[\.\d]*)-", content)
    if not match:
        return record(False, "Gradle version", "Cannot parse version from wrapper properties")
    version = match.group(1)
    major, minor = (int(x) for x in version.split(".")[:2])
    ok = (major, minor) >= (8, 0)
    return record(ok, "Gradle version", f"{version} ({'OK' if ok else 'need 8.0+'})")


def check_sdk_versions() -> bool:
    if not VERSIONS_TOML.exists():
        return record(False, "SDK versions (libs.versions.toml)", "File not found")
    content = VERSIONS_TOML.read_text(encoding="utf-8")

    def extract_sdk(key: str) -> Optional[int]:
        m = re.search(rf'{re.escape(key)}\s*=\s*"(\d+)"', content)
        return int(m.group(1)) if m else None

    min_sdk = extract_sdk("android-minSdk")
    target_sdk = extract_sdk("android-targetSdk")
    compile_sdk = extract_sdk("android-compileSdk")

    issues = []
    if min_sdk is None:
        issues.append("android-minSdk not found")
    if target_sdk is None:
        issues.append("android-targetSdk not found")
    elif target_sdk < 34:
        issues.append(f"android-targetSdk={target_sdk} (Google Play requires ≥34)")
    if compile_sdk is None:
        issues.append("android-compileSdk not found")
    elif compile_sdk < 34:
        issues.append(f"android-compileSdk={compile_sdk} (should be ≥34)")

    ok = len(issues) == 0
    msg = (
        f"minSdk={min_sdk}, targetSdk={target_sdk}, compileSdk={compile_sdk}"
        + (f" — Issues: {'; '.join(issues)}" if issues else " — OK")
    )
    return record(ok, "SDK versions", msg)


def check_signing_properties() -> bool:
    if not KEYS_PROPERTIES.exists():
        return record(
            False,
            "keys.properties present",
            f"{KEYS_PROPERTIES} not found — run scripts/setup_signing.py first",
        )
    content = KEYS_PROPERTIES.read_text(encoding="utf-8")
    required_keys = [
        "prodKeyStore",
        "prodKeyAlias",
        "prodKeyStorePassword",
        "prodKeyAliasPassword",
    ]
    missing = [k for k in required_keys if not re.search(rf"^{k}\s*=\s*.+", content, re.MULTILINE)]
    ok = len(missing) == 0
    msg = "All required keys present" if ok else f"Missing: {', '.join(missing)}"
    return record(ok, "keys.properties contents", msg)


def check_keystore_present() -> bool:
    ok = KEYSTORE_PATH.exists() and KEYSTORE_PATH.stat().st_size > 0
    msg = f"{KEYSTORE_PATH} ({'found' if ok else 'NOT found — run setup_signing.py'})"
    return record(ok, "keystore.jks present", msg)


def check_build_gradle_signing() -> bool:
    if not MBW_BUILD_GRADLE.exists():
        return record(False, "mbw/build.gradle signing", "File not found")
    content = MBW_BUILD_GRADLE.read_text(encoding="utf-8")
    checks = {
        "prodKeyStore property reference": r"prodKeyStore",
        "prodKeyAlias property reference": r"prodKeyAlias",
        "prodKeyStorePassword property reference": r"prodKeyStorePassword",
        "prodKeyAliasPassword property reference": r"prodKeyAliasPassword",
        "release signingConfig assigned": r"signingConfig signingConfigs\.release",
    }
    missing = [name for name, pattern in checks.items() if not re.search(pattern, content)]
    ok = len(missing) == 0
    msg = "Signing config wired correctly" if ok else f"Missing: {', '.join(missing)}"
    return record(ok, "build.gradle signing config", msg)


def check_no_hardcoded_secrets() -> bool:
    """Warn if any obvious hardcoded credentials appear in build files (not debug keystore)."""
    files_to_scan = [
        MBW_BUILD_GRADLE,
        REPO_ROOT / "build.gradle",
        REPO_ROOT / "gradle.properties",
    ]
    issues = []
    # Patterns that could indicate a hardcoded non-debug password
    secret_patterns = [
        (r'storePassword\s+["\'](?!android)[^"\']{6,}', "storePassword hardcoded"),
        (r'keyPassword\s+["\'](?!android)[^"\']{6,}', "keyPassword hardcoded"),
    ]
    for path in files_to_scan:
        if not path.exists():
            continue
        content = path.read_text(encoding="utf-8")
        for pattern, label in secret_patterns:
            if re.search(pattern, content):
                issues.append(f"{path.name}: {label}")
    ok = len(issues) == 0
    msg = "No obvious hardcoded secrets found" if ok else f"Possible secrets: {'; '.join(issues)}"
    return record(ok, "No hardcoded secrets", msg)


def check_manifest() -> bool:
    if not MANIFEST_PATH.exists():
        return record(False, "AndroidManifest.xml", "Not found")
    content = MANIFEST_PATH.read_text(encoding="utf-8")
    checks = {
        "INTERNET permission": r'android\.permission\.INTERNET',
        "application label": r'android:label=',
        "application icon": r'android:icon=',
        "application theme": r'android:theme=',
        "networkSecurityConfig": r'android:networkSecurityConfig=',
        "queries block (Android 11+)": r'<queries>',
        "launcher activity exported=true": r'android:exported="true"',
    }
    missing = [name for name, pattern in checks.items() if not re.search(pattern, content)]
    ok = len(missing) == 0
    msg = "All required manifest attributes found" if ok else f"Missing: {', '.join(missing)}"
    return record(ok, "AndroidManifest.xml", msg)


def check_codemagic_yaml() -> bool:
    path = REPO_ROOT / "codemagic.yaml"
    ok = path.exists() and path.stat().st_size > 100
    msg = f"{path} ({'found' if ok else 'NOT found'})"
    return record(ok, "codemagic.yaml present", msg)


def check_dry_run() -> bool:
    """Run ./gradlew :mbw:assembleProdnetRelease --dry-run as a quick sanity check."""
    print("\n[verify] Running Gradle dry-run (this may take ~30 s)…")
    rc, stdout, stderr = run_cmd(
        [str(GRADLEW), ":mbw:assembleProdnetRelease", "--dry-run", "--no-daemon"],
        timeout=180,
    )
    ok = rc == 0
    if not ok:
        snippet = (stdout + stderr)[-800:]
        return record(False, "Gradle dry-run", f"Exit {rc}. Last output:\n{snippet}")
    return record(True, "Gradle dry-run", "Exit 0 — task graph resolves correctly")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    print("=" * 60)
    print("  wallet-tethrus — Release Readiness Check")
    print("=" * 60)

    all_checks = [
        check_python_version,
        check_java_version,
        check_gradlew_executable,
        check_gradle_version,
        check_sdk_versions,
        check_codemagic_yaml,
        check_build_gradle_signing,
        check_signing_properties,
        check_keystore_present,
        check_no_hardcoded_secrets,
        check_manifest,
        check_dry_run,
    ]

    passed = 0
    failed = 0
    for check_fn in all_checks:
        try:
            ok = check_fn()
        except Exception as exc:  # noqa: BLE001
            ok = False
            results.append((FAIL, check_fn.__name__, f"Unexpected error: {exc}"))
        if ok:
            passed += 1
        else:
            failed += 1

    print("\n" + "=" * 60)
    print("  Results")
    print("=" * 60)
    for status, name, msg in results:
        detail = f" — {msg}" if msg else ""
        print(f"  {status}  {name}{detail}")

    print("=" * 60)
    total = passed + failed
    if failed == 0:
        print(f"  {PASS}  ALL {total} CHECKS PASSED — repository is release-ready.")
    else:
        print(f"  {FAIL}  {failed}/{total} CHECKS FAILED — fix the issues above before building.")
    print("=" * 60)

    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
