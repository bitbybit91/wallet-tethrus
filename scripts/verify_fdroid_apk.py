#!/usr/bin/env python3
"""
verify_fdroid_apk.py — Verify that an F-Droid APK contains no proprietary blobs.

Usage:
    python3 scripts/verify_fdroid_apk.py <path-to-apk>

Checks performed:
  1. APK exists and is a valid ZIP.
  2. No Google Play Services classes (com/google/android/gms/).
  3. No Firebase classes (com/google/firebase/).
  4. No Crashlytics classes (com/crashlytics/).
  5. No AdMob classes (com/google/android/gms/ads/).
  6. google-services.json is NOT bundled in the APK.

Exit codes:
  0 — all checks passed
  1 — one or more checks failed
"""

import sys
import zipfile
from pathlib import Path


PROPRIETARY_PREFIXES = [
    "com/google/android/gms/",        # Google Play Services
    "com/google/firebase/",            # Firebase
    "com/crashlytics/",                # Crashlytics (legacy)
    "io/fabric/",                      # Fabric (Crashlytics parent)
    "com/google/android/gms/ads/",     # AdMob
]

BANNED_ASSETS = [
    "google-services.json",
]


def check_apk(apk_path: Path) -> bool:
    """Return True if APK passes all F-Droid checks, False otherwise."""
    if not apk_path.exists():
        print(f"[FAIL] APK not found: {apk_path}", file=sys.stderr)
        return False

    failures: list[str] = []

    try:
        with zipfile.ZipFile(apk_path, "r") as zf:
            all_names = zf.namelist()
            dex_entries = [n for n in all_names if n.endswith(".dex")]
            dex_data: dict[str, bytes] = {d: zf.read(d) for d in dex_entries}
    except zipfile.BadZipFile as exc:
        print(f"[FAIL] Not a valid ZIP/APK: {exc}", file=sys.stderr)
        return False

    # Check for proprietary class prefixes in dex files
    # We check the raw bytes of each dex for string markers.
    for dex, dex_bytes in dex_data.items():
        for prefix in PROPRIETARY_PREFIXES:
            marker = prefix.encode("utf-8")
            if marker in dex_bytes:
                failures.append(
                    f"Proprietary class prefix '{prefix}' found in {dex}"
                )

    # Check for banned asset files
    for banned in BANNED_ASSETS:
        for entry in all_names:
            if entry.endswith(banned):
                failures.append(f"Banned asset '{banned}' bundled in APK: {entry}")

    # Report
    print(f"\n=== F-Droid APK Verification: {apk_path.name} ===\n")
    if failures:
        for f in failures:
            print(f"  [FAIL] {f}", file=sys.stderr)
        print(
            f"\n[FAILED] {len(failures)} issue(s) found. "
            f"This APK is NOT suitable for F-Droid.\n",
            file=sys.stderr,
        )
        return False
    else:
        print("  [PASS] No proprietary class prefixes found in dex.")
        print("  [PASS] No banned assets bundled.")
        print(f"\n[OK] APK appears clean for F-Droid distribution.\n")
        return True


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python3 scripts/verify_fdroid_apk.py <path-to-apk>", file=sys.stderr)
        sys.exit(1)

    apk_path = Path(sys.argv[1])
    success = check_apk(apk_path)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
