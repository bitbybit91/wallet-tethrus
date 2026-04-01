# Mycelium Bitcoin Wallet

A multi-currency, modular Android HD wallet supporting Bitcoin, Ethereum, FIO Protocol, Bitcoin Vault, and hardware wallets (Trezor, Ledger). Built with deterministic-build verification, Tor privacy, and BIP32/39/44 compliance.

**Version:** `3.21.0.0` (versionCode `3210000`)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Building](#building)
- [Running](#running)
- [Testing](#testing)
- [Deployment](#deployment)
- [Deterministic Builds](#deterministic-builds)
- [App Download Verification](#app-download-verification)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Authors](#authors)
- [Credits](#credits)
- [License](#license)

---

## Overview

Mycelium Bitcoin Wallet is a multi-module Android application that enables users to send and receive Bitcoin and other cryptocurrencies from their mobile phone. It features HD key management (BIP32/BIP44), masterseed backups (BIP39), hardware wallet integration (Trezor, Ledger), and exchange/trading services (Simplex, Safello, LocalTrader). The wallet connects to Mycelium's Electrum-based super-nodes and supports Tor for enhanced privacy.

The project is built with Gradle using a version catalog (`libs.versions.toml`) and produces deterministic builds via Docker/Podman with `disorderfs` to ensure binary reproducibility.

---

## Features

- **HD wallets** — manage multiple accounts, never reuse addresses ([BIP32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)/[BIP44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki))
- **Masterseed backup** — one backup, safe forever ([BIP39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki))
- **100% key control** — private keys never leave your device unless you export them
- **No blockchain download** — install and run in seconds
- **Tor integration** — connect to super-nodes via `.onion` addresses (Orchid/Netcipher)
- **Hardware wallets** — Trezor and Ledger Nano S/X (btchip) support
- **Cold storage** — watch-only addresses (xPub) and private key import (xPriv)
- **Paper wallet import** — spend from single key, xPriv, or master seed
- **Multi-currency** — Bitcoin, Ethereum, Bitcoin Vault, FIO Protocol, ERC-20 tokens
- **PIN & biometric security** — fingerprint authentication support
- **QR code scanner** — integrated ZXing-based scanning
- **Shamir Secret Sharing** — 2-out-of-3 key spending (Mycelium Entropy compatible)
- **Exchange integrations** — Simplex, Safello, Bits of Gold, Bequant
- **LocalTrader** — built-in peer-to-peer trading
- **Multiple fiat currencies** — USD, EUR, GBP, JPY, CNY, and many more
- **Multiple BTC denominations** — BTC, mBTC, bits, uBTC
- **`bitcoin:` URI scheme** — compatible with other Bitcoin services
- **BitID authentication** — `bitid://` protocol support
- **BIP 121 Proof of Payment** — `btcpop://` protocol support
- **Deterministic builds** — reproducible APKs verified in CI
- **Message signing** — sign messages with private keys (bitcoin-qt compatible)

---

## Prerequisites

### Required Tools

| Tool | Version | Notes |
|------|---------|-------|
| **JDK** | 17 | Zulu distribution recommended (CI uses `zulu` via `actions/setup-java`) |
| **Gradle** | 8.13 | Bundled via Gradle Wrapper (`gradlew`) — no manual install needed |
| **Android SDK** | API 36 (compile/target), API 24 (min) | Install via Android Studio or `sdkmanager` |
| **Android Build Tools** | 34.0.0 | Used in Docker builds |
| **Android NDK** | 21.1.6352462 | Required for native code |
| **CMake** | 3.22.1 | Required for NDK builds |
| **Android Studio** | Latest stable | Recommended IDE |
| **Git** | 2.x+ | With submodule support |

### Android SDK Components

Install the following via `sdkmanager` or Android Studio SDK Manager:

```bash
sdkmanager "platform-tools"
sdkmanager "platforms;android-36"
sdkmanager "build-tools;34.0.0"
sdkmanager "ndk;21.1.6352462"
sdkmanager "cmake;3.22.1"
```

### Gradle JVM Configuration (from `gradle.properties`)

```properties
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1024m
kotlin.daemon.jvmargs=-Xmx4g
```

> **Note:** A minimum of 4 GB heap memory is required for the Gradle daemon.

### Version Catalog Summary (from `gradle/libs.versions.toml`)

| Dependency | Version |
|------------|---------|
| Android Gradle Plugin | `8.12.1` |
| Kotlin | `2.0.21` |
| Compile SDK | `36` |
| Min SDK | `24` |
| Target SDK | `36` |
| Firebase BOM | `33.10.0` |
| SQLDelight | `2.0.2` |
| Retrofit | `2.6.1` |
| Web3j | `4.12.3` |
| BouncyCastle | `1.79` |
| Jackson | `2.9.6` |
| Guava | `32.1.3-android` |
| Protobuf | `3.6.1` |
| Glide | `5.0.0-rc01` |
| AndroidX Lifecycle | `2.8.7` |
| AndroidX Navigation | `2.8.8` |
| Espresso | `3.6.1` |
| MockK | `1.13.3` |
| JUnit | `4.13.2` |
| KSP | `2.0.21-1.0.28` |
| Dokka | `2.0.0` |
| Google Services | `4.4.2` |
| Kotlinx Coroutines | `1.10.1` |
| Play Services Base | `18.7.0` |

---

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/mycelium-com/wallet-android.git
cd wallet-android
```

### 2. Initialize Git Submodules

The project depends on two Git submodules defined in `.gitmodules`:

| Submodule | Path | Repository |
|-----------|------|------------|
| wallet-android-modularization-tools | `wallet-android-modularization-tools/` | `https://github.com/mycelium-com/wallet-android-modularization-tools` |
| fiosdk_kotlin | `fiosdk_kotlin/` | `https://github.com/mycelium-com/fiosdk_kotlin` |

```bash
git submodule update --init --recursive
```

### 3. Install Dependencies

No manual dependency installation is needed — Gradle handles all dependencies automatically on first build. If you want to pre-download:

```bash
# macOS/Linux
./gradlew dependencies

# Windows
gradlew.bat dependencies
```

---

## Configuration

### Environment Variables

| Variable | Used In | Description |
|----------|---------|-------------|
| `MYCELIUM_BUILD_SYSTEM` | `settings.gradle` | Set to `server` to exclude Android-dependent modules (for server-side builds). When unset, all modules including `mbw`, `trezor`, `btchip`, etc. are included. |
| `ANDROID_HOME` | Build system | Path to Android SDK (set automatically by Android Studio or `setup-android` action) |
| `CROWDIN_API_KEY` | `crowdin.yml` | API key for Crowdin translation management |

### Signing Configuration

Release signing is configured via a `keys.properties` file in the project root (**git-ignored**):

```properties
# keys.properties (create this file for release builds)
prodKeyStore=keystore_mbwProd
prodKeyAlias=your_alias
prodKeyStorePassword=your_password
prodKeyAliasPassword=your_password

testKeyStore=keystore_mbwTest
testKeyAlias=your_alias
testKeyStorePassword=your_password
testKeyAliasPassword=your_password
```

Place your keystore files (`keystore_mbwProd`, `keystore_mbwTest`) in the project root directory.

> **Debug builds** use the committed `debug.keystore` (password: `android`, alias: `androiddebugkey`).

If release keys are not provided, the build falls back to the debug keystore. To enforce release signing and fail on missing keys, add:

```bash
./gradlew mbw:assembleProdnetRelease -PenforceReleaseSigning
```

### Product Flavors

| Flavor | Application ID | Network | Description |
|--------|---------------|---------|-------------|
| `prodnet` | `com.mycelium.wallet` | Bitcoin mainnet | Production release for Google Play |
| `btctestnet` | `com.mycelium.testnetwallet` | Bitcoin testnet | Testnet build (version name suffixed `-TESTNET`) |
| `huaweiProdnet` | `com.mycelium.wallet.app` | Bitcoin mainnet | Production release for Huawei App Gallery |

> Debug builds append `.debug` to the application ID (e.g., `com.mycelium.wallet.debug`).

---

## Building

### Quick Start

```bash
# macOS/Linux
./gradlew clean test mbw:assembleProdnetDebug mbw:assembleBtctestnetDebug

# Windows
gradlew.bat clean test mbw:assembleProdnetDebug mbw:assembleBtctestnetDebug
```

### All Build Variants

#### Debug Builds

```bash
# macOS/Linux
./gradlew mbw:assembleProdnetDebug
./gradlew mbw:assembleBtctestnetDebug

# Windows
gradlew.bat mbw:assembleProdnetDebug
gradlew.bat mbw:assembleBtctestnetDebug
```

#### Release Builds

```bash
# macOS/Linux (requires keys.properties + keystores)
./gradlew mbw:assembleProdnetRelease
./gradlew mbw:assembleBtctestnetRelease
./gradlew mbw:assembleHuaweiProdnetRelease

# Windows
gradlew.bat mbw:assembleProdnetRelease
gradlew.bat mbw:assembleBtctestnetRelease
gradlew.bat mbw:assembleHuaweiProdnetRelease
```

#### Build All Variants at Once

```bash
# macOS/Linux
./gradlew mbw:assembleDebug          # All debug flavors
./gradlew mbw:assembleRelease        # All release flavors (requires signing keys)

# Windows
gradlew.bat mbw:assembleDebug
gradlew.bat mbw:assembleRelease
```

#### Full CI Build (tests + debug APKs)

```bash
./gradlew --no-daemon --build-cache --parallel --configure-on-demand clean test mbw:assembleProdnetDebug mbw:assembleBtctestnetDebug
```

#### Full RC Build (tests + all APKs)

```bash
./gradlew --no-daemon --parallel --configure-on-demand clean test mbw:assembleProdnetDebug mbw:assembleBtctestnetDebug mbw:assembleProdnetRelease mbw:assembleBtctestnetRelease mbw:assembleHuaweiProdnetRelease
```

### APK Output Locations

| Variant | Path |
|---------|------|
| Prodnet Debug | `mbw/build/outputs/apk/prodnet/debug/mbw-prodnet-debug.apk` |
| Prodnet Release | `mbw/build/outputs/apk/prodnet/release/mbw-prodnet-release.apk` |
| Btctestnet Debug | `mbw/build/outputs/apk/btctestnet/debug/mbw-btctestnet-debug.apk` |
| Btctestnet Release | `mbw/build/outputs/apk/btctestnet/release/mbw-btctestnet-release.apk` |
| Huawei Prodnet Release | `mbw/build/outputs/apk/huaweiProdnet/release/mbw-huaweiProdnet-release.apk` |

### Utility Tasks

```bash
# Generate a fat JAR from walletcore (includes all dependencies)
./gradlew walletcore:fatJar

# Run the wallet console application
./gradlew wallet-console:run

# Run the backup utility
./gradlew backuputil:run

# Lint check (with baseline)
./gradlew mbw:lint

# Collect APKs into a release zip
./collectApks.sh
```

---

## Running

### Android Studio

1. Open the project root directory in Android Studio.
2. Wait for Gradle sync to complete.
3. Select a build variant from **Build → Select Build Variant**:
   - `prodnetDebug` — mainnet debug build
   - `btctestnetDebug` — testnet debug build
4. Click **Run** (▶) to deploy to a connected device or emulator.

### Command Line

```bash
# Build and install on connected device (prodnet debug)
./gradlew mbw:installProdnetDebug

# Build and install on connected device (btctestnet debug)
./gradlew mbw:installBtctestnetDebug
```

### Wallet Console (CLI)

The `wallet-console` module provides a command-line interface:

```bash
./gradlew wallet-console:run
```

Main class: `com.mycelium.WalletConsole`

---

## Testing

### Unit Tests

```bash
# Run all unit tests across all modules
./gradlew test

# Run tests for specific modules
./gradlew mbw:testProdnetDebugUnitTest
./gradlew mbw:testBtctestnetDebugUnitTest
./gradlew walletcore:test
./gradlew bitlib:test
./gradlew wapi:test
./gradlew lt-api:test
./gradlew mbwlib:test
```

Test configuration (from `mbw/build.gradle`):

```groovy
testOptions {
    unitTests.returnDefaultValues = true
}
```

### Android Instrumentation Tests

```bash
# Requires a connected device or emulator
./gradlew mbw:connectedProdnetDebugAndroidTest
./gradlew mbw:connectedBtctestnetDebugAndroidTest
```

Test runner: `androidx.test.runner.AndroidJUnitRunner`

### Integration Tests

```bash
# Run all integration tests (walletcore + wallet-console)
./gradlew allIntegrationTests

# Run integration tests for specific modules
./gradlew integrationTestWalletCore
./gradlew integrationTestWalletConsole
```

### Test Dependencies

| Library | Version | Scope |
|---------|---------|-------|
| JUnit | `4.13.2` | Unit tests |
| Mockito | `2.23.0` | Unit tests |
| MockK | `1.13.3` | Unit + Android tests |
| Espresso | `3.6.1` | Android instrumentation |
| AndroidX Test Core | `1.6.1` | Android instrumentation |
| AndroidX Test Runner | `1.6.1` | Android instrumentation |
| Kotlinx Coroutines Test | `1.10.1` | Coroutine testing |

---

## Deployment

### CI/CD Pipelines

#### GitHub Actions — Pull Request CI (`.github/workflows/ci.yml`)

**Trigger:** Pull requests on all branches
**Runner:** `ubuntu-latest`

Steps:
1. Set up JDK 17 (Zulu distribution)
2. Checkout with recursive submodules
3. Set up Android SDK and Gradle
4. Build + test: `./gradlew clean test mbw:assembleProdnetDebug mbw:assembleBtctestnetDebug`
5. Upload APK and native debug symbol artifacts
6. Verify target SDK equals `36`
7. Deterministic build verification (rebuild and diff)

Skip CI by including `#skip-ci` in the commit message.

#### GitHub Actions — Release Candidate (`.github/workflows/rc.yml`)

**Trigger:** Push to `master` or `ci-build-rc` branches
**Runner:** `mbw-builder` (self-hosted)

Steps:
1. Checkout with recursive submodules
2. Build Docker image from `Dockerfile`
3. Run deterministic build inside container with `disorderfs`:
   ```
   ./gradlew clean test mbw:assembleProdnetDebug mbw:assembleBtctestnetDebug \
     mbw:assembleProdnetRelease mbw:assembleBtctestnetRelease \
     mbw:assembleHuaweiProdnetRelease
   ```
4. Upload all build outputs

#### GitLab CI (`.gitlab-ci.yml`)

**Tags:** `4GB_RAM`
**Artifacts:** expire in 4 weeks

```bash
# Master branch
./gradlew clean test lint build -Pbranch=$CI_BUILD_REF_NAME

# Feature branches (skip ProGuard)
./gradlew clean test lint build -PskipProguard -Pbranch=$CI_BUILD_REF_NAME
```

### Docker Build Environment

The `Dockerfile` provides a reproducible build environment:

```dockerfile
FROM ubuntu:18.04
# JDK 17, Android SDK 11076708, Build Tools 34.0.0
# NDK 21.1.6352462, CMake 3.22.1, Platform android-34
```

Build the image:

```bash
# Using Docker
docker build --no-cache --tag mycelium_builder .

# Using Podman
podman build --no-cache --tag mycelium_builder .
```

### Collecting Release APKs

```bash
./collectApks.sh
```

Creates a timestamped folder in `/tmp/release_mbw/` with all APKs packaged into a zip file named `release_mbw_<versionName>.zip`.

---

## Deterministic Builds

To validate the APK you obtain from a distribution channel, you can rebuild the wallet yourself and compare both images:

### 1. Build the Docker Image

```bash
podman build --no-cache --tag mycelium_builder .
```

### 2. Run the Deterministic Build

```bash
podman run --rm --interactive --tty \
    --device /dev/fuse \
    --cap-add SYS_ADMIN \
    --volume .:/app \
    mycelium_builder \
    bash -c "apt update;
    apt install -y disorderfs;
    mkdir /project/;
    disorderfs --sort-dirents=yes --reverse-dirents=no /app/ /project/;
    cd /project/;
    ./gradlew -x lint -x test clean :mbw:assembleProdnetRelease;"
```

> If you see errors about local paths not being found, remove or move `local.properties`.

Output: `mbw/build/outputs/apk/prodnet/release/mbw-prodnet-release.apk`

### 3. Build with Release Keys (Maintainers)

```bash
podman run --rm --interactive --tty \
    --device /dev/fuse \
    --cap-add SYS_ADMIN \
    --volume .:/app \
    --volume 'path/to/keys.properties':/project/keys.properties \
    --volume 'path/to/keystore_mbwProd':/project/keystore_mbwProd \
    --volume 'path/to/keystore_mbwTest':/project/keystore_mbwTest \
    mycelium_builder \
    bash -c "apt update;
    apt install -y disorderfs;
    mkdir /project/;
    disorderfs --sort-dirents=yes --reverse-dirents=no /app/ /project/;
    cd /project/;
    ./gradlew -x lint -x test clean \
        :mbw:assembleBtctestnetRelease \
        :mbw:assembleProdnetRelease \
        :mbw:assembleBtctestnetDebug \
        :mbw:assembleProdnetDebug \
        -PenforceReleaseSigning;"
```

### 4. Compare APKs

Retrieve the APK from your device:

```bash
adb shell pm path com.mycelium.wallet
# package:/data/app/com.mycelium.wallet-1/base.apk

adb pull /data/app/com.mycelium.wallet-1/base.apk mycelium-signed.apk
```

Extract and compare using [ApkTool](https://ibotpeaches.github.io/Apktool/):

```bash
java -jar apktool.jar d mbw-prodnet-release.apk
java -jar apktool.jar d mycelium-signed.apk

diff --brief --recursive mbw-prodnet-release/ mycelium-signed/ \
    | grep -v "META-INF/CERT.RSA\|META-INF/CERT.SF\|META-INF/MANIFEST.MF"
```

Or use the included script:

```bash
./checkBuild.sh <apk-file> <git-revision> [retries]
```

Expected differences are limited to signature files: `META-INF/CERT.RSA`, `META-INF/CERT.SF`, `META-INF/MANIFEST.MF`.

---

## App Download Verification

All releases are signed with the same release keys. Verify with [apksigner](https://developer.android.com/studio/command-line/apksigner.html#options-verify):

```bash
apksigner verify --print-certs --verbose mycelium.apk
```

Expected output:

```
Verifies
Verified using v1 scheme (JAR signing): true
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): false
Number of signers: 1
Signer #1 certificate DN: CN=Mycelium Developers, O=Mycelium, L=Vienna, C=AT
Signer #1 certificate SHA-256 digest: b8e59d4a60b65290efb2716319e50b94e298d7a72c76c2119eb7d8d3afac302e
Signer #1 certificate SHA-1 digest: be575ec3b3b52e0b2392146cbdb245c91ef5a04f
Signer #1 certificate MD5 digest: 7aec063675b0206aba3b6175b89abc7d
Signer #1 key algorithm: RSA
Signer #1 key size (bits): 2048
Signer #1 public key SHA-256 digest: 6d9c0cda9dcd3ec5efcdca41243829b1dcf1e9a91c6309bca167807282590a20
Signer #1 public key SHA-1 digest: b34336038c7ca678285c14aebe78b7d5add90e4c
Signer #1 public key MD5 digest: a78bdb2b6d074db4b1ff12eb9cddcfa3
WARNING: ...
```

---

## Project Structure

```
wallet-android/
├── mbw/                          Main Android application module
├── mbwlib/                       Core library (networking, crypto primitives)
├── walletcore/                   Wallet core logic (accounts, transactions, modules)
├── walletmodel/                  Wallet data model interfaces
├── bitlib/                       Bitcoin library (keys, addresses, transactions)
├── wapi/                         WAPI — wallet API client
├── lt-api/                       LocalTrader API client
├── view/                         Shared Android UI components
├── btchip/                       Ledger Nano hardware wallet integration
├── trezor/                       Trezor hardware wallet integration
├── LVL/                          Google Play License Verification Library
├── testhelper/                   Testing utilities
├── backuputil/                   Backup utility (CLI application)
├── wallet-console/               Console wallet application (CLI)
├── libs/
│   ├── nordpol/                  NFC communication library
│   └── netcipher-2.2.1.jar       Tor/Orbot proxy library
├── fiosdk_kotlin/                FIO Protocol SDK (Git submodule)
├── wallet-android-modularization-tools/  Build tooling (Git submodule)
├── docs/
│   └── multi-currency.md         Multi-currency architecture documentation
├── gradle/
│   ├── libs.versions.toml        Gradle version catalog
│   └── wrapper/                  Gradle Wrapper files (v8.13)
├── build.gradle                  Root Gradle build script
├── settings.gradle               Module inclusion and repository configuration
├── ext_settings.gradle           Shared version variables
├── tools.gradle                  Git commit hash, branch detection, signing enforcement
├── integration-test.gradle       Integration test task aggregator
├── Dockerfile                    Deterministic build environment (Ubuntu 18.04 + JDK 17)
├── debug.keystore                Debug signing keystore
├── checkBuild.sh                 Deterministic build verification script
├── collectApks.sh                APK collection and packaging script
├── apkdiff.py                    APK diff comparison tool (Python)
├── crowdin.yml                   Crowdin translation configuration
├── .github/workflows/
│   ├── ci.yml                    PR build + deterministic verification
│   └── rc.yml                    Release candidate build (Docker)
└── .gitlab-ci.yml                GitLab CI build configuration
```

### Module Details

| Module | Type | Plugin(s) | Description |
|--------|------|-----------|-------------|
| `mbw` | Android Application | `android.application`, `kotlin.android`, `ksp`, `navigation`, `google-services`, `sqldelight` | Main wallet app with 3 product flavors, SQLDelight databases (GiftboxDB, LoggerDB, RatesDB), Firebase integration |
| `walletcore` | Java/Kotlin Library | `kotlin.jvm`, `sqldelight` | Core wallet logic, account management, transaction creation; SQLDelight database (WalletDB); includes `fatJar` task |
| `walletmodel` | Java/Kotlin Library | `kotlin.jvm` | Data model interfaces for wallet accounts and transactions |
| `bitlib` | Java/Kotlin Library | `java`, `kotlin.jvm` | Bitcoin primitives — keys, addresses, script, transaction parsing |
| `wapi` | Java/Kotlin Library | `java`, `kotlin` | WAPI client for Mycelium backend services |
| `lt-api` | Java Library | `java` | LocalTrader peer-to-peer trading API |
| `mbwlib` | Java Library | `java` | Core networking, crypto, and protocol buffer support |
| `view` | Android Library | `android.library`, `kotlin.android` | Shared Android UI components (RecyclerView, AppCompat) |
| `btchip` | Android Library | `android.library`, `kotlin.android` | Ledger Nano S/X integration via NFC (AIDL) |
| `trezor` | Android Library | `android.library`, `kotlin.android` | Trezor hardware wallet integration (Protobuf) |
| `LVL` | Android Library | `android.library` | Google Play License Verification (namespace: `com.google.android.vending.licensing`) |
| `wallet-console` | Java/Kotlin Application | `java`, `kotlin`, `application` | CLI wallet (main class: `com.mycelium.WalletConsole`) |
| `backuputil` | Java Application | `java`, `application` | CLI backup utility (main class: `com.mrd.bitlib.BackupUtil`) |
| `testhelper` | Java/Kotlin Library | `java`, `kotlin` | Shared test utilities |

### Conditional Module Inclusion

In `settings.gradle`, modules are conditionally included based on the `MYCELIUM_BUILD_SYSTEM` environment variable:

```groovy
// Always included
include ':testhelper', ':view', 'bitlib', 'lt-api', 'walletmodel', 'walletcore', 'wapi', 'mbwlib'

// Only included when NOT building on server (MYCELIUM_BUILD_SYSTEM != 'server')
include 'mbw', 'trezor', 'libs:nordpol', 'btchip', 'LVL', 'wallet-console'
include ':androidfioserializationprovider', ':fiosdk'
```

---

## Troubleshooting

### Build Fails with "Could not find keys.properties"

The `keys.properties` file is optional for debug builds. If you see a warning, it is safe to ignore for debug builds. For release builds, create `keys.properties` in the project root (see [Configuration](#configuration)).

### `local.properties` Errors in Docker/Podman

Remove or rename `local.properties` before running container builds — it contains host-specific Android SDK paths:

```bash
rm -f local.properties
```

### Out of Memory During Build

Ensure your Gradle JVM has enough memory. The project requires at least 4 GB:

```properties
# gradle.properties
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1024m
kotlin.daemon.jvmargs=-Xmx4g
```

### Submodule Not Initialized

If you see missing classes from `fiosdk` or `wallet-android-modularization-tools`:

```bash
git submodule update --init --recursive
```

### Android SDK Not Found

Set `ANDROID_HOME` or create `local.properties`:

```properties
# local.properties
sdk.dir=/path/to/your/android/sdk
```

### NDK Version Mismatch

The project requires NDK `21.1.6352462`. Install it via:

```bash
sdkmanager "ndk;21.1.6352462"
```

### File Ownership After Docker Build

Container-generated files may have different ownership. Fix with:

```bash
sudo chown -R $(whoami):$(whoami) .
```

### Gradle Wrapper Permission Denied (macOS/Linux)

```bash
chmod +x gradlew
```

### Jetifier Warnings

The project uses `android.enableJetifier=true` in `gradle.properties` for legacy support library compatibility. Warnings about Jetifier are expected and can be ignored.

### Docker Toolbox on Windows

When using Docker Toolbox, `$(pwd)` must be under your home user folder since this is the [only folder shared with the VM](https://github.com/docker/kitematic/issues/2738).

### Server-Side Build (Without Android Modules)

To build only the pure Java/Kotlin libraries without Android dependencies:

```bash
MYCELIUM_BUILD_SYSTEM=server ./gradlew build
```

---

## Authors

- Jan Møller
- [Andreas Petersson](https://github.com/apetersson)
- [Daniel Weigl](https://github.com/DanielWeigl)
- [Jan Dreske](https://github.com/jandreske)
- Dmitry Murashchik
- Constantin Vennekel
- [Leo Wandersleb](https://github.com/Giszmo)
- [Daniel Krawisz](https://github.com/DanielKrawisz)
- [Jerome Rousselot](https://github.com/jeromerousselot)
- [Nelson Melina](https://github.com/DaLN)
- [Elvis Kurtnebiev](https://github.com/xElvis89x)
- [Sergey Dolgopolov](https://github.com/itserg)
- [Sergey Lappo](https://github.com/sergeylappo)
- Alexander Makarov
- [Nadia Poletova](https://github.com/poletova-n)
- [Kristina Tezieva](https://github.com/agneslovelace)
- [Nuru Nabiyev](https://github.com/NuruNabiyev)

---

## Credits

Thanks to all collaborators who provided code or helped with integrations:

- [Nicolas Bacca from Ledger](https://github.com/btchip)
- Sipa, Marek and others from Trezor
- Jani and Aleš from Cashila
- [Kalle Rosenbaum, BIP120/121](https://github.com/kallerosenbaum)
- David and Alex from Glidera
- [Wiz](https://twitter.com/wiz) for helping with KeepKey
- Tom Bitton and Asa Zaidman from Simplex

Thanks to Jethro for tirelessly testing during beta development, our volunteer translators, Johannes Zweng for testing and pull request fixes, and all beta testers for early feedback.

---

## License

Depending on the component, a different license applies:

| Component | License |
|-----------|---------|
| `backuputil` | Apache 2.0 |
| `bitlib` | Apache 2.0 |
| `lt-api` | Apache 2.0 |
| `mbw` | MS-RSL |
| `wapi` | Apache 2.0 |
| `zxing-android` | Apache 2.0 |
| `zxing-core` | Apache 2.0 |
