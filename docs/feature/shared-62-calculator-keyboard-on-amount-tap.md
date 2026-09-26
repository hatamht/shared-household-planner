# Shared-62: Direct Custom Calculator Keyboard on Amount Input (Suppress System Keyboard)

## Problem Statement

In `AddBillScreen`, when the user taps on the Amount input area (`VND 0`), the Android/iOS system virtual soft keyboard currently slides up.
Users expect tapping the amount field to directly display the in-app custom calculator keyboard (`CalculatorKeyboard`) with arithmetic operations (`+`, `-`, `×`, `÷`, `=`, `C`, `⌫`, `000`), rather than popping up the generic system keyboard.
Having the system keyboard popup creates friction, covers the screen, and forces the user to manually seek and tap the separate calculator icon button.

## Proposed Solution

1. **Amount TextField Configuration**:
   - In `_buildCompactAmountInput` and `_buildFullAmountInput` in `lib/features/split_bills/presentation/pages/add_bill_screen.dart`:
     - Set `readOnly: true` on `compactAmountField` and `fullAmountField`.
     - Set `showCursor: true` to ensure the blinking cursor remains active.
     - Add `onTap` callback to the `TextField` and its container:
       ```dart
       onTap: () {
         FocusScope.of(context).unfocus(); // Dismiss system keyboard if previously active
         if (!_showCalculator) {
           setState(() {
             _showCalculator = true;
           });
         }
       }
       ```
2. **Container Click Handling**:
   - Wrap the entire Amount card container in `InkWell` / `GestureDetector` (`key: Key('compactAmountContainer')` & `Key('fullAmountContainer')`) so that tapping anywhere within the amount box smoothly brings up the custom calculator.
3. **Focus Switching**:
   - When the user focuses or taps another field (such as the Title field or Note field), the system keyboard opens normally for text typing, and `_showCalculator` can hide gracefully.
4. **Calculator Toggle Button**:
   - The icon button (`toggleCalculatorButton` / `fullToggleCalculatorButton`) remains functional to toggle/collapse the calculator (`Icons.keyboard_hide` when open, `Icons.calculate_outlined` when closed).
5. **Expression & Arithmetic Continuity**:
   - All arithmetic expressions evaluated via `CalculatorEvaluator` (`+`, `-`, `*`, `/`, `=`, `000`, `C`, backspace) and live calculation previews continue to work seamlessly.

## Acceptance Criteria

1. Tapping on the Amount input field or amount container automatically reveals the custom `CalculatorKeyboard` without displaying the OS system keyboard.
2. The Amount `TextField` uses `readOnly: true` and `showCursor: true` to suppress the system virtual keyboard while keeping active focus and cursor visibility.
3. Both Compact mode (`compactAmountField`) and Full/Expanded mode (`fullAmountField`) implement this behavior consistently.
4. Tapping other text inputs (Title, Notes, etc.) restores the normal system soft keyboard.
5. The calculator toggle button remains functional to show or hide the calculator keypad on demand.
6. All arithmetic operations continue to update the amount correctly with real-time preview and split calculations.
7. All unit and widget tests pass with 100% pass rate.
