import 'package:flutter/material.dart';
import '../../domain/services/calculator_evaluator.dart';
import '../../../../core/localization/app_localizations.dart';

/// A custom calculator keyboard widget for Amount input.
/// Provides number keys (0-9), operators (+, -, ×, ÷, =), decimal (.),
/// backspace (⌫), space, clear (C), and real-time calculation preview.
class CalculatorKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSubmitted;
  final Color? accentColor;

  const CalculatorKeyboard({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.accentColor,
  });

  void _onKeyPress(String key) {
    if (key == 'C') {
      controller.clear();
      return;
    }

    if (key == '⌫') {
      var text = controller.text;
      if (text.isNotEmpty) {
        text = text.substring(0, text.length - 1);
        if (text.endsWith(',')) {
          text = text.substring(0, text.length - 1);
        }
        controller.text = CalculatorEvaluator.formatExpression(text);
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
      }
      return;
    }

    if (key == '=') {
      final result = CalculatorEvaluator.evaluate(controller.text);
      if (result != null && !result.isNaN && !result.isInfinite) {
        controller.text = CalculatorEvaluator.formatResult(result);
        controller.selection = TextSelection.collapsed(offset: controller.text.length);
      }
      return;
    }

    // Append key
    final text = controller.text;
    controller.text = CalculatorEvaluator.formatExpression(text + key);
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);
    final primary = accentColor ?? theme.colorScheme.primary;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;
    final numKeyBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final opKeyBg = isDark ? const Color(0xFF383838) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final currentText = value.text.trim();
        final hasOp = CalculatorEvaluator.hasOperator(currentText);
        final evalResult = CalculatorEvaluator.evaluate(currentText);
        final canEval = evalResult != null && !evalResult.isNaN && !evalResult.isInfinite;
        final hasSyntaxError = hasOp && !canEval && currentText.isNotEmpty;

        return Container(
          key: const Key('calculatorKeyboard'),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Real-time calculation preview header
              if (currentText.isNotEmpty)
                Container(
                  key: const Key('calc_expression_preview'),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          currentText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor.withOpacity(0.85),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasOp && canEval)
                        Text(
                          '= ${CalculatorEvaluator.formatResult(evalResult)}',
                          key: const Key('calc_result_preview'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        )
                      else if (hasSyntaxError)
                        Text(
                          loc.translate('invalid_expression'),
                          key: const Key('calc_error_text'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ),

              // Keypad rows
              Row(
                children: [
                  _buildKey('C', 'calc_key_clear', opKeyBg, Colors.redAccent, flex: 1),
                  _buildKey('÷', 'calc_key_divide', opKeyBg, primary, flex: 1),
                  _buildKey('×', 'calc_key_multiply', opKeyBg, primary, flex: 1),
                  _buildKey('⌫', 'calc_key_backspace', opKeyBg, Colors.orangeAccent, flex: 1),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildKey('7', 'calc_key_7', numKeyBg, textColor),
                  _buildKey('8', 'calc_key_8', numKeyBg, textColor),
                  _buildKey('9', 'calc_key_9', numKeyBg, textColor),
                  _buildKey('-', 'calc_key_subtract', opKeyBg, primary),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildKey('4', 'calc_key_4', numKeyBg, textColor),
                  _buildKey('5', 'calc_key_5', numKeyBg, textColor),
                  _buildKey('6', 'calc_key_6', numKeyBg, textColor),
                  _buildKey('+', 'calc_key_add', opKeyBg, primary),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildKey('1', 'calc_key_1', numKeyBg, textColor),
                  _buildKey('2', 'calc_key_2', numKeyBg, textColor),
                  _buildKey('3', 'calc_key_3', numKeyBg, textColor),
                  _buildKey(
                    '=',
                    'calc_key_equals',
                    canEval ? primary : Colors.grey.shade400,
                    Colors.white,
                    enabled: canEval,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildKey('0', 'calc_key_0', numKeyBg, textColor, flex: 1),
                  _buildKey('.', 'calc_key_dot', numKeyBg, textColor, flex: 1),
                  _buildKey(' ', 'calc_key_space', numKeyBg, textColor, flex: 1, label: '␣'),
                  _buildKey(
                    'Done',
                    'calc_key_done',
                    primary,
                    Colors.white,
                    flex: 1,
                    onTap: () {
                      if (canEval) {
                        controller.text = CalculatorEvaluator.formatResult(evalResult);
                      }
                      onSubmitted?.call();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKey(
    String keyStr,
    String keyName,
    Color bg,
    Color textCol, {
    int flex = 1,
    String? label,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            key: Key(keyName),
            onPressed: enabled ? (onTap ?? () => _onKeyPress(keyStr)) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: textCol,
              disabledBackgroundColor: bg.withOpacity(0.5),
              disabledForegroundColor: textCol.withOpacity(0.4),
              elevation: 1,
              shadowColor: Colors.black26,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              label ?? keyStr,
              style: TextStyle(
                fontSize: keyStr == 'Done' ? 14 : 20,
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
