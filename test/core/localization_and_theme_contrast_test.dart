import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_planner/core/localization/app_localizations.dart';
import 'package:shared_household_planner/core/theme/app_theme.dart';

void main() {
  group('Localization Completeness', () {
    late Map<String, dynamic> enJson;
    late Map<String, dynamic> viJson;

    setUpAll(() {
      final enFile = File('lib/core/localization/translations/en.json');
      final viFile = File('lib/core/localization/translations/vi.json');
      enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
      viJson = jsonDecode(viFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('All recently reported missing keys exist in en.json', () {
      final requiredKeys = [
        'bill_name_hint',
        'deselect_all',
        'select_all',
        'done',
        'receipt',
        'account_name',
        'status',
        'items',
      ];

      for (final key in requiredKeys) {
        expect(enJson.containsKey(key), isTrue, reason: '$key missing in en.json');
        expect(enJson[key], isNotEmpty);
      }
    });

    test('All recently reported missing keys exist in vi.json', () {
      final requiredKeys = [
        'bill_name_hint',
        'deselect_all',
        'select_all',
        'done',
        'receipt',
        'account_name',
        'status',
        'items',
      ];

      for (final key in requiredKeys) {
        expect(viJson.containsKey(key), isTrue, reason: '$key missing in vi.json');
        expect(viJson[key], isNotEmpty);
      }
    });

    test('Specific Vietnamese translations are correct', () {
      expect(viJson['bill_name_hint'], equals('VD: Ăn tối cùng bạn bè'));
      expect(viJson['deselect_all'], equals('Bỏ chọn tất cả'));
      expect(viJson['select_all'], equals('Chọn tất cả'));
      expect(viJson['done'], equals('Xong'));
      expect(viJson['receipt'], equals('Biên lai'));
      expect(viJson['account_name'], equals('Quản trị viên'));
      expect(viJson['status'], equals('Trạng thái'));
      expect(viJson['items'], equals('mục'));
    });
  });

  group('TabBar Contrast in Light Theme', () {
    testWidgets('TabBar text is clearly visible (white) against purple AppBar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: DefaultTabController(
            length: 3,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Test Project'),
                bottom: const TabBar(
                  tabs: [
                    Tab(key: Key('tab1'), text: 'Chi tiêu'),
                    Tab(key: Key('tab2'), text: 'Thanh toán'),
                    Tab(key: Key('tab3'), text: 'Thống kê'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Text('Body 1'),
                  Text('Body 2'),
                  Text('Body 3'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final tabBar = tester.widget<TabBar>(find.byType(TabBar));
      expect(tabBar.labelColor ?? AppTheme.lightTheme.tabBarTheme.labelColor, Colors.white);
      expect(
        tabBar.unselectedLabelColor ?? AppTheme.lightTheme.tabBarTheme.unselectedLabelColor,
        isNot(equals(AppTheme.lightTheme.colorScheme.primary)),
      );
    });
  });
}
