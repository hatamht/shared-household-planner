# Setup & Project Structure - Shared Household Planner

## Mục đích
Tài liệu này hướng dẫn Member setup project, hiểu cấu trúc folder, và chạy app local.

## Tech Stack
- **Framework**: Flutter
- **Architecture**: Clean Architecture + BLoC pattern
- **State Management**: BLoC
- **Database**: SQLite (hoặc local file storage)
- **Target**: Android + iOS

## Yêu cầu
- Flutter SDK >= 3.0
- Dart >= 3.0
- Android Studio / Xcode (cho emulator)
- Git

## Installation

### 1. Clone & Setup
```bash
cd shared-household-planner
flutter pub get
```

### 2. Generate build files (nếu có)
```bash
# Nếu dùng build_runner
flutter pub run build_runner build
```

### 3. Chạy trên emulator / device
```bash
# Android
flutter run -d emulator-5554

# iOS
flutter run -d iphone
```

## Cấu trúc thư mục

```
lib/
├── main.dart                 # Entry point
├── features/                 # Features theo Clean Arch
│   ├── split_bills/          # Feature chia tiền
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── calendar/             # Feature lịch
│   ├── shopping_list/        # Feature mua sắm
├── core/                     # Shared code
│   ├── network/
│   ├── database/
│   ├── theme/
│   └── constants/
test/                         # Unit tests
integration_test/             # Integration tests
```

## Clean Architecture Pattern

```
presentation (UI) 
    ↓ (BLoC)
domain (Business Logic)
    ↓ (Use Cases)
data (Repositories, Models)
    ↓
External (DB, API)
```

## V1.0 Scope
- Single-user office mode (không multi-user)
- Tính năng chính: chia tiền chuyến đi
- Lưu trữ: SQLite local
- Không cần backend / login

## Hướng dẫn viết code
- Tuân theo BLoC pattern
- Mỗi feature có data/domain/presentation tách biệt
- Unit test cho domain logic (sử dụng mockito)

## Commit & Push
```bash
git add .
git commit -m "Tên commit rõ ràng"
git push origin main
```

---

Sau khi setup xong, báo PM để phê duyệt.
