# Codemagic Setup Guide — wallet-tethrus

This document explains every environment variable used by the Codemagic
`android-release-apk` workflow and provides step-by-step instructions for
a first-time setup.

---

## Table of Contents

1. [Quick-Start Checklist](#quick-start-checklist)
2. [Environment Variables Reference](#environment-variables-reference)
3. [How to Base64-Encode Your Keystore](#how-to-base64-encode-your-keystore)
4. [Connecting the Repository in Codemagic](#connecting-the-repository-in-codemagic)
5. [Creating the `release_signing` Variable Group](#creating-the-release_signing-variable-group)
6. [Triggering Your First Build](#triggering-your-first-build)
7. [Artifacts Location](#artifacts-location)
8. [Troubleshooting](#troubleshooting)

---

## Quick-Start Checklist

- [ ] You have a release keystore (`.jks` / `.keystore`) for signing APKs.
- [ ] The repository is connected to Codemagic.
- [ ] The `release_signing` variable group is created with all required variables.
- [ ] Push to `main` (or tag `v*.*.*`) to trigger the first build.

---

## Environment Variables Reference

All variables live in a **variable group** named **`release_signing`**.
Create it in the Codemagic UI at:
**Teams → Your team → Global variables and secrets**  
or directly in a specific application's **Environment variables** section.

| Variable name | Required | Sensitive | Description |
|---|---|---|---|
| `CM_KEYSTORE` | ✅ Yes | ✅ Yes | Base64-encoded release keystore (`.jks`). See encoding instructions below. |
| `CM_KEYSTORE_PASSWORD` | ✅ Yes | ✅ Yes | Password for the keystore file. |
| `CM_KEY_ALIAS` | ✅ Yes | ✅ Yes | Alias of the private key inside the keystore. |
| `CM_KEY_PASSWORD` | ✅ Yes | ✅ Yes | Password for the private key. |
| `CM_EMAIL_ADDRESS` | ❌ Optional | No | Email address that receives build-result notifications. |
| `CM_TELEGRAM_BOT_TOKEN` | ❌ Optional | ✅ Yes | Telegram bot token for build notifications. Leave empty to skip. |
| `CM_TELEGRAM_CHAT_ID` | ❌ Optional | No | Telegram chat/group ID for notifications. Leave empty to skip. |

---

## How to Base64-Encode Your Keystore

### Linux / macOS

```bash
base64 -w 0 your-release.jks > keystore_b64.txt
cat keystore_b64.txt
```

### macOS (if `-w` flag is not available)

```bash
base64 -i your-release.jks -o keystore_b64.txt
cat keystore_b64.txt
```

### Windows (PowerShell)

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("your-release.jks")) | Out-File keystore_b64.txt -NoNewline
Get-Content keystore_b64.txt
```

Copy the entire single-line output and paste it as the value of `CM_KEYSTORE`.

---

## Connecting the Repository in Codemagic

1. Log in to [codemagic.io](https://codemagic.io).
2. Click **"Add application"**.
3. Choose **GitHub / GitLab / Bitbucket** and grant access to
   `bitbybit91/wallet-tethrus`.
4. Codemagic will detect `codemagic.yaml` automatically.
5. Select the **`android-release-apk`** workflow and click **Save**.

---

## Creating the `release_signing` Variable Group

1. In Codemagic, go to **Teams → [Your team] → Global variables and secrets**.
2. Click **"Add group"** and name it **`release_signing`** (exact name — the
   `codemagic.yaml` references this group).
3. Add each variable from the table above:
   - Toggle **"Secure"** for variables marked ✅ Yes in the Sensitive column.
   - Paste the base64 keystore string as the value of `CM_KEYSTORE`.
4. Click **"Create group"**.
5. In your application settings, under **Environment variables**, click
   **"Import from group"** and select `release_signing`.

---

## Triggering Your First Build

The workflow triggers automatically on:

- Every push to `main` or `master`
- Every tag matching the pattern `v*.*.*`

To start a build manually:

1. Open the application in Codemagic.
2. Select the **`android-release-apk`** workflow.
3. Click **"Start new build"**.

---

## Artifacts Location

After a successful build, the following artifacts are available for download
in the Codemagic build log:

| Artifact | Path in build |
|---|---|
| Prodnet release APK | `mbw/build/outputs/apk/prodnet/release/*.apk` |
| Testnet release APK | `mbw/build/outputs/apk/btctestnet/release/*.apk` |
| ProGuard/R8 mapping | `mbw/build/outputs/mapping/**/*.txt` |
| Native debug symbols | `mbw/build/outputs/native-debug-symbols/**/*.zip` |

---

## Troubleshooting

### "Required environment variable 'CM_KEYSTORE' is missing"

The `release_signing` variable group is not imported into this application.
Go to the application's **Environment variables** tab and import the group.

### "keytool -list failed"

The keystore password or alias is wrong. Verify with:

```bash
keytool -list -v -keystore your-release.jks -storepass YOUR_STORE_PASS -alias YOUR_ALIAS
```

### "Failed to base64-decode CM_KEYSTORE"

The value was not a pure single-line base64 string. Re-encode using
`base64 -w 0` (Linux) and paste **without** line breaks.

### Build fails with "Couldn't load release signing keys!"

`keys.properties` was not generated (the `setup_signing.py` pre-build script
did not run or failed). Check the **"Set up signing"** step in the build log.

### Submodule errors

The workflow runs `git submodule update --init --recursive`. If a submodule
URL has changed, update `.gitmodules` and re-run.
