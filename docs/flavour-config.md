# Flavour Configuration

TaskStack uses **3 flavours** managed by dart-define + gradle productFlavours.

## Flavour Summary

| Flavour | App ID suffix | App name | Backend |
|---|---|---|---|
| `dev` | `.dev` | TaskStack Dev | local/debug |
| `staging` | `.staging` | TaskStack Staging | staging |
| `production` | _(none)_ | TaskStack | production |

## Running a Flavour

```bash
# Development
flutter run --dart-define=FLAVOUR=dev --flavor dev

# Staging
flutter run --dart-define=FLAVOUR=staging --flavor staging

# Production
flutter run --dart-define=FLAVOUR=production --flavor production

# Build release APK (production)
flutter build apk --release --flavor production --dart-define=FLAVOUR=production
```

## Dart-side Flavour Access

```dart
// lib/core/config/app_config.dart
const flavour = String.fromEnvironment('FLAVOUR', defaultValue: 'production');
```

## Android productFlavours

Add to `android/app/build.gradle.kts` `android {}` block:

```kotlin
flavorDimensions += "env"
productFlavors {
    create("dev") {
        dimension = "env"
        applicationIdSuffix = ".dev"
        versionNameSuffix = "-dev"
        resValue("string", "app_name", "TaskStack Dev")
    }
    create("staging") {
        dimension = "env"
        applicationIdSuffix = ".staging"
        versionNameSuffix = "-staging"
        resValue("string", "app_name", "TaskStack Staging")
    }
    create("production") {
        dimension = "env"
        resValue("string", "app_name", "TaskStack")
    }
}
```
