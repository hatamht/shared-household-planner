# Internationalization (i18n) + Theme Selection - Shared Household Planner

## Mục đích
Xây dựng foundation để app hỗ trợ đa ngôn ngữ và cho phép người dùng chọn light/dark theme.
Cần làm **trước** các feature khác (vì mỗi screen sẽ cần i18n + theme).

## Yêu cầu

### Phần 1: Internationalization (i18n)

**Ngôn ngữ hỗ trợ:**
- Tiếng Việt (vi)
- Tiếng Anh (en)
- (Thêm ngôn ngữ khác sau V1.0)

**Cách triển khai:**
- Sử dụng package: `flutter_localizations` + `intl` (hoặc `easy_localization` nếu thích)
- Tạo folder `lib/core/localization/` chứa:
  - `localization_delegate.dart` - cấu hình localization
  - `translations/` - file ngôn ngữ (JSON hoặc Dart)
    - `en.json` - Tiếng Anh
    - `vi.json` - Tiếng Việt
  - `app_localizations.dart` - lớp để access chuỗi đa ngôn ngữ

**Strings cần dịch (V1.0):**
- Tên app: "Shared Household Planner"
- Menu: "Home", "Settings", "About"
- Buttons: "Add", "Edit", "Delete", "Save", "Cancel"
- Messages: "Thêm thành công", "Lỗi", vv
- (Thêm dần khi code features)

### Phần 2: Theme Selection

**Themes:**
- Light mode (mặc định)
- Dark mode (tuỳ chọn)

**Cách triển khai:**
- Tạo folder `lib/core/theme/` chứa:
  - `app_theme.dart` - định nghĩa Light + Dark ThemeData
  - `theme_provider.dart` - BLoC/StateNotifier quản lý theme hiện tại
- Lưu preference: `shared_preferences` package
- Sync với system setting (nếu người dùng chọn "System Default")

**Theme config:**
- Color palette: xác định màu Primary, Secondary, Background, Text cho mỗi theme
- Typography: font size, weight cho heading, body, button
- Spacing: margin, padding constants

### Phần 3: Integrasi vào App

**main.dart thay đổi:**
```dart
MaterialApp(
  localizationsDelegates: [/* AppLocalizations delegate */],
  supportedLocales: [Locale('en'), Locale('vi')],
  theme: lightTheme,
  darkTheme: darkTheme,
  themeMode: ThemeMode.system,  // hoặc từ BLoC
  home: HomePage(),
)
```

**Settings screen (sau):**
- Dropdown chọn ngôn ngữ
- Toggle chọn Dark/Light/System

## V1.0 Scope

✅ Cần làm trong task này:
- i18n structure + 2 ngôn ngữ (en, vi)
- Light + Dark theme
- Lưu preference (shared_preferences)
- Test trên emulator (đổi ngôn ngữ + theme)

❌ Không làm lúc này:
- Settings screen UI (làm sau khi có i18n + theme)
- Localization cho features chưa code

## Acceptance Criteria

1. ✓ Folder `lib/core/localization/` + `lib/core/theme/` tồn tại với cấu trúc đúng
2. ✓ `localization_delegate.dart` implement AppLocalizationsDelegate
3. ✓ File `lib/core/localization/translations/{en,vi}.json` chứa ≥20 strings cơ bản
4. ✓ `app_theme.dart` định nghĩa Light + Dark ThemeData (color, typography)
5. ✓ `theme_provider.dart` (BLoC hoặc StateNotifier) quản lý theme state
6. ✓ `shared_preferences` cấu hình lưu + load theme preference
7. ✓ `main.dart` cập nhật: localizationsDelegates, supportedLocales, theme/darkTheme
8. ✓ Chạy trên emulator, đổi ngôn ngữ + theme OK, persist sau khi restart app
9. ✓ Unit test cho theme provider + localization logic (≥3 test cases)
10. ✓ Push lên GitHub, test lại từ fresh clone

## File cấu trúc

```
lib/
├── core/
│   ├── localization/
│   │   ├── app_localizations.dart
│   │   ├── localization_delegate.dart
│   │   ├── translations/
│   │   │   ├── en.json
│   │   │   └── vi.json
│   ├── theme/
│   │   ├── app_theme.dart
│   │   ├── theme_provider.dart
│   ├── constants/
│   │   └── app_colors.dart (nếu cần)
│   └── ...
├── main.dart (cập nhật)
└── ...

pubspec.yaml (thêm):
  - flutter_localizations
  - intl
  - shared_preferences
```

## Reference

- Flutter Localization: https://flutter.dev/docs/development/accessibility-and-localization/internationalization
- Flutter Theme: https://flutter.dev/docs/cookbook/design/themes
- easy_localization package: https://pub.dev/packages/easy_localization (alternative)

---

Sau task này xong, Member sẽ dùng i18n + theme khi code split_bills feature.
