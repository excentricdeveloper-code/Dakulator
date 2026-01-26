import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'main.dart'; // To use HistoryItem
import 'utils.dart'; // To use performVibration
import 'history_screen.dart';

// Internal helper classes for robust parsing and polynomial operations.
class _Polynomial {
  Map<int, Fraction> coefficients = {};

  _Polynomial();
  _Polynomial.fromCoeff(int degree, Fraction coeff) {
    if (coeff.numerator != 0) {
      coefficients[degree] = coeff;
    }
  }

  _Polynomial add(_Polynomial other) {
    final result = _Polynomial();
    result.coefficients.addAll(coefficients);
    other.coefficients.forEach((degree, coeff) {
      final newCoeff = (result.coefficients[degree] ?? Fraction(0, 1)).add(coeff);
      if (newCoeff.numerator == 0) {
        result.coefficients.remove(degree);
      } else {
        result.coefficients[degree] = newCoeff;
      }
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
        final existingCoeff = result.coefficients[newDegree] ?? Fraction(0, 1);
        result.coefficients[newDegree] = existingCoeff.add(newCoeff);
      });
    });
    return result;
  }

  _Polynomial negate() {
    final result = _Polynomial();
    coefficients.forEach((degree, coeff) {
      result.coefficients[degree] = coeff.negate();
    });
    return result;
  }

  _Polynomial pow(int exponent) {
    if (exponent < 0) throw Exception("Negative exponents not supported");
    if (exponent == 0) return _Polynomial.fromCoeff(0, Fraction(1, 1));
    if (exponent == 1) return this;
    _Polynomial result = this;
    for (int i = 1; i < exponent; i++) {
      result = result.multiply(this);
    }
    return result;
  }
}

class _ExpressionParser {
  final String expression;
  int pos = -1;
  int ch = -1;

  _ExpressionParser(this.expression);

  void nextChar() {
    ch = (++pos < expression.length) ? expression.codeUnitAt(pos) : -1;
  }

  bool eat(int charToEat) {
    while (ch == 32) {
      nextChar();
    }
    if (ch == charToEat) {
      nextChar();
      return true;
    }
    return false;
  }

  _Polynomial parse() {
    nextChar();
    final p = parseExpression();
    if (pos < expression.length) {
      throw FormatException("Unexpected: ${String.fromCharCode(ch)}");
    }
    return p;
  }

  _Polynomial parseExpression() {
    var p = parseTerm();
    while (true) {
      if (eat(43)) {
        p = p.add(parseTerm()); // +
      } else if (eat(45)) {
        p = p.subtract(parseTerm()); // -
      } else {
        return p;
      }
    }
  }

  _Polynomial parseTerm() {
    var p = parseFactor();
    while (true) {
      if (eat(42)) { // *
        p = p.multiply(parseFactor());
      } else if (eat(47)) { // Division by a constant
        final divisor = parseFactor();
        if (divisor.coefficients.keys.any((d) => d != 0)) {
          throw FormatException("Division by variable unsupported");
        }
        final c = divisor.coefficients[0]!;
        final res = _Polynomial();
        p.coefficients.forEach((deg, coeff) => res.coefficients[deg] = coeff.divide(c));
        p = res;
      } else if (ch == 40 || (ch >= 48 && ch <= 57) || ch == 120) { // implicit multiplication
        p = p.multiply(parseFactor());
      } else {
        return p;
      }
    }
  }

  _Polynomial parseFactor() {
    if (eat(43)) {
      return parseFactor(); // unary plus
    }
    if (eat(45)) {
      return parseFactor().negate(); // unary minus
    }

    _Polynomial p;
    if (eat(40)) { // parentheses
      p = parseExpression();
      if (!eat(41)) {
        throw FormatException("Missing ')'");
      }
    } else if ((ch >= 48 && ch <= 57) || ch == 46) { // number
      int startPos = pos;
      while ((ch >= 48 && ch <= 57) || ch == 46 || ch == 47) {
        nextChar();
      }
      p = _Polynomial.fromCoeff(0, _parseTermCoefficient(expression.substring(startPos, pos)));
    } else if (eat(120)) { // variable 'x'
      p = _Polynomial.fromCoeff(1, Fraction(1, 1));
    } else {
      throw FormatException("Unexpected char: ${String.fromCharCode(ch)}");
    }

    if (eat(94)) { // exponent '^'
      if (p.coefficients.length > 1 || (p.coefficients.containsKey(0) && p.coefficients.length == 1)) {
        throw FormatException("Exponentiation is only supported on variables (e.g., x^2)");
      }
      int startPos = pos;
      while (ch >= 48 && ch <= 57) {
        nextChar();
      }
      p = p.pow(int.parse(expression.substring(startPos, pos)));
    }

    return p;
  }

  Fraction _parseTermCoefficient(String term) {
    if (term.isEmpty || term == '+') return Fraction(1, 1);
    if (term == '-') return Fraction(-1, 1);
    if (term.contains('/')) {
      final parts = term.split('/');
      return Fraction(int.parse(parts[0]), int.parse(parts[1]));
    }
    return Fraction.fromDouble(double.parse(term));
  }
}


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

  void _solve() {
    performVibration();
    try {
      String equation = _equationController.text;
      if (equation.isEmpty) return;
      if (!equation.contains('=')) equation += '=0';

      List<String> parts = equation.split('=');
      if (parts.length != 2) throw Exception("Invalid Format: Must have one '='.");

      _Polynomial leftPoly = _ExpressionParser(parts[0]).parse();
      _Polynomial rightPoly = _ExpressionParser(parts[1]).parse();
      _Polynomial finalPoly = leftPoly.subtract(rightPoly);

      Fraction a = finalPoly.coefficients[2] ?? Fraction(0, 1);
      Fraction b = finalPoly.coefficients[1] ?? Fraction(0, 1);
      Fraction c = finalPoly.coefficients[0] ?? Fraction(0, 1);
      
      int maxDegree = 0;
      if (finalPoly.coefficients.isNotEmpty) maxDegree = finalPoly.coefficients.keys.reduce(math.max);

      if (maxDegree > 2 || a.numerator == 0) {
        setState(() {
          _rootsText = "Not a quadratic equation.";
          _stepsText = "Equation must be of degree 2. Your equation simplifies to degree $maxDegree.";
        });
        return;
      }

      if (_solveMethod == 'Factorization') {
        _solveByFactorization(a, b, c);
      } else {
        _solveByFormula(a, b, c);
      }

      setState(() {
        _historyList.insert(0, HistoryItem("${_equationController.text}\n$_rootsText"));
        _saveHistory();
      });
    } catch (e) {
      setState(() {
        _rootsText = 'Error';
        _stepsText = "Invalid equation format. ${e.toString()}";
      });
    }
  }

  bool _isPerfectSquare(int n) => n >= 0 && math.sqrt(n) == math.sqrt(n).toInt();

  List<int> _simplifyRadicalParts(int n) {
    if (n < 0) n = -n;
    if (n == 0) return [0, 1];
    int outside = 1;
    int inside = n;
    for (int i = 2; i * i <= inside; i++) {
      if (inside % (i * i) == 0) {
        outside *= i;
        inside ~/= (i * i);
        i--;
      }
    }
    return [outside, inside];
  }

  void _solveByFormula(Fraction a, Fraction b, Fraction c) {
    Fraction discriminant = b.multiply(b).subtract(Fraction(4, 1).multiply(a).multiply(c));
    String steps = "1. Standard Form: $a x² + $b x + $c = 0\n";
    steps += "2. Discriminant D = b²-4ac = ($b)² - 4($a)($c) = $discriminant\n";

    if (discriminant.numerator >= 0) { // Real Roots
      if (_isPerfectSquare(discriminant.numerator) && _isPerfectSquare(discriminant.denominator)) {
        Fraction sqrtD = Fraction(math.sqrt(discriminant.numerator).toInt(), math.sqrt(discriminant.denominator).toInt());
        Fraction twoA = a.multiply(Fraction(2, 1));
        Fraction root1 = b.negate().add(sqrtD).divide(twoA);
        Fraction root2 = b.negate().subtract(sqrtD).divide(twoA);
        _rootsText = "Roots: x₁ = $root1, x₂ = $root2";
        steps += "3. D is a perfect square. Roots are rational.\n   x = (-b ± √D) / 2a\n";
        steps += "   x₁ = (${b.negate()} + $sqrtD) / $twoA = $root1\n";
        steps += "   x₂ = (${b.negate()} - $sqrtD) / $twoA = $root2";
      } else { // Irrational Roots
        Fraction twoA = a.multiply(Fraction(2, 1));
        String simplifiedD = _simplifyRadicalParts(discriminant.numerator)[0] == 1 ? "√${discriminant.numerator}" : "${_simplifyRadicalParts(discriminant.numerator)[0]}√${_simplifyRadicalParts(discriminant.numerator)[1]}";
        if (discriminant.denominator != 1) simplifiedD = "($simplifiedD)/${math.sqrt(discriminant.denominator).toInt()}";
        _rootsText = "Roots: x = (${b.negate()} ± $simplifiedD) / $twoA";
        steps += "3. D is not a perfect square. Roots are irrational.\n   x = (-$b ± √$discriminant) / $twoA";
      }
    } else { // Complex Roots
      Fraction twoA = a.multiply(Fraction(2, 1));
      Fraction realPart = b.negate().divide(twoA);

      var absD = discriminant.abs();
      var numParts = _simplifyRadicalParts(absD.numerator);
      var denIsSquare = _isPerfectSquare(absD.denominator);
      var denSqrt = denIsSquare ? math.sqrt(absD.denominator).toInt() : null;

      var imagCoeffNum = Fraction(numParts[0],1);
      var imagCoeffDen = Fraction(denSqrt ?? 1,1).multiply(twoA);
      var finalImagCoeff = imagCoeffNum.divide(imagCoeffDen);

      String radical = numParts[1] == 1 ? '' : '√${numParts[1]}';
      String imagText = "${finalImagCoeff.abs() == Fraction(1, 1) ? '' : finalImagCoeff.abs()}i$radical";
      
      _rootsText = "Roots: x = $realPart ± $imagText";
      steps += "3. D is negative. Roots are complex conjugates.\n   x = (-$b ± i√$absD) / $twoA\n";
      steps += "   x = $realPart ± $imagText";
    }
    setState(() => _stepsText = steps);
  }

  void _solveByFactorization(Fraction a, Fraction b, Fraction c) {
    int denA = a.denominator, denB = b.denominator, denC = c.denominator;
    int lcmVal = _lcm(_lcm(denA, denB), denC);
    int intA = (a.doubleValue() * lcmVal).round(), intB = (b.doubleValue() * lcmVal).round(), intC = (c.doubleValue() * lcmVal).round();
    int ac = intA * intC;
    int p = 0, q = 0;
    bool found = false;
    for (int i = 1; i * i <= ac.abs(); i++) {
      if (ac % i == 0) {
        int j = ac ~/ i;
        if (i + j == intB) { p = i; q = j; found = true; break; }
        if (-i - j == intB) { p = -i; q = -j; found = true; break; }
        if (i - j == intB) { p = i; q = -j; found = true; break; }
        if (-i + j == intB) { p = -i; q = j; found = true; break; }
      }
    }
    if (!found) {
      setState(() {
        _rootsText = "Not easily factorable";
        _stepsText = "The polynomial cannot be factored with integers. Use the formula method.";
      });
      return;
    }
    Fraction root1 = Fraction(-p, intA), root2 = Fraction(-q, intA);
    setState(() {
      _rootsText = "Roots: x₁ = $root1, x₂ = $root2";
      _stepsText = "Original: $a x² + $b x + $c = 0\n1. Clear fractions with LCM ($lcmVal):\n   ${intA}x² + ${intB}x + ${intC} = 0\n2. Find p, q where p*q=$ac & p+q=$intB:\n   p=$p, q=$q\n3. Factor by grouping: ${intA}x² + ${p}x + ${q}x + ${intC} = 0\n   ... leads to (${_getFactoredForm(intA, p, q, intC)})\n4. Roots: $root1, $root2";
    });
  }

  String _getFactoredForm(int a, int p, int q, int c) {
    int gcd1 = _gcd(a.abs(), p.abs()), f1A = a ~/ gcd1, f1P = p ~/ gcd1;
    int gcd2 = _gcd(q.abs(), c.abs());
    return "(${_formatTerm(gcd1, "x")} + ${_formatTerm(gcd2, "")})(${_formatTerm(f1A, "x")} + ${_formatTerm(f1P, "")}) = 0";
  }

  String _formatTerm(int coeff, String variable) => "${coeff == 1 && variable.isNotEmpty ? '' : (coeff == -1 && variable.isNotEmpty ? '-' : coeff)}$variable";
  int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
  int _lcm(int a, int b) => (a * b).abs() ~/ _gcd(a, b);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quadratic Solver'), actions: [IconButton(icon: const Icon(Icons.history), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen(storageKey: 'quadratic_history', title: 'Quadratic History'))))]),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(controller: _equationController, readOnly: true, showCursor: true, decoration: const InputDecoration(labelText: 'Equation (e.g., x^2-x-6=0)', border: OutlineInputBorder()), onTap: () => setState(() => _isKeyboardVisible = true)),
            const SizedBox(height: 16),
            Row(children: [const Text('Method:'), Radio<String>(value: 'Formula', groupValue: _solveMethod, onChanged: (v) => setState(() => _solveMethod = v!)), const Text('Quadratic Formula'), Radio<String>(value: 'Factorization', groupValue: _solveMethod, onChanged: (v) => setState(() => _solveMethod = v!)), const Text('Factorization')]),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _solve, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), child: const Text('SOLVE'))),
            const SizedBox(height: 24),
            Text(_rootsText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const Divider(color: Colors.orange),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(_stepsText, style: const TextStyle(fontFamily: 'monospace', fontSize: 13))),
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
