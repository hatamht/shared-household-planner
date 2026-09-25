import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household-planner/core/widgets/global_keyboard_dismiss.dart'
    if (dart.library.io) 'package:shared_household_planner/core/widgets/global_keyboard_dismiss.dart';

void main() {
  group('GlobalKeyboardDismiss Tests', () {
    testWidgets('1. Tapping outside focused TextField unfocuses it', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => GlobalKeyboardDismiss(child: child),
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: const Key('testInput'),
                  focusNode: focusNode,
                ),
                const SizedBox(height: 200),
                const Text('Outside Area', key: Key('outsideText')),
              ],
            ),
          ),
        ),
      );

      // Focus the text field
      await tester.tap(find.byKey(const Key('testInput')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Tap outside
      await tester.tap(find.byKey(const Key('outsideText')));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('2. Tapping inside focused TextField keeps focus', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => GlobalKeyboardDismiss(child: child),
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: const Key('testInput'),
                  focusNode: focusNode,
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      );

      // Focus the text field
      await tester.tap(find.byKey(const Key('testInput')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Tap inside again
      await tester.tap(find.byKey(const Key('testInput')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('3. Tapping a button outside unfocuses and executes button onPressed', (tester) async {
      final focusNode = FocusNode();
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => GlobalKeyboardDismiss(child: child),
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: const Key('testInput'),
                  focusNode: focusNode,
                ),
                const SizedBox(height: 50),
                ElevatedButton(
                  key: const Key('testButton'),
                  onPressed: () => buttonPressed = true,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('testInput')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      await tester.tap(find.byKey(const Key('testButton')));
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);
      expect(buttonPressed, isTrue);
    });

    testWidgets('4. Tapping when nothing is focused does not throw error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => GlobalKeyboardDismiss(child: child),
          home: const Scaffold(
            body: Center(
              child: Text('Just Text', key: Key('plainText')),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('plainText')));
      await tester.pump();
      // No exceptions thrown
    });

    testWidgets('5. Works inside ListView and scrolling areas', (tester) async {
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => GlobalKeyboardDismiss(child: child),
          home: Scaffold(
            body: ListView(
              children: [
                TextField(
                  key: const Key('testInput'),
                  focusNode: focusNode,
                ),
                for (int i = 0; i < 20; i++)
                  ListTile(
                    key: Key('item_$i'),
                    title: Text('Item $i'),
                  ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('testInput')));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Tap on a list tile
      await tester.tap(find.byKey(const Key('item_5')));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });
  });
}
