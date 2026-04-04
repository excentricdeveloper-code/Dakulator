import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'main.dart';
import 'utils.dart';
import 'history_screen.dart';

class QuadraticSolverScreen extends StatefulWidget {
  const QuadraticSolverScreen({super.key});

  @override
  State<QuadraticSolverScreen> createState() => _QuadraticSolverScreenState();
}

class _QuadraticSolverScreenState extends State<QuadraticSolverScreen> {
  final TextEditingController _equationController = TextEditingController();
  String _rootsText = '';
  String _stepsText = '';
  String _solveMethod = 'Formula';
  bool _isKeyboardVisible = false;
  bool _isSolving = false;
  List<HistoryItem> _historyList = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _historyList = await loadHistory('quadratic_history');
    setState(() {});
  }

  Future<void> _saveHistory() async {
    await saveHistory('quadratic_history', _historyList);
  }

  void _onKeyboardPress(String text) {
    performVibration();
    final currentText = _equationController.text;
    final selection = _equationController.selection;
    final newText = currentText.replaceRange(selection.start, selection.end, text);
    _equationController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  void _onBackspace() {
    performVibration();
    final currentText = _equationController.text;
    final selection = _equationController.selection;
    if (selection.start > 0) {
      final newText = currentText.replaceRange(selection.start - 1, selection.end, '');
      _equationController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start - 1),
      );
    }
  }

  Future<void> _solve() async {
    if (_isSolving) return;
    performVibration();
    
    setState(() {
      _isSolving = true;
      _rootsText = 'Solving...';
      _stepsText = '';
    });

    try {
      final input = _equationController.text;
      if (input.isEmpty) {
        setState(() {
          _rootsText = '';
          _isSolving = false;
        });
        return;
      }

      // Offload the heavy computation to an isolate to prevent ANR
      final result = await compute(_solveQuadraticIsolate, {
        'equation': input,
        'method': _solveMethod,
      });

      setState(() {
        _rootsText = result['roots'] ?? '';
        _stepsText = result['steps'] ?? '';
        if (_rootsText.isNotEmpty && !_rootsText.startsWith('Error') && !_rootsText.contains("Not a quadratic")) {
          _historyList.insert(0, HistoryItem("$input\n$_rootsText"));
          _saveHistory();
        }
      });
    } catch (e) {
      setState(() {
        _rootsText = 'Error';
        _stepsText = "An unexpected error occurred: ${e.toString()}";
      });
    } finally {
      setState(() => _isSolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quadratic Solver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen(storageKey: 'quadratic_history', title: 'Quadratic History')),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: _equationController, readOnly: true, showCursor: true, decoration: const InputDecoration(labelText: 'Equation (e.g., x^2-x-6=0)', border: OutlineInputBorder()), onTap: () => setState(() => _isKeyboardVisible = true)),
            const SizedBox(height: 16),
            Row(children: [
              const Text('Method:'),
              Radio<String>(
                value: 'Formula',
                groupValue: _solveMethod,
                onChanged: (v) => setState(() => _solveMethod = v!),
                activeColor: Colors.orange,
              ),
              const Text('Formula'),
              Radio<String>(
                value: 'Factorization',
                groupValue: _solveMethod,
                onChanged: (v) => setState(() => _solveMethod = v!),
                activeColor: Colors.orange,
              ),
              const Text('Factorization')
            ]),
            SizedBox(
              width: double.infinity, 
              child: ElevatedButton(
                onPressed: _isSolving ? null : _solve, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), 
                child: _isSolving 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('SOLVE')
              )
            ),
            const SizedBox(height: 24),
            Text(_rootsText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const Divider(color: Colors.orange),
            Text(_stepsText, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ]))),
          if (_isKeyboardVisible) _buildCustomKeyboard(),
        ]),
      ),
    );
  }

  Widget _buildCustomKeyboard() {
    return Container(
      color: Colors.black, padding: const EdgeInsets.all(4), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [IconButton(icon: const Icon(Icons.keyboard_hide, color: Colors.white), onPressed: () => setState(() => _isKeyboardVisible = false))]),
        _buildKeyboardRow(['1', '2', '3', 'x', 'del']),
        _buildKeyboardRow(['4', '5', '6', '^', 'x²']),
        _buildKeyboardRow(['7', '8', '9', '+', '-']),
        _buildKeyboardRow(['.', '0', '/', '(', ')', '=']),
      ]),
    );
  }

  Widget _buildKeyboardRow(List<String> keys) {
    return Row(children: keys.map((key) => Expanded(child: Padding(padding: const EdgeInsets.all(2), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))), onPressed: () {
      if (key == 'del') {
        _onBackspace();
      } else if (key == 'x²') {
        _onKeyboardPress('^2');
      } else {
        _onKeyboardPress(key);
      }
    }, child: Text(key, style: const TextStyle(fontSize: 18)))) )).toList());
  }
}

// Top-level function for compute()
Map<String, String> _solveQuadraticIsolate(Map<String, dynamic> params) {
  String equation = params['equation'];
  String method = params['method'];
  
  try {
    if (!equation.contains('=')) equation += '=0';
    List<String> sides = equation.split('=');
    if (sides.length != 2) return {'roots': 'Error', 'steps': 'Equation must have one equals sign.'};

    _Polynomial leftPoly = _ExpressionParser(sides[0]).parse();
    _Polynomial rightPoly = _ExpressionParser(sides[1]).parse();
    _Polynomial finalPoly = leftPoly.subtract(rightPoly);

    Fraction a = finalPoly.coefficients[2] ?? Fraction(0, 1);
    Fraction b = finalPoly.coefficients[1] ?? Fraction(0, 1);
    Fraction c = finalPoly.coefficients[0] ?? Fraction(0, 1);
    
    int maxDegree = 0;
    if (finalPoly.coefficients.isNotEmpty) {
      maxDegree = finalPoly.coefficients.keys.reduce(math.max);
    }

    if (a.numerator == 0) {
      return {
        'roots': "Not a quadratic equation.",
        'steps': "Equation simplifies to degree $maxDegree (must be 2)."
      };
    }

    if (method == 'Factorization') {
      return _solveByFactorizationCore(a, b, c);
    } else {
      return _solveByFormulaCore(a, b, c);
    }
  } catch (e) {
    return {'roots': 'Error', 'steps': "Invalid equation format: $e"};
  }
}

Map<String, String> _solveByFormulaCore(Fraction a, Fraction b, Fraction c) {
  Fraction discriminant = b.multiply(b).subtract(Fraction(4, 1).multiply(a).multiply(c));
  String steps = "1. Standard Form: ($a)x² + ($b)x + ($c) = 0\n";
  steps += "2. Discriminant D = b²-4ac = ($b)² - 4($a)($c) = $discriminant\n";

  Fraction twoA = a.multiply(Fraction(2, 1));
  String rootsText;
  if (discriminant.numerator >= 0) {
    double dVal = discriminant.doubleValue;
    double r1 = (b.negate().doubleValue + math.sqrt(dVal)) / twoA.doubleValue;
    double r2 = (b.negate().doubleValue - math.sqrt(dVal)) / twoA.doubleValue;
    rootsText = "Roots: x₁ = ${formatRoot(r1)}, x₂ = ${formatRoot(r2)}";
    steps += "3. D >= 0. Roots are real.\n   x = (-b ± √D) / 2a";
  } else {
    double real = b.negate().doubleValue / twoA.doubleValue;
    double imag = math.sqrt(-discriminant.doubleValue) / twoA.doubleValue;
    
    ComplexResult cr1 = ComplexResult(realPart: formatRoot(real), imaginaryPart: formatRoot(imag), isComplex: true);
    ComplexResult cr2 = ComplexResult(realPart: formatRoot(real), imaginaryPart: formatRoot(-imag), isComplex: true);
    
    rootsText = "Roots: $cr1, $cr2";
    steps += "3. D < 0. Roots are complex conjugates.\n   x = (-$b ± i√|D|) / 2a";
  }
  return {'roots': rootsText, 'steps': steps};
}

Map<String, String> _solveByFactorizationCore(Fraction a, Fraction b, Fraction c) {
  int lcmVal = _lcm(_lcm(a.denominator, b.denominator), c.denominator);
  int intA = (a.doubleValue * lcmVal).round();
  int intB = (b.doubleValue * lcmVal).round();
  int intC = (c.doubleValue * lcmVal).round();
  int ac = intA * intC;
  int p = 0, q = 0;
  bool found = false;
  
  int absAc = ac.abs();
  // Limit factorization loop
  if (absAc > 1000000) {
    return _solveByFormulaCore(a, b, c)..['steps'] = "Note: Coefficients too large for efficient factorization. Using formula.\n\n" + _solveByFormulaCore(a, b, c)['steps']!;
  }

  for (int i = 1; i * i <= absAc; i++) {
    if (absAc % i == 0) {
      int f1 = i;
      int f2 = absAc ~/ i;
      List<List<int>> pairs = [[f1, f2], [-f1, -f2], [f1, -f2], [-f1, f2]];
      for (var pair in pairs) {
        if (pair[0] * pair[1] == ac && pair[0] + pair[1] == intB) {
          p = pair[0]; q = pair[1]; found = true; break;
        }
      }
      if (found) break;
    }
  }
  
  if (!found) {
    return {
      'roots': "Not easily factorable",
      'steps': "The polynomial cannot be factored with integers. Try using the Formula method instead."
    };
  }
  
  Fraction r1 = Fraction(-p, intA).simplify();
  Fraction r2 = Fraction(-q, intA).simplify();
  
  String steps = "1. Standard Form: ($a)x² + ($b)x + ($c) = 0\n";
  steps += "2. Multiply by LCM $lcmVal: ${intA}x² + ${intB}x + $intC = 0\n";
  steps += "3. Factor by grouping: (${_getFactoredFormStatic(intA, p, q, intC)}) = 0\n";
  steps += "4. Solve for x: x₁ = ${formatRoot(r1.doubleValue)}, x₂ = ${formatRoot(r2.doubleValue)}";

  return {
    'roots': "Roots: x₁ = ${formatRoot(r1.doubleValue)}, x₂ = ${formatRoot(r2.doubleValue)}",
    'steps': steps
  };
}

String _getFactoredFormStatic(int a, int p, int q, int c) {
  int g1 = _gcd(a.abs(), p.abs());
  int f1A = a ~/ g1, f1P = p ~/ g1;
  int g2 = _gcd(q.abs(), c.abs());
  if (q < 0) g2 = -g2.abs(); else g2 = g2.abs();
  return "(${_formatTermStatic(g1, "x")} + $g2)(${_formatTermStatic(f1A, "x")} + $f1P)";
}

String _formatTermStatic(int coeff, String variable) => "${coeff == 1 ? '' : (coeff == -1 ? '-' : coeff)}$variable";
int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
int _lcm(int a, int b) => (a == 0 || b == 0) ? 0 : (a * b).abs() ~/ _gcd(a, b);

class _Polynomial {
  Map<int, Fraction> coefficients = {};
  _Polynomial();
  _Polynomial.fromCoeff(int degree, Fraction coeff) { if (coeff.numerator != 0) coefficients[degree] = coeff; }
  _Polynomial add(_Polynomial other) {
    final result = _Polynomial()..coefficients.addAll(coefficients);
    other.coefficients.forEach((degree, coeff) {
      final newCoeff = (result.coefficients[degree] ?? Fraction(0, 1)).add(coeff);
      if (newCoeff.numerator == 0) result.coefficients.remove(degree); else result.coefficients[degree] = newCoeff;
    });
    return result;
  }
  _Polynomial subtract(_Polynomial other) => add(other.negate());
  _Polynomial multiply(_Polynomial other) {
    final result = _Polynomial();
    coefficients.forEach((d1, c1) {
      other.coefficients.forEach((d2, c2) {
        final newDegree = d1 + d2;
        final newCoeff = c1.multiply(c2);
        result.coefficients[newDegree] = (result.coefficients[newDegree] ?? Fraction(0, 1)).add(newCoeff);
      });
    });
    return result;
  }
  _Polynomial negate() {
    final result = _Polynomial();
    coefficients.forEach((degree, coeff) => result.coefficients[degree] = coeff.negate());
    return result;
  }
  _Polynomial pow(int exponent) {
    if (exponent < 0) throw Exception("Negative exponents not supported");
    if (exponent == 0) return _Polynomial.fromCoeff(0, Fraction(1, 1));
    _Polynomial result = this;
    for (int i = 1; i < exponent; i++) result = result.multiply(this);
    return result;
  }
}

class _ExpressionParser {
  final String expression;
  int pos = -1, ch = -1;
  _ExpressionParser(this.expression);
  void nextChar() => ch = (++pos < expression.length) ? expression.codeUnitAt(pos) : -1;
  bool eat(int charToEat) {
    while (ch == 32) nextChar();
    if (ch == charToEat) { nextChar(); return true; }
    return false;
  }
  _Polynomial parse() { nextChar(); final p = parseExpression(); if (pos < expression.length) throw FormatException("Unexpected char: ${String.fromCharCode(ch)}"); return p; }
  _Polynomial parseExpression() {
    var p = parseTerm();
    while (true) { if (eat(43)) p = p.add(parseTerm()); else if (eat(45)) p = p.subtract(parseTerm()); else return p; }
  }
  _Polynomial parseTerm() {
    var p = parseFactor();
    while (true) {
      if (eat(42)) p = p.multiply(parseFactor());
      else if (eat(47)) {
        final divisor = parseFactor();
        if (divisor.coefficients.keys.any((d) => d != 0)) throw FormatException("Division by variable unsupported");
        final c = divisor.coefficients[0]!;
        final res = _Polynomial();
        p.coefficients.forEach((deg, coeff) => res.coefficients[deg] = coeff.divide(c));
        p = res;
      } else if (ch == 40 || (ch >= 48 && ch <= 57) || ch == 120) p = p.multiply(parseFactor());
      else return p;
    }
  }
  _Polynomial parseFactor() {
    if (eat(43)) return parseFactor();
    if (eat(45)) return parseFactor().negate();
    _Polynomial p;
    if (eat(40)) { p = parseExpression(); if (!eat(41)) throw FormatException("Missing ')'"); }
    else if ((ch >= 48 && ch <= 57) || ch == 46) {
      int startPos = pos;
      while ((ch >= 48 && ch <= 57) || ch == 46 || ch == 47) nextChar();
      p = _Polynomial.fromCoeff(0, _parseTermCoefficient(expression.substring(startPos, pos)));
    } else if (eat(120)) p = _Polynomial.fromCoeff(1, Fraction(1, 1));
    else throw FormatException("Unexpected char: ${String.fromCharCode(ch)}");
    if (eat(94)) {
      if (p.coefficients.length > 1 || (p.coefficients.containsKey(0) && p.coefficients.length == 1)) throw FormatException("Exponentiation only on x");
      int startPos = pos;
      while (ch >= 48 && ch <= 57) nextChar();
      p = p.pow(int.parse(expression.substring(startPos, pos)));
    }
    return p;
  }
  Fraction _parseTermCoefficient(String term) {
    if (term.isEmpty || term == '+') return Fraction(1, 1);
    if (term == '-') return Fraction(-1, 1);
    if (term.contains('/')) { final parts = term.split('/'); return Fraction(int.parse(parts[0]), int.parse(parts[1])); }
    try { return Fraction.fromDouble(double.parse(term)); } catch(e) { return Fraction(0,1); }
  }
}
