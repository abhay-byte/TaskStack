# Copilot / Agent Instructions

## Environment

This workspace runs inside a **proot-distro environment within Termux on an Android device**.

## Important Constraints

### Terminal Startup Delay
- The terminal takes approximately **1 minute to start/load** due to the proot-distro overhead in Termux.
- **Always prefer VS Code tools** (file editors, search, etc.) over running terminal commands wherever possible.
- Only use the terminal when absolutely necessary (e.g., running builds, installing packages).

### Building & Installing APKs

**Working debug build command** (use this):
```bash
ANDROID_SDK_ROOT=/opt/android-sdk ANDROID_HOME=/opt/android-sdk flutter build apk --debug --split-debug-info=/tmp/flutter_debug
cp build/app/outputs/flutter-apk/app-debug.apk /sdcard/Download/taskstack-debug.apk
```

- APK will be copied to `/sdcard/Download/taskstack-debug.apk` (verified path, no trailing 's')
- Device will have JIT (not AOT), so no `gen_snapshot` needed
- Environment vars are required because `/opt/flutter` is native ARM64 but engine artifacts (gen_snapshot) only have x86-64 versions
- DO NOT use `--release` flag (requires AOT, which would fail; native ARM64 `gen_snapshot` not published by Flutter for this engine version)

#### How the Build Was Fixed

**Problem 1: NDK version mismatch**
- Error: NDK version 28.2.13676358 required but 29.0.14206865 installed
- Fix: Update `android/app/build.gradle.kts` line 11 from `ndkVersion = flutter.ndkVersion` to `ndkVersion = "29.0.14206865"`

**Problem 2: Wrong SDK path**
- Gradle was checking `/usr/lib/android-sdk` (no NDK licenses) instead of `/opt/android-sdk`
- Fix: Always set environment variables before `flutter build`:
  ```bash
  ANDROID_SDK_ROOT=/opt/android-sdk ANDROID_HOME=/opt/android-sdk flutter build...
  ```

**Problem 3: Flutter SDK Architecture Mismatch**
- `/opt/flutter` is correctly ARM64 (native) but its engine artifacts only have x86-64 `gen_snapshot`
- Release builds require AOT (needs `gen_snapshot`), which fails on ARM64
- Debug builds use JIT (no `gen_snapshot`), so they work fine
- Solution: Build as debug only until Flutter publishes native ARM64 engine artifacts for this version
