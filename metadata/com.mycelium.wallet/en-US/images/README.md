# F-Droid Image Assets

This directory should contain the following image files required for F-Droid
metadata submission:

## Required

- `icon.png` — App icon, 512×512 px PNG.
  Copy from: `mbw/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
  Or export from: `mbw/res-sources/`

## Optional (but recommended for F-Droid store listing)

- `phoneScreenshots/01.png` — Screenshot 1 (portrait, 1080×1920 px recommended)
- `phoneScreenshots/02.png` — Screenshot 2
- `phoneScreenshots/03.png` — Screenshot 3
- ... up to 8 screenshots

## How to populate

Run the following from the repository root to copy the launcher icon:

```bash
cp mbw/src/main/res/mipmap-xxxhdpi/ic_launcher.png \
   metadata/com.mycelium.wallet/en-US/images/icon.png
```

Screenshots can be captured from a running emulator or device using:

```bash
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png metadata/com.mycelium.wallet/en-US/images/phoneScreenshots/01.png
```
