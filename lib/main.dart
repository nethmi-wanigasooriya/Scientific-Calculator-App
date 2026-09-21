import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(const ScientificCalculatorApp());
}

class ScientificCalculatorApp extends StatefulWidget {
  const ScientificCalculatorApp({super.key});

  @override
  State<ScientificCalculatorApp> createState() => _ScientificCalculatorAppState();
}

class _ScientificCalculatorAppState extends State<ScientificCalculatorApp> {
  // Theme state: default to dark mode
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scientific Calculator',
      themeMode: _themeMode,
      // Light Theme configuration
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF2F4F7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2E6FF2),
          surface: Color(0xFFFFFFFF),
          onSurface: Colors.black87,
        ),
      ),
      // Dark Theme configuration
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF17171C),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4B5EAA),
          surface: Color(0xFF21222A),
          onSurface: Colors.white,
        ),
      ),
      home: CalculatorScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}

// Data model for storing calculation history
class CalculationHistory {
  final String expression;
  final String result;

  CalculationHistory({required this.expression, required this.result});
}

class CalculatorScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const CalculatorScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '0';
  final List<CalculationHistory> _historyList = [];

  // Handle keypad button taps
  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '0';
      } else if (value == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (value == '=') {
        _evaluateExpression();
      } else {
        _expression += value;
      }
    });
  }

  // Parse and evaluate expression with ShuntingYardParser
  void _evaluateExpression() {
    if (_expression.trim().isEmpty) return;

    try {
      String parsedExp = _expression
          .replaceAll('×', '*')
          .replaceAll('÷', '/')
          .replaceAll('π', '3.14159265')
          .replaceAll('e', '2.71828182');

      ShuntingYardParser p = ShuntingYardParser();
      Expression exp = p.parse(parsedExp);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      String calculatedResult;
      if (eval % 1 == 0) {
        calculatedResult = eval.toInt().toString();
      } else {
        calculatedResult = eval.toStringAsFixed(4);
      }

      setState(() {
        _result = calculatedResult;
        // Prepend to history list
        _historyList.insert(
          0,
          CalculationHistory(expression: _expression, result: _result),
        );
      });
    } catch (e) {
      setState(() {
        _result = 'Error';
      });
    }
  }

  // Open calculation history bottom sheet
  void _showHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Calculation History 📜',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_historyList.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Clear History',
                          onPressed: () {
                            setState(() {
                              _historyList.clear();
                            });
                            setModalState(() {});
                          },
                        ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: _historyList.isEmpty
                        ? const Center(
                            child: Text(
                              'No history recorded yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _historyList.length,
                            itemBuilder: (context, index) {
                              final item = _historyList[index];
                              return ListTile(
                                title: Text(
                                  item.expression,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                subtitle: Text(
                                  '= ${item.result}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.lightBlueAccent,
                                  ),
                                ),
                                onTap: () {
                                  // Reuse expression from history
                                  setState(() {
                                    _expression = item.expression;
                                    _result = item.result;
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper widget to build keypad buttons
  Widget _buildButton(String text, {Color? customColor, Color? textColor}) {
    bool isDark = widget.isDarkMode;
    Color defaultBtnColor = isDark ? const Color(0xFF2E2F38) : Colors.white;

    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: customColor ?? defaultBtnColor,
            elevation: isDark ? 0 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          onPressed: () => _onButtonPressed(text),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor ?? (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = widget.isDarkMode;
    Color primaryFuncColor = isDark ? const Color(0xFF4B5EAA) : const Color(0xFF6C63FF);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scientific Calculator 🧮'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // History button
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: _showHistoryModal,
          ),
          // Theme toggle button
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Expression and Result display screen
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        _expression.isEmpty ? '0' : _expression,
                        style: TextStyle(
                          fontSize: 32,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _result,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.lightBlueAccent : Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Keypad container
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Row 1: Trigonometric & Logarithmic functions
                  Row(
                    children: [
                      _buildButton('sin(', customColor: primaryFuncColor, textColor: Colors.white),
                      _buildButton('cos(', customColor: primaryFuncColor, textColor: Colors.white),
                      _buildButton('tan(', customColor: primaryFuncColor, textColor: Colors.white),
                      _buildButton('ln(', customColor: primaryFuncColor, textColor: Colors.white),
                    ],
                  ),
                  // Row 2: Roots, Powers & Constants
                  Row(
                    children: [
                      _buildButton('sqrt(', customColor: primaryFuncColor, textColor: Colors.white),
                      _buildButton('^', customColor: primaryFuncColor, textColor: Colors.white),
                      _buildButton('π', customColor: primaryFuncColor, textColor: Colors.white),
                      _buildButton('e', customColor: primaryFuncColor, textColor: Colors.white),
                    ],
                  ),
                  // Row 3: Clear, Backspace & Parentheses
                  Row(
                    children: [
                      _buildButton('C', customColor: Colors.redAccent, textColor: Colors.white),
                      _buildButton('⌫', customColor: Colors.orangeAccent, textColor: Colors.white),
                      _buildButton('(', customColor: isDark ? const Color(0xFF4E505F) : const Color(0xFFE0E0E0)),
                      _buildButton(')', customColor: isDark ? const Color(0xFF4E505F) : const Color(0xFFE0E0E0)),
                    ],
                  ),
                  // Row 4: Digits 7-9 & Division
                  Row(
                    children: [
                      _buildButton('7'),
                      _buildButton('8'),
                      _buildButton('9'),
                      _buildButton('÷', customColor: Colors.blueAccent, textColor: Colors.white),
                    ],
                  ),
                  // Row 5: Digits 4-6 & Multiplication
                  Row(
                    children: [
                      _buildButton('4'),
                      _buildButton('5'),
                      _buildButton('6'),
                      _buildButton('×', customColor: Colors.blueAccent, textColor: Colors.white),
                    ],
                  ),
                  // Row 6: Digits 1-3 & Subtraction
                  Row(
                    children: [
                      _buildButton('1'),
                      _buildButton('2'),
                      _buildButton('3'),
                      _buildButton('-', customColor: Colors.blueAccent, textColor: Colors.white),
                    ],
                  ),
                  // Row 7: Decimal, Zero, Equals & Addition
                  Row(
                    children: [
                      _buildButton('.'),
                      _buildButton('0'),
                      _buildButton('=', customColor: Colors.greenAccent, textColor: Colors.black),
                      _buildButton('+', customColor: Colors.blueAccent, textColor: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}