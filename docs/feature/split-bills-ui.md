# Split Bills Presentation Layer (UI) - Shared Household Planner

## Mục đích

Xây dựng **presentation layer** (UI screens + BLoC state management) cho feature "Chia tiền chuyến đi" theo Clean Architecture pattern.

Presentation layer chứa:
- **Screens**: BillsListScreen, AddBillScreen, BillDetailScreen
- **BLoC**: BillsBloc (quản lý state danh sách hóa đơn)
- **Widgets**: Bill list, bill card, add bill form, stats card
- **Localization**: Tất cả text dùng i18n (từ t2)
- **Theme**: Light/Dark mode (từ t2)

## Yêu cầu

### Phần 1: Bills List Screen

**Hiển thị:**
- Header: "Hóa đơn" + Settings icon
- Stats card: 2 stat (Tổng chi, Bạn nợ)
- Bill list: Danh sách hóa đơn với:
  - Tên + emoji category
  - Ngày + người thanh toán
  - Số người tham gia
  - Tổng tiền
  - Status indicator (−/+)
- Date grouping: Nhóm theo tháng/năm
- Tab bar: "Hóa đơn" | "Thống kê" | "Bạn bè"
- Button: "➕ Thêm hóa đơn"

**Dữ liệu từ:**
- BillsBloc (lấy từ domain layer t3)
- GetBillsUseCase (từ t3)
- Calculate stats từ danh sách

### Phần 2: Add Bill Form

**Input fields:**
- Tên hóa đơn (TextField)
- Category (Dropdown: Food, Transport, Entertainment, Accommodation, Other)
- Tổng tiền (TextField + NumberFormat)
- Người thanh toán (Dropdown, lấy danh sách từ settings)
- Danh sách chia (MultiSelect checkboxes)
- Date picker (default = hôm nay)

**Action:**
- Button "Lưu": gọi AddBillUseCase (từ t3)
- Button "Hủy": quay lại list

**Validation:**
- Tên không trống
- Tiền > 0
- Ít nhất 2 người trong danh sách chia

### Phần 3: Bill Detail Screen (nếu tap vào bill)

**Hiển thị:**
- Bill info: tên, tiền, ngày, người thanh toán
- Chi tiết chia tiền: từng người tham gia + số tiền họ nợ/được nợ
- Button: "Chỉnh sửa" | "Xóa"

### Phần 4: State Management (BLoC)

**BillsBloc:**
- State: BillsInitial, BillsLoading, BillsLoaded, BillsError
- Event: GetBills, AddBill, UpdateBill, DeleteBill
- Gọi domain layer use cases (t3)

**AddBillBloc:**
- State: Form init, validate, submit, success/error
- Event: FormChanged, Submit

### Phần 5: Localization & Theme

**Localization:**
- Tất cả text dùng i18n (từ t2)
- Strings cần dịch: "Hóa đơn", "Thêm hóa đơn", "Tổng chi", "Bạn nợ", "Người thanh toán", "Danh sách chia", vv
- Support: en, vi

**Theme:**
- Dùng AppTheme (từ t2)
- Light mode: primary=#667eea, background=white
- Dark mode: primary=#667eea, background=dark
- Tất cả card/button áp dụng theme

### Phần 6: Navigation

**Routes:**
- /bills → BillsListScreen
- /bills/add → AddBillScreen
- /bills/:id → BillDetailScreen

**Tab bar navigation:**
- Bills tab → current screen
- Stats tab → StatsScreen (dummy, future)
- Friends tab → FriendsScreen (dummy, future)

## V1.0 Scope

✅ Cần làm:
- BillsListScreen + bill card widget
- AddBillScreen + form validation
- BillsBloc + AddBillBloc
- Stats calculation
- Localization (i18n)
- Theme support (Light/Dark)
- Widget tests

❌ Không làm lúc này:
- Bill detail/edit (làm v1.1)
- StatsScreen UI (làm v1.1)
- FriendsScreen UI (làm v1.1)
- Push notifications
- Sync với backend

## Acceptance Criteria

1. ✓ Bills List Screen hiển thị danh sách hóa đơn từ BillsBloc
2. ✓ Stats card hiển thị "Tổng chi" + "Bạn nợ" (tính từ domain layer)
3. ✓ Add Bill Form có input: name, category, amount, payer, participants
4. ✓ Form validation: tên + tiền > 0 + ít nhất 2 người chia
5. ✓ Date grouping: nhóm bill theo tháng/năm
6. ✓ Bill card widget: emoji category + info + status indicator (−/+)
7. ✓ BillsBloc + AddBillBloc implements UseCase (từ t3)
8. ✓ Localization: tất cả text dùng i18n (docs/i18n-theme.md)
9. ✓ Theme support: Light/Dark mode áp dụng trên tất cả screen
10. ✓ Widget tests: ≥15 test cases (BlocTest, WidgetTest) + fresh clone running OK

## File cấu trúc

```
lib/features/split_bills/presentation/
├── bloc/
│   ├── bills_bloc.dart
│   └── add_bill_bloc.dart
├── pages/
│   ├── bills_list_screen.dart
│   ├── add_bill_screen.dart
│   └── bill_detail_screen.dart
├── widgets/
│   ├── bill_card.dart
│   ├── stats_card.dart
│   ├── bill_form.dart
│   └── bill_list.dart
└── ...

lib/features/split_bills/data/
├── datasources/
│   └── bill_local_datasource.dart (SQLite từ t5)
├── repositories/
│   └── bill_repository_impl.dart
└── models/
    └── bill_model.dart

test/features/split_bills/presentation/
├── bloc/
│   ├── bills_bloc_test.dart
│   └── add_bill_bloc_test.dart
└── widgets/
    ├── bills_list_screen_test.dart
    ├── add_bill_screen_test.dart
    └── bill_card_test.dart
```

## pubspec.yaml (thêm)

```yaml
dependencies:
  flutter_bloc: ^8.1.0        # (đã có từ t1)
  provider: ^6.0.0            # (tùy chọn, nếu dùng StateNotifier thay BLoC)
  intl: ^0.18.1               # (đã có từ t2)
  shared_preferences: ^2.2.0  # (đã có từ t2)

dev_dependencies:
  bloc_test: ^9.1.0           # Test BLoC
  mocktail: ^0.3.0            # Mock dependencies
```

## Reference

- Clean Architecture Presentation: https://resocoder.com/flutter-clean-architecture-tdd
- BLoC pattern: https://bloclibrary.dev/
- Flutter Widget Testing: https://flutter.dev/docs/testing/testing-overview
- Localization: docs/i18n-theme.md (từ t2)
- Theme: docs/i18n-theme.md (từ t2)
- Domain layer: docs/feature/split-bills-domain.md (từ t3)

---

Sau task này xong, UI sẽ hoàn chỉnh và sẵn sàng cho data layer (t5 - SQLite integration).
