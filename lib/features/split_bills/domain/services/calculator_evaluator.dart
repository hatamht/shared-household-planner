/// A math expression evaluator implementing standard PEMDAS order of operations.
/// Supports integers, decimals, parentheses, and operators: +, -, *, ×, /, ÷.
class CalculatorEvaluator {
  /// Evaluates an expression string and returns the calculated [double],
  /// Evaluates an expression string and returns the calculated [double],
  /// or `null` if the expression is empty or invalid.
  static double? evaluate(String? input) {
    if (input == null) return null;
    final cleaned = input
        .replaceAll(' ', '')
        .replaceAll(',', '')
        .replaceAll('×', '*')
        .replaceAll('÷', '/');

    if (cleaned.isEmpty) return null;

    try {
      final tokens = _tokenize(cleaned);
      if (tokens.isEmpty) return null;
      return _evaluateTokens(tokens);
    } catch (_) {
      return null;
    }
  }

  /// Checks if an expression contains any mathematical operator.
  static bool hasOperator(String input) {
    return input.contains('+') ||
        input.contains('-') ||
        input.contains('*') ||
        input.contains('×') ||
        input.contains('/') ||
        input.contains('÷');
  }

  /// Checks if the expression is syntactically complete and can be evaluated.
  static bool canEvaluate(String input) {
    final result = evaluate(input);
    return result != null && !result.isNaN && !result.isInfinite;
  }

  /// Checks if a character is valid in a calculator expression.
  static bool isValidChar(String char) {
    return RegExp(r'[0-9\.\+\-\*\/×÷\s\(\),]').hasMatch(char);
  }

  /// Formats an integer or number string with comma thousand separators (e.g. "100000" -> "100,000").
  static String formatWithCommas(String digits) {
    final isNegative = digits.startsWith('-');
    final absDigits = isNegative ? digits.substring(1) : digits;
    final formatted = absDigits.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return isNegative ? '-$formatted' : formatted;
  }

  /// Formats all numbers in an expression with comma thousand separators.
  static String formatExpression(String expr) {
    if (expr.isEmpty) return expr;
    final uncomma = expr.replaceAll(',', '');
    return uncomma.replaceAllMapped(RegExp(r'\d+(?:\.\d*)?'), (match) {
      final s = match.group(0)!;
      if (s.contains('.')) {
        final parts = s.split('.');
        final intPart = formatWithCommas(parts[0]);
        return '$intPart.${parts.length > 1 ? parts[1] : ''}';
      }
      return formatWithCommas(s);
    });
  }

  /// Formats a double value cleanly (with comma thousand separators).
  static String formatResult(double value) {
    if (value.isNaN || value.isInfinite) return '0';
    if (value == value.roundToDouble()) {
      return formatWithCommas(value.toInt().toString());
    }
    // Trim trailing zeros after decimal point
    final str = value.toStringAsFixed(4);
    var trimmed = str.replaceAll(RegExp(r'0+$'), '');
    if (trimmed.endsWith('.')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    final parts = trimmed.split('.');
    final intPart = formatWithCommas(parts[0]);
    if (parts.length > 1) {
      return '$intPart.${parts[1]}';
    }
    return intPart;
  }

  // ─── Internal Tokenizer & Shunting Yard Parser ──────────────────────────

  static List<_Token> _tokenize(String s) {
    final List<_Token> tokens = [];
    int i = 0;

    while (i < s.length) {
      final ch = s[i];

      if (ch == '+' || ch == '-' || ch == '*' || ch == '/') {
        // Check for unary minus: at start or immediately following another operator or '('
        if (ch == '-' && (tokens.isEmpty || tokens.last.type == _TokenType.operator || tokens.last.type == _TokenType.openParen)) {
          // Read negative number
          i++;
          final start = i;
          while (i < s.length && (RegExp(r'[0-9\.]').hasMatch(s[i]))) {
            i++;
          }
          if (start == i) throw FormatException('Expected number after unary minus at $i');
          final numStr = '-${s.substring(start, i)}';
          final val = double.parse(numStr);
          tokens.add(_Token(_TokenType.number, val));
          continue;
        }

        tokens.add(_Token(_TokenType.operator, ch));
        i++;
      } else if (ch == '(') {
        tokens.add(_Token(_TokenType.openParen, ch));
        i++;
      } else if (ch == ')') {
        tokens.add(_Token(_TokenType.closeParen, ch));
        i++;
      } else if (RegExp(r'[0-9\.]').hasMatch(ch)) {
        final start = i;
        while (i < s.length && RegExp(r'[0-9\.]').hasMatch(s[i])) {
          i++;
        }
        final numStr = s.substring(start, i);
        final val = double.parse(numStr);
        tokens.add(_Token(_TokenType.number, val));
      } else {
        throw FormatException('Unexpected character: $ch');
      }
    }

    return tokens;
  }

  static double _evaluateTokens(List<_Token> tokens) {
    final List<double> values = [];
    final List<String> ops = [];

    int precedence(String op) {
      if (op == '+' || op == '-') return 1;
      if (op == '*' || op == '/') return 2;
      return 0;
    }

    void applyOp() {
      if (values.length < 2 || ops.isEmpty) {
        throw StateError('Invalid expression syntax');
      }
      final right = values.removeLast();
      final left = values.removeLast();
      final op = ops.removeLast();

      switch (op) {
        case '+':
          values.add(left + right);
          break;
        case '-':
          values.add(left - right);
          break;
        case '*':
          values.add(left * right);
          break;
        case '/':
          if (right == 0) throw StateError('Division by zero');
          values.add(left / right);
          break;
      }
    }

    for (final token in tokens) {
      if (token.type == _TokenType.number) {
        values.add(token.value as double);
      } else if (token.type == _TokenType.openParen) {
        ops.add('(');
      } else if (token.type == _TokenType.closeParen) {
        while (ops.isNotEmpty && ops.last != '(') {
          applyOp();
        }
        if (ops.isNotEmpty && ops.last == '(') {
          ops.removeLast();
        } else {
          throw StateError('Mismatched parentheses');
        }
      } else if (token.type == _TokenType.operator) {
        final currentOp = token.value as String;
        while (ops.isNotEmpty &&
            ops.last != '(' &&
            precedence(ops.last) >= precedence(currentOp)) {
          applyOp();
        }
        ops.add(currentOp);
      }
    }

    while (ops.isNotEmpty) {
      if (ops.last == '(') throw StateError('Mismatched parentheses');
      applyOp();
    }

    if (values.length != 1) {
      throw StateError('Invalid expression');
    }

    return values.single;
  }
}

enum _TokenType { number, operator, openParen, closeParen }

class _Token {
  final _TokenType type;
  final dynamic value;
  _Token(this.type, this.value);
}
