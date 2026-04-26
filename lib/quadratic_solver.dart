import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'main.dart';
import 'utils.dart';
import 'history_screen.dart';
import 'ui_components.dart';

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
      final input = _equationController.text.trim();
      if (input.isEmpty) {
        setState(() {
          _rootsText = '';
          _isSolving = false;
        });
        return;
      }

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
        _stepsText = "Invalid input: $e";
      });
    } finally {
      setState(() => _isSolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Quadratic Solver'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryScreen(storageKey: 'quadratic_history', title: 'Quadratic History')),
            ),
          )
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCard(
                        opacity: isDarkMode ? 0.05 : 0.2,
                        child: TextField(
                          controller: _equationController,
                          readOnly: true,
                          showCursor: true,
                          style: const TextStyle(fontSize: 18),
                          decoration: InputDecoration(
                            labelText: 'Equation',
                            hintText: 'e.g., x^2-x-6=0',
                            labelStyle: TextStyle(color: isDarkMode ? TechColors.primary : Colors.orange),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.functions_rounded, color: isDarkMode ? TechColors.primary : Colors.orange),
                          ),
                          onTap: () => setState(() => _isKeyboardVisible = true),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        opacity: isDarkMode ? 0.05 : 0.1,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              Text('Method:', style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white70 : Colors.black87)),
                              const SizedBox(width: 16),
                              ChoiceChip(
                                label: const Text('Formula'),
                                selected: _solveMethod == 'Formula',
                                onSelected: (selected) => setState(() => _solveMethod = 'Formula'),
                                selectedColor: isDarkMode ? TechColors.primary.withAlpha(76) : Colors.orange.withAlpha(76),
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: const Text('Factoring'),
                                selected: _solveMethod == 'Factorization',
                                onSelected: (selected) => setState(() => _solveMethod = 'Factorization'),
                                selectedColor: isDarkMode ? TechColors.primary.withAlpha(76) : Colors.orange.withAlpha(76),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
                              : const FittedBox(child: Text('CALCULATE ROOTS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5))),
                        ),
                      ),
                      if (_rootsText.isNotEmpty) ...[
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
                                  _rootsText,
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
                    ],
                  ),
                ),
              ),
              if (_isKeyboardVisible) _buildCustomKeyboard(),
            ],
          ),
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
          _buildKeyboardRow(['1', '2', '3', 'x', 'del']),
          _buildKeyboardRow(['4', '5', '6', '^', 'x²']),
          _buildKeyboardRow(['7', '8', '9', '+', '-']),
          _buildKeyboardRow(['.', '0', '/', '(', ')', '=']),
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
                } else if (key == 'x²') {
                  _onKeyboardPress('^2');
                } else {
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
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: (key == 'del' || key == 'x²' || key == '^' || key == '=') 
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

// Top-level function for compute()
Map<String, String> _solveQuadraticIsolate(Map<String, dynamic> params) {
  String equation = params['equation'];
  String method = params['method'];
  try {
    String processed = equation.replaceAll(' ', '').toLowerCase();
    if (!processed.contains('=')) processed += '=0';
    List<String> sides = processed.split('=');
    if (sides.length != 2) return {'roots': 'Error', 'steps': 'Equation must have one equals sign.'};

    _RationalExpression leftExpr = _ExpressionParser(sides[0]).parse();
    _RationalExpression rightExpr = _ExpressionParser(sides[1]).parse();
    
    // N1/D1 = N2/D2  =>  N1*D2 - N2*D1 = 0
    _Polynomial finalPoly = leftExpr.numerator.multiply(rightExpr.denominator)
        .subtract(rightExpr.numerator.multiply(leftExpr.denominator));
    _Polynomial finalDenom = leftExpr.denominator.multiply(rightExpr.denominator);

    Fraction a = finalPoly.coefficients[2] ?? Fraction(0, 1);
    Fraction b = finalPoly.coefficients[1] ?? Fraction(0, 1);
    Fraction c = finalPoly.coefficients[0] ?? Fraction(0, 1);
    
    int maxDegree = 0;
    if (finalPoly.coefficients.isNotEmpty) maxDegree = finalPoly.coefficients.keys.reduce(math.max);

    if (a.numerator == 0) {
      if (b.numerator != 0) {
        double root = -c.doubleValue / b.doubleValue;
        if (finalDenom.evaluate(root).abs() < 1e-9) {
          return {'roots': "No solution", 'steps': "The potential solution x = ${formatRoot(root)} makes the denominator zero."};
        }
        return {'roots': "Roots: x = ${formatRoot(root)}", 'steps': "Equation simplifies to a linear form: ($b)x + ($c) = 0"};
      }
      return {'roots': "Not a quadratic equation.", 'steps': "Equation simplifies to degree $maxDegree (must be 2)."};
    }

    Map<String, String> coreResult;
    if (method == 'Factorization') {
      coreResult = _solveByFactorizationCore(a, b, c);
    } else {
      coreResult = _solveByFormulaCore(a, b, c);
    }

    String rootsText = coreResult['roots']!;
    if (rootsText.startsWith("Roots: ")) {
      List<String> rootParts = rootsText.substring(7).split(', ');
      List<String> validRoots = [];
      for (var rp in rootParts) {
        String cleanRp = rp.replaceFirst('x₁ = ', '').replaceFirst('x₂ = ', '').replaceFirst('x = ', '').trim();
        // Extract numeric value from potentially complex formatting
        double? val;
        if (cleanRp.contains('(')) {
           // Might be complex (real +/- imag i). Denominators in this app's scope are usually real.
        } else {
           // Try to parse double or evaluate fraction/radical if simple
           val = double.tryParse(cleanRp);
           // Handle common radical/fraction outputs from formatRoot
           if (val == null && cleanRp.contains('/')) {
             var parts = cleanRp.split('/');
             var n = double.tryParse(parts[0]);
             var d = double.tryParse(parts[1]);
             if (n != null && d != null && d != 0) val = n / d;
           }
        }
        
        if (val != null) {
          if (finalDenom.evaluate(val).abs() > 1e-7) {
            validRoots.add(rp);
          }
        } else {
          validRoots.add(rp);
        }
      }
      if (validRoots.isEmpty) {
        rootsText = "No valid roots found (all potential roots make the denominator zero).";
      } else {
        rootsText = "Roots: ${validRoots.join(', ')}";
      }
    }

    return {'roots': rootsText, 'steps': coreResult['steps']!};
  } catch (e) { return {'roots': 'Error', 'steps': "Parsing error: $e"}; }
}

Map<String, String> _solveByFormulaCore(Fraction a, Fraction b, Fraction c) {
  Fraction discriminant = b.multiply(b).subtract(Fraction(4, 1).multiply(a).multiply(c));
  String steps = "1. Standard Form: ($a)x² + ($b)x + ($c) = 0\n2. Discriminant D = b²-4ac = ($b)² - 4($a)($c) = $discriminant\n";
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
  if (absAc > 1000000) {
    final formulaResult = _solveByFormulaCore(a, b, c);
    return formulaResult..['steps'] = "Note: Coefficients too large for factorization. Using formula.\n\n${formulaResult['steps']!}";
  }
  for (int i = 1; i * i <= absAc; i++) {
    if (absAc % i == 0) {
      int f1 = i, f2 = absAc ~/ i;
      List<List<int>> pairs = [[f1, f2], [-f1, -f2], [f1, -f2], [-f1, f2]];
      for (var pair in pairs) {
        if (pair[0] * pair[1] == ac && pair[0] + pair[1] == intB) { p = pair[0]; q = pair[1]; found = true; break; }
      }
      if (found) break;
    }
  }
  if (!found) return {'roots': "Not easily factorable", 'steps': "The polynomial cannot be factored with integers. Try the Formula method."};
  Fraction r1 = Fraction(-p, intA).simplify(), r2 = Fraction(-q, intA).simplify();
  String steps = "1. Standard Form: ($a)x² + ($b)x + ($c) = 0\n2. Multiply by LCM $lcmVal: ${intA}x² + ${intB}x + $intC = 0\n3. Factor by grouping: (${_getFactoredFormStatic(intA, p, q, intC)}) = 0\n4. Solve for x: x₁ = ${formatRoot(r1.doubleValue)}, x₂ = ${formatRoot(r2.doubleValue)}";
  return {'roots': "Roots: x₁ = ${formatRoot(r1.doubleValue)}, x₂ = ${formatRoot(r2.doubleValue)}", 'steps': steps};
}

String _getFactoredFormStatic(int a, int p, int q, int c) {
  int g1 = _gcd(a.abs(), p.abs());
  int f1A = a ~/ g1, f1P = p ~/ g1;
  int g2 = _gcd(q.abs(), c.abs());
  if (q < 0) {
    g2 = -g2.abs();
  } else {
    g2 = g2.abs();
  }
  return "(${_formatTermStatic(g1, "x")} + $g2)(${_formatTermStatic(f1A, "x")} + $f1P)";
}

String _formatTermStatic(int coeff, String variable) => "${coeff == 1 ? '' : (coeff == -1 ? '-' : coeff)}$variable";
int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);
int _lcm(int a, int b) => (a == 0 || b == 0) ? 0 : (a * b).abs() ~/ _gcd(a, b);

class _Polynomial {
  Map<int, Fraction> coefficients = {};
  _Polynomial();
  _Polynomial.fromCoeff(int degree, Fraction coeff) { if (coeff.numerator != 0) coefficients[degree] = coeff; }
  double evaluate(double x) {
    double result = 0;
    coefficients.forEach((degree, coeff) => result += coeff.doubleValue * math.pow(x, degree));
    return result;
  }
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
    for (int i = 1; i < exponent; i++) {
      result = result.multiply(this);
    }
    return result;
  }
}

class _RationalExpression {
  final _Polynomial numerator;
  final _Polynomial denominator;
  _RationalExpression(this.numerator, this.denominator);
  factory _RationalExpression.fromPolynomial(_Polynomial p) => _RationalExpression(p, _Polynomial.fromCoeff(0, Fraction(1, 1)));
  _RationalExpression add(_RationalExpression other) => _RationalExpression(numerator.multiply(other.denominator).add(other.numerator.multiply(denominator)), denominator.multiply(other.denominator));
  _RationalExpression subtract(_RationalExpression other) => _RationalExpression(numerator.multiply(other.denominator).subtract(other.numerator.multiply(denominator)), denominator.multiply(other.denominator));
  _RationalExpression multiply(_RationalExpression other) => _RationalExpression(numerator.multiply(other.numerator), denominator.multiply(other.denominator));
  _RationalExpression divide(_RationalExpression other) => _RationalExpression(numerator.multiply(other.denominator), denominator.multiply(other.numerator));
  _RationalExpression negate() => _RationalExpression(numerator.negate(), denominator);
  _RationalExpression pow(int exponent) => _RationalExpression(numerator.pow(exponent), denominator.pow(exponent));
}

class _ExpressionParser {
  final String expression;
  int pos = -1, ch = -1;
  _ExpressionParser(this.expression);
  void nextChar() => ch = (++pos < expression.length) ? expression.codeUnitAt(pos) : -1;
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
  _RationalExpression parse() { nextChar(); final p = parseExpression(); if (pos < expression.length) throw FormatException("Unexpected character: ${String.fromCharCode(ch)}"); return p; }
  _RationalExpression parseExpression() {
    var p = parseTerm();
    while (true) { if (eat(43)) p = p.add(parseTerm()); else if (eat(45)) p = p.subtract(parseTerm()); else return p; }
  }
  _RationalExpression parseTerm() {
    var p = parseFactor();
    while (true) {
      if (eat(42)) p = p.multiply(parseFactor());
      else if (eat(47)) p = p.divide(parseFactor());
      else if (ch == 40 || (ch >= 48 && ch <= 57) || ch == 120) p = p.multiply(parseFactor());
      else return p;
    }
  }
  _RationalExpression parseFactor() {
    if (eat(43)) return parseFactor();
    if (eat(45)) return parseFactor().negate();
    _RationalExpression p;
    if (eat(40)) { p = parseExpression(); if (!eat(41)) throw FormatException("Missing closing parenthesis ')'"); }
    else if ((ch >= 48 && ch <= 57) || ch == 46) {
      int startPos = pos;
      while ((ch >= 48 && ch <= 57) || ch == 46) nextChar();
      p = _RationalExpression.fromPolynomial(_Polynomial.fromCoeff(0, _parseTermCoefficient(expression.substring(startPos, pos))));
    } else if (eat(120)) p = _RationalExpression.fromPolynomial(_Polynomial.fromCoeff(1, Fraction(1, 1)));
    else throw FormatException("Unexpected character: ${String.fromCharCode(ch)}");
    if (eat(94)) {
      int startPos = pos;
      while (ch >= 48 && ch <= 57) nextChar();
      final expStr = expression.substring(startPos, pos);
      if (expStr.isEmpty) throw FormatException("Exponent value expected after '^'");
      p = p.pow(int.parse(expStr));
    }
    return p;
  }
  Fraction _parseTermCoefficient(String term) {
    if (term.isEmpty || term == '+') return Fraction(1, 1);
    if (term == '-') return Fraction(-1, 1);
    final d = double.tryParse(term);
    if (d != null) return Fraction.fromDouble(d);
    return Fraction(1, 1);
  }
}
