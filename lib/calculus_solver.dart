import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'utils.dart';
import 'main.dart';
import 'history_screen.dart';
import 'ui_components.dart';

// --- UI Layer ---

class CalculusSolverScreen extends StatefulWidget {
  const CalculusSolverScreen({super.key});

  @override
  State<CalculusSolverScreen> createState() => _CalculusSolverScreenState();
}

class _CalculusSolverScreenState extends State<CalculusSolverScreen> {
  final TextEditingController _controller = TextEditingController();
  String _resultText = '';
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
    _historyList = await loadHistory('calculus_history');
    setState(() {});
  }

  void _onKeyboardPress(String text) {
    performVibration();
    final currentText = _controller.text;
    final selection = _controller.selection;
    final newText =
        currentText.replaceRange(selection.start, selection.end, text);
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
      final newText =
          currentText.replaceRange(selection.start - 1, selection.end, '');
      _controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: selection.start - 1),
      );
    }
  }

  Future<void> _performCalculus(bool isDifferentiation) async {
    if (_isSolving) return;
    performVibration();
    String expression = _controller.text.trim();
    if (expression.isEmpty) {
      setState(() => _resultText = "Please enter an expression");
      return;
    }

    setState(() {
      _isSolving = true;
      _resultText = 'Solving...';
      _stepsText = '';
    });

    try {
      final result = await compute(_solveCalculusIsolate, {
        'expression': expression,
        'isDifferentiation': isDifferentiation,
      });

      setState(() {
        _resultText = result['result'] ?? 'Error';
        _stepsText = result['steps'] ?? '';
        if (!_resultText.startsWith('Error')) {
          _historyList.insert(
              0,
              HistoryItem(
                  "${isDifferentiation ? 'd/dx' : '∫'}($expression) = $_resultText"));
          saveHistory('calculus_history', _historyList);
        }
      });
    } catch (e) {
      setState(() {
        _resultText = "Error: An unexpected error occurred: $e";
        _stepsText = "";
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
        title: const Text('Calculus Solver'),
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
                    storageKey: 'calculus_history',
                    title: 'Calculus History',
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassCard(
                        opacity: isDarkMode ? 0.05 : 0.2,
                        child: TextField(
                          controller: _controller,
                          readOnly: true,
                          showCursor: true,
                          style: const TextStyle(fontSize: 18),
                          onTap: () => setState(() => _isKeyboardVisible = true),
                          decoration: InputDecoration(
                            labelText: 'Function f(x)',
                            hintText: 'e.g., x^2 + sin(x)',
                            labelStyle: TextStyle(color: isDarkMode ? TechColors.primary : Colors.orange),
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.show_chart_rounded, color: isDarkMode ? TechColors.primary : Colors.orange),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSolving ? null : () => _performCalculus(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? TechColors.primary : Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isSolving
                                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const FittedBox(child: Text('DIFFERENTIATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isSolving ? null : () => _performCalculus(false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode ? TechColors.primary : Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _isSolving
                                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const FittedBox(child: Text('INTEGRATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                            ),
                          ),
                        ],
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
                                  _resultText,
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
              if (_isKeyboardVisible) _buildKeyboard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
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
              IconButton(
                icon: const Icon(Icons.keyboard_hide_rounded),
                onPressed: () => setState(() => _isKeyboardVisible = false),
              ),
            ],
          ),
          _buildRow(['sin', 'cos', 'tan', 'sec']),
          _buildRow(['ln', 'e', '√', '^']),
          _buildRow(['x', 'y', '(', ')']),
          _buildRow(['7', '8', '9', '/']),
          _buildRow(['4', '5', '6', '+']),
          _buildRow(['1', '2', '3', '-']),
          _buildRow(['0', '.', 'dx', 'del']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    const functionKeys = ['sin', 'cos', 'tan', 'sec', 'ln'];

    return Row(
      children: keys.map((k) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (k == 'del') {
                  _onBackspace();
                } else if (k == '√') {
                  _onKeyboardPress('sqrt(');
                } else {
                  _onKeyboardPress(functionKeys.contains(k) ? '$k(' : k);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white10 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
                ),
                child: Center(
                  child: Text(
                    k,
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: (k == 'del' || k == 'dx' || functionKeys.contains(k)) 
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

// --- Calculus Isolate ---

Map<String, String> _solveCalculusIsolate(Map<String, dynamic> params) {
  String expression = params['expression'];
  bool isDifferentiation = params['isDifferentiation'];
  try {
    final result = solveCalculus(expression, isDifferentiation);
    return {
      'result': result.resultDisplay,
      'steps': result.steps,
    };
  } catch (e) {
    String errorMessage = e.toString();
    if (e is UnsupportedError) {
      errorMessage = "The calculus engine does not support this expression yet.";
      final message = e.message ?? "";
      if (message.contains("is not supported")) {
        errorMessage = "Integration or differentiation for '${message.split("'")[1]}' is not supported.";
      }
    } else if (e is FormatException) {
      errorMessage = "Invalid format: ${e.message}";
    }
    return {
      'result': "Error: $errorMessage",
      'steps': "",
    };
  }
}

// --- Calculus Engine (AST) ---

class CalculusResult {
  final String resultDisplay;
  final String steps;
  CalculusResult(this.resultDisplay, this.steps);
}

CalculusResult solveCalculus(String expression, bool isDifferentiation) {
  final steps = StringBuffer();
  String processedExpression = expression
      .replaceAll(' ', '')
      .replaceAll('√', 'sqrt')
      .toLowerCase();

  if (processedExpression.contains('=')) {
    final parts = processedExpression.split('=');
    if (parts.length > 2 || parts[1].isEmpty) {
      throw FormatException("Invalid equation. Use a format like 'y = x^2'.");
    }
    processedExpression = parts.last;
  }

  if (processedExpression.endsWith('dx')) {
    processedExpression =
        processedExpression.substring(0, processedExpression.length - 2);
  }
  final parser = ExpressionParser(processedExpression);
  final ast = parser.parse();

  steps.writeln("1. Parsed Expression: ${ast.toInfixString()}\n");

  final variable = ast.getVariables().isNotEmpty ? ast.getVariables().first : 'x';

  Expression resultAST;
  if (isDifferentiation) {
    steps.writeln("2. Differentiating with respect to $variable...\n");
    resultAST = ast.differentiate(variable, steps);
  } else {
    steps.writeln("2. Integrating ∫${ast.toInfixString()} d$variable...\n");
    resultAST = ast.integrate(variable, steps);
  }

  steps.writeln("\n3. Simplifying the result...");
  Expression simplifiedAST = resultAST.simplify();
  steps.writeln("   Simplified: ${simplifiedAST.toInfixString()}");

  String resultString = simplifiedAST.toInfixString();
  if (!isDifferentiation) resultString += " + C";

  return CalculusResult(resultString, steps.toString());
}

abstract class Expression {
  Expression differentiate(String varName, StringBuffer steps);
  Expression integrate(String varName, StringBuffer steps);
  Expression simplify();
  String toInfixString();
  Set<String> getVariables();

  bool isZero() => false;
  bool isOne() => false;

  bool equals(Expression other) => toInfixString() == other.toInfixString();
}

class Constant extends Expression {
  final double value;
  Constant(this.value);

  @override
  String toInfixString() => value
      .toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)
      .replaceAll(RegExp(r'\.00$'), '');

  @override
  Expression differentiate(String varName, StringBuffer steps) {
    steps.writeln("   • d/d$varName[${toInfixString()}] = 0 (Derivative of a Constant)");
    return Constant(0);
  }

  @override
  Expression integrate(String varName, StringBuffer steps) {
    final result = BinaryOp(this, Variable(varName), '*');
    steps.writeln(
        "   • ∫${toInfixString()} d$varName = ${result.toInfixString()} (Integral of a Constant)");
    return result;
  }

  @override
  Expression simplify() => this;
  @override
  bool isZero() => value == 0;
  @override
  bool isOne() => value == 1;
  @override
  Set<String> getVariables() => {};
}

class Variable extends Expression {
  final String name;
  Variable(this.name);

  @override
  String toInfixString() => name;

  @override
  Expression differentiate(String varName, StringBuffer steps) {
    if (name == varName) {
      steps.writeln("   • d/d$varName[$name] = 1 (Power Rule)");
      return Constant(1);
    } else {
      steps.writeln("   • d/d$varName[$name] = 0 (Derivative of a constant variable)");
      return Constant(0);
    }
  }

  @override
  Expression integrate(String varName, StringBuffer steps) {
    if (name == varName) {
      final result = BinaryOp(
          BinaryOp(Variable(varName), Constant(2), '^'), Constant(2), '/');
      steps.writeln("   • ∫$name d$varName = ${result.toInfixString()} (Power Rule)");
      return result;
    }
    final result = BinaryOp(this, Variable(varName), '*');
    steps.writeln("   • ∫$name d$varName = ${result.toInfixString()} (Integral of a constant variable)");
    return result;
  }

  @override
  Expression simplify() => this;
  @override
  Set<String> getVariables() => {name};
}

class BinaryOp extends Expression {
  Expression left, right;
  final String op;
  BinaryOp(this.left, this.right, this.op);

  int get _precedence {
    switch (op) {
      case '+': case '-': return 1;
      case '*': case '/': return 2;
      case '^': return 3;
      default: return 0;
    }
  }

  @override
  String toInfixString() {
    String l = left.toInfixString();
    String r = right.toInfixString();
    if (left is BinaryOp && (left as BinaryOp)._precedence < _precedence) {
      l = '($l)';
    }
    if (right is BinaryOp && (right as BinaryOp)._precedence <= _precedence) {
      r = '($r)';
    }
    if (op == '-' && right is BinaryOp && (right as BinaryOp)._precedence == 1) {
      r = '($r)';
    }
    if (op == '/') return '$l/$r';
    return '$l $op $r';
  }

  @override
  Expression differentiate(String varName, StringBuffer steps) {
    steps.writeln("   • Applying rule for operator '$op' to ${toInfixString()}");
    switch (op) {
      case '+':
        steps.writeln("     - Sum Rule: d/d$varName(f+g) = f' + g'");
        return BinaryOp(left.differentiate(varName, steps), right.differentiate(varName, steps), '+');
      case '-':
        steps.writeln("     - Difference Rule: d/d$varName(f-g) = f' - g'");
        return BinaryOp(left.differentiate(varName, steps), right.differentiate(varName, steps), '-');
      case '*':
        steps.writeln("     - Product Rule: d/d$varName(f*g) = f'*g + f*g'");
        return BinaryOp(
            BinaryOp(left.differentiate(varName, steps), right, '*'),
            BinaryOp(left, right.differentiate(varName, steps), '*'),
            '+');
      case '/':
        steps.writeln("     - Quotient Rule: d/d$varName(f/g) = (f'*g - f*g') / g^2");
        return BinaryOp(
            BinaryOp(
                BinaryOp(left.differentiate(varName, steps), right, '*'),
                BinaryOp(left, right.differentiate(varName, steps), '-'),
                '-'),
            BinaryOp(right, Constant(2), '^'),
            '/');
      case '^':
        if (right is Constant) {
          steps.writeln("     - Power & Chain Rule: d/d$varName(f^n) = n*f^(n-1)*f'");
          double n = (right as Constant).value;
          Expression newPower = n == 2 ? left : BinaryOp(left, Constant(n - 1), '^');
          return BinaryOp(BinaryOp(Constant(n), newPower, '*'), left.differentiate(varName, steps), '*');
        }
        if (left is Constant) {
            steps.writeln("     - Exponential & Chain Rule: d/d$varName(a^g) = a^g * ln(a) * g'");
            return BinaryOp(
                BinaryOp(this, FunctionCall('ln', left), '*'),
                right.differentiate(varName, steps),
                '*'
            );
        }
    }
    throw UnsupportedError("Differentiation for operator '$op' not supported.");
  }

  @override
  Expression integrate(String varName, StringBuffer steps) {
    final originalInfix = toInfixString();
    final simplified = simplify();
    if (simplified is! BinaryOp) {
      if (!simplified.equals(this)) {
        steps.writeln("   • Simplify: ∫$originalInfix d$varName = ∫${simplified.toInfixString()} d$varName");
      }
      return simplified.integrate(varName, steps);
    }

    final sLeft = simplified.left;
    final sRight = simplified.right;
    final sOp = simplified.op;

    if (sOp == '+' || sOp == '-') {
      steps.writeln("   • Apply Linearity Rule:");
      steps.writeln("     ∫(${sLeft.toInfixString()} $sOp ${sRight.toInfixString()}) d$varName = ∫${sLeft.toInfixString()} d$varName $sOp ∫${sRight.toInfixString()} d$varName");
      return BinaryOp(sLeft.integrate(varName, steps), sRight.integrate(varName, steps), sOp);
    }
    if (sOp == '*' && sLeft is Constant) {
      steps.writeln("   • Apply Constant Multiple Rule:");
      steps.writeln("     ∫$originalInfix d$varName = ${sLeft.toInfixString()} * ∫${sRight.toInfixString()} d$varName");
      return BinaryOp(sLeft, sRight.integrate(varName, steps), '*');
    }
     if (sOp == '*' && sRight is Constant) {
      steps.writeln("   • Apply Constant Multiple Rule:");
      steps.writeln("     ∫$originalInfix d$varName = ${sRight.toInfixString()} * ∫${sLeft.toInfixString()} d$varName");
      return BinaryOp(sRight, sLeft.integrate(varName, steps), '*');
    }

    if (sOp == '/') {
        Expression derivativeOfRight = sRight.differentiate(varName, StringBuffer()).simplify();
        if (sLeft.equals(derivativeOfRight)) {
            steps.writeln("   • Apply Reverse Chain Rule: ∫g'(x)/g(x) dx = ln|g(x)|");
            steps.writeln("     - Let g(x) = ${sRight.toInfixString()}, so g'(x) = ${derivativeOfRight.toInfixString()}");
            return FunctionCall('ln', sRight);
        }
        if (sLeft is Constant && derivativeOfRight is Constant && !derivativeOfRight.isZero()){
             final a = (sLeft).value / (derivativeOfRight).value;
             steps.writeln("   • Apply Reverse Chain Rule (scaled): ∫(k*g'(x))/g(x) dx = k*ln|g(x)|");
             steps.writeln("     - Let g(x) = ${sRight.toInfixString()}, g'(x) = ${derivativeOfRight.toInfixString()}");
             steps.writeln("     - We have ∫(${sLeft.toInfixString()}/${sRight.toInfixString()}) dx = ∫((${a.toStringAsFixed(2)}*${derivativeOfRight.toInfixString()})/${sRight.toInfixString()}) dx");
             return BinaryOp(Constant(a), FunctionCall('ln', sRight), '*');
        }
    }

    if (sOp == '^' && sRight is Constant) {
      final n = sRight.value;
      if (n != -1) {
          final linearCoeffs = sLeft.getLinearCoefficients(varName);
          if (linearCoeffs != null) {
              final a = linearCoeffs.a;
              final b = linearCoeffs.b;
              if (a != 0) {
                 final nPlus1 = n + 1;
                 final result = BinaryOp(
                     BinaryOp(sLeft, Constant(nPlus1), '^'),
                     Constant(a * nPlus1),
                     '/'
                 );
                 steps.writeln("   • Apply Power Rule for Linear Argument: ∫(ax+b)^n dx = (ax+b)^(n+1)/(a*(n+1))");
                 steps.writeln("     - Let u = ${sLeft.toInfixString()}, n = ${n.toStringAsFixed(2)}");
                 steps.writeln("     - With a=$a, b=$b, the result is ${result.toInfixString()}");
                 return result;
              }
          }
      }
    }

    throw UnsupportedError("Integration for '$originalInfix' is not supported.");
  }

  @override
  Expression simplify() {
    left = left.simplify();
    right = right.simplify();

    if (left is Constant && right is Constant) {
      final l = (left as Constant).value, r = (right as Constant).value;
      switch (op) {
        case '+': return Constant(l + r);
        case '-': return Constant(l - r);
        case '*': return Constant(l * r);
        case '/': return r != 0 ? Constant(l / r) : this;
        case '^':
            if(l == 0 && r <= 0) return this; // Avoid 0^0 or 0^-n
            return Constant(math.pow(l, r).toDouble());
      }
    }
    
    if ((op == '+' || op == '*') && left.toInfixString().compareTo(right.toInfixString()) > 0) {
        final temp = left;
        left = right;
        right = temp;
    }

    if (op == '*') {
      if (left.isZero() || right.isZero()) return Constant(0);
      if (left.isOne()) return right;
      if (right.isOne()) return left;
    }
    if (op == '+') {
      if (left.isZero()) return right;
      if (right.isZero()) return left;
    }
    if (op == '-') {
      if (right.isZero()) return left;
      if (left.equals(right)) return Constant(0);
    }
    if (op == '/') {
      if (right.isOne()) return left;
      if (left.equals(right) && !left.isZero()) return Constant(1);
    }
    if (op == '^') {
      if (right.isOne()) return left;
      if (right.isZero()) return Constant(1);
      if (left.isOne()) return Constant(1);
      if (left.isZero()) return Constant(0);
      if (left is BinaryOp && (left as BinaryOp).op == '^') {
        return BinaryOp(left, BinaryOp(left, right, '*'), '^').simplify();
      }
    }
    
    if(op == '*' && left.equals(right)) {
      return BinaryOp(left, Constant(2), '^');
    }

    return this;
  }
   @override
  Set<String> getVariables() => {...left.getVariables(), ...right.getVariables()};
}

class FunctionCall extends Expression {
  final String name;
  final Expression arg;
  FunctionCall(this.name, this.arg);

  @override
  String toInfixString() => '$name(${arg.toInfixString()})';

  @override
  Expression differentiate(String varName, StringBuffer steps) {
    steps.writeln("   • Applying Chain Rule to ${toInfixString()}");
    steps.writeln("     - d/d$varName[f(g)] = f'(g) * g'");
    Expression innerDerivative = arg.differentiate(varName, steps);
    Expression outerDerivative;
    switch (name) {
      case 'sin': outerDerivative = FunctionCall('cos', arg); break;
      case 'cos': outerDerivative = BinaryOp(Constant(-1), FunctionCall('sin', arg), '*'); break;
      case 'tan': outerDerivative = BinaryOp(FunctionCall('sec', arg), Constant(2), '^'); break;
      case 'sec': outerDerivative = BinaryOp(FunctionCall('sec', arg), FunctionCall('tan', arg), '*'); break;
      case 'ln': outerDerivative = BinaryOp(Constant(1), arg, '/'); break;
      case 'sqrt': return BinaryOp(arg, Constant(0.5), '^').differentiate(varName, steps);
      default: throw UnsupportedError("Differentiation of function '$name' not supported");
    }
    return BinaryOp(outerDerivative, innerDerivative, '*');
  }

  @override
  Expression integrate(String varName, StringBuffer steps) {
     final simplified = simplify();
     if (!simplified.equals(this)) {
        steps.writeln("   • Simplify: ∫${toInfixString()} d$varName = ∫${simplified.toInfixString()} d$varName");
        return simplified.integrate(varName, steps);
    }

    final linearCoeffs = arg.getLinearCoefficients(varName);
     if (linearCoeffs != null && linearCoeffs.a != 0) {
      steps.writeln("   • Apply U-Substitution for ∫${toInfixString()} d$varName, with u = ${arg.toInfixString()}");
      steps.writeln("     - du = ${linearCoeffs.a} d$varName  =>  d$varName = (1/${linearCoeffs.a}) du");
      steps.writeln("     - The integral becomes: ∫$name(u) * (1/${linearCoeffs.a}) du");
      
      final coefficient = BinaryOp(Constant(1), Constant(linearCoeffs.a), '/');
      Expression integralOfF;
      String integralOfU;

      switch (name) {
        case 'sin':
          integralOfU = "-cos(u)";
          integralOfF = BinaryOp(Constant(-1), FunctionCall('cos', arg), '*');
          break;
        case 'cos':
          integralOfU = "sin(u)";
          integralOfF = FunctionCall('sin', arg);
          break;
        case 'sec':
           if (arg is Variable && (arg as Variable).name == varName) {
              integralOfU = "ln|sec(u)+tan(u)|";
              integralOfF = FunctionCall('ln', BinaryOp(FunctionCall('sec', arg), FunctionCall('tan', arg), '+'));
              break;
           }
            throw UnsupportedError("Integration of function '$name' with complex argument not supported.");
        case 'ln':
          if (arg is Variable && (arg as Variable).name == varName) {
            steps.writeln("   • Apply Integration by Parts: ∫ln(x)dx = x*ln(x) - x");
            return BinaryOp(BinaryOp(Variable(varName), this, '*'), Variable(varName), '-');
          } else {
             throw UnsupportedError("Integration of '$name' with complex argument not supported.");
          }
        default:
          throw UnsupportedError("Integration of function '$name' not supported.");
      }
      final result = BinaryOp(coefficient, integralOfF, '*');
      steps.writeln("     - Since ∫$name(u)du = $integralOfU, the result is: ${result.simplify().toInfixString()}");
      return result;
    }

    throw UnsupportedError("Integration of '${toInfixString()}' is not supported. Argument must be linear (e.g., ax+b).");
  }

  @override
  Expression simplify() {
    final simplifiedArg = arg.simplify();
    if (name == 'sqrt') {
      if (simplifiedArg is Constant) {
        if ((simplifiedArg).value >= 0) {
          final sqrtValue = math.sqrt((simplifiedArg).value);
          return Constant(sqrtValue);
        }
      }
      if (simplifiedArg is BinaryOp && simplifiedArg.op == '^') {
        if (simplifiedArg.right is Constant) {
           final exponent = (simplifiedArg.right as Constant).value;
           if (exponent % 2 == 0) {
             return BinaryOp(simplifiedArg.left, Constant(exponent / 2), '^');
           }
        }
      }
      return BinaryOp(simplifiedArg, Constant(0.5), '^');
    }
    return FunctionCall(name, simplifiedArg);
  }
   @override
  Set<String> getVariables() => arg.getVariables();
}

// --- Expression Parser ---
class ExpressionParser {
  final String expr;
  int pos = 0;
  int ch = 0;
  
  ExpressionParser(this.expr) {
     ch = expr.isEmpty ? -1 : expr.codeUnitAt(0);
  }

  void next() {
    pos++;
    ch = (pos < expr.length) ? expr.codeUnitAt(pos) : -1;
  }

  bool eat(int charToEat) {
    while (ch == 32) { next(); }
    if (ch == charToEat) {
      next();
      return true;
    }
    return false;
  }

  Expression parse() {
    if(expr.isEmpty) throw FormatException("Empty expression");
    final expression = parseExpression();
    if (pos < expr.length) {
      throw FormatException("Unexpected character at end of expression: ${expr.substring(pos)}");
    }
    return expression;
  }

  Expression parseExpression() {
    var x = parseTerm();
    for (;;) {
      if (eat(43)) { x = BinaryOp(x, parseTerm(), '+'); } 
      else if (eat(45)) { x = BinaryOp(x, parseTerm(), '-'); } 
      else { return x; }
    }
  }

  Expression parseTerm() {
    var x = parseFactor();
    for (;;) {
       if (eat(42)) { x = BinaryOp(x, parseFactor(), '*');}
       else if (eat(47)) { x = BinaryOp(x, parseFactor(), '/');}
       else if (ch >= 97 && ch <= 122 || ch == 40 || ch >= 48 && ch <= 57 && (x is! Constant)) {
         if (x is BinaryOp && (x.op == '+' || x.op == '-')) { return x;}
         x = BinaryOp(x, parseFactor(), '*');
       }
       else { return x; }
    }
  }

  Expression parseFactor() {
    if (eat(43)) { return parseFactor(); }
    if (eat(45)) {
      final factor = parseFactor();
      if (factor is Constant) { return Constant(-factor.value); }
      return BinaryOp(Constant(0), factor, '-');
    }
    return parsePower();
  }

  Expression parsePower() {
    var x = parseBase();
    if (eat(94)) { 
      x = BinaryOp(x, parsePower(), '^');
    }
    return x;
  }

  Expression parseBase() {
    Expression x;
    int startPos = pos;
    if (eat(40)) { // parentheses
      x = parseExpression();
      eat(41);
    } else if ((ch >= 48 && ch <= 57) || ch == 46) { // numbers
      while ((ch >= 48 && ch <= 57) || ch == 46) { next(); }
      x = Constant(double.parse(expr.substring(startPos, pos)));
    } else if (ch >= 97 && ch <= 122) { // functions or variables
      while ((ch >= 97 && ch <= 122)) { next(); }
      String word = expr.substring(startPos, pos);
      if (word == 'e') {
         x = Constant(math.e);
      } else if (eat(40)) {
        x = FunctionCall(word, parseExpression());
        eat(41);
      } else {
        x = Variable(word);
      }
    } else {
      if (ch == -1) { throw FormatException('Unexpected end of expression');}
      throw FormatException('Unexpected character: ${String.fromCharCode(ch)} at position $pos');
    }
    return x;
  }
}

class LinearCoefficients {
    final double a; // coefficient of x
    final double b; // constant term
    LinearCoefficients(this.a, this.b);
}


extension ExpressionExtensions on Expression {
    LinearCoefficients? getLinearCoefficients(String varName) {
        final simplified = simplify();
        if (simplified is Constant) {
            return LinearCoefficients(0, simplified.value);
        }
        if (simplified is Variable) {
            return simplified.name == varName ? LinearCoefficients(1, 0) : LinearCoefficients(0, 0);
        }
        if (simplified is BinaryOp) {
            if (simplified.op == '+') {
                final leftCoeffs = simplified.left.getLinearCoefficients(varName);
                final rightCoeffs = simplified.right.getLinearCoefficients(varName);
                if (leftCoeffs != null && rightCoeffs != null) {
                    return LinearCoefficients(leftCoeffs.a + rightCoeffs.a, leftCoeffs.b + rightCoeffs.b);
                }
            }
             if (simplified.op == '-') {
                final leftCoeffs = simplified.left.getLinearCoefficients(varName);
                final rightCoeffs = simplified.right.getLinearCoefficients(varName);
                if (leftCoeffs != null && rightCoeffs != null) {
                    return LinearCoefficients(leftCoeffs.a - rightCoeffs.a, leftCoeffs.b - rightCoeffs.b);
                }
            }
            if (simplified.op == '*') {
                if (simplified.left is Constant) {
                    final rightCoeffs = simplified.right.getLinearCoefficients(varName);
                    if (rightCoeffs != null) {
                        return LinearCoefficients((simplified.left as Constant).value * rightCoeffs.a, (simplified.left as Constant).value * rightCoeffs.b);
                    }
                }
                 if (simplified.right is Constant) {
                    final leftCoeffs = simplified.left.getLinearCoefficients(varName);
                    if (leftCoeffs != null) {
                        return LinearCoefficients((simplified.right as Constant).value * leftCoeffs.a, (simplified.right as Constant).value * leftCoeffs.b);
                    }
                }
            }
        }
        return null;
    }
}
