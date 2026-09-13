import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_filter.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/services/bill_filter_persistence_service.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/bills_list_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/bill_search_filter_bar.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/bill_filter_bottom_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test Helpers & Mock Data
// ─────────────────────────────────────────────────────────────────────────────
Bill createTestBill({
  required String id,
  required String title,
  required double amount,
  required String category,
  required DateTime date,
  required String paidBy,
  List<String> participantNames = const ['Alice', 'Bob'],
}) {
  return Bill(
    id: id,
    title: title,
    amount: amount,
    category: category,
    date: date,
    paidBy: paidBy,
    participants: participantNames
        .map((name) => BillParticipant(
              participantId: 'p_$name',
              name: name,
              amount: amount / participantNames.length,
            ))
        .toList(),
  );
}

final sampleBills = [
  createTestBill(
    id: 'b1',
    title: 'Pizza Dinner',
    amount: 50.0,
    category: 'Food',
    date: DateTime(2026, 9, 1),
    paidBy: 'Alice',
    participantNames: ['Alice', 'Bob'],
  ),
  createTestBill(
    id: 'b2',
    title: 'Uber Ride',
    amount: 25.0,
    category: 'Transport',
    date: DateTime(2026, 9, 5),
    paidBy: 'Bob',
    participantNames: ['Bob', 'Charlie'],
  ),
  createTestBill(
    id: 'b3',
    title: 'Electricity Bill',
    amount: 120.0,
    category: 'Utilities',
    date: DateTime(2026, 9, 10),
    paidBy: 'Charlie',
    participantNames: ['Alice', 'Bob', 'Charlie'],
  ),
  createTestBill(
    id: 'b4',
    title: 'Cinema Tickets',
    amount: 30.0,
    category: 'Entertainment',
    date: DateTime(2026, 9, 12),
    paidBy: 'Alice',
    participantNames: ['Alice', 'Charlie'],
  ),
  createTestBill(
    id: 'b5',
    title: 'Grocery Shopping',
    amount: 85.0,
    category: 'Food',
    date: DateTime(2026, 9, 15),
    paidBy: 'David',
    participantNames: ['Alice', 'Bob', 'David'],
  ),
];

class _MockSearchLoc extends AppLocalizations {
  _MockSearchLoc(super.locale);

  static const _en = <String, String>{
    'bills': 'Bills',
    'search_bills': 'Search bills',
    'search_hint': 'Search by title or description...',
    'filter': 'Filter',
    'filters': 'Filters',
    'filter_by_person': 'Filter by Person',
    'filter_by_category': 'Filter by Category',
    'filter_by_date': 'Filter by Date Range',
    'filter_by_amount': 'Filter by Amount',
    'all_persons': 'All Persons',
    'all_categories': 'All Categories',
    'select_persons': 'Select Persons',
    'select_categories': 'Select Categories',
    'from_date': 'From Date',
    'to_date': 'To Date',
    'min_amount': 'Min Amount',
    'max_amount': 'Max Amount',
    'amount_range': 'Amount Range',
    'bills_found': 'bills found',
    'bill_found': 'bill found',
    'no_bills': 'No bills yet',
    'no_matching_bills': 'No matching bills found',
    'clear_all_filters': 'Clear all filters',
    'clear_filters': 'Clear Filters',
    'apply_filters': 'Apply Filters',
    'active_filters': 'Active Filters',
    'reset_filters': 'Reset',
    'error': 'Error',
  };

  static const _vi = <String, String>{
    'bills': 'Hóa đơn',
    'search_bills': 'Tìm kiếm hóa đơn',
    'search_hint': 'Tìm theo tên hoặc mô tả...',
    'filter': 'Bộ lọc',
    'filters': 'Bộ lọc',
    'filter_by_person': 'Lọc theo người',
    'filter_by_category': 'Lọc theo danh mục',
    'filter_by_date': 'Lọc theo khoảng thời gian',
    'filter_by_amount': 'Lọc theo số tiền',
    'all_persons': 'Tất cả mọi người',
    'all_categories': 'Tất cả danh mục',
    'select_persons': 'Chọn người tham gia',
    'select_categories': 'Chọn danh mục',
    'from_date': 'Từ ngày',
    'to_date': 'Đến ngày',
    'min_amount': 'Số tiền tối thiểu',
    'max_amount': 'Số tiền tối đa',
    'amount_range': 'Khoảng số tiền',
    'bills_found': 'hóa đơn được tìm thấy',
    'bill_found': 'hóa đơn được tìm thấy',
    'no_bills': 'Chưa có hóa đơn nào',
    'no_matching_bills': 'Không tìm thấy hóa đơn phù hợp',
    'clear_all_filters': 'Xóa tất cả bộ lọc',
    'clear_filters': 'Xóa bộ lọc',
    'apply_filters': 'Áp dụng',
    'active_filters': 'Bộ lọc đang kích hoạt',
    'reset_filters': 'Đặt lại',
    'error': 'Lỗi',
  };

  @override
  String translate(String key) {
    if (locale.languageCode == 'vi') return _vi[key] ?? key;
    return _en[key] ?? key;
  }
}

class _SearchLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SearchLocDelegate();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<AppLocalizations> load(Locale locale) async => _MockSearchLoc(locale);
  @override
  bool shouldReload(_SearchLocDelegate old) => false;
}

class _FakeBillRepo extends Fake implements BillRepository {
  List<Bill> list = [];
  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(list);
  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async =>
      Right(list.where((b) => b.projectId == projectId).toList());
  @override
  Future<Either<Failure, Bill>> create(Bill b) async {
    list.add(b);
    return Right(b);
  }
}

Widget buildTestableWidget(Widget child, {List<Bill>? bills, Locale locale = const Locale('en')}) {
  final repo = _FakeBillRepo()..list = bills ?? List.from(sampleBills);
  final bloc = BillsBloc(
    getBillsUseCase: GetBillsUseCase(repo),
    addBillUseCase: AddBillUseCase(repo),
  );

  return BlocProvider<BillsBloc>.value(
    value: bloc,
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('vi')],
      localizationsDelegates: const [
        _SearchLocDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    BillFilterPersistenceService.resetMemoryFilter();
    SharedPreferences.setMockInitialValues({});
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. BillFilter Unit Tests - Search Criteria (AC 1)
  // ═══════════════════════════════════════════════════════════════════════════
  group('1. BillFilter Search Criteria (AC 1)', () {
    test('1. Matches exact title', () {
      const filter = BillFilter(searchQuery: 'Pizza Dinner');
      expect(filter.matches(sampleBills[0]), isTrue);
      expect(filter.matches(sampleBills[1]), isFalse);
    });

    test('2. Matches case-insensitive title', () {
      const filter = BillFilter(searchQuery: 'pizza');
      expect(filter.matches(sampleBills[0]), isTrue);
    });

    test('3. Matches uppercase query against title', () {
      const filter = BillFilter(searchQuery: 'UBER');
      expect(filter.matches(sampleBills[1]), isTrue);
    });

    test('4. Matches substring inside title', () {
      const filter = BillFilter(searchQuery: 'ectric');
      expect(filter.matches(sampleBills[2]), isTrue);
    });

    test('5. Matches category name via search query', () {
      const filter = BillFilter(searchQuery: 'transport');
      expect(filter.matches(sampleBills[1]), isTrue);
      expect(filter.matches(sampleBills[0]), isFalse);
    });

    test('6. Matches payer name in search query', () {
      const filter = BillFilter(searchQuery: 'Charlie');
      expect(filter.matches(sampleBills[2]), isTrue);
    });

    test('7. Matches participant name in search query', () {
      const filter = BillFilter(searchQuery: 'David');
      expect(filter.matches(sampleBills[4]), isTrue);
    });

    test('8. Empty search query matches any bill', () {
      const filter = BillFilter(searchQuery: '');
      for (final b in sampleBills) {
        expect(filter.matches(b), isTrue);
      }
    });

    test('9. Whitespace-only search query matches any bill', () {
      const filter = BillFilter(searchQuery: '   ');
      for (final b in sampleBills) {
        expect(filter.matches(b), isTrue);
      }
    });

    test('10. Non-matching search query returns false', () {
      const filter = BillFilter(searchQuery: 'NonExistentXYZ');
      for (final b in sampleBills) {
        expect(filter.matches(b), isFalse);
      }
    });

    test('11. Search query with trimmed whitespaces', () {
      const filter = BillFilter(searchQuery: '  Cinema  ');
      expect(filter.matches(sampleBills[3]), isTrue);
    });

    test('12. Search with special characters matching title', () {
      final bill = createTestBill(
        id: 'special',
        title: 'Café & Bánh Mì',
        amount: 20,
        category: 'Food',
        date: DateTime.now(),
        paidBy: 'Alice',
      );
      const filter = BillFilter(searchQuery: 'Bánh');
      expect(filter.matches(bill), isTrue);
    });

    test('13. apply() returns all bills when query is empty', () {
      const filter = BillFilter.initial();
      expect(filter.apply(sampleBills).length, sampleBills.length);
    });

    test('14. apply() filters out non-matching bills', () {
      const filter = BillFilter(searchQuery: 'Food');
      final result = filter.apply(sampleBills);
      expect(result.length, 2);
      expect(result.map((b) => b.id), containsAll(['b1', 'b5']));
    });

    test('15. apply() returns empty list when no bills match', () {
      const filter = BillFilter(searchQuery: 'NoSuchBillEver');
      expect(filter.apply(sampleBills), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. BillFilter Unit Tests - Person Filter (AC 2)
  // ═══════════════════════════════════════════════════════════════════════════
  group('2. BillFilter Person Filter (AC 2)', () {
    test('16. Matches bill when payer is in selectedPersons', () {
      const filter = BillFilter(selectedPersons: {'Alice'});
      expect(filter.matches(sampleBills[0]), isTrue); // Alice paid
      expect(filter.matches(sampleBills[3]), isTrue); // Alice paid
    });

    test('17. Matches bill when participant is in selectedPersons', () {
      const filter = BillFilter(selectedPersons: {'Bob'});
      expect(filter.matches(sampleBills[0]), isTrue); // Bob participant
      expect(filter.matches(sampleBills[1]), isTrue); // Bob payer
      expect(filter.matches(sampleBills[2]), isTrue); // Bob participant
      expect(filter.matches(sampleBills[3]), isFalse); // Alice, Charlie
    });

    test('18. Matches bill when both payer and participant match', () {
      const filter = BillFilter(selectedPersons: {'Alice', 'Bob'});
      expect(filter.matches(sampleBills[0]), isTrue);
    });

    test('19. Does not match bill when person not involved', () {
      const filter = BillFilter(selectedPersons: {'David'});
      expect(filter.matches(sampleBills[0]), isFalse);
      expect(filter.matches(sampleBills[1]), isFalse);
      expect(filter.matches(sampleBills[2]), isFalse);
      expect(filter.matches(sampleBills[3]), isFalse);
      expect(filter.matches(sampleBills[4]), isTrue); // David paid
    });

    test('20. Empty selectedPersons matches any bill', () {
      const filter = BillFilter(selectedPersons: {});
      for (final b in sampleBills) {
        expect(filter.matches(b), isTrue);
      }
    });

    test('21. Multi-person filter matches if ANY selected person is involved (Payer)', () {
      const filter = BillFilter(selectedPersons: {'Bob', 'Charlie'});
      expect(filter.matches(sampleBills[1]), isTrue); // Bob paid
      expect(filter.matches(sampleBills[2]), isTrue); // Charlie paid
    });

    test('22. Multi-person filter matches if ANY selected person is participant', () {
      const filter = BillFilter(selectedPersons: {'Charlie'});
      expect(filter.matches(sampleBills[1]), isTrue); // Charlie participant
      expect(filter.matches(sampleBills[3]), isTrue); // Charlie participant
    });

    test('23. Multi-person filter excludes bills without any selected persons', () {
      const filter = BillFilter(selectedPersons: {'David'});
      final filtered = filter.apply(sampleBills);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'b5');
    });

    test('24. Person filter with unknown person returns empty list', () {
      const filter = BillFilter(selectedPersons: {'UnknownPerson'});
      expect(filter.apply(sampleBills), isEmpty);
    });

    test('25. apply() with single person filter returns correct count', () {
      const filter = BillFilter(selectedPersons: {'Alice'});
      final res = filter.apply(sampleBills);
      expect(res.length, 4);
    });

    test('26. apply() with all persons selected returns all bills', () {
      const filter = BillFilter(selectedPersons: {'Alice', 'Bob', 'Charlie', 'David'});
      expect(filter.apply(sampleBills).length, sampleBills.length);
    });

    test('27. apply() with empty person filter returns original bills', () {
      const filter = BillFilter(selectedPersons: {});
      expect(filter.apply(sampleBills).length, sampleBills.length);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. BillFilter Unit Tests - Category Filter (AC 3)
  // ═══════════════════════════════════════════════════════════════════════════
  group('3. BillFilter Category Filter (AC 3)', () {
    test('28. Matches bill with exact category', () {
      const filter = BillFilter(selectedCategories: {'Transport'});
      expect(filter.matches(sampleBills[1]), isTrue);
      expect(filter.matches(sampleBills[0]), isFalse);
    });

    test('29. Matches bill with case-insensitive category', () {
      const filter = BillFilter(selectedCategories: {'utilities'});
      expect(filter.matches(sampleBills[2]), isTrue);
    });

    test('30. Does not match bill with different category', () {
      const filter = BillFilter(selectedCategories: {'Health'});
      for (final b in sampleBills) {
        expect(filter.matches(b), isFalse);
      }
    });

    test('31. Empty selectedCategories matches any bill', () {
      const filter = BillFilter(selectedCategories: {});
      for (final b in sampleBills) {
        expect(filter.matches(b), isTrue);
      }
    });

    test('32. Multi-category selection matches any selected category', () {
      const filter = BillFilter(selectedCategories: {'Food', 'Entertainment'});
      expect(filter.matches(sampleBills[0]), isTrue); // Food
      expect(filter.matches(sampleBills[3]), isTrue); // Entertainment
      expect(filter.matches(sampleBills[4]), isTrue); // Food
      expect(filter.matches(sampleBills[1]), isFalse); // Transport
      expect(filter.matches(sampleBills[2]), isFalse); // Utilities
    });

    test('33. Multi-category selection excludes unselected category', () {
      const filter = BillFilter(selectedCategories: {'Transport', 'Utilities'});
      expect(filter.matches(sampleBills[0]), isFalse);
      expect(filter.matches(sampleBills[1]), isTrue);
      expect(filter.matches(sampleBills[2]), isTrue);
    });

    test('34. Unknown category returns 0 results', () {
      const filter = BillFilter(selectedCategories: {'Gaming'});
      expect(filter.apply(sampleBills), isEmpty);
    });

    test('35. apply() with single category returns matching subset', () {
      const filter = BillFilter(selectedCategories: {'Food'});
      final res = filter.apply(sampleBills);
      expect(res.length, 2);
      expect(res.every((b) => b.category == 'Food'), isTrue);
    });

    test('36. apply() with all available categories returns all bills', () {
      const filter = BillFilter(
        selectedCategories: {'Food', 'Transport', 'Utilities', 'Entertainment'},
      );
      expect(filter.apply(sampleBills).length, sampleBills.length);
    });

    test('37. apply() with empty category set returns all bills', () {
      const filter = BillFilter(selectedCategories: {});
      expect(filter.apply(sampleBills).length, sampleBills.length);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. BillFilter Unit Tests - Date Range Filter (AC 4)
  // ═══════════════════════════════════════════════════════════════════════════
  group('4. BillFilter Date Range Filter (AC 4)', () {
    test('38. Bill on same day as fromDate matches (start of day inclusive)', () {
      final filter = BillFilter(fromDate: DateTime(2026, 9, 1));
      expect(filter.matches(sampleBills[0]), isTrue);
    });

    test('39. Bill before fromDate does not match', () {
      final filter = BillFilter(fromDate: DateTime(2026, 9, 2));
      expect(filter.matches(sampleBills[0]), isFalse); // b1 is Sept 1
      expect(filter.matches(sampleBills[1]), isTrue);  // b2 is Sept 5
    });

    test('40. Bill after fromDate matches when toDate is null', () {
      final filter = BillFilter(fromDate: DateTime(2026, 9, 10));
      expect(filter.matches(sampleBills[2]), isTrue); // Sept 10
      expect(filter.matches(sampleBills[3]), isTrue); // Sept 12
      expect(filter.matches(sampleBills[4]), isTrue); // Sept 15
    });

    test('41. Bill on same day as toDate matches (end of day inclusive)', () {
      final filter = BillFilter(toDate: DateTime(2026, 9, 5));
      expect(filter.matches(sampleBills[0]), isTrue); // Sept 1
      expect(filter.matches(sampleBills[1]), isTrue); // Sept 5
      expect(filter.matches(sampleBills[2]), isFalse); // Sept 10
    });

    test('42. Bill after toDate does not match', () {
      final filter = BillFilter(toDate: DateTime(2026, 9, 4));
      expect(filter.matches(sampleBills[0]), isTrue);
      expect(filter.matches(sampleBills[1]), isFalse);
    });

    test('43. Bill before toDate matches when fromDate is null', () {
      final filter = BillFilter(toDate: DateTime(2026, 9, 10));
      final res = filter.apply(sampleBills);
      expect(res.length, 3);
    });

    test('44. Bill between fromDate and toDate matches', () {
      final filter = BillFilter(
        fromDate: DateTime(2026, 9, 5),
        toDate: DateTime(2026, 9, 12),
      );
      final res = filter.apply(sampleBills);
      expect(res.length, 3);
    });

    test('45. Bill outside range (earlier) does not match', () {
      final filter = BillFilter(
        fromDate: DateTime(2026, 9, 2),
        toDate: DateTime(2026, 9, 5),
      );
      expect(filter.matches(sampleBills[0]), isFalse);
    });

    test('46. Bill outside range (later) does not match', () {
      final filter = BillFilter(
        fromDate: DateTime(2026, 9, 2),
        toDate: DateTime(2026, 9, 5),
      );
      expect(filter.matches(sampleBills[2]), isFalse);
    });

    test('47. Same day fromDate and toDate matches only bills on that day', () {
      final filter = BillFilter(
        fromDate: DateTime(2026, 9, 5),
        toDate: DateTime(2026, 9, 5),
      );
      final res = filter.apply(sampleBills);
      expect(res.length, 1);
      expect(res.first.id, 'b2');
    });

    test('48. Both dates null matches all bills', () {
      const filter = BillFilter(fromDate: null, toDate: null);
      expect(filter.apply(sampleBills).length, sampleBills.length);
    });

    test('49. Range in future returns empty', () {
      final filter = BillFilter(
        fromDate: DateTime(2027, 1, 1),
        toDate: DateTime(2027, 12, 31),
      );
      expect(filter.apply(sampleBills), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 5. BillFilter Unit Tests - Amount Range Filter (AC 5)
  // ═══════════════════════════════════════════════════════════════════════════
  group('5. BillFilter Amount Range Filter (AC 5)', () {
    test('50. Bill with amount >= minAmount matches', () {
      const filter = BillFilter(minAmount: 50.0);
      expect(filter.matches(sampleBills[0]), isTrue); // 50.0
      expect(filter.matches(sampleBills[1]), isFalse); // 25.0
      expect(filter.matches(sampleBills[2]), isTrue); // 120.0
    });

    test('51. Bill with amount exactly equal to minAmount matches', () {
      const filter = BillFilter(minAmount: 25.0);
      expect(filter.matches(sampleBills[1]), isTrue);
    });

    test('52. Bill with amount < minAmount does not match', () {
      const filter = BillFilter(minAmount: 30.0);
      expect(filter.matches(sampleBills[1]), isFalse);
    });

    test('53. Bill with amount <= maxAmount matches', () {
      const filter = BillFilter(maxAmount: 50.0);
      expect(filter.matches(sampleBills[0]), isTrue);
      expect(filter.matches(sampleBills[1]), isTrue);
      expect(filter.matches(sampleBills[3]), isTrue);
      expect(filter.matches(sampleBills[2]), isFalse);
    });

    test('54. Bill with amount exactly equal to maxAmount matches', () {
      const filter = BillFilter(maxAmount: 120.0);
      expect(filter.matches(sampleBills[2]), isTrue);
    });

    test('55. Bill with amount > maxAmount does not match', () {
      const filter = BillFilter(maxAmount: 84.0);
      expect(filter.matches(sampleBills[4]), isFalse);
    });

    test('56. Bill within [minAmount, maxAmount] range matches', () {
      const filter = BillFilter(minAmount: 30.0, maxAmount: 85.0);
      final res = filter.apply(sampleBills);
      expect(res.length, 3);
      expect(res.map((b) => b.id), containsAll(['b1', 'b4', 'b5']));
    });

    test('57. Bill below range does not match', () {
      const filter = BillFilter(minAmount: 60.0, maxAmount: 100.0);
      expect(filter.matches(sampleBills[0]), isFalse);
      expect(filter.matches(sampleBills[1]), isFalse);
    });

    test('58. Bill above range does not match', () {
      const filter = BillFilter(minAmount: 10.0, maxAmount: 40.0);
      expect(filter.matches(sampleBills[0]), isFalse);
      expect(filter.matches(sampleBills[2]), isFalse);
    });

    test('59. Both minAmount and maxAmount null matches all bills', () {
      const filter = BillFilter(minAmount: null, maxAmount: null);
      expect(filter.apply(sampleBills).length, sampleBills.length);
    });

    test('60. Min equals Max matches only exact amount', () {
      const filter = BillFilter(minAmount: 50.0, maxAmount: 50.0);
      final res = filter.apply(sampleBills);
      expect(res.length, 1);
      expect(res.first.id, 'b1');
    });

    test('61. Min amount higher than all bills returns empty list', () {
      const filter = BillFilter(minAmount: 500.0);
      expect(filter.apply(sampleBills), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 6. BillFilter Unit Tests - Combined Multi-Filters (AC 6)
  // ═══════════════════════════════════════════════════════════════════════════
  group('6. BillFilter Combined Multi-Filters (AC 6)', () {
    test('62. Search + Person matching bill returns true', () {
      const filter = BillFilter(
        searchQuery: 'Pizza',
        selectedPersons: {'Alice'},
      );
      expect(filter.matches(sampleBills[0]), isTrue);
    });

    test('63. Search + Person where search matches but person fails returns false', () {
      const filter = BillFilter(
        searchQuery: 'Pizza',
        selectedPersons: {'David'},
      );
      expect(filter.matches(sampleBills[0]), isFalse);
    });

    test('64. Search + Person where person matches but search fails returns false', () {
      const filter = BillFilter(
        searchQuery: 'Sushi',
        selectedPersons: {'Alice'},
      );
      expect(filter.matches(sampleBills[0]), isFalse);
    });

    test('65. Search + Category matching bill returns true', () {
      const filter = BillFilter(
        searchQuery: 'Dinner',
        selectedCategories: {'Food'},
      );
      expect(filter.matches(sampleBills[0]), isTrue);
    });

    test('66. Search + Category where category fails returns false', () {
      const filter = BillFilter(
        searchQuery: 'Dinner',
        selectedCategories: {'Transport'},
      );
      expect(filter.matches(sampleBills[0]), isFalse);
    });

    test('67. Person + Category matching bill returns true', () {
      const filter = BillFilter(
        selectedPersons: {'Bob'},
        selectedCategories: {'Transport'},
      );
      expect(filter.matches(sampleBills[1]), isTrue);
    });

    test('68. Person + Category where person fails returns false', () {
      const filter = BillFilter(
        selectedPersons: {'Alice'},
        selectedCategories: {'Transport'},
      );
      expect(filter.matches(sampleBills[1]), isFalse);
    });

    test('69. Search + Date Range matching bill returns true', () {
      final filter = BillFilter(
        searchQuery: 'Uber',
        fromDate: DateTime(2026, 9, 1),
        toDate: DateTime(2026, 9, 6),
      );
      expect(filter.matches(sampleBills[1]), isTrue);
    });

    test('70. Search + Date Range where date fails returns false', () {
      final filter = BillFilter(
        searchQuery: 'Uber',
        fromDate: DateTime(2026, 9, 6),
      );
      expect(filter.matches(sampleBills[1]), isFalse);
    });

    test('71. Category + Date Range matching bill returns true', () {
      final filter = BillFilter(
        selectedCategories: {'Utilities'},
        fromDate: DateTime(2026, 9, 9),
        toDate: DateTime(2026, 9, 11),
      );
      expect(filter.matches(sampleBills[2]), isTrue);
    });

    test('72. Person + Date Range matching bill returns true', () {
      final filter = BillFilter(
        selectedPersons: {'Charlie'},
        fromDate: DateTime(2026, 9, 1),
        toDate: DateTime(2026, 9, 15),
      );
      final res = filter.apply(sampleBills);
      expect(res.length, 3);
    });

    test('73. Search + Amount Range matching bill returns true', () {
      const filter = BillFilter(
        searchQuery: 'Grocery',
        minAmount: 50.0,
        maxAmount: 100.0,
      );
      expect(filter.matches(sampleBills[4]), isTrue);
    });

    test('74. Search + Amount Range where amount fails returns false', () {
      const filter = BillFilter(
        searchQuery: 'Grocery',
        maxAmount: 50.0,
      );
      expect(filter.matches(sampleBills[4]), isFalse);
    });

    test('75. Person + Category + Date matching bill returns true', () {
      final filter = BillFilter(
        selectedPersons: {'Alice'},
        selectedCategories: {'Food'},
        fromDate: DateTime(2026, 9, 1),
        toDate: DateTime(2026, 9, 2),
      );
      final res = filter.apply(sampleBills);
      expect(res.length, 1);
      expect(res.first.id, 'b1');
    });

    test('76. Person + Category + Amount matching bill returns true', () {
      const filter = BillFilter(
        selectedPersons: {'Alice'},
        selectedCategories: {'Food'},
        minAmount: 40.0,
        maxAmount: 60.0,
      );
      final res = filter.apply(sampleBills);
      expect(res.length, 1);
      expect(res.first.id, 'b1');
    });

    test('77. Search + Person + Category + Date all match returns true', () {
      final filter = BillFilter(
        searchQuery: 'Tickets',
        selectedPersons: {'Charlie'},
        selectedCategories: {'Entertainment'},
        fromDate: DateTime(2026, 9, 10),
        toDate: DateTime(2026, 9, 15),
      );
      expect(filter.matches(sampleBills[3]), isTrue);
    });

    test('78. Search + Person + Category + Amount all match returns true', () {
      const filter = BillFilter(
        searchQuery: 'Cinema',
        selectedPersons: {'Alice'},
        selectedCategories: {'Entertainment'},
        minAmount: 20.0,
        maxAmount: 50.0,
      );
      expect(filter.matches(sampleBills[3]), isTrue);
    });

    test('79. All 5 criteria (Search + Person + Category + Date + Amount) all match', () {
      final filter = BillFilter(
        searchQuery: 'Cinema',
        selectedPersons: {'Alice'},
        selectedCategories: {'Entertainment'},
        fromDate: DateTime(2026, 9, 11),
        toDate: DateTime(2026, 9, 13),
        minAmount: 20.0,
        maxAmount: 40.0,
      );
      expect(filter.matches(sampleBills[3]), isTrue);
    });

    test('80. All 5 criteria where only amount fails returns false', () {
      final filter = BillFilter(
        searchQuery: 'Cinema',
        selectedPersons: {'Alice'},
        selectedCategories: {'Entertainment'},
        fromDate: DateTime(2026, 9, 11),
        toDate: DateTime(2026, 9, 13),
        minAmount: 35.0,
        maxAmount: 40.0,
      );
      expect(filter.matches(sampleBills[3]), isFalse);
    });

    test('81. All 5 criteria where only date fails returns false', () {
      final filter = BillFilter(
        searchQuery: 'Cinema',
        selectedPersons: {'Alice'},
        selectedCategories: {'Entertainment'},
        fromDate: DateTime(2026, 9, 15),
        toDate: DateTime(2026, 9, 20),
        minAmount: 20.0,
        maxAmount: 40.0,
      );
      expect(filter.matches(sampleBills[3]), isFalse);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 7. BillFilter Unit Tests - Helper Properties, CopyWith & Serialization (AC 7, 8, 9)
  // ═══════════════════════════════════════════════════════════════════════════
  group('7. BillFilter Helper Properties, CopyWith & Serialization (AC 7, 8, 9)', () {
    test('82. isActive is false for initial filter', () {
      const filter = BillFilter.initial();
      expect(filter.isActive, isFalse);
    });

    test('83. isActive is true when searchQuery is set', () {
      const filter = BillFilter(searchQuery: 'pizza');
      expect(filter.isActive, isTrue);
    });

    test('84. isActive is true when selectedPersons is set', () {
      const filter = BillFilter(selectedPersons: {'Alice'});
      expect(filter.isActive, isTrue);
    });

    test('85. isActive is true when selectedCategories is set', () {
      const filter = BillFilter(selectedCategories: {'Food'});
      expect(filter.isActive, isTrue);
    });

    test('86. isActive is true when fromDate is set', () {
      final filter = BillFilter(fromDate: DateTime.now());
      expect(filter.isActive, isTrue);
    });

    test('87. isActive is true when toDate is set', () {
      final filter = BillFilter(toDate: DateTime.now());
      expect(filter.isActive, isTrue);
    });

    test('88. isActive is true when minAmount is set', () {
      const filter = BillFilter(minAmount: 10);
      expect(filter.isActive, isTrue);
    });

    test('89. isActive is true when maxAmount is set', () {
      const filter = BillFilter(maxAmount: 100);
      expect(filter.isActive, isTrue);
    });

    test('90. activeFilterCount counts active dimensions accurately', () {
      final filter = BillFilter(
        searchQuery: 'test',
        selectedPersons: const {'Alice'},
        selectedCategories: const {'Food'},
        fromDate: DateTime.now(),
        minAmount: 10,
      );
      expect(filter.activeFilterCount, 5);
    });

    test('91. nonTextFilterCount ignores search text', () {
      final filter = BillFilter(
        searchQuery: 'test',
        selectedPersons: const {'Alice'},
        selectedCategories: const {'Food'},
      );
      expect(filter.nonTextFilterCount, 2);
    });

    test('92. copyWith creates modified copy without mutating original', () {
      const orig = BillFilter(searchQuery: 'orig', minAmount: 20);
      final copy = orig.copyWith(searchQuery: 'new', maxAmount: 100);
      expect(copy.searchQuery, 'new');
      expect(copy.minAmount, 20);
      expect(copy.maxAmount, 100);
      expect(orig.searchQuery, 'orig');
      expect(orig.maxAmount, isNull);
    });

    test('93. copyWith(clearDates: true) resets both fromDate and toDate', () {
      final orig = BillFilter(
        fromDate: DateTime(2026, 1, 1),
        toDate: DateTime(2026, 1, 31),
      );
      final cleared = orig.copyWith(clearDates: true);
      expect(cleared.fromDate, isNull);
      expect(cleared.toDate, isNull);
    });

    test('94. copyWith(clearAmounts: true) resets both amounts', () {
      const orig = BillFilter(minAmount: 10, maxAmount: 50);
      final cleared = orig.copyWith(clearAmounts: true);
      expect(cleared.minAmount, isNull);
      expect(cleared.maxAmount, isNull);
    });

    test('95. toJson serializes all fields properly', () {
      final date = DateTime(2026, 9, 15);
      final filter = BillFilter(
        searchQuery: 'query',
        selectedPersons: const {'Alice', 'Bob'},
        selectedCategories: const {'Food'},
        fromDate: date,
        toDate: date,
        minAmount: 10.5,
        maxAmount: 99.5,
      );
      final json = filter.toJson();
      expect(json['searchQuery'], 'query');
      expect(json['selectedPersons'], containsAll(['Alice', 'Bob']));
      expect(json['selectedCategories'], contains('Food'));
      expect(json['fromDate'], date.toIso8601String());
      expect(json['minAmount'], 10.5);
      expect(json['maxAmount'], 99.5);
    });

    test('96. fromJson deserializes JSON cleanly', () {
      final dateStr = DateTime(2026, 9, 15).toIso8601String();
      final map = {
        'searchQuery': 'query',
        'selectedPersons': ['Alice', 'Bob'],
        'selectedCategories': ['Food'],
        'fromDate': dateStr,
        'toDate': dateStr,
        'minAmount': 10.5,
        'maxAmount': 99.5,
      };
      final filter = BillFilter.fromJson(map);
      expect(filter.searchQuery, 'query');
      expect(filter.selectedPersons, containsAll(['Alice', 'Bob']));
      expect(filter.selectedCategories, contains('Food'));
      expect(filter.fromDate, DateTime.parse(dateStr));
      expect(filter.minAmount, 10.5);
      expect(filter.maxAmount, 99.5);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 8. BillFilterPersistenceService Unit Tests (AC 9)
  // ═══════════════════════════════════════════════════════════════════════════
  group('8. BillFilterPersistenceService Unit Tests (AC 9)', () {
    test('97. currentFilter starts with initial filter', () {
      expect(BillFilterPersistenceService.currentFilter, const BillFilter.initial());
    });

    test('98. setMemoryFilter updates in-memory filter', () {
      const filter = BillFilter(searchQuery: 'updatedMemory');
      BillFilterPersistenceService.setMemoryFilter(filter);
      expect(BillFilterPersistenceService.currentFilter.searchQuery, 'updatedMemory');
    });

    test('99. resetMemoryFilter restores empty filter', () {
      BillFilterPersistenceService.setMemoryFilter(const BillFilter(searchQuery: 'some'));
      BillFilterPersistenceService.resetMemoryFilter();
      expect(BillFilterPersistenceService.currentFilter, const BillFilter.initial());
    });

    test('100. saveFilter() writes JSON to SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = BillFilterPersistenceService(prefs);
      const filter = BillFilter(searchQuery: 'savedToPrefs', minAmount: 15.0);
      await service.saveFilter(filter);

      final raw = prefs.getString(BillFilterPersistenceService.prefKey);
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      expect(decoded['searchQuery'], 'savedToPrefs');
      expect(decoded['minAmount'], 15.0);
    });

    test('101. loadFilter() reads saved filter from SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      const original = BillFilter(searchQuery: 'fromPrefs', selectedPersons: {'Alice'});
      await prefs.setString(
        BillFilterPersistenceService.prefKey,
        jsonEncode(original.toJson()),
      );

      final service = BillFilterPersistenceService(prefs);
      final loaded = await service.loadFilter();
      expect(loaded.searchQuery, 'fromPrefs');
      expect(loaded.selectedPersons, contains('Alice'));
      expect(BillFilterPersistenceService.currentFilter.searchQuery, 'fromPrefs');
    });

    test('102. clearFilter() removes key from SharedPreferences and resets memory', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(BillFilterPersistenceService.prefKey, '{"searchQuery":"dummy"}');
      final service = BillFilterPersistenceService(prefs);
      await service.clearFilter();

      expect(prefs.containsKey(BillFilterPersistenceService.prefKey), isFalse);
      expect(BillFilterPersistenceService.currentFilter, const BillFilter.initial());
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // 9. Widget Tests - UI Search & Filter, Count & Reset (AC 1-10)
  // ═══════════════════════════════════════════════════════════════════════════
  group('9. Widget Tests - BillsListScreen Search & Filter UI (AC 1-10)', () {
    testWidgets('103. BillsListScreen renders Search TextField and Filter icon button', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen()));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('searchBillsTextField')), findsOneWidget);
      expect(find.byKey(const Key('openFilterSheetButton')), findsOneWidget);
      expect(find.text('5 bills found'), findsOneWidget);
    });

    testWidgets('104. Typing in Search TextField filters bills in real-time', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('searchBillsTextField')), 'Pizza');
      await tester.pumpAndSettle();

      expect(find.text('1 bill found'), findsOneWidget);
      expect(find.text('Pizza Dinner'), findsOneWidget);
      expect(find.text('Uber Ride'), findsNothing);
    });

    testWidgets('105. Clear button (X) appears when typing and clears search query', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('searchBillsTextField')), 'Uber');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('clearSearchQueryButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('clearSearchQueryButton')));
      await tester.pumpAndSettle();

      expect(find.text('5 bills found'), findsOneWidget);
      expect(find.byKey(const Key('clearSearchQueryButton')), findsNothing);
    });

    testWidgets('106. Result count updates to 0 and shows empty state when no bills match', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('searchBillsTextField')), 'NoSuchBillAtAll');
      await tester.pumpAndSettle();

      expect(find.text('0 bills found'), findsOneWidget);
      expect(find.byKey(const Key('noMatchingBillsEmptyState')), findsOneWidget);
      expect(find.byKey(const Key('clearFiltersEmptyStateButton')), findsOneWidget);
    });

    testWidgets('107. Tapping "Clear all filters" button on empty state restores all bills', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('searchBillsTextField')), 'NoSuchBillAtAll');
      await tester.pumpAndSettle();
      expect(find.text('0 bills found'), findsOneWidget);

      await tester.tap(find.byKey(const Key('clearFiltersEmptyStateButton')));
      await tester.pumpAndSettle();

      expect(find.text('5 bills found'), findsOneWidget);
      expect(find.byKey(const Key('noMatchingBillsEmptyState')), findsNothing);
    });

    testWidgets('108. Tapping Filter Sheet button opens bottom sheet modal', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openFilterSheetButton')));
      await tester.pumpAndSettle();

      expect(find.byType(BillFilterBottomSheet), findsOneWidget);
      expect(find.byKey(const Key('applyFiltersButton')), findsOneWidget);
      expect(find.byKey(const Key('resetFiltersButton')), findsOneWidget);
    });

    testWidgets('109. Selecting person chip in filter sheet filters bills list', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openFilterSheetButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('personFilterChip_Alice')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('applyFiltersButton')));
      await tester.pumpAndSettle();

      expect(find.text('4 bills found'), findsOneWidget);
    });

    testWidgets('110. Selecting category chip in filter sheet filters bills list', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openFilterSheetButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('categoryFilterChip_Transport')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('applyFiltersButton')));
      await tester.pumpAndSettle();

      expect(find.text('1 bill found'), findsOneWidget);
      expect(find.text('Uber Ride'), findsOneWidget);
    });

    testWidgets('111. Filter count badge displays on Filter button when filters active', (tester) async {
      const initial = BillFilter(selectedCategories: {'Transport'});
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen(initialFilter: initial)));
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets);
    });

    testWidgets('112. Tapping clearAllFiltersHeaderButton resets all filters', (tester) async {
      const initial = BillFilter(searchQuery: 'Pizza', selectedCategories: {'Food'});
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen(initialFilter: initial)));
      await tester.pumpAndSettle();

      expect(find.text('1 bill found'), findsOneWidget);
      expect(find.byKey(const Key('clearAllFiltersHeaderButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('clearAllFiltersHeaderButton')));
      await tester.pumpAndSettle();

      expect(find.text('5 bills found'), findsOneWidget);
    });

    testWidgets('113. Quick Person Chip opens filter sheet', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('personFilterQuickChip')));
      await tester.pumpAndSettle();

      expect(find.byType(BillFilterBottomSheet), findsOneWidget);
    });

    testWidgets('114. Quick Category Chip opens filter sheet', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('categoryFilterQuickChip')));
      await tester.pumpAndSettle();

      expect(find.byType(BillFilterBottomSheet), findsOneWidget);
    });

    testWidgets('115. Filter Sheet Reset button clears all selections', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const BillsListScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('openFilterSheetButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('personFilterChip_Alice')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('resetFiltersButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('applyFiltersButton')));
      await tester.pumpAndSettle();

      expect(find.text('5 bills found'), findsOneWidget);
    });

    testWidgets('116. Persistence: Filter state survives screen leave and return', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final persistence = BillFilterPersistenceService(prefs);

      await tester.pumpWidget(buildTestableWidget(
        BillsListScreen(key: UniqueKey(), persistenceService: persistence),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('searchBillsTextField')), 'Uber');
      await tester.pumpAndSettle();
      expect(find.text('1 bill found'), findsOneWidget);

      final saved = await persistence.loadFilter();
      expect(saved.searchQuery, 'Uber');

      await tester.pumpWidget(buildTestableWidget(
        BillsListScreen(key: UniqueKey(), persistenceService: persistence),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Uber Ride'), findsOneWidget);
      expect(find.text('1 bill found'), findsOneWidget);
    });

    testWidgets('117. Vietnamese locale displays localized count and search hint', (tester) async {
      await tester.pumpWidget(buildTestableWidget(
        const BillsListScreen(),
        locale: const Locale('vi'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('5 hóa đơn được tìm thấy'), findsOneWidget);
      expect(find.text('Tìm theo tên hoặc mô tả...'), findsOneWidget);
    });
  });
}
