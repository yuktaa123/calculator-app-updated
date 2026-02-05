import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

/// Button type for Figma styling
enum CalcButtonType { digit, operator, equals, control, scientific, backspace }

/// Figma dark theme colors
class CalcColorsDark {
  static const mainBackground = Color(0xFF1A1A1A);
  static const displayBackground = Color(0xFF1A1A1A);
  static const digitButtonBg = Color(0xFF2C2C2E);
  static const controlButtonBg = Color(0xFF5B5B5B);
  static const operatorButtonBg = Color(0xFF1A73E8);
  static const digitText = Color(0xFF5091FF);
  static const controlText = Color(0xFFFFFFFF);
  static const inputText = Color(0xFFD0D0D0);
  static const resultText = Color(0xFFFFFFFF);
}

/// Figma light theme colors - neumorphic/glassmorphic
class CalcColorsLight {
  static const mainBackgroundGradientStart = Color(0xFFE8F4FC);
  static const mainBackgroundGradientEnd = Color(0xFFB8D4E8);
  static const displayBackground = Color(0x00000000);
  static const digitButtonBg = Color(0x33FFFFFF);
  static const controlButtonBg = Color(0x33FFFFFF);
  static const operatorButtonBg = Color(0x66007AFF);
  static const operatorButtonBgSolid = Color(0xFF007AFF);
  static const digitText = Color(0xFF606060);
  static const controlText = Color(0xFF606060);
  static const inputText = Color(0xFF606060);
  static const resultText = Color(0xFF2C2C2C);
  static const operatorText = Color(0xFFFFFFFF);
}

/// Root widget
class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const CalculatorScreen(),
    );
  }
}

/// Main calculator screen - a StatefulWidget that holds all calculator state.
/// Displays the calculator UI and handles user input for calculations.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // --- Theme ---
  bool _isDarkMode = true;

  // --- State variables ---
  /// The expression/input currently displayed (e.g., "12 + 5")
  String _display = '0';

  /// The result of the last calculation (shown after pressing =)
  String _result = '';

  /// First operand for binary operations
  double? _firstNumber;

  /// The operator currently selected (+, -, *, /, %)
  String? _operator;

  /// Indicates whether we're entering the second number (after operator)
  bool _isSecondNumber = false;

  /// Tracks if an error occurred (e.g., division by zero)
  bool _hasError = false;

  // --- Digit button handler ---
  /// Appends a digit to the display. Handles leading zeros and decimal input.
  void _onDigitPressed(String digit) {
    if (_hasError) return;

    setState(() {
      if (_isSecondNumber) {
        // Starting fresh second number entry
        _display = digit == '0' ? '0' : digit;
        _isSecondNumber = false;
      } else {
        // Append to current number (avoid multiple leading zeros)
        if (_display == '0' && digit != '.') {
          _display = digit;
        } else {
          _display += digit;
        }
      }
      _result = '';
    });
  }

  // --- Decimal point handler ---
  /// Adds a decimal point if the current number doesn't already have one.
  void _onDecimalPressed() {
    if (_hasError) return;

    setState(() {
      if (_isSecondNumber) {
        _display = '0.';
        _isSecondNumber = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
      _result = '';
    });
  }

  // --- Operator button handler ---
  /// Sets the operator. Only one operator is active at a time.
  /// If user presses a new operator while one is active, we perform the
  /// pending calculation first and use the result as the new first number.
  void _onOperatorPressed(String operatorSymbol) {
    if (_hasError) return;

    setState(() {
      final currentValue = double.tryParse(_display) ?? 0;

      if (_operator == null) {
        // No previous operator - store first number and operator
        _firstNumber = currentValue;
        _operator = operatorSymbol;
        _isSecondNumber = true;
      } else {
        // Operator already set - perform pending calculation, then set new operator
        final prevOperator = _operator!;
        double? calculated;

        if (prevOperator == '/') {
          if (currentValue == 0) {
            _hasError = true;
            _result = 'Error: Division by zero';
            return;
          }
          calculated = _firstNumber! / currentValue;
        } else if (prevOperator == '%') {
          if (currentValue == 0) {
            _hasError = true;
            _result = 'Error: Modulus by zero';
            return;
          }
          calculated = _firstNumber! % currentValue;
        } else if (prevOperator == '+') {
          calculated = _firstNumber! + currentValue;
        } else if (prevOperator == '-') {
          calculated = _firstNumber! - currentValue;
        } else if (prevOperator == '*') {
          calculated = _firstNumber! * currentValue;
        }

        if (calculated != null) {
          _firstNumber = calculated;
          _display = _formatResult(calculated);
        }
        _operator = operatorSymbol;
        _isSecondNumber = true;
      }
      _result = '';
    });
  }

  /// Formats a double for display (removes trailing .0, adds commas).
  String _formatResult(double value) {
    String resultStr = value.toString();
    if (resultStr.endsWith('.0')) {
      resultStr = resultStr.substring(0, resultStr.length - 2);
    }
    // Add thousand separators (e.g. 12454 -> 12,454)
    if (resultStr.contains('.')) {
      final parts = resultStr.split('.');
      resultStr = '${_addCommas(parts[0])}.${parts[1]}';
    } else {
      resultStr = _addCommas(resultStr);
    }
    return resultStr;
  }

  String _addCommas(String s) {
    final neg = s.startsWith('-');
    if (neg) s = s.substring(1);
    final sb = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) sb.write(',');
      sb.write(s[i]);
    }
    return neg ? '-${sb.toString()}' : sb.toString();
  }

  // --- Equals handler ---
  /// Performs the calculation and displays the result.
  /// Handles division by zero safely.
  void _onEqualsPressed() {
    if (_hasError || _operator == null) return;

    setState(() {
      final secondNumber = double.tryParse(_display) ?? 0;

      double? calculatedResult;

      switch (_operator) {
        case '+':
          calculatedResult = _firstNumber! + secondNumber;
          break;
        case '-':
          calculatedResult = _firstNumber! - secondNumber;
          break;
        case '*':
          calculatedResult = _firstNumber! * secondNumber;
          break;
        case '/':
          if (secondNumber == 0) {
            _hasError = true;
            _result = 'Error: Division by zero';
            return;
          }
          calculatedResult = _firstNumber! / secondNumber;
          break;
        case '%':
          if (secondNumber == 0) {
            _hasError = true;
            _result = 'Error: Modulus by zero';
            return;
          }
          // Standard modulus: remainder of division
          calculatedResult = _firstNumber! % secondNumber;
          break;
      }

      if (calculatedResult != null) {
        _result = _formatResult(calculatedResult);

        // Result becomes new first number for chained calculations
        _firstNumber = calculatedResult;
        _display = _result;
        _isSecondNumber = true;
      }
    });
  }

  // --- Clear handler ---
  /// Resets all calculator state to initial values (Ac = All Clear).
  void _onClearPressed() {
    setState(() {
      _display = '0';
      _result = '';
      _firstNumber = null;
      _operator = null;
      _isSecondNumber = false;
      _hasError = false;
    });
  }

  // --- Backspace handler ---
  /// Removes the last character from the display.
  void _onBackspacePressed() {
    if (_hasError) return;

    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
      _result = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _isDarkMode
            ? const BoxDecoration(
                color: CalcColorsDark.mainBackground,
              )
            : const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    CalcColorsLight.mainBackgroundGradientStart,
                    CalcColorsLight.mainBackgroundGradientEnd,
                  ],
                ),
              ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                Expanded(flex: 1, child: _buildDisplay()),
                const SizedBox(height: 20),
                Expanded(flex: 3, child: _buildButtonGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Display panel - theme-aware input and result lines
  Widget _buildDisplay() {
    final inputColor =
        _isDarkMode ? CalcColorsDark.inputText : CalcColorsLight.inputText;
    final resultColor = _hasError
        ? Colors.red
        : (_isDarkMode
            ? CalcColorsDark.resultText
            : CalcColorsLight.resultText);
    final displayBg = _isDarkMode
        ? CalcColorsDark.displayBackground
        : CalcColorsLight.displayBackground;
    final iconColor = _isDarkMode ? CalcColorsDark.digitText : CalcColorsLight.digitText;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: displayBg,
      ),
      child: Stack(
        children: [
          // Input and result - right aligned
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Input/expression line
              Text(
                _display,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w400,
                  color: inputColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
              const SizedBox(height: 8),
              // Result line - = prefix
              Text(
                '=${_result.isNotEmpty ? _result : _display}',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ],
          ),
          // Theme toggle - top right, compact
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => setState(() => _isDarkMode = !_isDarkMode),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  _isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: iconColor,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Keypad - Figma layout: 6 rows, + and = span 2 rows, 0 spans 2 cols
  Widget _buildButtonGrid() {
    const spacing = 12.0;

    return Column(
      children: [
        // Row 1: e, μ, sin, deg (scientific - display only)
        Expanded(
          child: _buildButtonRow(
            ['e', 'μ', 'sin', 'deg'],
            isScientific: true,
          ),
        ),
        SizedBox(height: spacing),
        // Row 2: Ac, Backspace, /, *
        Expanded(child: _buildButtonRow(['Ac', '⌫', '/', '*'])),
        SizedBox(height: spacing),
        // Row 3: 7, 8, 9, -
        Expanded(child: _buildButtonRow(['7', '8', '9', '-'])),
        SizedBox(height: spacing),
        // Rows 4-6: + and = span 2 rows each, 0 spans 2 cols
        Expanded(
          flex: 3,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Expanded(
                      child: _buildButtonRow(['4', '5', '6']),
                    ),
                    SizedBox(height: spacing),
                    Expanded(
                      child: _buildButtonRow(['1', '2', '3']),
                    ),
                    SizedBox(height: spacing),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildCalcButton('0', CalcButtonType.digit),
                          ),
                          SizedBox(width: spacing),
                          Expanded(
                            child: _buildCalcButton(
                              '.',
                              CalcButtonType.digit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildCalcButton('+', CalcButtonType.operator),
                    ),
                    SizedBox(height: spacing),
                    Expanded(
                      flex: 2,
                      child: _buildCalcButton('=', CalcButtonType.equals),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtonRow(
    List<String> labels, {
    bool isScientific = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: _buildCalcButton(
              labels[i],
              _getButtonType(labels[i], isScientific),
            ),
          ),
        ],
      ],
    );
  }

  CalcButtonType _getButtonType(String label, bool isScientific) {
    if (isScientific) return CalcButtonType.scientific;
    if (label == 'Ac') return CalcButtonType.control;
    if (label == '⌫') return CalcButtonType.backspace;
    if (label == '=') return CalcButtonType.equals;
    if (['+', '-', '*', '/'].contains(label)) return CalcButtonType.operator;
    return CalcButtonType.digit;
  }

  /// Single button - theme-aware Figma styling
  Widget _buildCalcButton(String label, CalcButtonType type) {
    late Color bg;
    late Color fg;
    double fontSize = 24;
    List<BoxShadow>? shadows;

    if (_isDarkMode) {
      switch (type) {
        case CalcButtonType.digit:
        case CalcButtonType.scientific:
          bg = CalcColorsDark.digitButtonBg;
          fg = CalcColorsDark.digitText;
          if (type == CalcButtonType.scientific) fontSize = 18;
          break;
        case CalcButtonType.control:
        case CalcButtonType.backspace:
          bg = CalcColorsDark.controlButtonBg;
          fg = CalcColorsDark.controlText;
          break;
        case CalcButtonType.operator:
        case CalcButtonType.equals:
          bg = CalcColorsDark.operatorButtonBg;
          fg = CalcColorsDark.controlText;
          break;
      }
    } else {
      switch (type) {
        case CalcButtonType.digit:
        case CalcButtonType.scientific:
          bg = CalcColorsLight.digitButtonBg;
          fg = CalcColorsLight.digitText;
          if (type == CalcButtonType.scientific) fontSize = 18;
          shadows = [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ];
          break;
        case CalcButtonType.control:
        case CalcButtonType.backspace:
          bg = CalcColorsLight.controlButtonBg;
          fg = CalcColorsLight.controlText;
          shadows = [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.5),
              offset: const Offset(-2, -2),
              blurRadius: 4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              offset: const Offset(2, 2),
              blurRadius: 4,
            ),
          ];
          break;
        case CalcButtonType.operator:
          if (label == '-') {
            bg = CalcColorsLight.digitButtonBg;
            fg = CalcColorsLight.digitText;
            shadows = [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                offset: const Offset(-2, -2),
                blurRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(2, 2),
                blurRadius: 4,
              ),
            ];
          } else {
            bg = CalcColorsLight.operatorButtonBg;
            fg = CalcColorsLight.operatorText;
            shadows = [
              BoxShadow(
                color: const Color(0xFF007AFF).withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ];
          }
          break;
        case CalcButtonType.equals:
          bg = CalcColorsLight.operatorButtonBgSolid;
          fg = CalcColorsLight.operatorText;
          shadows = [
            BoxShadow(
              color: const Color(0xFF007AFF).withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ];
          break;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _onButtonTap(label),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: shadows,
            ),
            alignment: Alignment.center,
            child: label == '⌫'
                ? Icon(Icons.backspace_outlined, color: fg, size: 24)
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w500,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// Routes button taps to the appropriate handler.
  void _onButtonTap(String label) {
    if (label == 'Ac') {
      _onClearPressed();
    } else if (label == '⌫') {
      _onBackspacePressed();
    } else if (label == '=') {
      _onEqualsPressed();
    } else if (label == '.') {
      _onDecimalPressed();
    } else if (['+', '-', '*', '/'].contains(label)) {
      _onOperatorPressed(label);
    } else if (['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'].contains(label)) {
      _onDigitPressed(label);
    }
    // e, μ, sin, deg - no action (scientific, not implemented)
  }
}
