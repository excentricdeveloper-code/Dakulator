import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
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
  bool _isSolving = false;
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

  Future<void> _solve() async {
    if (_isSolving) return;
    performVibration();
    String equation = _controller.text.trim();
    if (equation.isEmpty) {
      setState(() {
        _stepsText = '';
        _rootsText = '';
      });
      return;
    }

    setState(() {
      _isSolving = true;
      _rootsText = 'Solving...';
      _stepsText = '';
    });

    try {
      // Offload to isolate using compute
      final result = await compute(_solvePolynomialIsolate, equation);

      setState(() {
        _rootsText = result['rootsText'] ?? '';
        _stepsText = result['stepsText'] ?? '';
        if (_rootsText.isNotEmpty && !_rootsText.contains("Error")) {
          _historyList.insert(0, HistoryItem("$equation\n$_rootsText"));
          saveHistory('polynomial_history', _historyList);
        }
      });
    } catch (e) {
      setState(() {
        _rootsText = "An unexpected error occurred.";
        _stepsText = e.toString();
      });
    } finally {
      setState(() => _isSolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Polynomial Solver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
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
                      decoration: const InputDecoration(
                          labelText: 'e.g. (x-1)(x-2)=0',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSolving ? null : _solve,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white),
                        child: _isSolving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('SOLVE'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(_rootsText,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
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
            IconButton(
                icon: const Icon(Icons.keyboard_hide, color: Colors.white),
                onPressed: () => setState(() => _isKeyboardVisible = false))
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
      children: keys
          .map((k) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[900],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4))),
                    onPressed: () => k == 'del' ? _onBackspace() : _onKeyboardPress(k),
                    child: Text(k, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

/// Top-level function for compute()
Map<String, String> _solvePolynomialIsolate(String equation) {
  try {
    final results = PolynomialParser.parseEquation(equation);
    final polyMap = results['final']!;
    final lhsMap = results['lhs']!;
    final rhsMap = results['rhs']!;

    final expandedLHS = _polyMapToStringStatic(lhsMap);
    final expandedRHS = _polyMapToStringStatic(rhsMap);

    final steps = StringBuffer();
    steps.writeln("1. Original Equation:");
    steps.writeln("   $equation");
    steps.writeln("2. Expand both sides:");
    steps.writeln("   $expandedLHS = $expandedRHS");
    steps.writeln("3. Move all terms to one side:");
    steps.writeln("   $expandedLHS - ($expandedRHS) = 0");

    final finalForm = _polyMapToStringStatic(polyMap);
    steps.writeln("4. Combine like terms (Standard Form):");
    steps.writeln("   $finalForm = 0");

    List<ComplexResult> roots = _solvePolynomialStatic(polyMap, steps);

    String rootsText;
    if (roots.isEmpty) {
      rootsText = "No roots found or unsupported degree.";
    } else {
      rootsText = "Roots: ${roots.map((r) => r.toString()).join(", ")}";
    }

    return {
      'rootsText': rootsText,
      'stepsText': steps.toString(),
    };
  } on FormatException catch (e) {
    return {'rootsText': "Error: ${e.message}", 'stepsText': "Please check the equation format."};
  } catch (e) {
    return {'rootsText': "Error", 'stepsText': e.toString()};
  }
}

List<ComplexResult> _solvePolynomialStatic(Map<int, Fraction> poly, StringBuffer steps) {
  int degree = 0;
  poly.forEach((d, c) {
    if (c.numerator != 0 && d > degree) degree = d;
  });

  if (degree == 0) {
    steps.writeln("\n5. Constant equation: No variable to solve for.");
    return [];
  }

  if (degree == 1) {
    double a = poly[1]?.doubleValue ?? 0;
    double b = poly[0]?.doubleValue ?? 0;
    double root = -b / a;
    steps.writeln("\n5. Linear Equation (ax + b = 0):");
    steps.writeln("   x = -$b / $a = ${formatRoot(root)}");
    return [ComplexResult(realPart: formatRoot(root), imaginaryPart: "0")];
  }

  if (degree == 2) {
    double a = poly[2]?.doubleValue ?? 0;
    double b = poly[1]?.doubleValue ?? 0;
    double c = poly[0]?.doubleValue ?? 0;
    steps.writeln("\n5. Quadratic Equation (ax² + bx + c = 0):");
    double discriminant = b * b - 4 * a * c;
    if (discriminant >= 0) {
      double r1 = (-b + math.sqrt(discriminant)) / (2 * a);
      double r2 = (-b - math.sqrt(discriminant)) / (2 * a);
      return [
        ComplexResult(realPart: formatRoot(r1), imaginaryPart: "0"),
        ComplexResult(realPart: formatRoot(r2), imaginaryPart: "0")
      ];
    } else {
      double real = -b / (2 * a);
      double imag = math.sqrt(-discriminant) / (2 * a);
      return [
        ComplexResult(realPart: formatRoot(real), imaginaryPart: formatRoot(imag), isComplex: true),
        ComplexResult(realPart: formatRoot(real), imaginaryPart: formatRoot(-imag), isComplex: true)
      ];
    }
  }

  if (degree > 5) {
    steps.writeln("\n5. Note: Solver handles up to degree 5 (Quintic).");
    return [];
  }

  steps.writeln("\n5. Higher Degree Polynomial (Degree $degree):");
  steps.writeln("   Finding roots using Durand-Kerner numerical method.");
  
  return _solveNumericalStatic(poly, degree, steps);
}

List<ComplexResult> _solveNumericalStatic(Map<int, Fraction> poly, int degree, StringBuffer steps) {
  List<_Complex> coeffs = List.generate(degree + 1, (i) => _Complex((poly[degree - i]?.doubleValue ?? 0), 0));
  _Complex leadCoeff = coeffs[0];
  if (leadCoeff.real == 0) return [];
  
  for (int i = 0; i < coeffs.length; i++) {
    coeffs[i] = coeffs[i] / leadCoeff;
  }

  _Complex initialBase = _Complex(0.4, 0.9);
  List<_Complex> roots = List.generate(degree, (i) => initialBase.pow(i));

  for (int iter = 0; iter < 1000; iter++) {
    bool converged = true;
    for (int i = 0; i < degree; i++) {
      _Complex pZi = _evaluatePolyStatic(coeffs, roots[i]);
      _Complex denom = _Complex(1, 0);
      for (int j = 0; j < degree; j++) {
        if (i == j) continue;
        denom = denom * (roots[i] - roots[j]);
      }
      _Complex delta = pZi / denom;
      roots[i] = roots[i] - delta;
      if (delta.abs() > 1e-12) converged = false;
    }
    if (converged) break;
  }

  List<ComplexResult> results = [];
  for (var c in roots) {
    double re = c.real;
    double im = c.imag;
    if (im.abs() < 1e-9) im = 0;
    if (re.abs() < 1e-9) re = 0;
    results.add(ComplexResult(
      realPart: formatRoot(re),
      imaginaryPart: formatRoot(im),
      isComplex: im != 0,
    ));
  }
  return results;
}

_Complex _evaluatePolyStatic(List<_Complex> coeffs, _Complex z) {
  _Complex res = coeffs[0];
  for (int i = 1; i < coeffs.length; i++) {
    res = res * z + coeffs[i];
  }
  return res;
}

String _polyMapToStringStatic(Map<int, Fraction> map) {
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
      if (absC != "1") {
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

class _Complex {
  final double real;
  final double imag;
  _Complex(this.real, this.imag);

  _Complex operator +(covariant _Complex other) => _Complex(real + other.real, imag + other.imag);
  _Complex operator -(covariant _Complex other) => _Complex(real - other.real, imag - other.imag);
  _Complex operator *(covariant _Complex other) => _Complex(real * other.real - imag * other.imag, real * other.imag + imag * other.real);
  _Complex operator /(covariant _Complex other) {
    double den = other.real * other.real + other.imag * other.imag;
    if (den == 0) return _Complex(0, 0);
    return _Complex((real * other.real + imag * other.imag) / den, (imag * other.real - real * other.imag) / den);
  }
  _Complex pow(int n) {
    _Complex res = _Complex(1, 0);
    for (int i = 0; i < n; i++) {
      res = res * this;
    }
    return res;
  }
  double abs() => math.sqrt(real * real + imag * imag);
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

  String get _peek => _pos < _text.length ? _text[_pos] : '\0';
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
