# Shared-61: App Icon & Avatar Redesign (Remove White Border, Multi-Platform Launcher Icons & Settings UI)

## Overview

The CEO provided a new brand emblem/app icon featuring a golden house badge with family, coin (Đ), and upward growth arrow on a blue/teal squircle container.
The original uploaded image included a thick white border/padding around the icon that must be removed.

## Scope of Work

1. **Asset Processing & Border Removal**:
   - Extract the squircle with an exact antialiased rounded rectangle mask (`bx=141.5, by=141.5, r=52.0`).
   - Remove the outer white background and bottom shadow completely, rendering transparent corners (`alpha=0`) outside the squircle.
   - Generate `assets/images/app_icon.png` (512x512 transparent squircle) and `assets/images/app_avatar.png` (512x512 circular emblem avatar).

2. **Launcher Icons Deployment**:
   - **Android**: Replace `res/mipmap-*/ic_launcher.png` across all densities (`mdpi`: 48px, `hdpi`: 72px, `xhdpi`: 96px, `xxhdpi`: 144px, `xxxhdpi`: 192px).
   - **iOS**: Replace all 15 icon resolutions in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (`Icon-App-*`), generating solid-fill corners according to Apple App Store guidelines without alpha transparency.
   - **Web**: Replace `web/icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png`, and `web/favicon.png`.
   - **macOS**: Replace `macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_*.png` (16px to 1024px).

3. **In-App Presentation**:
   - In `SettingsScreen` -> `_buildAboutCard`: Replace generic `Icons.home_work` with `Image.asset('assets/images/app_icon.png')` inside a `ClipRRect(borderRadius: BorderRadius.circular(10))`.
   - Register `assets/images/` in `pubspec.yaml`.

4. **Testing**:
   - All 2179 unit and widget tests pass.
