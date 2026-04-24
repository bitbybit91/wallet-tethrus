#!/usr/bin/env python3
"""
tethrus_builder.py — Tethrus Wallet Build Orchestrator
=======================================================
Automates pre-flight checks, Gradle invocation, APK verification and
SHA-256 hashing for the Tethrus Android wallet on Windows and Linux.

Usage examples
--------------
  python tethrus_builder.py --full
  python tethrus_builder.py --build prodnetDebug
  python tethrus_builder.py --release --verify-apks
  python tethrus_builder.py --install
  python tethrus_builder.py --config

Exit codes
----------
  0  All requested operations succeeded.
  1  One or more operations failed (details in tethrus_build.log).
"""

from __future__ import annotations

import argparse
import datetime
import hashlib
import logging
import os
import platform
import shutil
import subprocess
import sys
import time
from pathlib import Path
from typing import List, Optional, Tuple

# ---------------------------------------------------------------------------
# Bootstrap optional third-party dependencies
# ---------------------------------------------------------------------------

def _ensure_package(pkg: str, import_name: Optional[str] = None) -> bool:
    """Install *pkg* via pip if not already importable; return True on success."""
    name = import_name or pkg
    try:
        __import__(name)
        return True
    except ImportError:
        pass
    log.info("Auto-installing '%s' via pip …", pkg)
    result = subprocess.run(
        [sys.executable, "-m", "pip", "install", "--quiet", pkg],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        log.warning("Could not install '%s': %s", pkg, result.stderr.strip())
        return False
    return True


# ---------------------------------------------------------------------------
# Logging setup  (always to file; optionally colorised on console)
# ---------------------------------------------------------------------------

LOG_FILE = Path("tethrus_build.log")

logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s  %(levelname)-8s  %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    handlers=[logging.FileHandler(LOG_FILE, encoding="utf-8")],
)
log = logging.getLogger("tethrus")

# Console handler — will be enhanced with colorama if available
_console_handler = logging.StreamHandler(sys.stdout)
_console_handler.setLevel(logging.INFO)
_console_handler.setFormatter(
    logging.Formatter("%(asctime)s  %(levelname)-8s  %(message)s", datefmt="%H:%M:%S")
)
log.addHandler(_console_handler)


def _setup_color() -> None:
    """Optionally enable colorised console output via colorama."""
    if _ensure_package("colorama"):
        try:
            import colorama  # type: ignore
            colorama.init(autoreset=True)
            log.debug("colorama initialised")
        except Exception:
            pass


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

IS_WINDOWS = platform.system() == "Windows"
REPO_ROOT = Path(__file__).parent.resolve()

GRADLEW = "gradlew.bat" if IS_WINDOWS else "./gradlew"

# Map short flavour names to Gradle task suffixes
FLAVOR_TASKS = {
    "prodnetDebug":          "mbw:assembleProdnetDebug",
    "prodnetRelease":        "mbw:assembleProdnetRelease",
    "btctestnetDebug":       "mbw:assembleBtctestnetDebug",
    "btctestnetRelease":     "mbw:assembleBtctestnetRelease",
    "huaweiProdnetDebug":    "mbw:assembleHuaweiProdnetDebug",
    "huaweiProdnetRelease":  "mbw:assembleHuaweiProdnetRelease",
}

RELEASE_FLAVORS = {k for k in FLAVOR_TASKS if "Release" in k}

MIN_FREE_RAM_GB  = 1.5
MIN_FREE_DISK_GB = 10.0

APK_OUTPUT_DIR = REPO_ROOT / "mbw" / "build" / "outputs" / "apk"


# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------

def check_free_ram() -> Tuple[bool, float]:
    """Return (ok, free_gb)."""
    try:
        import psutil  # type: ignore
        free_gb = psutil.virtual_memory().available / (1024 ** 3)
        return free_gb >= MIN_FREE_RAM_GB, free_gb
    except Exception:
        # psutil unavailable — try platform-specific fallback
        if IS_WINDOWS:
            try:
                import ctypes
                class MEMSTATUS(ctypes.Structure):
                    _fields_ = [
                        ("dwLength", ctypes.c_ulong),
                        ("dwMemoryLoad", ctypes.c_ulong),
                        ("ullTotalPhys", ctypes.c_ulonglong),
                        ("ullAvailPhys", ctypes.c_ulonglong),
                        ("ullTotalPageFile", ctypes.c_ulonglong),
                        ("ullAvailPageFile", ctypes.c_ulonglong),
                        ("ullTotalVirtual", ctypes.c_ulonglong),
                        ("ullAvailVirtual", ctypes.c_ulonglong),
                        ("ullAvailExtendedVirtual", ctypes.c_ulonglong),
                    ]
                stat = MEMSTATUS()
                stat.dwLength = ctypes.sizeof(MEMSTATUS)
                ctypes.windll.kernel32.GlobalMemoryStatusEx(ctypes.byref(stat))  # type: ignore[attr-defined]
                free_gb = stat.ullAvailPhys / (1024 ** 3)
                return free_gb >= MIN_FREE_RAM_GB, free_gb
            except Exception:
                pass
        else:
            try:
                with open("/proc/meminfo") as fh:
                    for line in fh:
                        if line.startswith("MemAvailable:"):
                            kb = int(line.split()[1])
                            free_gb = kb / (1024 ** 2)
                            return free_gb >= MIN_FREE_RAM_GB, free_gb
            except Exception:
                pass
    return True, 0.0  # Unknown — optimistically allow


def check_jdk17() -> Tuple[bool, str]:
    """Return (ok, version_string)."""
    java = shutil.which("java")
    if not java:
        return False, "java not found on PATH"
    result = subprocess.run(
        ["java", "-version"], capture_output=True, text=True
    )
    output = (result.stdout + result.stderr).strip()
    first_line = output.splitlines()[0] if output else ""
    # Java 17+ prints e.g. 'openjdk version "17.0.x" ...' or 'java version "17" ...'
    # Java 11 prints '"11.0.x"', Java 8 prints '"1.8.x"'
    for token in first_line.split():
        stripped = token.strip('"')
        if stripped.startswith("17") or stripped.startswith("17."):
            return True, first_line
        if "." in stripped:
            major = stripped.split(".")[0]
            if major == "17":
                return True, first_line
    return False, first_line


def check_android_home() -> Tuple[bool, str]:
    """Return (ok, path_or_message)."""
    android_home = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if not android_home:
        return False, "ANDROID_HOME (or ANDROID_SDK_ROOT) is not set"
    p = Path(android_home)
    if not p.is_dir():
        return False, f"ANDROID_HOME={android_home} does not exist"
    return True, android_home


def check_disk_space() -> Tuple[bool, float]:
    """Return (ok, free_gb)."""
    try:
        stat = shutil.disk_usage(REPO_ROOT)
        free_gb = stat.free / (1024 ** 3)
        return free_gb >= MIN_FREE_DISK_GB, free_gb
    except Exception:
        return True, 0.0


def check_gradlew() -> bool:
    """Verify gradlew exists and is executable."""
    gw = REPO_ROOT / ("gradlew.bat" if IS_WINDOWS else "gradlew")
    return gw.exists()


def run_preflight(skip_ram: bool = False) -> bool:
    """Execute all pre-flight checks; return True only when all pass."""
    log.info("=== Pre-flight checks ===")
    ok = True

    # RAM
    if not skip_ram:
        ram_ok, free_gb = check_free_ram()
        _ensure_package("psutil")  # attempt install for subsequent calls
        ram_ok, free_gb = check_free_ram()
        if ram_ok:
            log.info("  RAM  : OK  (%.1f GB free)", free_gb)
        else:
            log.warning("  RAM  : WARN  (%.1f GB free; minimum is %.1f GB)", free_gb, MIN_FREE_RAM_GB)
            ok = False
    else:
        log.info("  RAM  : SKIP (--no-ram-check)")

    # JDK 17
    jdk_ok, jdk_ver = check_jdk17()
    if jdk_ok:
        log.info("  JDK  : OK  (%s)", jdk_ver.split('"')[1] if '"' in jdk_ver else jdk_ver)
    else:
        log.error("  JDK  : FAIL  (%s)", jdk_ver)
        ok = False

    # ANDROID_HOME
    ah_ok, ah_val = check_android_home()
    if ah_ok:
        log.info("  SDK  : OK  (%s)", ah_val)
    else:
        log.error("  SDK  : FAIL  (%s)", ah_val)
        ok = False

    # Disk
    disk_ok, free_gb = check_disk_space()
    if disk_ok:
        log.info("  Disk : OK  (%.1f GB free)", free_gb)
    else:
        log.warning("  Disk : WARN  (%.1f GB free; minimum is %.1f GB)", free_gb, MIN_FREE_DISK_GB)
        ok = False

    # gradlew
    if check_gradlew():
        log.info("  gradlew : OK")
    else:
        log.error("  gradlew : FAIL  (not found in %s)", REPO_ROOT)
        ok = False

    return ok


# ---------------------------------------------------------------------------
# Git submodules
# ---------------------------------------------------------------------------

def update_submodules() -> bool:
    """Run 'git submodule update --init --recursive'."""
    log.info("Updating git submodules …")
    result = subprocess.run(
        ["git", "submodule", "update", "--init", "--recursive"],
        cwd=REPO_ROOT,
        capture_output=False,
    )
    if result.returncode != 0:
        log.error("git submodule update failed (exit %d)", result.returncode)
        return False
    log.info("Submodules up-to-date.")
    return True


# ---------------------------------------------------------------------------
# Gradle invocation
# ---------------------------------------------------------------------------

def _gradle_cmd(tasks: List[str], extra_args: Optional[List[str]] = None) -> List[str]:
    base = [GRADLEW, "--no-daemon", "--max-workers=2"]
    if extra_args:
        base.extend(extra_args)
    base.extend(tasks)
    return base


def run_gradle(tasks: List[str], extra_args: Optional[List[str]] = None) -> bool:
    """Invoke Gradle with *tasks*; stream output; return True on success."""
    cmd = _gradle_cmd(tasks, extra_args)
    log.info("Running: %s", " ".join(cmd))
    start = time.monotonic()
    try:
        process = subprocess.Popen(
            cmd,
            cwd=REPO_ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            encoding="utf-8",
            errors="replace",
        )
        assert process.stdout is not None
        for line in process.stdout:
            stripped = line.rstrip()
            log.debug(stripped)
            print(stripped)
        process.wait()
        elapsed = time.monotonic() - start
        if process.returncode == 0:
            log.info("Gradle finished successfully in %.1f s", elapsed)
            return True
        else:
            log.error("Gradle exited with code %d after %.1f s", process.returncode, elapsed)
            return False
    except FileNotFoundError:
        log.error("Could not find '%s'. Are you in the repo root?", GRADLEW)
        return False


# ---------------------------------------------------------------------------
# APK utilities
# ---------------------------------------------------------------------------

def sha256_file(path: Path) -> str:
    """Return the SHA-256 hex digest of *path*."""
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def find_apks(root: Path = APK_OUTPUT_DIR) -> List[Path]:
    """Return sorted list of all .apk files under *root*."""
    if not root.is_dir():
        return []
    return sorted(root.rglob("*.apk"))


def hash_apks(apks: List[Path]) -> None:
    """Log SHA-256 digest for each APK."""
    log.info("=== APK SHA-256 hashes ===")
    for apk in apks:
        digest = sha256_file(apk)
        log.info("  %s  %s", digest, apk.name)
        print(f"  SHA-256  {digest}  {apk.name}")


def verify_apks_with_apksigner(apks: List[Path]) -> bool:
    """Run 'apksigner verify --print-certs' on release APKs; return True when all pass."""
    apksigner = shutil.which("apksigner")
    if not apksigner:
        log.warning("apksigner not found on PATH — skipping APK signature verification")
        return True

    all_ok = True
    for apk in apks:
        if "release" not in apk.name.lower():
            continue
        log.info("Verifying signature: %s", apk.name)
        result = subprocess.run(
            [apksigner, "verify", "--print-certs", "--verbose", str(apk)],
            capture_output=True,
            text=True,
        )
        log.debug(result.stdout)
        if result.returncode != 0:
            log.error("apksigner FAILED for %s:\n%s", apk.name, result.stderr)
            all_ok = False
        else:
            log.info("  → Signature OK")
    return all_ok


# ---------------------------------------------------------------------------
# High-level commands
# ---------------------------------------------------------------------------

def cmd_install() -> bool:
    """Install / update required Python packages."""
    log.info("=== Installing Python dependencies ===")
    packages = {"psutil": "psutil", "colorama": "colorama"}
    ok = True
    for pkg, imp in packages.items():
        if _ensure_package(pkg, imp):
            log.info("  %s : OK", pkg)
        else:
            log.error("  %s : FAILED", pkg)
            ok = False
    return ok


def cmd_config() -> bool:
    """Print current configuration / environment summary."""
    log.info("=== Configuration summary ===")
    print(f"  Platform        : {platform.system()} {platform.release()}")
    print(f"  Python          : {sys.version.split()[0]}")
    print(f"  Repo root       : {REPO_ROOT}")
    print(f"  Log file        : {LOG_FILE.resolve()}")
    print(f"  Gradle wrapper  : {GRADLEW}")

    _, jdk_ver = check_jdk17()
    print(f"  JDK             : {jdk_ver}")

    _, ah = check_android_home()
    print(f"  ANDROID_HOME    : {ah}")

    _, free_gb = check_free_ram()
    print(f"  Free RAM        : {free_gb:.1f} GB")

    _, disk_gb = check_disk_space()
    print(f"  Free Disk       : {disk_gb:.1f} GB")

    return True


def cmd_build(flavor: str) -> bool:
    """Build a specific flavour."""
    if flavor not in FLAVOR_TASKS:
        log.error("Unknown flavor '%s'. Valid options: %s", flavor, list(FLAVOR_TASKS))
        return False

    task = FLAVOR_TASKS[flavor]
    log.info("=== Building %s (%s) ===", flavor, task)

    if not run_preflight():
        log.error("Pre-flight checks failed — aborting build")
        return False

    if not update_submodules():
        return False

    success = run_gradle(["clean", task])
    if success:
        apks = find_apks()
        if apks:
            hash_apks(apks)
    return success


def cmd_release() -> bool:
    """Build all release flavours sequentially."""
    log.info("=== Building ALL release flavours ===")
    if not run_preflight():
        log.error("Pre-flight checks failed — aborting")
        return False

    if not update_submodules():
        return False

    release_tasks = [FLAVOR_TASKS[f] for f in sorted(RELEASE_FLAVORS)]
    log.info("Tasks: %s", release_tasks)

    all_tasks = ["clean"] + release_tasks
    success = run_gradle(all_tasks)
    if success:
        apks = find_apks()
        hash_apks(apks)
    return success


def cmd_verify_apks() -> bool:
    """Hash and (optionally) signature-verify all APKs found in the output directory."""
    log.info("=== Verifying APKs ===")
    apks = find_apks()
    if not apks:
        log.warning("No APKs found under %s", APK_OUTPUT_DIR)
        return True
    hash_apks(apks)
    return verify_apks_with_apksigner(apks)


def cmd_full() -> bool:
    """Run everything: install deps, checks, all debug builds, hashing."""
    log.info("=== FULL build sequence ===")

    _ensure_package("psutil")
    _ensure_package("colorama")
    _setup_color()

    if not run_preflight():
        log.error("Pre-flight checks failed — aborting")
        return False

    if not update_submodules():
        return False

    debug_tasks = [
        FLAVOR_TASKS["prodnetDebug"],
        FLAVOR_TASKS["btctestnetDebug"],
        FLAVOR_TASKS["huaweiProdnetDebug"],
    ]
    all_tasks = ["clean"] + debug_tasks
    success = run_gradle(all_tasks)

    if success:
        apks = find_apks()
        if apks:
            hash_apks(apks)
            verify_apks_with_apksigner(apks)
    return success


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="tethrus_builder.py",
        description="Tethrus Wallet Build Orchestrator",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "--install",
        action="store_true",
        help="Install required Python packages (psutil, colorama)",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable DEBUG-level console logging",
    )
    parser.add_argument(
        "--config",
        action="store_true",
        help="Print environment / configuration summary and exit",
    )
    parser.add_argument(
        "--build",
        metavar="FLAVOR",
        help=(
            "Build a specific flavor: "
            + ", ".join(sorted(FLAVOR_TASKS))
        ),
    )
    parser.add_argument(
        "--release",
        action="store_true",
        help="Build all release flavors sequentially",
    )
    parser.add_argument(
        "--verify-apks",
        action="store_true",
        dest="verify_apks",
        help="Hash and signature-verify produced APKs",
    )
    parser.add_argument(
        "--full",
        action="store_true",
        help=(
            "Run the complete pipeline: deps → checks → submodules → "
            "all debug builds → APK hashing"
        ),
    )
    parser.add_argument(
        "--no-ram-check",
        action="store_true",
        dest="no_ram_check",
        help="Skip free-RAM pre-flight check",
    )
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    # Adjust console log level
    if args.debug:
        _console_handler.setLevel(logging.DEBUG)

    _setup_color()

    log.info(
        "tethrus_builder.py started at %s",
        datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    )
    log.debug("Arguments: %s", vars(args))

    results: List[Tuple[str, bool]] = []

    # ---- --install ----
    if args.install:
        results.append(("install", cmd_install()))

    # ---- --config ----
    if args.config:
        results.append(("config", cmd_config()))

    # ---- --build FLAVOR ----
    if args.build:
        results.append(("build:" + args.build, cmd_build(args.build)))

    # ---- --release ----
    if args.release:
        results.append(("release", cmd_release()))

    # ---- --verify-apks ----
    if args.verify_apks and not args.full:
        results.append(("verify-apks", cmd_verify_apks()))

    # ---- --full ----
    if args.full:
        results.append(("full", cmd_full()))

    # ---- No action ----
    if not results:
        parser.print_help()
        return 0

    # ---- Summary ----
    log.info("=== Build summary ===")
    all_ok = True
    for name, ok in results:
        status = "OK   " if ok else "FAIL "
        log.info("  %s  %s", status, name)
        if not ok:
            all_ok = False

    if all_ok:
        log.info("All operations completed successfully.")
        return 0
    else:
        log.error("One or more operations FAILED. See %s for details.", LOG_FILE)
        return 1


if __name__ == "__main__":
    sys.exit(main())
