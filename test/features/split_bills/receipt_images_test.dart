import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_household_planner/core/error/failure.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/services/receipt_image_service.dart';
import 'package:shared_household_planner/features/projects/domain/entities/project.dart';
import 'package:shared_household_planner/features/projects/domain/repositories/project_repository.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/create_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/delete_project_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_all_projects_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/get_project_by_id_usecase.dart';
import 'package:shared_household_planner/features/projects/domain/usecases/update_project_usecase.dart';
import 'package:shared_household_planner/features/projects/presentation/bloc/project_bloc.dart';
import 'package:shared_household_planner/features/split_bills/data/datasources/database_helper.dart';
import 'package:shared_household_planner/features/split_bills/data/models/bill_model.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill.dart';
import 'package:shared_household_planner/features/split_bills/domain/entities/bill_participant.dart';
import 'package:shared_household_planner/features/split_bills/domain/repositories/bill_repository.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/add_bill_usecase.dart';
import 'package:shared_household_planner/features/split_bills/domain/usecases/get_bills_usecase.dart';
import 'package:shared_household_planner/features/split_bills/presentation/bloc/bills_bloc.dart';
import 'package:shared_household_planner/features/split_bills/presentation/pages/add_bill_screen.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/bill_card.dart';
import 'package:shared_household_planner/features/split_bills/presentation/widgets/receipt_viewer_modal.dart';

class FakeBillRepository implements BillRepository {
  final List<Bill> bills = [];

  @override
  Future<Either<Failure, Bill>> create(Bill bill) async {
    bills.add(bill);
    return Right(bill);
  }

  @override
  Future<Either<Failure, List<Bill>>> getAll() async => Right(List.from(bills));

  @override
  Future<Either<Failure, Bill>> getById(String billId) async =>
      Right(bills.firstWhere((b) => b.id == billId));

  @override
  Future<Either<Failure, Bill>> update(Bill bill) async {
    final idx = bills.indexWhere((b) => b.id == bill.id);
    if (idx >= 0) {
      bills[idx] = bill;
    } else {
      bills.add(bill);
    }
    return Right(bill);
  }

  @override
  Future<Either<Failure, void>> delete(String billId) async {
    bills.removeWhere((b) => b.id == billId);
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Bill>>> getBillsByProjectId(String projectId) async =>
      Right(bills.where((b) => b.projectId == projectId).toList());
}

class FakeProjectRepository implements ProjectRepository {
  final List<Project> projects = [];

  @override
  Future<Either<Failure, List<Project>>> getAll() async => Right(List.from(projects));

  @override
  Future<Either<Failure, Project>> create(Project project) async {
    projects.add(project);
    return Right(project);
  }

  @override
  Future<Either<Failure, Project>> getById(String id) async =>
      Right(projects.firstWhere((p) => p.id == id));

  @override
  Future<Either<Failure, Project>> update(Project project) async => Right(project);

  @override
  Future<Either<Failure, void>> delete(String id) async => const Right(null);
}

class TestAppLocalizations extends AppLocalizations {
  TestAppLocalizations(Locale locale) : super(locale);

  static const Map<String, String> _enStrings = {
    'add_bill': 'Add Bill',
    'edit_bill': 'Edit Bill',
    'bill_name': 'Bill Name',
    'bill_name_required': 'Bill name is required',
    'amount': 'Amount',
    'amount_required': 'Amount is required',
    'amount_must_be_positive': 'Amount must be positive',
    'category': 'Category',
    'payer': 'Payer',
    'payer_required': 'Payer is required',
    'paid_by_label': 'Paid by',
    'participants': 'participants',
    'min_2_participants': 'At least 2 participants required',
    'cancel': 'Cancel',
    'delete': 'Delete',
    'close': 'Close',
    'previous': 'Previous',
    'next_page': 'Next',
    'image': 'Image',
    'gallery': 'Gallery',
    'camera': 'Camera',
    'remove_image': 'Remove Image',
    'receipts': 'Receipts',
    'receipt_images': 'Receipt Images',
    'add_receipt': 'Add Receipt',
    'attach_receipt': 'Attach Receipt',
    'view_receipt': 'View Receipt',
    'receipt_gallery': 'Receipt Gallery',
    'receipt_count': '{count} photos',
    'delete_receipt': 'Delete Receipt',
    'delete_receipt_confirm': 'Are you sure you want to delete this receipt image?',
    'no_receipt': 'No receipt attached',
    'receipt_preview': 'Receipt Preview',
    'category_restaurant': 'Restaurant',
    'category_transport': 'Transport',
    'category_shopping': 'Shopping',
    'category_health': 'Health',
    'category_entertainment': 'Entertainment',
    'category_travel': 'Travel',
    'category_utilities': 'Utilities',
    'category_education': 'Education',
    'category_party': 'Party',
    'category_office': 'Office',
    'category_pet': 'Pet',
    'category_sport': 'Sport',
    'category_food': 'Food',
  };

  static const Map<String, String> _viStrings = {
    'add_bill': 'Thêm hóa đơn',
    'edit_bill': 'Sửa hóa đơn',
    'bill_name': 'Tên hóa đơn',
    'bill_name_required': 'Vui lòng nhập tên hóa đơn',
    'amount': 'Số tiền',
    'amount_required': 'Vui lòng nhập số tiền',
    'amount_must_be_positive': 'Số tiền phải lớn hơn 0',
    'category': 'Danh mục',
    'payer': 'Người trả',
    'payer_required': 'Vui lòng nhập người trả',
    'paid_by_label': 'Người trả',
    'participants': 'người tham gia',
    'min_2_participants': 'Cần ít nhất 2 người tham gia',
    'cancel': 'Hủy',
    'delete': 'Xóa',
    'close': 'Đóng',
    'previous': 'Trước',
    'next_page': 'Tiếp theo',
    'image': 'Hình ảnh',
    'gallery': 'Thư viện ảnh',
    'camera': 'Chụp ảnh',
    'remove_image': 'Xóa ảnh',
    'receipts': 'Hóa đơn đính kèm',
    'receipt_images': 'Ảnh hóa đơn',
    'add_receipt': 'Thêm ảnh hóa đơn',
    'attach_receipt': 'Đính kèm hóa đơn',
    'view_receipt': 'Xem ảnh hóa đơn',
    'receipt_gallery': 'Bộ sưu tập hóa đơn',
    'receipt_count': '{count} hình ảnh',
    'delete_receipt': 'Xóa hóa đơn',
    'delete_receipt_confirm': 'Bạn có chắc muốn xóa ảnh hóa đơn này không?',
    'no_receipt': 'Chưa đính kèm hóa đơn',
    'receipt_preview': 'Xem trước hóa đơn',
    'category_restaurant': 'Ăn uống',
    'category_transport': 'Di chuyển',
    'category_shopping': 'Mua sắm',
    'category_health': 'Y tế',
    'category_entertainment': 'Giải trí',
    'category_travel': 'Du lịch',
    'category_utilities': 'Hóa đơn',
    'category_education': 'Giáo dục',
    'category_party': 'Tiệc tùng',
    'category_office': 'Công sở',
    'category_pet': 'Thú cưng',
    'category_sport': 'Thể thao',
    'category_food': 'Ăn uống',
  };

  @override
  String translate(String key) {
    if (locale.languageCode == 'vi') {
      return _viStrings[key] ?? key;
    }
    return _enStrings[key] ?? key;
  }
}

class TestAppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const TestAppLocalizationsDelegate();
  @override
  bool isSupported(Locale locale) => ['en', 'vi'].contains(locale.languageCode);
  @override
  Future<AppLocalizations> load(Locale locale) async => TestAppLocalizations(locale);
  @override
  bool shouldReload(TestAppLocalizationsDelegate old) => false;
}

Widget createTestWidget(
  Widget child, {
  Locale locale = const Locale('en'),
  ThemeMode themeMode = ThemeMode.light,
  BillsBloc? billsBloc,
  ProjectBloc? projectBloc,
  BillRepository? billRepository,
}) {
  final fakeBillRepo = FakeBillRepository();
  final effectiveBillRepo = billRepository ?? fakeBillRepo;
  final effectiveBillsBloc = billsBloc ??
      BillsBloc(
        getBillsUseCase: GetBillsUseCase(effectiveBillRepo),
        addBillUseCase: AddBillUseCase(effectiveBillRepo),
      );

  final fakeProjectRepo = FakeProjectRepository();
  final effectiveProjectBloc = projectBloc ??
      ProjectBloc(
        getAllProjectsUseCase: GetAllProjectsUseCase(fakeProjectRepo),
        getProjectByIdUseCase: GetProjectByIdUseCase(fakeProjectRepo),
        createProjectUseCase: CreateProjectUseCase(fakeProjectRepo),
        updateProjectUseCase: UpdateProjectUseCase(fakeProjectRepo),
        deleteProjectUseCase: DeleteProjectUseCase(fakeProjectRepo),
      );

  return MultiRepositoryProvider(
    providers: [
      RepositoryProvider<BillRepository>.value(value: effectiveBillRepo),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider<BillsBloc>.value(value: effectiveBillsBloc),
        BlocProvider<ProjectBloc>.value(value: effectiveProjectBloc),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: const [Locale('en'), Locale('vi')],
        localizationsDelegates: const [
          TestAppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        home: Material(child: child),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    await initializeDateFormatting('en', null);
    await initializeDateFormatting('vi', null);
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('receipt_test_');
    ReceiptImageService.setOverrideDirectory(tempDir);
  });

  tearDown(() {
    ReceiptImageService.setOverrideDirectory(null);
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('ReceiptImageService Unit Tests', () {
    test('1. Sets and gets override directory properly', () async {
      final dir = await ReceiptImageService.getReceiptsDirectory();
      expect(dir.path, equals(tempDir.path));
      expect(dir.existsSync(), isTrue);
    });

    test('2. Saves receipt from valid local file path', () async {
      final sample = File('${tempDir.path}/source.jpg')..writeAsStringSync('dummy image content');
      final savedPath = await ReceiptImageService.saveReceiptFromPath(sample.path, billId: 'bill_1');

      expect(File(savedPath).existsSync(), isTrue);
      expect(savedPath.contains('receipt_bill_1_'), isTrue);
      expect(savedPath.endsWith('.jpg'), isTrue);
    });

    test('3. Returns original path if source file does not exist', () async {
      const nonExistent = '/invalid/path/photo.png';
      final res = await ReceiptImageService.saveReceiptFromPath(nonExistent);
      expect(res, equals(nonExistent));
    });

    test('4. Saves receipt raw bytes into storage', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final savedPath = await ReceiptImageService.saveReceiptBytes(bytes, billId: 'b2', extension: 'png');

      expect(File(savedPath).existsSync(), isTrue);
      expect(savedPath.contains('receipt_b2_'), isTrue);
      expect(savedPath.endsWith('.png'), isTrue);
      expect(File(savedPath).readAsBytesSync(), equals(bytes));
    });

    test('5. Deletes existing receipt file and returns true', () async {
      final file = File('${tempDir.path}/test_del.jpg')..writeAsStringSync('del');
      expect(file.existsSync(), isTrue);

      final success = await ReceiptImageService.deleteReceipt(file.path);
      expect(success, isTrue);
      expect(file.existsSync(), isFalse);
    });

    test('6. Deleting non-existent file returns false without throwing', () async {
      final success = await ReceiptImageService.deleteReceipt('${tempDir.path}/none.jpg');
      expect(success, isFalse);
    });

    test('7. receiptExists checks file existence correctly', () {
      final file = File('${tempDir.path}/exists.jpg')..writeAsStringSync('ok');
      expect(ReceiptImageService.receiptExists(file.path), isTrue);
      expect(ReceiptImageService.receiptExists('${tempDir.path}/missing.jpg'), isFalse);
      expect(ReceiptImageService.receiptExists(null), isFalse);
      expect(ReceiptImageService.receiptExists(''), isFalse);
    });

    test('8. Calculates total receipt storage bytes and count', () async {
      expect(await ReceiptImageService.getTotalReceiptStorageBytes(), equals(0));
      expect(await ReceiptImageService.getReceiptCount(), equals(0));

      await ReceiptImageService.saveReceiptBytes(Uint8List.fromList([1, 2, 3, 4]));
      await ReceiptImageService.saveReceiptBytes(Uint8List.fromList([5, 6, 7, 8, 9, 10]));

      expect(await ReceiptImageService.getReceiptCount(), equals(2));
      expect(await ReceiptImageService.getTotalReceiptStorageBytes(), equals(10));
    });

    test('9. Clears all receipts from directory', () async {
      await ReceiptImageService.saveReceiptBytes(Uint8List.fromList([1, 2]));
      await ReceiptImageService.saveReceiptBytes(Uint8List.fromList([3, 4]));
      expect(await ReceiptImageService.getReceiptCount(), equals(2));

      await ReceiptImageService.clearAllReceipts();
      expect(await ReceiptImageService.getReceiptCount(), equals(0));
      expect(await ReceiptImageService.getTotalReceiptStorageBytes(), equals(0));
    });

    test('10. formatStorageSize formats bytes, KB, and MB accurately', () {
      expect(ReceiptImageService.formatStorageSize(500), equals('500 B'));
      expect(ReceiptImageService.formatStorageSize(1024), equals('1.0 KB'));
      expect(ReceiptImageService.formatStorageSize(1536), equals('1.5 KB'));
      expect(ReceiptImageService.formatStorageSize(1024 * 1024), equals('1.0 MB'));
      expect(ReceiptImageService.formatStorageSize((2.5 * 1024 * 1024).round()), equals('2.5 MB'));
    });

    test('11. isValidImageExtension validates popular image extensions', () {
      expect(ReceiptImageService.isValidImageExtension('test.jpg'), isTrue);
      expect(ReceiptImageService.isValidImageExtension('test.JPEG'), isTrue);
      expect(ReceiptImageService.isValidImageExtension('test.png'), isTrue);
      expect(ReceiptImageService.isValidImageExtension('test.webp'), isTrue);
      expect(ReceiptImageService.isValidImageExtension('test.heic'), isTrue);
      expect(ReceiptImageService.isValidImageExtension('test.pdf'), isFalse);
      expect(ReceiptImageService.isValidImageExtension('test.txt'), isFalse);
      expect(ReceiptImageService.isValidImageExtension('test'), isFalse);
    });
  });

  group('Bill Entity Multi-Image & Backward Compatibility Tests', () {
    test('12. Bill entity default constructor sets empty imagePaths', () {
      final bill = Bill(
        id: '1',
        title: 'Lunch',
        amount: 100,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Alice',
        participants: const [],
      );

      expect(bill.imagePaths, isEmpty);
      expect(bill.imagePath, isNull);
      expect(bill.effectiveImagePaths, isEmpty);
      expect(bill.effectiveImagePath, isNull);
      expect(bill.hasReceipt, isFalse);
      expect(bill.receiptCount, equals(0));
    });

    test('13. Bill entity preserves backward compatible imagePath single field', () {
      final bill = Bill(
        id: '1',
        title: 'Coffee',
        amount: 50,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Alice',
        participants: const [],
        imagePath: '/path/single.jpg',
      );

      expect(bill.imagePath, equals('/path/single.jpg'));
      expect(bill.imagePaths, isEmpty);
      expect(bill.effectiveImagePaths, equals(['/path/single.jpg']));
      expect(bill.effectiveImagePath, equals('/path/single.jpg'));
      expect(bill.hasReceipt, isTrue);
      expect(bill.receiptCount, equals(1));
    });

    test('14. Bill entity supports multiple imagePaths', () {
      final bill = Bill(
        id: '1',
        title: 'Supermarket',
        amount: 300,
        category: 'shopping',
        date: DateTime.now(),
        paidBy: 'Bob',
        participants: const [],
        imagePaths: const ['/path/1.jpg', '/path/2.jpg', '/path/3.jpg'],
      );

      expect(bill.imagePaths.length, equals(3));
      expect(bill.effectiveImagePaths.length, equals(3));
      expect(bill.effectiveImagePath, equals('/path/1.jpg'));
      expect(bill.hasReceipt, isTrue);
      expect(bill.receiptCount, equals(3));
    });

    test('15. effectiveImagePaths prioritizes imagePaths over imagePath', () {
      final bill = Bill(
        id: '1',
        title: 'Dinner',
        amount: 200,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Charlie',
        participants: const [],
        imagePath: '/old/single.jpg',
        imagePaths: const ['/new/1.jpg', '/new/2.jpg'],
      );

      expect(bill.effectiveImagePaths, equals(['/new/1.jpg', '/new/2.jpg']));
      expect(bill.effectiveImagePath, equals('/old/single.jpg'));
    });

    test('16. Bill equality check includes imagePaths', () {
      final date = DateTime(2026, 9, 13);
      final b1 = Bill(
        id: '1',
        title: 'Gas',
        amount: 100,
        category: 'transport',
        date: date,
        paidBy: 'Dan',
        participants: const [],
        imagePaths: const ['/a.jpg'],
      );
      final b2 = Bill(
        id: '1',
        title: 'Gas',
        amount: 100,
        category: 'transport',
        date: date,
        paidBy: 'Dan',
        participants: const [],
        imagePaths: const ['/a.jpg'],
      );
      final b3 = Bill(
        id: '1',
        title: 'Gas',
        amount: 100,
        category: 'transport',
        date: date,
        paidBy: 'Dan',
        participants: const [],
        imagePaths: const ['/b.jpg'],
      );

      expect(b1, equals(b2));
      expect(b1 == b3, isFalse);
    });
  });

  group('BillModel Serialization Tests', () {
    test('17. fromJson parses stringified JSON imagePaths list', () {
      final json = {
        'id': 'b1',
        'title': 'Dinner',
        'amount': 150.0,
        'category': 'food',
        'date': DateTime.now().toIso8601String(),
        'paidBy': 'Alice',
        'participants': jsonEncode([
          {'participantId': 'p1', 'name': 'Alice', 'amount': 75.0},
          {'participantId': 'p2', 'name': 'Bob', 'amount': 75.0},
        ]),
        'imagePaths': jsonEncode(['/receipts/1.jpg', '/receipts/2.jpg']),
      };

      final model = BillModel.fromJson(json);
      expect(model.imagePaths, equals(['/receipts/1.jpg', '/receipts/2.jpg']));
      expect(model.hasReceipt, isTrue);
      expect(model.receiptCount, equals(2));
      expect(model.effectiveImagePath, equals('/receipts/1.jpg'));
    });

    test('18. fromJson parses raw List imagePaths', () {
      final json = {
        'id': 'b2',
        'title': 'Taxi',
        'amount': 80.0,
        'category': 'transport',
        'date': DateTime.now().toIso8601String(),
        'paidBy': 'Bob',
        'participants': [],
        'imagePaths': ['/img1.png', '/img2.png'],
      };

      final model = BillModel.fromJson(json);
      expect(model.imagePaths, equals(['/img1.png', '/img2.png']));
    });

    test('19. fromJson falls back to single imagePath when imagePaths missing', () {
      final json = {
        'id': 'b3',
        'title': 'Hotel',
        'amount': 500.0,
        'category': 'travel',
        'date': DateTime.now().toIso8601String(),
        'paidBy': 'Alice',
        'participants': [],
        'imagePath': '/legacy/receipt.jpg',
      };

      final model = BillModel.fromJson(json);
      expect(model.imagePath, equals('/legacy/receipt.jpg'));
      expect(model.imagePaths, equals(['/legacy/receipt.jpg']));
      expect(model.effectiveImagePaths, equals(['/legacy/receipt.jpg']));
    });

    test('20. fromJson handles malformed imagePaths JSON gracefully', () {
      final json = {
        'id': 'b4',
        'title': 'Coffee',
        'amount': 30.0,
        'category': 'food',
        'date': DateTime.now().toIso8601String(),
        'paidBy': 'Alice',
        'participants': [],
        'imagePaths': '{invalid json}',
        'imagePath': '/fallback.jpg',
      };

      final model = BillModel.fromJson(json);
      expect(model.imagePaths, equals(['/fallback.jpg']));
      expect(model.effectiveImagePath, equals('/fallback.jpg'));
    });

    test('21. toJson serializes imagePaths as JSON string and sets imagePath', () {
      final model = BillModel(
        id: 'b5',
        title: 'Electricity',
        amount: 250.0,
        category: 'utilities',
        date: DateTime(2026, 9, 1),
        paidBy: 'Bob',
        participants: const [],
        imagePaths: const ['/p1.jpg', '/p2.jpg'],
      );

      final json = model.toJson();
      expect(json['imagePath'], equals('/p1.jpg'));
      expect(json['imagePaths'], equals(jsonEncode(['/p1.jpg', '/p2.jpg'])));
    });

    test('22. toJson omits imagePath and imagePaths when empty', () {
      final model = BillModel(
        id: 'b6',
        title: 'Water',
        amount: 50.0,
        category: 'utilities',
        date: DateTime(2026, 9, 1),
        paidBy: 'Bob',
        participants: const [],
      );

      final json = model.toJson();
      expect(json.containsKey('imagePath'), isFalse);
      expect(json.containsKey('imagePaths'), isFalse);
    });

    test('23. BillModel.fromEntity converts entity with multiple imagePaths', () {
      final entity = Bill(
        id: 'b7',
        title: 'Party',
        amount: 400.0,
        category: 'party',
        date: DateTime(2026, 9, 2),
        paidBy: 'Charlie',
        participants: const [],
        imagePaths: const ['/party1.jpg', '/party2.jpg'],
        imagePath: '/party1.jpg',
      );

      final model = BillModel.fromEntity(entity);
      expect(model.id, equals(entity.id));
      expect(model.imagePaths, equals(entity.imagePaths));
      expect(model.imagePath, equals(entity.imagePath));
    });
  });

  group('DatabaseHelper v6 Schema Verification Tests', () {
    test('24. DatabaseHelper singleton instance exists', () {
      final helper = DatabaseHelper();
      expect(helper, isNotNull);
    });
  });

  group('BillCard Receipt Thumbnail Widget Tests', () {
    testWidgets('25. BillCard without receipts renders standard card without thumbnail', (tester) async {
      final bill = Bill(
        id: 'b1',
        title: 'No Receipt Bill',
        amount: 100000,
        category: 'food',
        date: DateTime(2026, 9, 10),
        paidBy: 'Alice',
        participants: const [
          BillParticipant(participantId: '1', name: 'Alice', amount: 50000),
          BillParticipant(participantId: '2', name: 'Bob', amount: 50000),
        ],
      );

      await tester.pumpWidget(createTestWidget(BillCard(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.text('No Receipt Bill'), findsOneWidget);
      expect(find.byKey(const Key('billReceiptThumbnail')), findsNothing);
      expect(find.byKey(const Key('receiptCountBadge')), findsNothing);
    });

    testWidgets('26. BillCard with single receipt displays billReceiptThumbnail', (tester) async {
      final sample = File('${tempDir.path}/card_rec.jpg')..writeAsStringSync('dummy');
      final bill = Bill(
        id: 'b2',
        title: 'Single Receipt Bill',
        amount: 150000,
        category: 'food',
        date: DateTime(2026, 9, 10),
        paidBy: 'Alice',
        participants: const [],
        imagePaths: [sample.path],
      );

      await tester.pumpWidget(createTestWidget(BillCard(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billReceiptThumbnail')), findsOneWidget);
      expect(find.byKey(Key('billReceiptThumbnail_${bill.id}')), findsOneWidget);
      expect(find.byKey(const Key('receiptCountBadge')), findsNothing);
    });

    testWidgets('27. BillCard with multiple receipts displays counter badge (+N)', (tester) async {
      final bill = Bill(
        id: 'b3',
        title: 'Multi Receipt Bill',
        amount: 250000,
        category: 'shopping',
        date: DateTime(2026, 9, 11),
        paidBy: 'Bob',
        participants: const [],
        imagePaths: const ['/mock/1.jpg', '/mock/2.jpg', '/mock/3.jpg'],
      );

      await tester.pumpWidget(createTestWidget(BillCard(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('billReceiptThumbnail')), findsOneWidget);
      expect(find.byKey(const Key('receiptCountBadge')), findsOneWidget);
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('28. Tapping billReceiptThumbnail opens ReceiptViewerModal', (tester) async {
      final bill = Bill(
        id: 'b4',
        title: 'Receipt Tap Bill',
        amount: 200000,
        category: 'entertainment',
        date: DateTime(2026, 9, 12),
        paidBy: 'Alice',
        participants: const [],
        imagePaths: const ['/mock/rec.jpg'],
      );

      await tester.pumpWidget(createTestWidget(BillCard(bill: bill)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('billReceiptThumbnail')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptViewerModal')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('receiptViewerModal')), matching: find.text('Receipt Tap Bill')), findsOneWidget);
    });

    testWidgets('29. Tapping BillCard itself opens ReceiptViewerModal when receipt attached', (tester) async {
      final bill = Bill(
        id: 'b5',
        title: 'Card Tap Bill',
        amount: 300000,
        category: 'travel',
        date: DateTime(2026, 9, 12),
        paidBy: 'Charlie',
        participants: const [],
        imagePaths: const ['/mock/flight.jpg'],
      );

      await tester.pumpWidget(createTestWidget(BillCard(bill: bill)));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('billCard_${bill.id}')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptViewerModal')), findsOneWidget);
    });

    testWidgets('30. Custom onTap on BillCard overrides default modal opening', (tester) async {
      bool tapped = false;
      final bill = Bill(
        id: 'b6',
        title: 'Custom Tap Bill',
        amount: 100000,
        category: 'utilities',
        date: DateTime(2026, 9, 12),
        paidBy: 'Dan',
        participants: const [],
        imagePaths: const ['/mock/util.jpg'],
      );

      await tester.pumpWidget(createTestWidget(BillCard(
        bill: bill,
        onTap: () => tapped = true,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(Key('billCard_${bill.id}')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.byKey(const Key('receiptViewerModal')), findsNothing);
    });

    testWidgets('31. BillCard adapts to dark theme', (tester) async {
      final bill = Bill(
        id: 'b7',
        title: 'Dark Theme Bill',
        amount: 90000,
        category: 'food',
        date: DateTime(2026, 9, 12),
        paidBy: 'Eve',
        participants: const [],
        imagePaths: const ['/mock/dark.jpg'],
      );

      await tester.pumpWidget(createTestWidget(
        BillCard(bill: bill),
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Dark Theme Bill'), findsOneWidget);
      expect(find.byKey(const Key('billReceiptThumbnail')), findsOneWidget);
    });
  });

  group('ReceiptViewerModal Interactive Widget Tests', () {
    testWidgets('32. Renders single image receipt viewer with close button', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ReceiptViewerModal(
          imagePaths: ['/test/mock_receipt.jpg'],
          title: 'Store Receipt',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptViewerModal')), findsOneWidget);
      expect(find.text('Store Receipt'), findsOneWidget);
      expect(find.byKey(const Key('receiptViewerCloseButton')), findsOneWidget);
      expect(find.byKey(const Key('receiptGalleryPageView')), findsOneWidget);
      expect(find.byKey(const Key('receiptGalleryPageIndicator')), findsNothing);
    });

    testWidgets('33. Renders multi-image gallery with page indicator and strip', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ReceiptViewerModal(
          imagePaths: ['/test/img1.jpg', '/test/img2.jpg', '/test/img3.jpg'],
          title: 'Multi Receipts',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptGalleryPageIndicator')), findsOneWidget);
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.byKey(const Key('receiptNextButton')), findsOneWidget);
      expect(find.byKey(const Key('receiptPrevButton')), findsNothing); // on first page
      expect(find.byKey(const Key('receiptGalleryStripItem_0')), findsOneWidget);
      expect(find.byKey(const Key('receiptGalleryStripItem_1')), findsOneWidget);
      expect(find.byKey(const Key('receiptGalleryStripItem_2')), findsOneWidget);
    });

    testWidgets('34. Next button navigates to next receipt and updates indicator', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ReceiptViewerModal(
          imagePaths: ['/test/img1.jpg', '/test/img2.jpg'],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsOneWidget);
      await tester.tap(find.byKey(const Key('receiptNextButton')));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.byKey(const Key('receiptPrevButton')), findsOneWidget);
      expect(find.byKey(const Key('receiptNextButton')), findsNothing);
    });

    testWidgets('35. Previous button navigates back to first receipt', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ReceiptViewerModal(
          imagePaths: ['/test/img1.jpg', '/test/img2.jpg'],
          initialIndex: 1,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
      await tester.tap(find.byKey(const Key('receiptPrevButton')));
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('36. Tapping thumbnail in strip jumps to selected receipt', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ReceiptViewerModal(
          imagePaths: ['/test/a.jpg', '/test/b.jpg', '/test/c.jpg'],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('receiptGalleryStripItem_2')));
      await tester.pumpAndSettle();

      expect(find.text('3 / 3'), findsOneWidget);
    });

    testWidgets('37. Delete button displays confirmation dialog', (tester) async {
      int? deletedIndex;
      await tester.pumpWidget(createTestWidget(
        ReceiptViewerModal(
          imagePaths: const ['/test/1.jpg', '/test/2.jpg'],
          onDelete: (idx) => deletedIndex = idx,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('deleteReceiptButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('deleteReceiptButton')));
      await tester.pumpAndSettle();

      expect(find.text('Delete Receipt'), findsOneWidget);
      expect(find.byKey(const Key('confirmDeleteReceiptButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('confirmDeleteReceiptButton')));
      await tester.pumpAndSettle();

      expect(deletedIndex, equals(0));
      expect(find.text('1 / 1'), findsNothing); // Now only 1 image left, indicator hides
    });

    testWidgets('38. Cancelling delete dialog leaves receipt untouched', (tester) async {
      int? deletedIndex;
      await tester.pumpWidget(createTestWidget(
        ReceiptViewerModal(
          imagePaths: const ['/test/1.jpg'],
          onDelete: (idx) => deletedIndex = idx,
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deleteReceiptButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(deletedIndex, isNull);
      expect(find.byKey(const Key('receiptViewerModal')), findsOneWidget);
    });

    testWidgets('39. Close button dismisses modal', (tester) async {
      await tester.pumpWidget(createTestWidget(
        Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => ReceiptViewerModal.show(ctx, imagePaths: const ['/test/1.jpg']),
            child: const Text('Open'),
          );
        }),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptViewerModal')), findsOneWidget);
      await tester.tap(find.byKey(const Key('receiptViewerCloseButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptViewerModal')), findsNothing);
    });

    testWidgets('40. Displays placeholder when image file does not exist on disk', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ReceiptViewerModal(
          imagePaths: ['/non_existent_folder/mock_photo.png'],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptViewerPlaceholder_0')), findsOneWidget);
      expect(find.text('mock_photo.png'), findsOneWidget);
    });

    testWidgets('41. Displays actual image when file exists on disk', (tester) async {
      final sample = File('${tempDir.path}/actual.png')..writeAsBytesSync([137, 80, 78, 71]);
      await tester.pumpWidget(createTestWidget(
        ReceiptViewerModal(
          imagePaths: [sample.path],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptViewerImage_0')), findsOneWidget);
    });

    testWidgets('42. Empty paths array shows empty state and close button', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ReceiptViewerModal(
          imagePaths: [],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No receipt attached'), findsOneWidget);
      expect(find.byKey(const Key('receiptViewerCloseButton')), findsOneWidget);
    });

    testWidgets('43. ReceiptViewerModal dark theme rendering', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ReceiptViewerModal(
          imagePaths: ['/mock/dark_rec.jpg'],
        ),
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptViewerModal')), findsOneWidget);
    });
  });

  group('AddBillScreen Receipt Attachment Widget Tests', () {
    testWidgets('44. AddBillScreen displays gallery and camera buttons', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('pickGalleryButton')), findsOneWidget);
      expect(find.byKey(const Key('takeCameraButton')), findsOneWidget);
      expect(find.byKey(const Key('imagePreview')), findsNothing);
    });

    testWidgets('45. Pre-populates single image from initialImagePath and renders imagePreview', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(initialImagePath: '/test/init.jpg'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsOneWidget);
      expect(find.byKey(const Key('removeImageButton')), findsOneWidget);
      expect(find.text('Receipts (1)'), findsOneWidget);
    });

    testWidgets('46. Pre-populates multiple images from initialImagePaths', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(
          initialImagePaths: ['/test/1.jpg', '/test/2.jpg'],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsOneWidget);
      expect(find.text('Receipts (2)'), findsOneWidget);
      expect(find.byKey(const Key('receiptThumbnail_0')), findsOneWidget);
      expect(find.byKey(const Key('receiptThumbnail_1')), findsOneWidget);
      expect(find.byKey(const Key('removeImageButton')), findsOneWidget);
    });

    testWidgets('47. Pre-populates images when editing existing bill via billToEdit', (tester) async {
      final bill = Bill(
        id: 'edit_1',
        title: 'Original Bill',
        amount: 200,
        category: 'food',
        date: DateTime.now(),
        paidBy: 'Alice',
        participants: const [
          BillParticipant(participantId: '1', name: 'Alice', amount: 100),
          BillParticipant(participantId: '2', name: 'Bob', amount: 100),
        ],
        imagePaths: const ['/receipts/bill_edit.jpg'],
      );

      await tester.pumpWidget(createTestWidget(
        AddBillScreen(billToEdit: bill),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Original Bill'), findsOneWidget);
      expect(find.byKey(const Key('imagePreview')), findsOneWidget);
      expect(find.text('Receipts (1)'), findsOneWidget);
    });

    testWidgets('48. Picking single image via onPickImage adds to list and renders preview', (tester) async {
      final sample = File('${tempDir.path}/picked.jpg')..writeAsStringSync('sample');

      await tester.pumpWidget(createTestWidget(
        AddBillScreen(
          onPickImage: (source) async => sample.path,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsNothing);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('pickGalleryButton')));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsOneWidget);
      expect(find.text('Receipts (1)'), findsOneWidget);
    });

    testWidgets('49. Taking photo via camera button triggers onPickImage with ImageSource.camera', (tester) async {
      ImageSource? pickedSource;
      final sample = File('${tempDir.path}/cam.jpg')..writeAsStringSync('cam');

      await tester.pumpWidget(createTestWidget(
        AddBillScreen(
          onPickImage: (source) async {
            pickedSource = source;
            return sample.path;
          },
        ),
      ));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('takeCameraButton')));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(pickedSource, equals(ImageSource.camera));
      expect(find.byKey(const Key('imagePreview')), findsOneWidget);
    });

    testWidgets('50. Picking multiple images via onPickMultipleImages adds all images', (tester) async {
      final img1 = File('${tempDir.path}/m1.jpg')..writeAsStringSync('1');
      final img2 = File('${tempDir.path}/m2.jpg')..writeAsStringSync('2');

      await tester.pumpWidget(createTestWidget(
        AddBillScreen(
          onPickMultipleImages: () async => [img1.path, img2.path],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('pickGalleryButton')));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsOneWidget);
      expect(find.text('Receipts (2)'), findsOneWidget);
      expect(find.byKey(const Key('receiptThumbnail_0')), findsOneWidget);
      expect(find.byKey(const Key('receiptThumbnail_1')), findsOneWidget);
    });

    testWidgets('51. Tapping removeImageButton clears image and hides imagePreview', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(initialImagePath: '/test/remove_me.jpg'),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsOneWidget);
      expect(find.byKey(const Key('removeImageButton')), findsOneWidget);

      await tester.tap(find.byKey(const Key('removeImageButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsNothing);
      expect(find.byKey(const Key('removeImageButton')), findsNothing);
    });

    testWidgets('52. Clear all receipts button removes all images at once', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(
          initialImagePaths: ['/test/1.jpg', '/test/2.jpg', '/test/3.jpg'],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clearAllReceiptsButton')), findsOneWidget);
      await tester.tap(find.byKey(const Key('clearAllReceiptsButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsNothing);
    });

    testWidgets('53. Tapping thumbnail in AddBillScreen opens ReceiptViewerModal', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(
          initialImagePaths: ['/test/thumb_tap.jpg'],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('receiptThumbnail_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptViewerModal')), findsOneWidget);
    });

    testWidgets('54. AddBillScreen dark theme rendering with images', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(initialImagePath: '/test/dark.jpg'),
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsOneWidget);
      expect(find.text('Receipts (1)'), findsOneWidget);
    });
  });

  group('Bilingual Localization Tests', () {
    testWidgets('55. English translations for all receipt keys', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(createTestWidget(
        Builder(builder: (ctx) {
          loc = AppLocalizations.of(ctx);
          return const SizedBox();
        }),
        locale: const Locale('en'),
      ));
      await tester.pumpAndSettle();

      expect(loc.translate('receipts'), equals('Receipts'));
      expect(loc.translate('receipt_images'), equals('Receipt Images'));
      expect(loc.translate('add_receipt'), equals('Add Receipt'));
      expect(loc.translate('attach_receipt'), equals('Attach Receipt'));
      expect(loc.translate('view_receipt'), equals('View Receipt'));
      expect(loc.translate('receipt_gallery'), equals('Receipt Gallery'));
      expect(loc.translate('delete_receipt'), equals('Delete Receipt'));
      expect(loc.translate('delete_receipt_confirm'), contains('delete this receipt image'));
      expect(loc.translate('no_receipt'), equals('No receipt attached'));
      expect(loc.translate('receipt_preview'), equals('Receipt Preview'));
    });

    testWidgets('56. Vietnamese translations for all receipt keys', (tester) async {
      late AppLocalizations loc;
      await tester.pumpWidget(createTestWidget(
        Builder(builder: (ctx) {
          loc = AppLocalizations.of(ctx);
          return const SizedBox();
        }),
        locale: const Locale('vi'),
      ));
      await tester.pumpAndSettle();

      expect(loc.translate('receipts'), equals('Hóa đơn đính kèm'));
      expect(loc.translate('receipt_images'), equals('Ảnh hóa đơn'));
      expect(loc.translate('add_receipt'), equals('Thêm ảnh hóa đơn'));
      expect(loc.translate('attach_receipt'), equals('Đính kèm hóa đơn'));
      expect(loc.translate('view_receipt'), equals('Xem ảnh hóa đơn'));
      expect(loc.translate('receipt_gallery'), equals('Bộ sưu tập hóa đơn'));
      expect(loc.translate('delete_receipt'), equals('Xóa hóa đơn'));
      expect(loc.translate('delete_receipt_confirm'), contains('xóa ảnh hóa đơn này không'));
      expect(loc.translate('no_receipt'), equals('Chưa đính kèm hóa đơn'));
      expect(loc.translate('receipt_preview'), equals('Xem trước hóa đơn'));
    });
  });

  group('Extensive Edge Cases & Storage Resilience Tests', () {
    test('57. Handling extremely large filename paths gracefully', () async {
      final sub = 'very_long_directory_name_' * 10;
      final longPath = '/a/b/c/${sub}test.jpg';
      final exists = ReceiptImageService.receiptExists(longPath);
      expect(exists, isFalse);
    });

    test('58. Bill with null imagePath and null imagePaths maintains equality', () {
      final b1 = Bill(id: '1', title: 'A', amount: 10, category: 'food', date: DateTime(2026), paidBy: 'A', participants: const []);
      final b2 = Bill(id: '1', title: 'A', amount: 10, category: 'food', date: DateTime(2026), paidBy: 'A', participants: const []);
      expect(b1, equals(b2));
    });

    test('59. Bill with empty string imagePath does not report hasReceipt', () {
      final bill = Bill(id: '1', title: 'A', amount: 10, category: 'food', date: DateTime(2026), paidBy: 'A', participants: const [], imagePath: '');
      expect(bill.hasReceipt, isFalse);
      expect(bill.effectiveImagePaths, isEmpty);
      expect(bill.effectiveImagePath, isNull);
    });

    test('60. BillModel serialization roundtrip preserves multi-image state', () {
      final original = BillModel(
        id: 'roundtrip',
        title: 'Roundtrip Bill',
        amount: 350.0,
        category: 'restaurant',
        date: DateTime(2026, 9, 13, 10, 0),
        paidBy: 'Alice',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'Alice', amount: 175.0),
          BillParticipant(participantId: 'p2', name: 'Bob', amount: 175.0),
        ],
        imagePaths: const ['/data/receipt_1.jpg', '/data/receipt_2.jpg'],
      );

      final json = original.toJson();
      final reconstructed = BillModel.fromJson(json);

      expect(reconstructed.id, equals(original.id));
      expect(reconstructed.title, equals(original.title));
      expect(reconstructed.amount, equals(original.amount));
      expect(reconstructed.imagePaths, equals(original.imagePaths));
      expect(reconstructed.effectiveImagePath, equals(original.effectiveImagePath));
      expect(reconstructed.hasReceipt, isTrue);
    });

    test('61. Multiple clearAllReceipts calls do not throw error', () async {
      await ReceiptImageService.clearAllReceipts();
      await ReceiptImageService.clearAllReceipts();
      expect(await ReceiptImageService.getReceiptCount(), equals(0));
    });

    test('62. Saving bytes with uppercase extension preserves normalized lowercase or valid extension', () async {
      final path = await ReceiptImageService.saveReceiptBytes(Uint8List.fromList([1, 2]), extension: 'PNG');
      expect(path.endsWith('.PNG'), isTrue);
      expect(File(path).existsSync(), isTrue);
    });

    test('63. Bill props list contains imagePaths', () {
      final bill = Bill(
        id: '1',
        title: 'Props Test',
        amount: 10,
        category: 'food',
        date: DateTime(2026),
        paidBy: 'A',
        participants: const [],
        imagePaths: const ['/test/props.jpg'],
      );
      expect(bill.props.contains(const ['/test/props.jpg']), isTrue);
    });

    test('64. Receipt count correctly reflects number of paths in effectiveImagePaths', () {
      final bill = Bill(
        id: '1',
        title: 'Count Test',
        amount: 10,
        category: 'food',
        date: DateTime(2026),
        paidBy: 'A',
        participants: const [],
        imagePaths: const ['/1.jpg', '/2.jpg', '/3.jpg', '/4.jpg'],
      );
      expect(bill.receiptCount, equals(4));
    });

    test('65. Bill effectiveCategoryColor fallback works with imagePaths present', () {
      final bill = Bill(
        id: '1',
        title: 'Color Test',
        amount: 10,
        category: 'restaurant',
        date: DateTime(2026),
        paidBy: 'A',
        participants: const [],
        imagePaths: const ['/test.jpg'],
      );
      expect(bill.effectiveCategoryColor, equals('#F44336'));
    });

    test('66. Bill effectiveCategoryColor custom color preserved with imagePaths', () {
      final bill = Bill(
        id: '1',
        title: 'Color Test',
        amount: 10,
        category: 'restaurant',
        categoryColor: '#123456',
        date: DateTime(2026),
        paidBy: 'A',
        participants: const [],
        imagePaths: const ['/test.jpg'],
      );
      expect(bill.effectiveCategoryColor, equals('#123456'));
    });

    test('67. BillModel fromJson with empty imagePaths string array', () {
      final json = {
        'id': 'b_empty',
        'title': 'Empty Images',
        'amount': 10.0,
        'category': 'food',
        'date': DateTime.now().toIso8601String(),
        'paidBy': 'A',
        'participants': '[]',
        'imagePaths': '[]',
      };
      final model = BillModel.fromJson(json);
      expect(model.imagePaths, isEmpty);
      expect(model.hasReceipt, isFalse);
    });

    test('68. BillModel fromJson with non-array json in imagePaths ignores and uses single imagePath', () {
      final json = {
        'id': 'b_obj',
        'title': 'Obj Images',
        'amount': 10.0,
        'category': 'food',
        'date': DateTime.now().toIso8601String(),
        'paidBy': 'A',
        'participants': '[]',
        'imagePaths': '{"some":"object"}',
        'imagePath': '/valid.jpg',
      };
      final model = BillModel.fromJson(json);
      expect(model.imagePaths, equals(['/valid.jpg']));
    });

    test('69. Saving receipt with special characters in billId sanitized', () async {
      final bytes = Uint8List.fromList([10, 20]);
      final path = await ReceiptImageService.saveReceiptBytes(bytes, billId: 'bill_2026-09-13');
      expect(File(path).existsSync(), isTrue);
      expect(path.contains('receipt_bill_2026-09-13_'), isTrue);
    });

    test('70. Format storage sizes for fractional values', () {
      expect(ReceiptImageService.formatStorageSize(1024 * 512), equals('512.0 KB'));
      expect(ReceiptImageService.formatStorageSize((1.75 * 1024 * 1024).round()), equals('1.8 MB'));
    });

    testWidgets('71. ReceiptViewerModal zoom test verifies InteractiveViewer properties', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ReceiptViewerModal(
          imagePaths: ['/test/zoom.jpg'],
        ),
      ));
      await tester.pumpAndSettle();

      final interactiveViewer = tester.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      expect(interactiveViewer.panEnabled, isTrue);
      expect(interactiveViewer.maxScale, equals(4.0));
      expect(interactiveViewer.minScale, equals(0.8));
    });

    testWidgets('72. ReceiptViewerModal multi-page navigation boundary test (cannot go past last)', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ReceiptViewerModal(
          imagePaths: ['/test/1.jpg', '/test/2.jpg'],
          initialIndex: 1,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.byKey(const Key('receiptNextButton')), findsNothing);
    });

    testWidgets('73. ReceiptViewerModal multi-page navigation boundary test (cannot go before first)', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const ReceiptViewerModal(
          imagePaths: ['/test/1.jpg', '/test/2.jpg'],
          initialIndex: 0,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsOneWidget);
      expect(find.byKey(const Key('receiptPrevButton')), findsNothing);
    });

    testWidgets('74. BillCard displays participant count with receipt indicator', (tester) async {
      final bill = Bill(
        id: 'b_part',
        title: 'Dinner Party',
        amount: 500000,
        category: 'restaurant',
        date: DateTime(2026, 9, 13),
        paidBy: 'Host',
        participants: const [
          BillParticipant(participantId: 'p1', name: 'A', amount: 250000),
          BillParticipant(participantId: 'p2', name: 'B', amount: 250000),
        ],
        imagePaths: const ['/img1.jpg', '/img2.jpg'],
      );

      await tester.pumpWidget(createTestWidget(BillCard(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.text('2 participants'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Receipt count label in bill card
    });

    testWidgets('75. AddBillScreen image preview shows correct count for 3 images', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(
          initialImagePaths: ['/a.jpg', '/b.jpg', '/c.jpg'],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Receipts (3)'), findsOneWidget);
      expect(find.byKey(const Key('receiptThumbnail_0')), findsOneWidget);
      expect(find.byKey(const Key('receiptThumbnail_1')), findsOneWidget);
      expect(find.byKey(const Key('receiptThumbnail_2')), findsOneWidget);
    });

    testWidgets('76. AddBillScreen image preview shows correct count for 5 images', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(
          initialImagePaths: ['/1.jpg', '/2.jpg', '/3.jpg', '/4.jpg', '/5.jpg'],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Receipts (5)'), findsOneWidget);
      expect(find.byKey(const Key('receiptThumbnail_0')), findsOneWidget);
    });

    testWidgets('77. AddBillScreen removeImageButton_1 removes only index 1', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(
          initialImagePaths: ['/keep1.jpg', '/delete_me.jpg', '/keep2.jpg'],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Receipts (3)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('removeImageButton_1')));
      await tester.pumpAndSettle();

      expect(find.text('Receipts (2)'), findsOneWidget);
    });

    testWidgets('78. AddBillScreen imagePath getter returns first path', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(
          initialImagePaths: ['/first.jpg', '/second.jpg'],
        ),
      ));
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(AddBillScreen));
      expect(state.imagePath, equals('/first.jpg'));
    });

    testWidgets('79. AddBillScreen imagePath setter appends new path', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(),
      ));
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(AddBillScreen));
      state.imagePath = '/new_set.jpg';
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsOneWidget);
      expect(state.imagePath, equals('/new_set.jpg'));
    });

    testWidgets('80. AddBillScreen imagePath setter null clears list', (tester) async {
      await tester.pumpWidget(createTestWidget(
        const AddBillScreen(initialImagePath: '/clear_via_setter.jpg'),
      ));
      await tester.pumpAndSettle();

      final dynamic state = tester.state(find.byType(AddBillScreen));
      state.imagePath = null;
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('imagePreview')), findsNothing);
      expect(state.imagePaths, isEmpty);
    });

    testWidgets('81. ReceiptViewerModal deletes second image and adjusts currentIndex', (tester) async {
      await tester.pumpWidget(createTestWidget(
        ReceiptViewerModal(
          imagePaths: const ['/test/a.jpg', '/test/b.jpg'],
          initialIndex: 1,
          onDelete: (_) {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('2 / 2'), findsOneWidget);

      await tester.tap(find.byKey(const Key('deleteReceiptButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmDeleteReceiptButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptGalleryPageIndicator')), findsNothing);
    });

    testWidgets('82. ReceiptViewerModal deleting sole image closes modal', (tester) async {
      await tester.pumpWidget(createTestWidget(
        Builder(builder: (ctx) {
          return ElevatedButton(
            onPressed: () => ReceiptViewerModal.show(
              ctx,
              imagePaths: ['/test/only_one.jpg'],
              onDelete: (_) {},
            ),
            child: const Text('Open Sole Modal'),
          );
        }),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sole Modal'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptViewerModal')), findsOneWidget);

      await tester.tap(find.byKey(const Key('deleteReceiptButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('confirmDeleteReceiptButton')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('receiptViewerModal')), findsNothing);
    });

    testWidgets('83. BillCard with custom currency formats symbol correctly', (tester) async {
      final bill = Bill(
        id: 'b_usd',
        title: 'Dollar Bill',
        amount: 50,
        currency: 'USD',
        category: 'food',
        date: DateTime(2026, 9, 13),
        paidBy: 'John',
        participants: const [],
        imagePaths: const ['/receipts/usd.jpg'],
      );

      await tester.pumpWidget(createTestWidget(BillCard(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.text('50 USD'), findsOneWidget);
    });

    testWidgets('84. BillCard categoryIcon emoji takes precedence over default category emoji', (tester) async {
      final bill = Bill(
        id: 'b_custom_icon',
        title: 'Custom Icon Bill',
        amount: 100,
        category: 'food',
        categoryIcon: '🍲',
        date: DateTime(2026, 9, 13),
        paidBy: 'John',
        participants: const [],
        imagePaths: const ['/receipts/custom.jpg'],
      );

      await tester.pumpWidget(createTestWidget(BillCard(bill: bill)));
      await tester.pumpAndSettle();

      expect(find.text('🍲'), findsOneWidget);
    });

    testWidgets('85. Full flow: adding multiple receipts and verifying state', (tester) async {
      final img1 = File('${tempDir.path}/flow1.jpg')..writeAsStringSync('1');
      final img2 = File('${tempDir.path}/flow2.jpg')..writeAsStringSync('2');

      await tester.pumpWidget(createTestWidget(
        AddBillScreen(
          onPickMultipleImages: () async => [img1.path, img2.path],
        ),
      ));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('pickGalleryButton')));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('Receipts (2)'), findsOneWidget);
      final AddBillScreenState state = tester.state(find.byType(AddBillScreen));
      expect(state.imagePaths.length, equals(2));
      expect(state.imagePath, equals(state.imagePaths.first));
    });
  });
}
