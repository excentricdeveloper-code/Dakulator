import 'package:flutter/material.dart';
import 'utils.dart';
import 'main.dart';
import 'history_screen.dart';

class PolynomialSolverScreen extends StatefulWidget {
  const PolynomialSolverScreen({super.key});

  @override
  State<PolynomialSolverScreen> createState() => _PolynomialSolverScreenState();
}

class _PolynomialSolverScreenState extends State<PolynomialSolverScreen> {
  final TextEditingController _controller = TextEditingController();
  String _rootsText = '';
  String _stepsText = '';
  bool _isKeyboardVisible = false;
  List<HistoryItem> _historyList = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _historyList = await loadHistory('polynomial_history');
    setState(() {});
  }

  void _onKeyboardPress(String text) {
    performVibration();
    final currentText = _controller.text;
    final selection = _controller.selection;
    final newText = currentText.replaceRange(selection.start, selection.end, text);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  void _onBackspace() {
    performVibration();
    final currentText = _controller.text;
    final selection = _controller.selection;
    if (selection.start > 0) {
      final newText = currentText.replaceRange(selection.start - 1, selection.end, '');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start - 1),
      );
    }
  }

  void _solve() {
    performVibration();
    String equation = _controller.text.trim();
    if (equation.isEmpty) {
      setState(() {
        _stepsText = '';
        _rootsText = '';
      });
      return;
    }

    try {
      final results = PolynomialParser.parseEquation(equation);
      final polyMap = results['final']!;
      final lhsMap = results['lhs']!;
      final rhsMap = results['rhs']!;

      final expandedLHS = _polyMapToString(lhsMap);
      final expandedRHS = _polyMapToString(rhsMap);

      final steps = StringBuffer();
      steps.writeln("1. Original Equation:");
      steps.writeln("   $equation");

      steps.writeln("2. Expand both sides:");
      steps.writeln("   $expandedLHS = $expandedRHS");

      steps.writeln("3. Move all terms to one side:");
      steps.writeln("   $expandedLHS - ($expandedRHS) = 0");

      final finalForm = _polyMapToString(polyMap);
      steps.writeln("4. Combine like terms (Standard Form):");
      steps.writeln("   $finalForm = 0");

      setState(() {
        _rootsText = "Standard Form: $finalForm = 0";
        _stepsText = steps.toString();
        _historyList.insert(0, HistoryItem("$equation\n$_rootsText"));
        saveHistory('polynomial_history', _historyList);
      });
    } on FormatException catch (e) {
      setState(() {
        _rootsText = "Error: ${e.message}";
        _stepsText = "Please check the equation format.";
      });
    } catch (e) {
      setState(() {
        _rootsText = "An unexpected error occurred.";
        _stepsText = e.toString();
      });
    }
  }

  String _polyMapToString(Map<int, Fraction> map) {
    if (map.isEmpty || map.values.every((c) => c.numerator == 0)) return "0";
    List<int> sortedDegrees = map.keys.toList()..sort((a, b) => b.compareTo(a));
    StringBuffer sb = StringBuffer();
    bool first = true;
    for (int d in sortedDegrees) {
      Fraction c = map[d]!;
      if (c.numerator == 0) continue;

      String sign = c.numerator > 0 ? "+" : "-";
      String absC = c.abs().toString();

      if (!first) {
        sb.write(" $sign ");
      } else if (sign == "-") {
        sb.write("-");
      }
      
      if (d == 0) {
        sb.write(absC);
      } else {
        if (absC != "1" || d == 0) {
           sb.write(absC);
        }
        sb.write("x");
        if (d > 1) {
          sb.write("^$d");
        }
      }
      first = false;
    }
    return sb.isEmpty ? "0" : sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polynomial Solver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history), tooltip: 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(
                    storageKey: 'polynomial_history',
                    title: 'Polynomial History',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _controller,
                      readOnly: true,
                      showCursor: true,
                      onTap: () => setState(() => _isKeyboardVisible = true),
                      decoration: const InputDecoration(labelText: 'e.g. (x-1)(x-2)=0', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _solve,
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        child: const Text('SOLVE'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(_rootsText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                    const Divider(color: Colors.orange),
                    Text(_stepsText, style: const TextStyle(fontFamily: 'monospace')),
                  ],
                ),
              ),
            ),
            if (_isKeyboardVisible) _buildKeyboard(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(icon: const Icon(Icons.keyboard_hide, color: Colors.white), onPressed: () => setState(() => _isKeyboardVisible = false))
          ]),
          _buildRow(['1', '2', '3', 'x^', 'del']),
          _buildRow(['4', '5', '6', 'x', '(']),
          _buildRow(['7', '8', '9', '=', ')']),
          _buildRow(['.', '0', '+', '-', '/']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      children: keys.map((k) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            onPressed: () => k == 'del' ? _onBackspace() : _onKeyboardPress(k),
            child: Text(k, style: const TextStyle(fontSize: 18)),
          ),
        ),
      )).toList(),
    );
  }
}

class PolynomialParser {
  final String _text;
  int _pos;

  PolynomialParser._(this._text, [this._pos = 0]);

  static Map<String, Map<int, Fraction>> parseEquation(String equation) {
    String processedEquation = equation.toLowerCase().replaceAll(' ', '');
    if (processedEquation.isEmpty) {
      return {'lhs': {}, 'rhs': {}, 'final': {}};
    }
    if (!processedEquation.contains('=')) {
      processedEquation = '$processedEquation=0';
    }

    final sides = processedEquation.split('=');
    if (sides.length != 2) {
      throw FormatException('Equation must have one equals sign.');
    }

    final lhsMap = PolynomialParser._(sides[0])._parseFullExpression();
    final rhsMap = PolynomialParser._(sides[1])._parseFullExpression();

    final finalMap = _subtract(lhsMap, rhsMap);

    return {'lhs': lhsMap, 'rhs': rhsMap, 'final': finalMap};
  }
  
  Map<int, Fraction> _parseFullExpression() {
    if (_text.isEmpty) return {};
    final result = _parseExpression();
    if (_pos < _text.length) {
      throw FormatException("Unexpected character '$_peek' at position $_pos");
    }
    return result;
  }

  String get _peek => _pos < _text.length ? _text[_pos] : ' ';
  bool _isDigit(String s) => '0'.compareTo(s) <= 0 && '9'.compareTo(s) >= 0;

  void _advance() => _pos++;

  void _expect(String char) {
    if (_peek != char) {
      throw FormatException("Expected '$char' but found '$_peek' at position $_pos");
    }
    _advance();
  }

  Map<int, Fraction> _parseExpression() {
    var result = _parseTerm();
    while (_peek == '+' || _peek == '-') {
      final op = _peek;
      _advance();
      final nextTerm = _parseTerm();
      result = (op == '+') ? _add(result, nextTerm) : _subtract(result, nextTerm);
    }
    return result;
  }

  Map<int, Fraction> _parseTerm() {
    var result = _parseFactor();
    while (_pos < _text.length && ('x(.'.contains(_peek) || _isDigit(_peek))) {
      final nextFactor = _parseFactor();
      result = _multiply(result, nextFactor);
    }
    return result;
  }

  Map<int, Fraction> _parseFactor() {
    Fraction sign = Fraction(1, 1);
    if (_peek == '+') {
      _advance();
    } else if (_peek == '-') {
      _advance();
      sign = Fraction(-1, 1);
    }

    Map<int, Fraction> result;
    if (_peek == '(') {
      _advance();
      result = _parseExpression();
      _expect(')');
    } else if (_isDigit(_peek) || _peek == '.') {
      result = {0: _parseNumber()};
    } else if (_peek == 'x') {
      _advance();
      int degree = 1;
      if (_peek == '^') {
        _advance();
        if (!_isDigit(_peek)) throw FormatException("Exponent value expected at pos $_pos");
        degree = _parseInteger();
      } else if (_isDigit(_peek)) {
        degree = _parseInteger();
      }
      result = {degree: Fraction(1, 1)};
    } else {
      throw FormatException("Number, 'x', or '(' expected at position $_pos");
    }

    if (_peek == '^') {
      _advance();
      if (!_isDigit(_peek)) throw FormatException("Exponent value expected at pos $_pos");
      final exponent = _parseInteger();
      result = _power(result, exponent);
    }

    return _multiply(result, {0: sign});
  }

  Fraction _parseNumber() {
    int start = _pos;
    while (_isDigit(_peek) || _peek == '.') _advance();
    if (_peek == '/') {
      _advance();
      while (_isDigit(_peek)) _advance();
    }
    final s = _text.substring(start, _pos);
    if (s.isEmpty) throw FormatException("Number expected at position $_pos");
    return _parseCoeffString(s);
  }

  int _parseInteger() {
    if (!_isDigit(_peek)) throw FormatException("Integer expected at position $_pos");
    int start = _pos;
    while (_isDigit(_peek)) _advance();
    return int.parse(_text.substring(start, _pos));
  }

  Fraction _parseCoeffString(String s) {
    try {
      if (s.contains('/')) {
        final parts = s.split('/');
        if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
          throw FormatException("Invalid fraction format: '$s'");
        }
        final num = int.parse(parts[0]);
        final den = int.parse(parts[1]);
        if (den == 0) throw FormatException("Fraction denominator cannot be zero.");
        return Fraction(num, den);
      }
      return Fraction.fromDouble(double.parse(s));
    } catch (e) {
      throw FormatException("Invalid coefficient format: '$s'");
    }
  }

  static Map<int, Fraction> _power(Map<int, Fraction> base, int exp) {
    if (exp < 0) throw FormatException("Negative exponents are not supported.");
    if (exp == 0) return {0: Fraction(1, 1)};
    if (exp == 1) return base;

    Map<int, Fraction> result = {0: Fraction(1, 1)};
    Map<int, Fraction> currentPower = Map.from(base);

    while (exp > 0) {
      if (exp % 2 == 1) {
        result = _multiply(result, currentPower);
      }
      currentPower = _multiply(currentPower, currentPower);
      exp ~/= 2;
    }
    return result;
  }

  static Map<int, Fraction> _add(Map<int, Fraction> p1, Map<int, Fraction> p2) {
    final result = Map<int, Fraction>.from(p1);
    p2.forEach((d, c) => result[d] = (result[d] ?? Fraction(0, 1)).add(c));
    return result;
  }

  static Map<int, Fraction> _subtract(Map<int, Fraction> p1, Map<int, Fraction> p2) {
    final result = Map<int, Fraction>.from(p1);
    p2.forEach((d, c) => result[d] = (result[d] ?? Fraction(0, 1)).subtract(c));
    return result;
  }

  static Map<int, Fraction> _multiply(Map<int, Fraction> p1, Map<int, Fraction> p2) {
    final result = <int, Fraction>{};
    if (p1.isEmpty || p2.isEmpty) return result;
    p1.forEach((d1, c1) {
      p2.forEach((d2, c2) {
        final newDegree = d1 + d2;
        final newCoeff = c1.multiply(c2);
        result[newDegree] = (result[newDegree] ?? Fraction(0, 1)).add(newCoeff);
      });
    });
    return result;
  }
}
