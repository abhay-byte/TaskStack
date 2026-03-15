# Fastlane Metadata for TaskStack

This directory contains metadata for F-Droid and Google Play Store listings.

## Structure

```
fastlane/
└── metadata/
    └── android/
        └── en-US/
            ├── title.txt                    # App title (max 50 chars)
            ├── short_description.txt        # Short description (max 80 chars)
            ├── full_description.txt         # Full description (max 500 chars for F-Droid)
            ├── changelogs/
            │   └── 1.txt                    # Changelog for versionCode 1
            └── images/
                ├── icon.png                 # App icon (512x512)
                ├── featureGraphic.png       # Feature graphic (1024x500)
                └── phoneScreenshots/        # Screenshots (max 8)
                    ├── 1.png
                    ├── 2.png
                    └── ...
```

## Usage

### F-Droid
F-Droid automatically uses this metadata when building and publishing the app.

### Google Play Store
Use `fastlane supply` to sync metadata to the Play Console.

## Guidelines

- **Changelogs**: Keep under 500 characters per version
- **Screenshots**: Use high-quality PNG images
- **Descriptions**: Focus on features and benefits, not technical details
- **Localization**: Add additional language directories (e.g., `de-DE/`, `fr-FR/`) for translations

## Taking Screenshots via ADB

```bash
# Take a screenshot and pull it directly to phoneScreenshots/
adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png fastlane/metadata/android/en-US/images/phoneScreenshots/1.png

# Clean up from device
adb shell rm /sdcard/screen.png
```

Replace `1.png` with `2.png`, `3.png`, etc. for additional screenshots.
