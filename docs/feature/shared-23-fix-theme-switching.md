# Shared-23: Fix Theme Switching (Dark/Light Mode)

**Layer:** Presentation (UI + State Management)  
**Priority:** High  
**Bug Fix:** Theme toggle button không hoạt động (CEO report 12/9)

---

## Root Cause

Button toggle theme trong `HomeScreen` chỉ hiển thị SnackBar thay vì gọi `ThemeProvider.toggleTheme()`. Import `ThemeProvider` bị thiếu trong `HomeScreen`.

---

## Acceptance Criteria

1. ✅ **Theme toggle UI:** Button dark_mode/light_mode trên AppBar của HomeScreen hoạt động đúng — gọi `ThemeProvider.toggleTheme()` khi nhấn.
2. ✅ **Theme persistence:** Theme được lưu vào SharedPreferences (key: `app_theme_mode`), persist qua app restart.
3. ✅ **Light theme colors:** Backgrounds trắng (#FFFFFF), primary indigo (#6366F1), text đen (Colors.black87), đủ contrast.
4. ✅ **Dark theme colors:** Backgrounds tối (Colors.grey[900], Colors.grey[850]), primary nhạt (#818CF8), text trắng — contrast ratio > 3:1 (WCAG).
5. ✅ **Apply to all screens:** `ThemeProvider` được đăng ký ở `MultiProvider` trong `main.dart`, wrap toàn bộ `MaterialApp` → tất cả screens tự nhận theme.
6. ✅ **Material Theme:** `ThemeData` với `brightness`, `colorScheme`, `textTheme`, `appBarTheme` đầy đủ cho cả light và dark.
7. ✅ **Category colors:** Category brand colors vẫn đọc được trên cả hai theme (màu được lưu dưới dạng hex string, render qua `Color.fromARGB`).
8. ✅ **Dialogs and bottom sheets:** Kế thừa theme từ `MaterialApp` → tự động themed.
9. ✅ **State management:** Dùng `Provider (ChangeNotifier)` — `ThemeProvider` đã đăng ký đúng trong `MultiProvider`.
10. ✅ **i18n:** Keys `light_mode`, `dark_mode`, `theme`, `theme_light`, `theme_dark`, `theme_settings` có trong cả `en.json` và `vi.json`.
11. ✅ **Tests:** 104 tests covering theme toggle, persistence, color consistency, UI rendering, state management, edge cases — tất cả pass.

---

## Changes Made

### `lib/features/home/presentation/pages/home_screen.dart`
- **Import:** Thêm `import 'package:shared_household_planner/core/theme/app_theme.dart'`
- **Provider read:** `final themeProvider = Provider.of<ThemeProvider>(context, listen: true)`
- **Button fix:** `onPressed: () => themeProvider.toggleTheme()` thay cho SnackBar
- **Icon logic:** Dùng `themeProvider.isDarkMode` thay vì `Theme.of(context).brightness`
- **Key:** Thêm `key: const Key('themeToggleButton')` để testability

### `lib/core/localization/translations/en.json`
- Thêm: `"theme_light": "Light Theme"`, `"theme_dark": "Dark Theme"`, `"theme_settings": "Theme Settings"`

### `lib/core/localization/translations/vi.json`
- Thêm: `"theme_light": "Giao diện sáng"`, `"theme_dark": "Giao diện tối"`, `"theme_settings": "Cài đặt giao diện"`

### `test/features/theme/theme_switching_test.dart` [NEW]
- 104 tests across 12 groups: ThemeProvider unit, Light theme colors, Dark theme colors, Toggle UI, Persistence, ThemeData consistency, ChangeNotifier, i18n keys, Widget rebuild, AppTheme properties, ProjectScreen themed, Edge cases.

---

## Verification

- **104/104 new theme tests pass**
- **Full suite** (379 + 104 = 483+ tests) all pass
