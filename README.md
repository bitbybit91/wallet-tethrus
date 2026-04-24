# Tethrus Wallet — Android

> A privacy-first, multi-asset, self-custodial Android wallet forked from [Mycelium Bitcoin Wallet](https://github.com/mycelium-com/wallet-android) with added TRON / TRC-20 (USDT) support and build-system improvements optimised for low-RAM (4 GB) machines.

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Prerequisites](#2-prerequisites)
3. [Environment Setup (No Physical Device Required)](#3-environment-setup-no-physical-device-required)
4. [Configuration](#4-configuration)
5. [Installation](#5-installation)
6. [Build](#6-build)
7. [Running Tests](#7-running-tests)
8. [Common Issues & Troubleshooting](#8-common-issues--troubleshooting)
9. [Project Structure](#9-project-structure)
10. [Scripts Reference](#10-scripts-reference)
11. [Contributing](#11-contributing)
12. [License](#12-license)

---

## 1. Project Overview

**Tethrus Wallet** is a fully self-custodial, open-source Android cryptocurrency wallet.  
It lets users send, receive, and manage Bitcoin (BTC), Ethereum (ETH), and TRON/TRC-20 tokens (including USDT) directly from their Android device — no centralised server ever holds private keys.

### Key Features

- **HD Wallet** — BIP-32/BIP-44 hierarchical-deterministic accounts; addresses are never reused
- **Single-seed backup** — one BIP-39 master seed recovers the entire wallet
- **TRON / TRC-20 support** — mainnet and Nile-testnet TronGrid API integration; USDT-TRC20 balance display and transfers
- **Ethereum / ERC-20** — via Web3j + Blockbook
- **Hardware-wallet support** — Trezor and Ledger via btchip/NordPol NFC
- **FIO Protocol** — human-readable crypto addresses
- **Firebase push notifications** — transaction alerts
- **Tor hidden-service** connectivity for privacy
- **Reproducible / deterministic builds** — verified using Podman + disorderfs
- **Three product flavours**: `prodnet` (mainnet), `btctestnet` (testnet), `huaweiProdnet` (Huawei App Gallery)

### Tech Stack

| Layer | Technology |
|---|---|
| Language | Kotlin 2.0.21, Java 17 |
| Build system | Gradle 8.8.1 + Android Gradle Plugin 8.12.1 |
| Min / Target Android SDK | 24 / 36 |
| Dependency injection | manual / ViewModel |
| Async | Kotlin Coroutines 1.10.1, RxJava 2 |
| Networking | Retrofit 2 + OkHttp 4 |
| Persistence | SQLDelight 2.0.2 |
| TRON | TronGrid REST API (Retrofit + OkHttp3 4.12.0) |
| Ethereum | Web3j 4.12.3 |
| Serialisation | Jackson 2.9.6, Gson 2.8.5, Protobuf 3 |
| Image loading | Glide 5 |
| Navigation | AndroidX Navigation 2.8.8 |
| Testing | JUnit 4, MockK, Espresso |
| CI | GitHub Actions (`.github/workflows/build.yml`) |
| Container build | Docker / Podman (reproducible builds) |

### Supported Platforms

- **Run-time**: Android 7.0+ (API 24)
- **Build host**: Linux, macOS, Windows 10/11 (minimum 4 GB RAM; 8 GB recommended)
- **Emulator**: Android Virtual Device (AVD) API 34, x86_64, Google Play

---

## 2. Prerequisites

Every tool listed below must be present on the build machine before the installation steps.

### 2.1 Java Development Kit 17

| Attribute | Value |
|---|---|
| Minimum version | JDK **17** (LTS) |
| Recommended distribution | Eclipse Temurin |
| Download | https://adoptium.net/temurin/releases/?version=17 |

<details>
<summary>macOS (Homebrew)</summary>

```bash
brew install --cask temurin@17
```

</details>

<details>
<summary>Ubuntu / Debian</summary>

```bash
sudo apt-get update
sudo apt-get install -y wget apt-transport-https gnupg
wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public \
  | sudo tee /usr/share/keyrings/adoptium.asc
echo "deb [signed-by=/usr/share/keyrings/adoptium.asc] \
  https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo apt-get update
sudo apt-get install -y temurin-17-jdk
```

</details>

<details>
<summary>Windows (winget)</summary>

```bat
winget install --id EclipseAdoptium.Temurin.17.JDK
```

</details>

**Verify:**

```bash
java -version
# Expected: openjdk version "17.x.x" ...
```

---

### 2.2 Android SDK (Command-line Tools)

| Attribute | Value |
|---|---|
| Build-tools version | 34.0.0 |
| Platform | android-34 |
| NDK | 21.1.6352462 |
| Download | https://developer.android.com/studio#command-tools |

<details>
<summary>Linux / macOS</summary>

```bash
export ANDROID_HOME="$HOME/android-sdk"
mkdir -p "$ANDROID_HOME"
cd "$ANDROID_HOME"

# Download the latest command-line tools (replace the URL with the current one from the download page)
wget "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip" \
     -O cmdline-tools.zip
unzip cmdline-tools.zip -d cmdline-tools/
mv cmdline-tools/cmdline-tools cmdline-tools/latest
rm cmdline-tools.zip

# Accept licences and install required components
yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
  "platform-tools" \
  "platforms;android-34" \
  "build-tools;34.0.0" \
  "ndk;21.1.6352462"

# Persist environment variables (add to ~/.bashrc or ~/.zshrc)
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/34.0.0:$PATH"
```

</details>

<details>
<summary>Windows (PowerShell, run as Administrator)</summary>

```powershell
$ANDROID_HOME = "C:\android-sdk"
New-Item -ItemType Directory -Force -Path $ANDROID_HOME
Set-Location $ANDROID_HOME

Invoke-WebRequest `
  "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip" `
  -OutFile "cmdline-tools.zip"
Expand-Archive "cmdline-tools.zip" -DestinationPath "cmdline-tools"
Rename-Item "cmdline-tools\cmdline-tools" "latest"
Remove-Item "cmdline-tools.zip"

# Accept licences and install
& "$ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
& "$ANDROID_HOME\cmdline-tools\latest\bin\sdkmanager.bat" `
  "platform-tools" "platforms;android-34" "build-tools;34.0.0" "ndk;21.1.6352462"

# Set permanent environment variables
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $ANDROID_HOME, "User")
[System.Environment]::SetEnvironmentVariable(
  "PATH",
  "$ANDROID_HOME\cmdline-tools\latest\bin;$ANDROID_HOME\platform-tools;$ANDROID_HOME\build-tools\34.0.0;" +
  [System.Environment]::GetEnvironmentVariable("PATH","User"),
  "User"
)
```

</details>

**Verify:**

```bash
sdkmanager --version
# Expected: 13.0 (or similar)

adb --version
# Expected: Android Debug Bridge version 1.0.41 ...
```

---

### 2.3 Git

| Attribute | Value |
|---|---|
| Minimum version | 2.30 |
| Download | https://git-scm.com/downloads |

```bash
# macOS
brew install git

# Ubuntu / Debian
sudo apt-get install -y git

# Windows
winget install --id Git.Git
```

**Verify:**

```bash
git --version
# Expected: git version 2.x.x
```

---

### 2.4 Python 3.8+ (for `tethrus_builder.py`)

| Attribute | Value |
|---|---|
| Minimum version | Python **3.8** |
| Download | https://www.python.org/downloads/ |

```bash
# macOS
brew install python@3.11

# Ubuntu / Debian
sudo apt-get install -y python3 python3-pip

# Windows
winget install --id Python.Python.3.11
```

**Verify:**

```bash
python3 --version   # Linux / macOS
python --version    # Windows
# Expected: Python 3.x.x (≥ 3.8)
```

---

### 2.5 Docker or Podman (reproducible builds only, optional)

Required only for deterministic / reproducible build verification.

```bash
# macOS
brew install --cask docker

# Ubuntu
sudo apt-get install -y docker.io
sudo systemctl enable --now docker

# Windows
winget install --id Docker.DockerDesktop
```

**Verify:**

```bash
docker --version
# Expected: Docker version 26.x.x ...
```

---

## 3. Environment Setup (No Physical Device Required)

All build and test steps can be completed without a physical Android device by using an Android Virtual Device (AVD) emulator, or entirely headless for unit tests and APK generation.

### 3.1 Create an Android Virtual Device (AVD)

```bash
# Install the system image (x86_64, API 34, Google Play)
"$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
  "system-images;android-34;google_apis_playstore;x86_64"

# Create the AVD  (accept defaults)
"$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" create avd \
  --name "tethrus_emu" \
  --package "system-images;android-34;google_apis_playstore;x86_64" \
  --device "pixel_4" \
  --force

# List created AVDs to confirm
"$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager" list avd
```

Expected output includes:
```
Name: tethrus_emu
Path: ~/.android/avd/tethrus_emu.avd
Target: Google Play (Google Inc.)
Based on: Android 14 (API 34)
```

### 3.2 Start the Emulator (Headless / CI Mode)

```bash
# Linux / macOS
"$ANDROID_HOME/emulator/emulator" -avd tethrus_emu \
  -no-window -no-audio -no-snapshot -gpu swiftshader_indirect &

# Wait until fully booted
adb wait-for-device
adb shell input keyevent 82   # unlock screen
```

Expected: `adb devices` shows `emulator-5554  device`

### 3.3 Verify the Emulator Is Running

```bash
adb devices
# Expected:
# List of devices attached
# emulator-5554   device
```

### 3.4 Docker-Based Build (no emulator needed)

Unit tests and APK generation do **not** require an emulator. Use the project's `Dockerfile` for a fully self-contained build environment:

```bash
# Build the container image (from repo root)
docker build --no-cache --tag tethrus_builder .

# Build all prodnet release APKs inside the container
docker run --rm \
  --volume "$(pwd):/app" \
  --workdir /app \
  tethrus_builder \
  bash -c "./gradlew --no-daemon --max-workers=2 clean mbw:assembleProdnetRelease"

# Output APKs appear in:
ls mbw/build/outputs/apk/prodnet/release/
```

### 3.5 Common Setup Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `JAVA_HOME is not set` | JDK not on `PATH` | `export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))` |
| `sdkmanager: command not found` | PATH not updated | Add `$ANDROID_HOME/cmdline-tools/latest/bin` to `PATH` |
| Emulator won't start — `ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL` error | KVM not available in VM | Pass `-accel off -gpu swiftshader_indirect` flags |
| `Error: Could not find class 'avdmanager'` | Wrong cmdline-tools layout | Ensure the zip was extracted to `cmdline-tools/latest/` not `cmdline-tools/cmdline-tools/` |

---

## 4. Configuration

### 4.1 Environment Variables

| Variable | Required | Description | Example |
|---|---|---|---|
| `ANDROID_HOME` | **Yes** | Root of Android SDK installation | `/home/user/android-sdk` |
| `ANDROID_SDK_ROOT` | No | Alias for `ANDROID_HOME`, accepted by AGP | same as above |
| `JAVA_HOME` | **Yes** | Root of JDK 17 installation | `/usr/lib/jvm/temurin-17` |
| `MYCELIUM_BUILD_SYSTEM` | No | Set to `server` to skip Android modules (JVM-only) | `server` |
| `GRADLE_OPTS` | No | Override JVM args for the Gradle process | `-Xmx512m -Dfile.encoding=UTF-8` |

### 4.2 `keys.properties` — Signing Configuration

Signing keys are **never** committed to source control (the file is gitignored). Copy the example file and fill in your values:

```bash
cp keys.properties.example keys.properties
```

Edit `keys.properties`:

```properties
# Absolute (or relative-to-repo-root) path to the production keystore file
prodKeyStore=C:\\path\\to\\keystore_mbwProd

# Key alias inside the production keystore
prodKeyAlias=mycelium_prod

# Password protecting the production keystore file
prodKeyStorePassword=CHANGE_ME

# Password protecting the production key alias
prodKeyAliasPassword=CHANGE_ME

# Absolute path to the testnet keystore file
testKeyStore=C:\\path\\to\\keystore_mbwTest

# Key alias inside the testnet keystore
testKeyAlias=mycelium_test

# Password protecting the testnet keystore file
testKeyStorePassword=CHANGE_ME

# Password protecting the testnet key alias
testKeyAliasPassword=CHANGE_ME
```

> **Note:** Debug builds automatically fall back to the committed `debug.keystore`
> (`password: android`, alias: `androiddebugkey`). You do **not** need `keys.properties`
> for debug builds.

### 4.3 Generating a Release Keystore (first time only)

```bash
# Replace all placeholders with your own values
keytool -genkey -v \
  -keystore keystore_mbwProd \
  -alias mycelium_prod \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

### 4.4 Build Flavours and TRON Config

| Flavour | Application ID | TRON Network | USDT Contract |
|---|---|---|---|
| `prodnet` | `com.mycelium.wallet` | Mainnet (`api.trongrid.io`) | `TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t` |
| `btctestnet` | `com.mycelium.testnetwallet` | Nile testnet (`nile.trongrid.io`) | `TXYZopYRdj2D9XRtbG411XZZ3kM5VkAeBf` |
| `huaweiProdnet` | `com.mycelium.wallet.app` | Mainnet (`api.trongrid.io`) | `TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t` |

TRON endpoints are injected at compile time via `BuildConfig`:

```groovy
// mbw/build.gradle (generated, do not edit directly)
buildConfigField "String", "TRON_GRID_URL", '"https://api.trongrid.io"'
buildConfigField "String", "TRON_SCAN_URL", '"https://tronscan.org"'
buildConfigField "String", "USDT_CONTRACT", '"TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t"'
```

### 4.5 `gradle.properties` — JVM / Parallelism Tuning

The committed `gradle.properties` is pre-tuned for 4 GB RAM hosts:

```properties
org.gradle.jvmargs=-Xmx1536m -XX:MaxMetaspaceSize=384m -XX:+UseSerialGC -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8
kotlin.daemon.jvmargs=-Xmx1024m -XX:+UseSerialGC -Dfile.encoding=UTF-8
org.gradle.parallel=false
org.gradle.workers.max=2
org.gradle.caching=true
android.r8.maxHeapSize=1024m
kotlin.incremental=true
```

On hosts with ≥ 8 GB RAM you may increase `-Xmx1536m` to `-Xmx3g` and enable `org.gradle.parallel=true`.

### 4.6 Switching Build Environments

| Target | Command | Notes |
|---|---|---|
| Debug | `./gradlew mbw:assembleProdnetDebug` | Uses `debug.keystore`; appId gets `.debug` suffix |
| Release (unsigned/debug key) | `./gradlew mbw:assembleProdnetRelease` | Without `keys.properties`, falls back to `debug.keystore` |
| Release (production signed) | same + `keys.properties` in place | Reads `prodKeyStore` / `prodKeyAlias` |
| CI (GitHub Actions) | push / PR triggers `build.yml` | Headless, no GUI |

---

## 5. Installation

### Step 1 — Clone the repository

```bash
git clone https://github.com/bitbybit91/wallet-tethrus.git
cd wallet-tethrus
```

Expected: the `wallet-tethrus` directory is created with the full repository.

---

### Step 2 — Initialise Git submodules

The project depends on two submodules: `wallet-android-modularization-tools` and `fiosdk_kotlin`.

```bash
git submodule update --init --recursive
```

Expected output ends with lines like:
```
Submodule path 'fiosdk_kotlin': checked out 'abc1234...'
Submodule path 'wallet-android-modularization-tools': checked out 'def5678...'
```

**Common error:** `fatal: repository 'https://github.com/...' not found`  
**Fix:** Ensure you have network access and that `git` is not behind a proxy blocking GitHub.

---

### Step 3 — Set up environment variables

#### Linux / macOS

```bash
export JAVA_HOME="$(dirname $(dirname $(readlink -f $(which java))))"
export ANDROID_HOME="$HOME/android-sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/34.0.0:$PATH"
```

Add the same lines to `~/.bashrc` (bash) or `~/.zshrc` (zsh) to persist them.

#### Windows (Command Prompt, run once)

```bat
setx JAVA_HOME "C:\Program Files\Eclipse Adoptium\jdk-17"
setx ANDROID_HOME "C:\android-sdk"
```

Restart your terminal after running `setx`.

---

### Step 4 — (Optional) Configure signing keys

Skip this step if you only need debug builds.

```bash
cp keys.properties.example keys.properties
# Edit keys.properties with your actual keystore paths and passwords
```

---

### Step 5 — Verify the environment with `setup-dev-env.bat` (Windows only)

```bat
setup-dev-env.bat
```

Expected output:

```
=== Tethrus Dev Environment Setup Check ===

Checking Java version...
  [OK] Java 17 detected (17.0.x)

Checking ANDROID_HOME...
  [OK] ANDROID_HOME=C:\android-sdk

Checking gradlew.bat...
  [OK] gradlew.bat is functional

=== All checks PASSED. Ready to build. ===
```

---

### Step 6 — Install Python dependencies for `tethrus_builder.py`

```bash
python3 tethrus_builder.py --install
```

Expected output:

```
12:00:00  INFO      psutil : OK
12:00:01  INFO      colorama : OK
```

**Common error:** `pip: command not found`  
**Fix (Linux):** `sudo apt-get install -y python3-pip`  
**Fix (Windows):** Python installer includes pip by default; re-run the Python installer and tick "Add pip".

---

### Step 7 — Verify the build environment

```bash
# Linux / macOS
./gradlew --version --no-daemon

# Windows
gradlew.bat --version --no-daemon
```

Expected output includes:
```
------------------------------------------------------------
Gradle 8.8.1
------------------------------------------------------------
...
```

---

## 6. Build

### 6.1 Development Build (Debug)

#### Linux / macOS

```bash
# Mainnet debug APK
./gradlew --no-daemon --max-workers=2 clean mbw:assembleProdnetDebug

# Testnet debug APK
./gradlew --no-daemon --max-workers=2 clean mbw:assembleBtctestnetDebug

# Huawei mainnet debug APK
./gradlew --no-daemon --max-workers=2 clean mbw:assembleHuaweiProdnetDebug
```

#### Windows

```bat
gradlew.bat --no-daemon --max-workers=2 clean mbw:assembleProdnetDebug
```

**Or use the interactive build menu:**

```bat
local-build.bat
```

Output APK location:
```
mbw/build/outputs/apk/prodnet/debug/mbw-prodnet-debug.apk
```

**Install on emulator / device:**

```bash
adb install mbw/build/outputs/apk/prodnet/debug/mbw-prodnet-debug.apk
```

---

### 6.2 Production Release Build

```bash
# Linux / macOS (requires keys.properties)
./gradlew --no-daemon --max-workers=2 clean mbw:assembleProdnetRelease

# Windows
gradlew.bat --no-daemon --max-workers=2 clean mbw:assembleProdnetRelease
```

Output APK location:
```
mbw/build/outputs/apk/prodnet/release/mbw-prodnet-release.apk
```

**Verify APK signature (optional):**

```bash
apksigner verify --print-certs --verbose mbw/build/outputs/apk/prodnet/release/mbw-prodnet-release.apk
```

---

### 6.3 Python Orchestrator (`tethrus_builder.py`)

The Python script wraps Gradle with additional pre-flight checks, APK hashing, and logging. All operations are logged to `tethrus_build.log`.

```bash
# Run the complete debug build pipeline (pre-flight checks + submodules + all 3 debug flavours + APK hashing)
python3 tethrus_builder.py --full

# Build a specific flavour
python3 tethrus_builder.py --build prodnetDebug
python3 tethrus_builder.py --build btctestnetDebug
python3 tethrus_builder.py --build huaweiProdnetDebug

# Build all release flavours
python3 tethrus_builder.py --release

# Hash and signature-verify existing APKs
python3 tethrus_builder.py --verify-apks

# Print environment summary
python3 tethrus_builder.py --config
```

Successful exit code is `0`. Non-zero means at least one step failed; details are in `tethrus_build.log`.

---

### 6.4 CI/CD Build — GitHub Actions

A workflow is included at `.github/workflows/build.yml`. It triggers on every push and pull request:

```yaml
name: Tethrus Build
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
        with: { submodules: recursive }
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17
      - uses: android-actions/setup-android@v3
      - run: chmod +x gradlew
      - run: ./gradlew clean test mbw:assembleProdnetRelease
      - uses: actions/upload-artifact@v4
        with:
          name: tethrus-apks
          path: mbw/build/outputs/apk/
```

APK artifacts are available in the **Actions** tab → workflow run → **tethrus-apks**.

**Injecting signing keys in CI (GitHub Actions Secrets):**

1. Base64-encode your keystore: `base64 keystore_mbwProd > keystore.b64`
2. Add the content as a secret named `PROD_KEYSTORE_BASE64` in the repository settings.
3. Add `PROD_KEY_ALIAS`, `PROD_KEYSTORE_PASSWORD`, `PROD_KEY_PASSWORD` as secrets.
4. Add a step before the Gradle step:

```yaml
- name: Decode keystore
  run: |
    echo "${{ secrets.PROD_KEYSTORE_BASE64 }}" | base64 -d > keystore_mbwProd
    cat > keys.properties <<EOF
    prodKeyStore=keystore_mbwProd
    prodKeyAlias=${{ secrets.PROD_KEY_ALIAS }}
    prodKeyStorePassword=${{ secrets.PROD_KEYSTORE_PASSWORD }}
    prodKeyAliasPassword=${{ secrets.PROD_KEY_PASSWORD }}
    EOF
```

---

### 6.5 Reproducible / Deterministic Build (Docker / Podman)

```bash
# Build the container image
docker build --no-cache --tag tethrus_builder .

# Build prodnet release using disorderfs for determinism
docker run --rm --interactive --tty \
  --device /dev/fuse \
  --cap-add SYS_ADMIN \
  --volume "$(pwd):/app" \
  tethrus_builder \
  bash -c "
    mkdir /project/
    disorderfs --sort-dirents=yes --reverse-dirents=no /app/ /project/
    cd /project/
    ./gradlew -x lint -x test clean :mbw:assembleProdnetRelease
  "

# APK is at:
ls mbw/build/outputs/apk/prodnet/release/
```

---

## 7. Running Tests

### 7.1 All Unit Tests (headless, no device required)

```bash
# Linux / macOS
./gradlew --no-daemon test

# Windows
gradlew.bat --no-daemon test
```

Expected output:
```
BUILD SUCCESSFUL in Xs
... tests were run, 0 failed.
```

HTML reports are generated at:
```
<module>/build/reports/tests/test/index.html
```

### 7.2 Single Module Unit Tests

```bash
# Only walletcore tests
./gradlew --no-daemon :walletcore:test

# Only bitlib tests
./gradlew --no-daemon :bitlib:test
```

### 7.3 Android Instrumented Tests (requires running emulator)

```bash
# Start emulator first (see Section 3.2), then:
./gradlew --no-daemon mbw:connectedAndroidTest
```

### 7.4 Specific Test Class

```bash
./gradlew :walletcore:test --tests "com.mycelium.wallet.SomeTest"
```

### 7.5 Test Coverage Report

The project uses Gradle's built-in JaCoCo integration (when configured). Run:

```bash
./gradlew --no-daemon jacocoTestReport
```

HTML coverage reports appear at:
```
<module>/build/reports/jacoco/test/html/index.html
```

### 7.6 Lint

```bash
./gradlew --no-daemon mbw:lint
# HTML report: mbw/build/reports/lint-results-*.html
```

---

## 8. Common Issues & Troubleshooting

| Error / Symptom | Cause | Fix |
|---|---|---|
| `JAVA_HOME is not set and no 'java' command could be found` | JDK 17 not on PATH or `JAVA_HOME` not set | Set `JAVA_HOME` to your JDK 17 root (see Section 2.1) |
| `Unsupported class file major version 61` | Module compiled with Java 17+ but runtime is Java 11 | Switch to JDK 17: `export JAVA_HOME=<temurin-17-path>` |
| `Could not resolve com.squareup.okhttp3:okhttp:4.12.0` | No internet access or Maven Central unreachable | Check network; set corporate proxy in `gradle.properties`: `systemProp.https.proxyHost=proxy.example.com` |
| `OutOfMemoryError: Java heap space` during Kotlin compilation | Gradle daemon heap too small | Confirm `gradle.properties` has `-Xmx1536m`; close other JVM processes |
| `submodule 'fiosdk_kotlin' ... did not contain a commit` | Submodule not initialised | Run `git submodule update --init --recursive` |
| `The minCompileSdk (34) specified in a dependency's AAR metadata` | Android SDK platform 34 not installed | Run `sdkmanager "platforms;android-34"` |
| `Execution failed for task ':mbw:compileDebugKotlin': ... unresolved reference: BuildConfig` | `buildConfig` not enabled | Confirm `buildFeatures { buildConfig = true }` is in `mbw/build.gradle` `android {}` block |
| `License for package Android SDK Platform 34 not accepted` | SDK licence not accepted | Run `yes \| sdkmanager --licenses` |
| `keys.properties (No such file or directory)` during release build | Missing signing config | Copy `keys.properties.example` to `keys.properties` and fill in your keystore details (or skip for debug) |
| `error: duplicate class com.google.protobuf.*` | Protobuf library version conflict | A `force()` in `resolutionStrategy` is already in place; verify no additional `protobuf-java` dependency is added separately |
| `Gradle build daemon disappeared unexpectedly` | Daemon OOM-killed | Reduce `-Xmx` further or add `--no-daemon` flag to disable the daemon entirely |
| `python3: command not found` | Python 3 not installed | Install Python 3.8+ (see Section 2.4) |

---

## 9. Project Structure

```
wallet-tethrus/                         ← Repository root
├── .github/
│   └── workflows/
│       ├── build.yml                   ← GitHub Actions CI (Tethrus Build)
│       ├── ci.yml                      ← Additional CI workflow
│       └── rc.yml                      ← Release-candidate workflow
├── bitlib/                             ← Bitcoin primitives library (Apache 2.0)
├── btchip/                             ← Ledger btchip NFC/USB library
├── docs/                               ← Additional documentation assets
├── fiosdk_kotlin/                      ← FIO Protocol SDK (git submodule)
│   ├── androidfioserializationprovider/
│   └── fiosdk/
├── gradle/
│   ├── libs.versions.toml              ← Version catalog (all dependency versions)
│   └── wrapper/
│       ├── gradle-wrapper.jar
│       └── gradle-wrapper.properties   ← Gradle 8.8.1 distribution URL
├── libs/
│   └── nordpol/                        ← NFC library for hardware wallets
├── lt-api/                             ← Local Trader API (Apache 2.0)
├── LVL/                                ← Google Play Licensing Verification Library
├── mbw/                                ← Main Android application module (MS-RSL)
│   ├── build.gradle                    ← App-level Gradle config (flavors, signing, deps)
│   ├── google-services.json            ← Firebase project config
│   ├── lint-baseline.xml               ← Known lint suppressions
│   └── src/
│       ├── main/                       ← Production source + resources
│       ├── prodnet/                    ← Mainnet-only source
│       ├── btctestnet/                 ← Testnet-only source
│       └── huaweiProdnet/              ← Huawei flavour source
├── mbwlib/                             ← Shared wallet logic used by mbw
├── testhelper/                         ← Shared test utilities
├── trezor/                             ← Trezor hardware-wallet integration
├── view/                               ← Shared UI components
├── wallet-android-modularization-tools/ ← Gradle modularisation helpers (git submodule)
├── wallet-console/                     ← CLI wallet console (server builds)
├── walletcore/                         ← Core wallet engine (Apache 2.0)
│   └── src/main/java/
│       └── com/tethrus/wallet/tron/   ← TRON / TRC-20 integration (NEW)
│           ├── TronNetworkEndpoints.kt ← TRON mainnet & Nile testnet URL constants
│           ├── TronGridApiClient.kt    ← Retrofit/OkHttp TronGrid REST client
│           ├── Trc20Token.kt           ← TRC-20 token data class
│           └── TronAccount.kt         ← TRON account model (TRX + TRC-20 balances)
├── walletmodel/                        ← Domain model shared across modules
├── wapi/                               ← Mycelium WAPI network client (Apache 2.0)
│
├── build.gradle                        ← Root Gradle config (plugins, allprojects)
├── ext_settings.gradle                 ← Shared ext{} version variables
├── gradle.properties                   ← JVM / Gradle performance tuning
├── settings.gradle                     ← Module inclusion and repo declarations
├── tools.gradle                        ← Utility Gradle tasks
├── integration-test.gradle             ← Integration test configuration
│
├── Dockerfile                          ← Ubuntu-based container for reproducible builds
├── .gitlab-ci.yml                      ← GitLab CI configuration (legacy)
├── .gitmodules                         ← Submodule declarations
├── .gitignore                          ← Ignores: build/, keys.properties, local.properties
│
├── debug.keystore                      ← Debug signing key (committed; password: android)
├── keys.properties.example             ← Template for production signing config
│
├── local-build.bat                     ← Windows interactive build menu (low-RAM)
├── local-build.ps1                     ← PowerShell equivalent with RAM check + stopwatch
├── setup-dev-env.bat                   ← Windows environment health check script
├── tethrus_builder.py                  ← Python 3 build orchestrator (646 lines)
│
├── apkdiff.py                          ← APK comparison utility
├── checkBuild.sh                       ← Deterministic build verification script
├── collectApks.sh                      ← Collect and zip all APKs for release
│
└── LICENSE                             ← Per-module licence summary
```

---

## 10. Scripts Reference

### Gradle Tasks

| Task | Command | Description |
|---|---|---|
| Clean | `./gradlew clean` | Delete all build outputs |
| Unit tests | `./gradlew test` | Run all JVM unit tests across all modules |
| Lint | `./gradlew mbw:lint` | Run Android Lint on the `mbw` module |
| Prodnet debug APK | `./gradlew mbw:assembleProdnetDebug` | Debug build — mainnet |
| Prodnet release APK | `./gradlew mbw:assembleProdnetRelease` | Release build — mainnet |
| Testnet debug APK | `./gradlew mbw:assembleBtctestnetDebug` | Debug build — BTC testnet |
| Testnet release APK | `./gradlew mbw:assembleBtctestnetRelease` | Release build — BTC testnet |
| Huawei debug APK | `./gradlew mbw:assembleHuaweiProdnetDebug` | Debug build — Huawei flavour |
| Huawei release APK | `./gradlew mbw:assembleHuaweiProdnetRelease` | Release build — Huawei flavour |
| All APKs | `./gradlew mbw:assemble` | All flavour × build-type combinations |
| Instrumented tests | `./gradlew mbw:connectedAndroidTest` | Requires running emulator or device |
| Generate docs | `./gradlew dokkaHtml` | KDoc HTML documentation |
| Walletcore fatJar | `./gradlew :walletcore:fatJar` | Single jar with all walletcore dependencies |

### Shell / Batch Scripts

| Script | Platform | Description |
|---|---|---|
| `local-build.bat` | Windows | Interactive menu to select and build any flavour; sets low-RAM `GRADLE_OPTS` |
| `local-build.ps1` | Windows (PowerShell) | PowerShell equivalent; shows available RAM and build stopwatch |
| `setup-dev-env.bat` | Windows | Checks Java 17, `ANDROID_HOME`, and `gradlew.bat` health |
| `checkBuild.sh` | Linux / macOS | Deterministic build verification: compares a locally built APK byte-for-byte against a reference revision |
| `collectApks.sh` | Linux / macOS | Copies all APKs into a timestamped folder and zips them for distribution |
| `apkdiff.py` | Any (Python 3) | APK file-level diff utility |

### Python Orchestrator

| Command | Description |
|---|---|
| `python3 tethrus_builder.py --install` | Auto-install `psutil` and `colorama` |
| `python3 tethrus_builder.py --config` | Print full environment summary |
| `python3 tethrus_builder.py --build <flavor>` | Pre-flight + submodule update + single-flavour build |
| `python3 tethrus_builder.py --release` | Build all release flavours sequentially |
| `python3 tethrus_builder.py --verify-apks` | SHA-256 hash + `apksigner verify` on all APKs |
| `python3 tethrus_builder.py --full` | Full pipeline: checks → submodules → all debug builds → hashing |
| `python3 tethrus_builder.py --debug` | Same as above with DEBUG-level console logging |

---

## 11. Contributing

### Fork and Clone

```bash
# 1. Fork the repo on GitHub (https://github.com/bitbybit91/wallet-tethrus)
# 2. Clone your fork
git clone https://github.com/<your-username>/wallet-tethrus.git
cd wallet-tethrus
git submodule update --init --recursive

# 3. Add upstream remote
git remote add upstream https://github.com/bitbybit91/wallet-tethrus.git
```

### Branch Naming Convention

```
feature/<short-description>        # New functionality
fix/<issue-number>-<short-desc>    # Bug fixes
chore/<short-description>          # Tooling / maintenance
task/<N>-<short-description>       # Numbered tasks matching project spec
```

Examples:
```
feature/tron-send-transaction
fix/42-crash-on-resume
chore/upgrade-kotlin-2.1
task/11-trc20-ui
```

### Pre-PR Checklist

Before opening a pull request, run the following:

```bash
# 1. Run unit tests
./gradlew --no-daemon test

# 2. Run Android Lint on mbw
./gradlew --no-daemon mbw:lint

# 3. Build debug APK to confirm compilation
./gradlew --no-daemon --max-workers=2 mbw:assembleProdnetDebug

# 4. (Optional) Run the full Python build pipeline
python3 tethrus_builder.py --full
```

**PR Checklist:**

- [ ] All unit tests pass (`./gradlew test`)
- [ ] No new lint errors (`./gradlew mbw:lint`)
- [ ] Debug APK builds without errors
- [ ] `keys.properties` is **not** committed
- [ ] New TRON/Kotlin source files are in `com.tethrus.wallet.*` packages
- [ ] Commit messages follow `task(N): description` or `feat/fix/chore: description`
- [ ] No existing files have been deleted (additive / in-place changes only)

---

## 12. License

This project is a fork of [Mycelium Bitcoin Wallet](https://github.com/mycelium-com/wallet-android).
Different components carry different licences:

| Module | License |
|---|---|
| `mbw` (main app) | [MS-RSL](https://referencesource.microsoft.com/license.html) |
| `bitlib` | Apache 2.0 |
| `lt-api` | Apache 2.0 |
| `wapi` | Apache 2.0 |
| `walletcore` | Apache 2.0 |
| `backuputil` | Apache 2.0 |
| New Tethrus code (`com.tethrus.*`) | Apache 2.0 |

See [LICENSE](./LICENSE) for the full per-module breakdown.

---

Beta channel
============

In order to receive updates quicker than others, you need to enable beta versions of the software in
[Google Play](https://play.google.com/apps/testing/com.mycelium.wallet)

As beta testers, please make sure you have a recent **backup of the masterseed** and all **private keys** inside Mycelium. Beta testers will experience many bugs.
So far, restoring the wallet from masterseed has never been necessary, but we offer no guarantees.

Building
========

To build everything from source, simply checkout the source and build using gradle on the build system you need:

 * JDK 1.8

The project layout is designed to be used with a recent version of Android Studio (currently 4.1.2)

#### Build commands

To get the source code, type:

    git clone https://github.com/mycelium-com/wallet-android.git
    cd wallet-android
    git submodule update --init --recursive

Linux/Mac type:

    ./gradlew clean test mbw::assembleProdnetRelease mbw::assembleBtctestnetRelease

Windows type:

    gradlew.bat clean test mbw::assembleProdnetRelease mbw::assembleBtctestnetRelease

 - Voila, look into `mbw/build/outputs/apk/` to see the generated apk.
   There are versions for both prodnet and testnet.

Alternatively you can install the latest version from the [Play Store](https://play.google.com/store/apps/details?id=com.mycelium.wallet).

If you cannot access the Play store, you can obtain the apk directly from the Mycelium Bitcoin
Wallet [download page](https://wallet.mycelium.com/).

App Download Verification
-------------------------

All versions released by Mycelium are signed with the same release keys. If you do not trust the apk
you can check that signature with
[apksigner](https://developer.android.com/studio/command-line/apksigner.html#options-verify):

```
apksigner verify --print-certs --verbose mycelium.apk
```

The output should look like:

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

Deterministic builds
====================

To validate the Mycelium image you obtain from Google Play Store, you can rebuild the Mycelium
wallet yourself using [Podman](https://podman.io/getting-started/) and compare both images following these steps:

* Get the source as above
* Create your own builder image from our simple Dockerfile

      $ podman build --no-cache --tag mycelium_builder .

* Build using disorderfs to eliminate non-determinism caused by file ordering

      $ podman run --rm --interactive --tty \
          --device /dev/fuse \
          --cap-add SYS_ADMIN \
          --volume .:/app \
          mycelium_builder \
          bash -c "apt update;
          apt install -y disorderfs;
          mkdir /project/
          disorderfs --sort-dirents=yes --reverse-dirents=no /app/ /project/;
          cd /project/
          ./gradlew -x lint -x test clean :mbw:assembleProdnetRelease;"

  If you see errors about local paths not being found, remove/move away `local.properties`.

  As container might run as a different user, its generated files will also be "not yours".
  Make them yours using `chown` as super user.
  
  The app can now be found in `mbw/build/outputs/apk/prodnet/release/mbw-prodnet-release.apk`.
  
  As maintainer with release keys you want to run a slightly different command:
  Add these parameters: `--volume 'path/to/keys.properties':/project/keys.properties --volume 'path/to/keystore_mbwProd':/project/keystore_mbwProd --volume 'path/to/keystore_mbwTest':/project/keystore_mbwTest`
  Build all these targets `:mbw:assBtctRel :mbw:assProdRel :mbw:assBtctDeb :mbw:assProdDeb`
  and to get an error on missing release keys, add this gradle option `-PenforceReleaseSigning`
  
  Note: for those who use Docker Toolbox $(pwd) should be under your home user folder since this is the [only folder that is shared with VM](https://github.com/docker/kitematic/issues/2738).

* Retrieve Google Play Mycelium APK from your phone
  Gets package path:

        $ adb shell pm path com.mycelium.wallet
        package:/data/app/com.mycelium.wallet-1/base.apk

  Retrieve file:

        $ adb pull /data/app/com.mycelium.wallet-1/base.apk mycelium-signed.apk
        
* Extract content from both apks you want to compare, using [ApkTool](https://ibotpeaches.github.io/Apktool/):

        java -jar ~/path/to/apktool.jar d mbw-prodnet-release.apk
        java -jar ~/path/to/apktool.jar d mycelium-signed.apk

* Compare signed apk with unsigned locally built apk using a diff tool

        diff --brief --recursive  mbw-prodnet-release/ mycelium-signed/ | grep -v "META-INF/CERT.RSA\|META-INF/CERT.SF\|META-INF/MANIFEST.MF"

* The expected difference between these files are elements that depend on the signature, that only
  the project's maintainer can reproduce:
  
  * `original/META-INF/CERT.RSA` 
  * `original/META-INF/CERT.SF` 
  * `original/META-INF/MANIFEST.MF`

Features
========

With the Mycelium Bitcoin Wallet you can send and receive Bitcoins using your mobile phone.

 - HD enabled - manage multiple accounts and never reuse addresses ([Bip32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)/[Bip44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki) compatible)
 - Masterseed based - make one backup and be safe for ever. ([Bip39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki))
 - 100% control over your private keys, they never leave your device unless you export them
 - No block chain download - install and run in seconds
 - Ultra fast connection to the Bitcoin network through our super nodes
 - For enhanced privacy and availability you can connect to our super nodes via a tor-hidden service ( *.onion* address)
 - Watch-only addresses (single or xPub) & private key (single or xPriv) import for secure cold-storage integration
 - Directly spend from paper wallets (single key, xPriv or master seed)
 - Trezor enabled - directly spend from trezor-secured accounts.
 - [Mycelium Entropy](https://mycelium.com/entropy) compatible Shamir-Secret-Shared 2-out-of-3 keys spending
 - Secure your wallet with a PIN
 - Compatible with other bitcoin services through the `bitcoin:` URI scheme


Please note that bitcoin is still experimental and this app comes with no warranty - while we make sure to adhere to the highest standards of software craftsmanship we can not exclude that the software contains bugs. Please make sure you have backups of your private keys and do not use this for more than you are willing to lose.

This application's source is published at https://github.com/mycelium-com/wallet
We need your feedback. If you have a suggestion or a bug to report [create an issue](https://github.com/mycelium-com/wallet/issues).

More features:
 - Sources [available for review](https://github.com/mycelium-com/wallet-android)
 - Multiple HD accounts, private keys, external xPub or xPriv accounts
 - Multiple Bitcoin denominations: BTC, mBTC, bits and uBTC
 - View your balance in multiple fiat currencies: USD, AUD, CAD, CHF, CNY, DKK, EUR, GBP, HKD, JPY, NZD, PLN, RUB, SEK, SGD, THB, and many more
 - Send and receive by specifying an amount in fiat and switch between fiat and BTC while entering the amount
 - Address book for commonly used addresses
 - Transaction history with detailed information and local stored comments
 - Import private keys using SIPA (the ones beginning with a 5) and mini private key format (Casascius private keys) from QR-codes or clipboard
 - Export private-, xPub- or xPriv-keys as QR-codes, on clipboard or share with other applications
 - Share your bitcoin address using Twitter, Facebook, email and more.
 - Integrated QR-code scanner
 - Client side load balancing between three 100% redundant server nodes located in different data centers.
 - Sign Messages using your private keys (compatible with bitcoin-qt)

Authors
=======
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
 

Credits
=======
Thanks to all collaborators who provided us with code or helped us with integrations!
Just to name a few:

 - [Nicolas Bacca from Ledger](https://github.com/btchip)
 - Sipa, Marek and others from Trezor
 - Jani and Aleš from Cashila
 - [Kalle Rosenbaum, Bip120/121](https://github.com/kallerosenbaum)
 - David and Alex from Glidera
 - [Wiz](https://twitter.com/wiz) for helping us with KeepKey
 - Tom Bitton and Asa Zaidman from Simplex
 - (if you think you should be mentioned here, just notify us)

Thanks to Jethro for tirelessly testing the app during beta development.

Thanks to our numerous volunteer translators who provide high-quality translations in many languages. Your name should be listed here, please contact me so I know you want to be included.

Thanks to Johannes Zweng for his testing and providing pull requests for fixes.

Thanks to all beta testers to provide early feedback.
