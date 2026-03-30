# Tethrus Wallet

Android cryptocurrency wallet — forked from Mycelium — supporting **Bitcoin**, **Tron/TRC20**, and **Ethereum**. This document is a developer build guide. All version numbers and commands come directly from the project's build files.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Repository Setup](#repository-setup)
4. [Configuration](#configuration)
5. [Building](#building)
6. [Signing](#signing)
7. [Testing](#testing)
8. [APK Verification](#apk-verification)
9. [Deterministic Builds](#deterministic-builds)
10. [CI/CD](#cicd)
11. [Troubleshooting](#troubleshooting)
12. [License](#license)

---

## Prerequisites

| Tool | Required Version | Notes |
|---|---|---|
| JDK | **17** | `openjdk-17-jdk`; Java source/target compatibility set to `JavaVersion.VERSION_17` |
| Android SDK (compileSdk) | **36** | Android 16 |
| Android Build Tools | **34.0.0** | |
| Android NDK | **21.1.6352462** | |
| CMake | **3.22.1** | Required by native code |
| Kotlin | **2.0.21** | Via Gradle plugin; KSP `2.0.21-1.0.28` |
| Gradle (wrapper) | **8.13** | Managed by `gradlew`; do not install separately |

---

## Environment Setup

### JDK 17

**macOS (Homebrew):**
```bash
brew install openjdk@17
export JAVA_HOME="$(brew --prefix openjdk@17)"
```

**Linux (apt):**
```bash
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

Verify:
```bash
java -version   # must show 17.x
```

### Android SDK (command-line tools)

```bash
# Download command-line tools from https://developer.android.com/studio#command-tools
# Then install the required SDK components:
sdkmanager "platform-tools" \
           "platforms;android-36" \
           "build-tools;34.0.0" \
           "ndk;21.1.6352462" \
           "cmake;3.22.1"
```

### Environment Variables

```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64   # adjust for your OS
export ANDROID_HOME=$HOME/Android/Sdk                  # or wherever your SDK lives
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools/bin
```

Add these to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) so they persist.

### Gradle JVM Settings

The project ships `gradle.properties` with the following JVM tuning already in place — no manual changes needed:

```properties
org.gradle.jvmargs=-Xmx4g -XX:MaxMetaspaceSize=1024m
kotlin.daemon.jvmargs=-Xmx4g
android.enableJetifier=true
android.useAndroidX=true
android.nonTransitiveRClass=false
android.nonFinalResIds=false
org.gradle.jvm.toolchain.install=true
org.gradle.java.installations.auto-detect=true
org.gradle.java.installations.auto-download=true
```

---

## Repository Setup

### Clone

```bash
git clone https://github.com/bitbybit91/wallet-tethrus.git
cd wallet-tethrus
```

### Initialise Submodules

```bash
git submodule update --init --recursive
```

#### Git Submodules

| Path | Remote |
|---|---|
| `wallet-android-modularization-tools` | `https://github.com/mycelium-com/wallet-android-modularization-tools` |
| `fiosdk_kotlin` | `https://github.com/mycelium-com/fiosdk_kotlin` |

### Project Module Structure

```
wallet-tethrus/
├── mbw/                          # Main wallet app (UI, flavors, signing)
├── walletcore/                   # Core wallet logic (Bitcoin, ETH, Tron, TRC20)
├── walletmodel/                  # Shared wallet data models
├── wapi/                         # Mycelium WAPI network layer
├── bitlib/                       # Bitcoin primitives library (Apache 2.0)
├── lt-api/                       # Local Trader API (Apache 2.0)
├── mbwlib/                       # Shared MBW utilities
├── view/                         # Shared UI components
├── trezor/                       # Trezor hardware wallet support
├── btchip/                       # Ledger hardware wallet support
├── LVL/                          # Android License Verification Library
├── wallet-console/               # Console/CLI wallet tool
├── androidfioserializationprovider/  # FIO serialization
├── fiosdk/                       # FIO SDK integration
├── testhelper/                   # Shared test utilities
└── wallet-android-modularization-tools/  # Modularization tooling (submodule)
    └── modularization-lib/
```

> **Server-only build:** when `MYCELIUM_BUILD_SYSTEM=server` is set, `settings.gradle` skips the app modules and includes only the library modules (`walletcore`, `walletmodel`, `wapi`, `bitlib`, `lt-api`, `mbwlib`, `view`, `testhelper`).

---

## Configuration

### Product Flavors

Defined in `mbw/build.gradle`:

| Flavor | Application ID | Purpose |
|---|---|---|
| `prodnet` | `com.mycelium.wallet` | Main production network build |
| `btctestnet` | *(testnet variant)* | Bitcoin testnet build |
| `huaweiProdnet` | *(Huawei variant)* | Huawei AppGallery production build |

Current version: `versionCode 3210000`, `versionName '3.21.0.0'`

### Version Catalog (`gradle/libs.versions.toml`)

| Key | Value |
|---|---|
| `android-minSdk` | `24` |
| `android-compileSdk` | `36` |
| `android-targetSdk` | `36` |
| `kotlin` | `2.0.21` |
| `androidGradlePlugin` | `8.12.1` |
| `sqldelight` | `2.0.2` |
| `web3j` | `4.12.3` |
| `bouncycastle` | `1.79` |
| `firebaseBomVersion` | `33.10.0` |
| `navigation` | `2.8.8` |
| `jackson` | `2.9.6` |
| KSP | `2.0.21-1.0.28` |

### Legacy ext Settings (`ext_settings.gradle`)

Key dependency versions used by older modules:

```groovy
gsonVersion          = '2.8.5'
okhttpVersion        = '2.7.5'
appCompatVersion     = '1.7.0'
materialVersion      = '1.12.0'
constraintLayoutVersion = '2.2.0'
workManagerVersion   = '2.7.1'
```

---

## Building

All commands use the Gradle wrapper (`./gradlew`). The wrapper automatically downloads Gradle **8.13**.

### Debug Builds

```bash
# Prodnet debug APK
./gradlew mbw:assembleProdnetDebug

# Testnet debug APK
./gradlew mbw:assembleBtctestnetDebug

# All debug APKs
./gradlew mbw:assembleDebug
```

### Release Builds

```bash
# Prodnet release APK
./gradlew mbw:assembleProdnetRelease

# Testnet release APK
./gradlew mbw:assembleBtctestnetRelease

# All release APKs
./gradlew mbw:assembleRelease
```

### AAB (Android App Bundle)

```bash
./gradlew mbw:bundleProdnetRelease
```

### Output Paths

| Artifact | Path |
|---|---|
| Prodnet APK | `mbw/build/outputs/apk/prodnet/release/` |
| Testnet APK | `mbw/build/outputs/apk/btctestnet/release/` |
| Huawei APK | `mbw/build/outputs/apk/huaweiProdnet/release/` |
| AAB | `mbw/build/outputs/bundle/prodnetRelease/` |

### Collect APKs

```bash
# Copies all APKs into /tmp/release_mbw/comp_<timestamp>/
# and creates release_mbw_<versionName>.zip
./collectApks.sh
```

### Full Clean + Test + Build (mirrors CI)

```bash
./gradlew clean test lint build
```

### Server-Only Build (library modules only)

```bash
MYCELIUM_BUILD_SYSTEM=server ./gradlew build
```

### Windows

```bat
gradlew.bat mbw:assembleProdnetDebug
gradlew.bat mbw:assembleProdnetRelease
```

---

## Signing

### Debug Keystore

The project includes a shared debug keystore (`debug.keystore`) with the following credentials (do not use for production):

| Property | Value |
|---|---|
| Store password | `android` |
| Key alias | `androiddebugkey` |
| Key password | `android` |

### Release Signing (`keys.properties`)

Create a `keys.properties` file in the project root (it is gitignored). The file must contain:

```properties
prodKeyStore=/absolute/path/to/keystore_mbwProd
prodKeyAlias=your-prod-alias
prodKeyStorePassword=your-prod-store-password
prodKeyAliasPassword=your-prod-key-password

testKeyStore=/absolute/path/to/keystore_mbwTest
testKeyAlias=your-test-alias
testKeyStorePassword=your-test-store-password
testKeyAliasPassword=your-test-key-password
```

> `keys.properties`, `keystore_mbwProd`, and `keystore_mbwTest` are all listed in `.gitignore` and will never be committed.

### Generating a Keystore

```bash
keytool -genkeypair \
  -keystore keystore_mbwProd \
  -alias your-prod-alias \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000
```

### Enforcing Release Signing in CI

Pass `-PenforceReleaseSigning` to fail the build immediately if `keys.properties` is missing or incomplete:

```bash
./gradlew mbw:assembleProdnetRelease -PenforceReleaseSigning
```

---

## Testing

### Unit Tests

```bash
./gradlew test
```

### Instrumentation Tests (requires connected device/emulator)

```bash
./gradlew connectedAndroidTest
```

### Lint

```bash
./gradlew lint
```

### All Checks

```bash
./gradlew clean test lint
```

---

## APK Verification

```bash
apksigner verify --verbose mbw/build/outputs/apk/prodnet/release/mbw-prodnet-release.apk
```

---

## Deterministic Builds

The project ships a `Dockerfile` for reproducible builds. The image is based on `ubuntu:18.04` and installs:

- `openjdk-17-jdk`
- Android SDK `11076708`
- Build Tools `34.0.0`
- NDK `21.1.6352462`
- CMake `3.22.1`
- Android platform `34`

### Build with Podman or Docker

```bash
# Build the image
podman build -t tethrus-builder .
# (or: docker build -t tethrus-builder .)

# Run the build inside the container
podman run --rm -v "$(pwd)":/workspace -w /workspace tethrus-builder \
  ./gradlew clean mbw:assembleProdnetRelease
```

### Verify Determinism with disorderfs

```bash
# Mount the source directory with randomised directory order
disorderfs --shuffle-dirents=yes /path/to/source /path/to/mount

# Build twice and compare checksums
sha256sum build1.apk build2.apk
```

### checkBuild.sh

```bash
# Usage: ./checkBuild.sh FILE REVISION [RETRIES]
# Requires apktool.jar in the project root
# Works in /tmp/mbwDeterministicBuild/
./checkBuild.sh mbw-prodnet-release.apk <git-revision> 3
```

---

## CI/CD

The project uses GitLab CI (`.gitlab-ci.yml`).

**Build command used in CI:**
```bash
./gradlew clean test lint build $gradleParam -Pbranch=$CI_BUILD_REF_NAME
```

- **`master` branch:** no extra params (full release build)
- **Other branches:** `-PskipProguard` is appended

> **Note:** GitHub Actions is not yet configured for this repository.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| `Could not resolve :wallet-android-modularization-tools` | Submodules not initialised | `git submodule update --init --recursive` |
| `SDK location not found` | Missing `local.properties` | Create `local.properties` with `sdk.dir=/path/to/android/sdk` |
| `Unsupported class file major version` | Wrong JDK version | Ensure `java -version` shows **17**; set `JAVA_HOME` correctly |
| NDK not found errors | NDK not installed | `sdkmanager "ndk;21.1.6352462"` |
| Gradle daemon OOM | Insufficient heap | Already set to `-Xmx4g` in `gradle.properties`; close other applications |
| `keys.properties (No such file or directory)` | Missing signing config | Create `keys.properties` in project root (see [Signing](#signing)) |
| Android SDK 36 not found | `compileSdk 36` requires recent SDK | `sdkmanager "platforms;android-36"` |

---

## License

- **`bitlib`**, **`lt-api`**, **`wapi`** — Apache License 2.0
- Other modules retain their respective upstream licenses.

