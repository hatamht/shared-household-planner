# Split Bills Domain Layer - Shared Household Planner

## Mục đích
Xây dựng **domain layer** (lớp logic kinh doanh) cho feature "Chia tiền chuyến đi" theo Clean Architecture pattern.

Domain layer chứa:
- **Entities**: Bill (hoá đơn), BillParticipant (người tham gia)
- **Repository interface**: BillRepository (hợp đồng dữ liệu)
- **Use cases**: GetBills, AddBill (logic kinh doanh)
- **Errors**: Failure class (xử lý lỗi)

## Yêu cầu

### Phần 1: Entities

**Bill entity:**
```dart
- id: String (unique)
- description: String (tên hoá đơn)
- totalAmount: double (tổng tiền)
- currency: String (đơn vị tiền: VND, USD)
- date: DateTime (ngày tạo)
- createdBy: String (người tạo)
- participants: List<BillParticipant> (danh sách người tham gia)
```

**BillParticipant entity:**
```dart
- participantId: String (ID người)
- name: String (tên người)
- amount: double (tiền người đó trả)
```

### Phần 2: Repository Interface

**BillRepository (abstract class):**
```dart
- Future<List<Bill>> getBills()
- Future<void> addBill(Bill bill)
- Future<void> updateBill(Bill bill)
- Future<void> deleteBill(String billId)
```

### Phần 3: Use Cases

**GetBillsUseCase:**
- Input: không
- Output: Either<Failure, List<Bill>>
- Logic: gọi repository.getBills()

**AddBillUseCase:**
- Input: Bill
- Output: Either<Failure, void>
- Logic: validate + gọi repository.addBill()

### Phần 4: Error Handling

**Failure class:**
- ServerFailure
- LocalFailure
- NetworkFailure

**UseCase base class:**
- Abstract class với Future<Either<Failure, T>> call()

## V1.0 Scope

✅ Cần làm:
- Entities + Equatable (value equality)
- Repository interface
- 2 use cases (Get, Add)
- Failure class + UseCase base
- Unit tests (≥80% coverage)
- dartz package (Either/Failure)

❌ Không làm lúc này:
- Data layer (repository implementation)
- Presentation layer (UI)
- Database/API integration (sau)

## Acceptance Criteria

1. ✓ File entities/bill.dart + entities/bill_participant.dart tồn tại, extend Equatable
2. ✓ Bill entity có toàn bộ fields: id, description, totalAmount, currency, date, createdBy, participants
3. ✓ BillParticipant entity có fields: participantId, name, amount
4. ✓ BillRepository (abstract class) định nghĩa 4 method CRUD (get, add, update, delete)
5. ✓ GetBillsUseCase + AddBillUseCase implement UseCase base class, return Either<Failure, T>
6. ✓ Failure class có 3 subclasses: ServerFailure, LocalFailure, NetworkFailure
7. ✓ UseCase abstract class có method call() return Future<Either<Failure, T>>
8. ✓ Unit tests cho entities + use cases (≥80% coverage, ≥20 test cases)
9. ✓ pubspec.yaml đã có dartz dependency
10. ✓ Push lên GitHub, test lại từ fresh clone running tests OK

## File cấu trúc

```
lib/features/split_bills/domain/
├── entities/
│   ├── bill.dart
│   └── bill_participant.dart
├── repositories/
│   └── bill_repository.dart
├── usecases/
│   ├── get_bills_usecase.dart
│   └── add_bill_usecase.dart

lib/core/
├── error/
│   └── failure.dart
├── usecases/
│   └── usecase.dart
```

## Reference

- Clean Architecture: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- Dartz Either: https://pub.dev/packages/dartz
- Test patterns: https://flutter.dev/docs/testing

---

Sau task này xong, Member sẽ code **data layer** (repository implementation + models).
