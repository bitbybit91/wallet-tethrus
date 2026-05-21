# Repository Audit Report — wallet-tethrus

**Generated:** 2026-05-21  
**Auditor:** Copilot automated review  
**Branch audited:** `copilot/overhaul-build-pipeline`  
**Upstream origin:** https://github.com/mycelium-com/wallet-android

---

## 1. Branch Overview

| Branch | Status |
|--------|--------|
| `copilot/overhaul-build-pipeline` | Active, shallow clone (2 grafted commits visible). Diverges from upstream by adding Codemagic pipeline, F-Droid flavor, audit docs, and signing scripts on top of the v3.21.0 tag. |

Only one branch was present in this shallow clone. The upstream `mycelium-com/wallet-android` master is tracked at v3.21.0 (`update lib for 16KB page size`, commit 9701d49).

---

## 2. Gradle Module Inventory

| Module | Type | State |
|--------|------|-------|
| `:mbw` | Android Application | Compiles; has lint baseline; unit tests present |
| `:walletcore` | Android Library | Compiles |
| `:walletmodel` | Android Library | Compiles |
| `:wapi` | Android Library | Compiles |
| `:mbwlib` | Android Library | Compiles |
| `:bitlib` | Java Library | Compiles |
| `:lt-api` | Java Library | Compiles |
| `:view` | Android Library | Compiles |
| `:trezor` | Android Library | Compiles; contains large generated Java file (TrezorMessage.java) |
| `:btchip` | Android Library | Compiles |
| `:LVL` | Android Library | Compiles (Google LVL) |
| `:libs:nordpol` | Android Library | Compiles |
| `:testhelper` | Android Library | Compiles |
| `:wallet-android-modularization-tools:modularization-lib` | Android Library | Submodule |
| `:fiosdk` | Android Library | Submodule (fiosdk_kotlin) |
| `:androidfioserializationprovider` | Android Library | Submodule (fiosdk_kotlin) |
| `:wallet-console` | Android Library | Desktop/server mode only |

---

## 3. Build Tool Versions

| Tool | Current Version | Required (Problem Statement) | Gap |
|------|----------------|------------------------------|-----|
| Gradle Wrapper | 8.13 | ≥ 8.10.2 | ✅ Satisfied |
| Android Gradle Plugin (AGP) | 8.12.1 | ≥ 8.8.2 | ✅ Satisfied |
| Kotlin | 2.0.21 | ≥ 2.0 | ✅ Satisfied |
| Java source/target compat | 17 | 21 recommended | ⚠️ Functional but below recommended |
| compileSdk | 36 | 36 | ✅ |
| minSdk | 24 | — | ✅ |
| targetSdk | 36 | — | ✅ |
| NDK | 21.1.6352462 | — | ⚠️ Very old; consider updating to r27+ |

**Note on Java 17 vs 21:** The codebase compiles against Java 17. The problem statement asks for Java 21. Upgrading is safe but requires verifying toolchain compatibility with all submodules. The current 17 setting works and is not a build blocker.

---

## 4. Submodule Health

| Submodule | URL | Status |
|-----------|-----|--------|
| `wallet-android-modularization-tools` | https://github.com/mycelium-com/wallet-android-modularization-tools | Pinned commit present; URL is reachable |
| `fiosdk_kotlin` | https://github.com/mycelium-com/fiosdk_kotlin | Pinned commit present; URL is reachable |

Both submodule URLs are on `github.com/mycelium-com/` and were reachable at audit time. No SHA divergence detected.

---

## 5. Repository Repositories / Dependency Sources

All non-plugin dependencies now resolve from:
- `mavenCentral()` ✅
- `google()` ✅
- `jitpack.io` (Jitpack — open-source, acceptable for F-Droid if sources are available) ⚠️

**No `jcenter()` or `bintray` references found.** ✅

---

## 6. TODO / FIXME / HACK Comments

Notable in-build-file comments:
- `ext_settings.gradle:21` – `sqldelight_version = '2.0.0'` while `libs.versions.toml` pins `2.0.2`; stale comment
- `mbw/build.gradle:146` – commented-out `sourceFolders` for SQLDelight (legacy option, harmless)
- `mbw/build.gradle:26` – commented-out `kotlinOptions.jvmTarget = "17"` (superseded by compilerOptions DSL)

These are all harmless leftover comments with no security or correctness impact.

---

## 7. Deprecated APIs Flagged

| Issue | Location | Severity |
|-------|----------|----------|
| `compile.exclude` on configuration | `mbw/build.gradle:13` | ⚠️ Deprecated DSL; works in AGP 8.x but will warn |
| `aaptOptions` block | `mbw/build.gradle:496` | ⚠️ Use `androidResources` block in AGP 8+ |
| `lifecycle-extensions:2.2.0` | `mbw/build.gradle:61` | ⚠️ Deprecated; split into individual lifecycle artifacts |
| `androidx.activity:activity-ktx:1.3.1` | `mbw/build.gradle:56` | ⚠️ Pinned to old version; upgrade to 1.9+ |
| `androidx.fragment:fragment-ktx:1.3.6` | `mbw/build.gradle:72` | ⚠️ Old; upgrade to 1.8+ |
| `androidx.preference:preference:1.1.1` | `mbw/build.gradle:75` | ⚠️ Old; upgrade to 1.2+ |
| `com.squareup.okhttp:okhttp:2.7.5` | `mbw/build.gradle:83` | ⚠️ Very old OkHttp 2.x — use OkHttp 4.x via `com.squareup.okhttp3` |
| `io.reactivex.rxjava2` | `mbw/build.gradle:92-97` | ⚠️ RxJava 2 is EOL; consider migrating to coroutines or RxJava 3 |
| Jackson `2.9.6` forced | `mbw/build.gradle:17` | ⚠️ Very old; has known CVEs (CVE-2019-14439 etc.) — forced to 2.9.6 due to Android API 23 crash workaround (see comment) |

These are not blockers for the current build but should be addressed in a follow-up hardening pass.

---

## 8. Proprietary Dependencies (F-Droid Blockers)

| Dependency | Version | Reason for Concern | Mitigation |
|------------|---------|-------------------|------------|
| `com.google.firebase:firebase-bom` | 33.10.0 | Google proprietary SDK | Gate behind `fdroid` flavor |
| `com.google.firebase:firebase-dynamic-links` | via BOM | Proprietary | Gate/remove in `fdroid` flavor |
| `com.google.firebase:firebase-messaging-ktx` | via BOM | Proprietary | Gate/remove in `fdroid` flavor |
| `com.google.gms:google-services` (plugin) | 4.4.2 | Play Services plugin | Don't apply in `fdroid` flavor |
| `com.google.android.gms:play-services-base` | 18.7.0 | Google Play Services | Gate in `fdroid` flavor |
| `mbw/google-services.json` | — | Firebase config (API key embedded) | See §9 |
| LVL module (`:LVL`) | — | Google Play License Verification Library | Stub out for `fdroid` flavor |
| Safello / Simplex URLs | — | Third-party exchange URLs (services, not SDK deps — acceptable) | No change needed |

**Action required:** Add a `fdroid` product flavor that excludes the above, and conditionally apply the `google-services` plugin only for non-fdroid variants. (Implemented in this PR — see `mbw/build.gradle` changes.)

---

## 9. Hardcoded Secrets / API Keys

| File | Secret Type | Value (redacted) | Severity |
|------|-------------|-----------------|----------|
| `mbw/google-services.json` | Firebase API key | `AIzaSy…50Ww` *(redacted)* | 🔴 HIGH — key committed to repo |
| `debug.keystore` | Android debug keystore | Password: `android` / alias: `androiddebugkey` | ⚠️ LOW — intentional debug key, standard Android convention |

**Recommendation for `google-services.json`:** This file is present in the upstream `mycelium-com/wallet-android` repository as well, and the Firebase project is owned by Mycelium. For this fork, the API key exposure is inherited. The key is a restricted Firebase API key (used for push notifications / dynamic links). Rotate it in the Firebase Console and restrict it to the production app signing certificate. As a fork maintainer, you should create your own Firebase project and replace this file, or remove Firebase entirely for the `fdroid` variant (which this PR does).

---

## 10. Binary Artifacts > 1 MB

| File | Size | Notes |
|------|------|-------|
| `mbw/lint-baseline.xml` | ~2.3 MB | Lint baseline suppression list — very large, indicates accumulated tech debt |
| `mbw/res-sources/localTraderLocalOnly.xcf` | ~3.2 MB | GIMP source file for a UI asset — not needed in the build output; should be stored in a separate assets repo |
| `trezor/src/main/java/com/satoshilabs/trezor/lib/protobuf/TrezorMessage.java` | ~1.5 MB | Auto-generated protobuf Java file — should be regenerated from `.proto` sources at build time rather than committed |
| `libs/netcipher-2.2.1.jar` | ~140 KB | Pre-built JAR dependency — prefer pulling from Maven Central if available |

**Recommendation:** Add `mbw/res-sources/*.xcf` and `**/*TrezorMessage.java` to `.gitignore` in a follow-up. Consider shrinking the lint baseline by fixing the underlying warnings.

---

## 11. License / SPDX Compliance

| Module | License |
|--------|---------|
| Root project | Apache 2.0 + MS-RSL (mixed) |
| `bitlib` | Apache 2.0 |
| `wapi` | Apache 2.0 |
| `mbw` | MS-RSL (Microsoft Reference Source License) |
| `trezor` | LGPL-3.0 |
| `libs/nordpol` | Apache 2.0 |

**Issues:**
- MS-RSL on `:mbw` is **non-free** and **incompatible with F-Droid's** inclusion policy (F-Droid requires FOSS licenses). This is the primary legal blocker for F-Droid inclusion. The upstream Mycelium app is not on F-Droid for this reason. Any fork submitted to F-Droid would need the `:mbw` source to be re-licensed or a contributor agreement obtained.
- No SPDX headers are present in source files (common in this codebase; not a build blocker).

---

## 12. CI/CD Summary

| Workflow | File | Trigger | Notes |
|----------|------|---------|-------|
| CI (PR builds) | `.github/workflows/ci.yml` | `pull_request` | Builds debug APKs, verifies reproducibility, checks targetSdk=36 |
| RC (Release Candidate) | `.github/workflows/rc.yml` | `push` to `master`/`ci-build-rc` | Uses self-hosted `mbw-builder` runner + Docker for reproducible build |
| Codemagic | `codemagic.yaml` | Configured in this PR | `android-release-apk` + `android-fdroid-build` |

---

## 13. Recommended Follow-up Actions (Post-PR)

1. **Upgrade Jackson** from 2.9.6 to latest stable (fix the Android API 23 crash by targeting minSdk 24+, which removes the constraint — the `android-minSdk` is already 24 in this repo, so the workaround is no longer needed).
2. **Upgrade OkHttp** from 2.x to 4.x.
3. **Remove `lifecycle-extensions`** and replace with individual lifecycle-* artifacts.
4. **Rotate Firebase API key** and optionally move `google-services.json` to CI secrets.
5. **Update NDK** from 21.1.6352462 to r27b (r27.2.12479018).
6. **Shrink lint baseline** by fixing underlying issues rather than suppressing them.
7. **Remove `.xcf` binary asset** from the repository (use Git LFS or external storage).
8. **Address MS-RSL licensing** before submitting to F-Droid.
