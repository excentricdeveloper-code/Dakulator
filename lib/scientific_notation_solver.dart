import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'utils.dart';
import 'history_screen.dart';
import 'main.dart';

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
    performVibration();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scientific Notation Solver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
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
      body: SafeArea(
        child: Column(children: [
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildInputField(_num1Controller, 'Number 1'),
            const SizedBox(height: 10),
            Center(child: _buildOperationSelector()),
            const SizedBox(height: 10),
            _buildInputField(_num2Controller, 'Number 2'),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _solve, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), child: const Text('SOLVE'))),
            const SizedBox(height: 24),
            Text(_resultText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const Divider(color: Colors.orange),
            Text(_stepsText, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5)),
          ]))),
          if (_isKeyboardVisible) _buildCustomKeyboard(),
        ]),
      ),
    );
  }
  
  Widget _buildInputField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      readOnly: true,
      showCursor: true,
      onTap: () => setState(() {
        _activeController = controller;
        _isKeyboardVisible = true;
      }),
      decoration: InputDecoration(labelText: label, hintText: 'e.g., 1.23 x 10^4 or 1.23E4', border: const OutlineInputBorder()),
    );
  }

  Widget _buildOperationSelector() {
    return ToggleButtons(
      isSelected: [ _operation == '×', _operation == '÷', _operation == '+', _operation == '-' ],
      onPressed: (index) => setState(() => _operation = ['×', '÷', '+', '-'][index]),
      borderRadius: BorderRadius.circular(8),
      children: const [ Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('×', style: TextStyle(fontSize: 18))), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('÷', style: TextStyle(fontSize: 18))), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('+', style: TextStyle(fontSize: 18))), Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('-', style: TextStyle(fontSize: 18))) ],
    );
  }

  Widget _buildCustomKeyboard() {
    return Container(
      color: Colors.black, padding: const EdgeInsets.all(4), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [IconButton(icon: const Icon(Icons.keyboard_hide, color: Colors.white), onPressed: () => setState(() => _isKeyboardVisible = false))]),
        _buildKeyboardRow(['1', '2', '3', 'x10^', 'del']),
        _buildKeyboardRow(['4', '5', '6', 'E', '(']),
        _buildKeyboardRow(['7', '8', '9', '-', ')']),
        _buildKeyboardRow(['.', '0', ' ', '(-)']),
      ]),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(children: keys.map((key) => Expanded(child: Padding(padding: const EdgeInsets.all(2), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))), onPressed: () {
      if (key == 'del') _onBackspace();
      else if (key == '(-)') _onKeyboardPress('-');
      else if (key.isNotEmpty) _onKeyboardPress(key);
    }, child: Text(key, style: const TextStyle(fontSize: 16)))) )).toList());
  }
}
