import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'utils.dart';
import 'history_screen.dart';
import 'main.dart';
import 'ui_components.dart';

// A robust class to handle parsing, operations, and normalization.
class _ScientificNumber {
  final double coefficient;
  final int exponent;

  _ScientificNumber(this.coefficient, this.exponent);

  static _ScientificNumber? tryParse(String s) {
    s = s.replaceAll(' ', '').toLowerCase();
    if (s.isEmpty) return null;

    if (s.contains('x10^')) {
      final parts = s.split('x10^');
      if (parts.length != 2) return null;
      final coeff = double.tryParse(parts[0]);
      final exp = int.tryParse(parts[1]);
      if (coeff == null || exp == null) return null;
      return _ScientificNumber(coeff, exp);
    } else if (s.contains('e')) {
      final parts = s.split('e');
      if (parts.length != 2) return null;
      final coeff = double.tryParse(parts[0]);
      final exp = int.tryParse(parts[1]);
      if (coeff == null || exp == null) return null;
      return _ScientificNumber(coeff, exp);
    } else {
      final coeff = double.tryParse(s);
      if (coeff == null) return null;
      return _ScientificNumber(coeff, 0).normalize();
    }
  }

  _ScientificNumber normalize() {
    if (coefficient == 0) return _ScientificNumber(0, 0);

    double newCoeff = coefficient;
    int newExp = exponent;
    final magnitude = newCoeff != 0 ? math.log(newCoeff.abs()) / math.ln10 : 0;
    int shift = magnitude.floor();

    newCoeff /= math.pow(10, shift);
    newExp += shift;
    
    return _ScientificNumber(newCoeff, newExp);
  }

  @override
  String toString() {
    final coeffFormat = NumberFormat('0.######');
    return "${coeffFormat.format(coefficient)} x 10^$exponent";
  }
}

class ScientificNotationSolverScreen extends StatefulWidget {
  const ScientificNotationSolverScreen({super.key});

  @override
  State<ScientificNotationSolverScreen> createState() => _ScientificNotationSolverScreenState();
}

class _ScientificNotationSolverScreenState extends State<ScientificNotationSolverScreen> {
  final TextEditingController _num1Controller = TextEditingController();
  final TextEditingController _num2Controller = TextEditingController();
  TextEditingController? _activeController;

  String _operation = '×';
  String _resultText = '';
  String _stepsText = '';
  bool _isKeyboardVisible = false;
  bool _isSolving = false;
  List<HistoryItem> _historyList = [];

  @override
  void initState() {
    super.initState();
    _activeController = _num1Controller;
    _loadHistory();
  }
  
  Future<void> _loadHistory() async {
    _historyList = await loadHistory('scientific_notation_history');
    setState(() {});
  }

  void _onKeyboardPress(String text) {
    performVibration();
    if (_activeController == null) return;
    final currentText = _activeController!.text;
    final selection = _activeController!.selection;
    final newText = currentText.replaceRange(selection.start, selection.end, text);
    _activeController!.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  void _onBackspace() {
    performVibration();
    if (_activeController == null) return;
    final currentText = _activeController!.text;
    final selection = _activeController!.selection;
    if (selection.start > 0) {
      final newText = currentText.replaceRange(selection.start - 1, selection.end, '');
      _activeController!.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start - 1),
      );
    }
  }

  void _solve() {
    if (_isSolving) return;
    performVibration();
    
    setState(() {
      _isSolving = true;
      _resultText = 'Solving...';
      _stepsText = '';
    });

    try {
      final num1 = _ScientificNumber.tryParse(_num1Controller.text);
      final num2 = _ScientificNumber.tryParse(_num2Controller.text);

      if (num1 == null || num2 == null) {
        setState(() {
          _resultText = 'Invalid Input';
          _stepsText = 'Please enter valid numbers in both fields. Use "x10^" or "E" for exponent.';
        });
        return;
      }

      _ScientificNumber result;
      String steps;
      String historyEquation;

      switch (_operation) {
        case '×':
          result = _multiply(num1, num2);
          steps = "1. Multiply Coefficients:\n   ${num1.coefficient} * ${num2.coefficient} = ${num1.coefficient * num2.coefficient}\n\n";
          steps += "2. Add Exponents:\n   ${num1.exponent} + ${num2.exponent} = ${num1.exponent + num2.exponent}\n\n";
          steps += "3. Un-normalized Result:\n   ${_ScientificNumber(num1.coefficient * num2.coefficient, num1.exponent + num2.exponent)}\n\n";
          steps += "4. Final Normalized Answer:\n   ${result.toString()}";
          break;
        case '÷':
          if(num2.coefficient == 0) {
            setState((){
              _resultText = 'Error'; _stepsText = 'Cannot divide by zero.';
            });
            return;
          }
          result = _divide(num1, num2);
          steps = "1. Divide Coefficients:\n   ${num1.coefficient} / ${num2.coefficient} = ${num1.coefficient / num2.coefficient}\n\n";
          steps += "2. Subtract Exponents:\n   ${num1.exponent} - ${num2.exponent} = ${num1.exponent - num2.exponent}\n\n";
          steps += "3. Un-normalized Result:\n   ${_ScientificNumber(num1.coefficient / num2.coefficient, num1.exponent - num2.exponent)}\n\n";
          steps += "4. Final Normalized Answer:\n   ${result.toString()}";
          break;
        case '+':
        case '-':
          final res = _addOrSubtract(num1, num2, isSubtract: _operation == '-');
          result = res['result']!;
          steps = res['steps']! as String;
          break;
        default:
          return;
      }
      
      historyEquation = "(${_num1Controller.text}) $_operation (${_num2Controller.text}) = ${result.toString()}";

      setState(() {
        _resultText = "Result: ${result.toString()}";
        _stepsText = steps;
        _historyList.insert(0, HistoryItem(historyEquation));
        saveHistory('scientific_notation_history', _historyList);
      });
    } catch (e) {
      setState(() {
        _resultText = 'Error';
        _stepsText = 'An unexpected calculation error occurred: $e';
      });
    } finally {
      setState(() => _isSolving = false);
    }
  }

   Map<String, dynamic> _addOrSubtract(_ScientificNumber n1, _ScientificNumber n2, {required bool isSubtract}) {
    final opSymbol = isSubtract ? '-' : '+';
    final opWord = isSubtract ? 'Subtract' : 'Add';

    String steps = "1. Align exponents to the largest value.\n";
    int maxExp = math.max(n1.exponent, n2.exponent);
    steps += "   Largest exponent is $maxExp.\n";

    double c1 = n1.coefficient * math.pow(10, n1.exponent - maxExp);
    double c2 = n2.coefficient * math.pow(10, n2.exponent - maxExp);
    steps += "   Number 1 becomes: ${NumberFormat('0.######').format(c1)} x 10^$maxExp\n";
    steps += "   Number 2 becomes: ${NumberFormat('0.######').format(c2)} x 10^$maxExp\n\n";

    double finalCoeff = isSubtract ? (c1 - c2) : (c1 + c2);
    steps += "2. $opWord New Coefficients:\n   ${NumberFormat('0.######').format(c1)} $opSymbol ${NumberFormat('0.######').format(c2)} = ${NumberFormat('0.######').format(finalCoeff)}\n\n";
    steps += "3. Un-normalized Result:\n   ${NumberFormat('0.######').format(finalCoeff)} x 10^$maxExp\n\n";

    _ScientificNumber result = _ScientificNumber(finalCoeff, maxExp).normalize();
    steps += "4. Final Normalized Answer:\n   ${result.toString()}";

    return {'result': result, 'steps': steps};
  }

  _ScientificNumber _multiply(_ScientificNumber n1, _ScientificNumber n2) {
    return _ScientificNumber(n1.coefficient * n2.coefficient, n1.exponent + n2.exponent).normalize();
  }

  _ScientificNumber _divide(_ScientificNumber n1, _ScientificNumber n2) {
    return _ScientificNumber(n1.coefficient / n2.coefficient, n1.exponent - n2.exponent).normalize();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scientific Notation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(
                    storageKey: 'scientific_notation_history',
                    title: 'Scientific Notation History',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode 
                ? [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)]
                : [Colors.grey[50]!, Colors.grey[200]!],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              GlassCard(
                opacity: isDarkMode ? 0.05 : 0.2,
                child: Column(
                  children: [
                    _buildInputField(_num1Controller, 'Number 1'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white10),
                    ),
                    Center(child: _buildOperationSelector()),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.white10),
                    ),
                    _buildInputField(_num2Controller, 'Number 2'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, 
                child: ElevatedButton(
                  onPressed: _isSolving ? null : _solve, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? TechColors.primary : Colors.orange, 
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ), 
                  child: _isSolving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SOLVE NOTATION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5))
                )
              ),
              if (_resultText.isNotEmpty) ...[
                const SizedBox(height: 24),
                GlassCard(
                  opacity: isDarkMode ? 0.1 : 0.2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Result",
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold, 
                          color: isDarkMode ? TechColors.primary : Colors.orange,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          _resultText.replaceFirst('Result: ', ''),
                          style: TextStyle(
                            fontSize: 20, 
                            fontWeight: FontWeight.bold, 
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (_stepsText.isNotEmpty) ...[
                        const Divider(height: 32),
                        Text(
                          "Solution Steps",
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold, 
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _stepsText,
                          style: TextStyle(
                            fontFamily: 'monospace', 
                            fontSize: 14,
                            height: 1.5,
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ]))),
            if (_isKeyboardVisible) _buildCustomKeyboard(),
          ]),
        ),
      ),
    );
  }
  
  Widget _buildInputField(TextEditingController controller, String label) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isActive = _activeController == controller;

    return TextField(
      controller: controller,
      readOnly: true,
      showCursor: true,
      style: const TextStyle(fontSize: 18),
      onTap: () => setState(() {
        _activeController = controller;
        _isKeyboardVisible = true;
      }),
      decoration: InputDecoration(
        labelText: label, 
        hintText: '1.23 x 10^4', 
        labelStyle: TextStyle(
          color: isActive 
              ? (isDarkMode ? TechColors.primary : Colors.orange)
              : (isDarkMode ? Colors.white54 : Colors.black54),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        border: InputBorder.none,
        prefixIcon: Icon(
          Icons.science_rounded, 
          color: isActive 
              ? (isDarkMode ? TechColors.primary : Colors.orange) 
              : (isDarkMode ? Colors.white24 : Colors.black12)
        ),
      ),
    );
  }

  Widget _buildOperationSelector() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final operations = ['×', '÷', '+', '-'];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withAlpha(13) : Colors.black.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: operations.map((op) {
            final isSelected = _operation == op;
            return GestureDetector(
              onTap: () => setState(() => _operation = op),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? (isDarkMode ? TechColors.primary : Colors.orange)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  op,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCustomKeyboard() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black87 : Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _isKeyboardVisible = false),
                icon: const Icon(Icons.keyboard_hide_rounded, size: 20),
                label: const Text('HIDE'),
              ),
            ],
          ),
          _buildKeyboardRow(['1', '2', '3', 'x10^', 'del']),
          _buildKeyboardRow(['4', '5', '6', 'E', '(']),
          _buildKeyboardRow(['7', '8', '9', '-', ')']),
          _buildKeyboardRow(['.', '0', ' ', '(-)']),
        ],
      ),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: keys.map((key) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (key == 'del') {
                  _onBackspace();
                } else if (key == '(-)') {
                  _onKeyboardPress('-');
                } else if (key.isNotEmpty) {
                  _onKeyboardPress(key);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
                ),
                child: Center(
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: (key == 'del' || key == 'x10^' || key == 'E' || key == '(-)') 
                          ? (isDarkMode ? TechColors.primary : Colors.orange)
                          : (isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }
}

