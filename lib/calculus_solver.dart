import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'utils.dart';
import 'main.dart';
import 'history_screen.dart';

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

  void _performCalculus(bool isDifferentiation) {
    performVibration();
    String expression = _controller.text.trim();
    if (expression.isEmpty) {
      setState(() => _resultText = "Please enter an expression");
      return;
    }

    try {
      final result = solveCalculus(expression, isDifferentiation);
      setState(() {
        _resultText = result.resultDisplay;
        _stepsText = result.steps;
        _historyList.insert(
            0,
            HistoryItem(
                "${isDifferentiation ? 'd/dx' : '∫'}($expression) dx = ${result.resultDisplay}"));
        saveHistory('calculus_history', _historyList);
      });
    } catch (e) {
      setState(() {
        _resultText = "Error: ${e.toString()}";
        _stepsText = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculus Solver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _controller,
                      readOnly: true,
                      showCursor: true,
                      onTap: () => setState(() => _isKeyboardVisible = true),
                      decoration: const InputDecoration(
                        labelText: 'f(x) = ...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                              onPressed: () => _performCalculus(true),
                              child: const Text('DIFFERENTIATE')),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                              onPressed: () => _performCalculus(false),
                              child: const Text('INTEGRATE')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text("Result:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(_resultText,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                    const SizedBox(height: 16),
                    const Text("Steps:",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(color: Colors.orange, thickness: 1),
                    Text(_stepsText,
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                            height: 1.5)),
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
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
                icon: const Icon(Icons.keyboard_hide),
                onPressed: () => setState(() => _isKeyboardVisible = false))
          ]),
          _buildRow(['sin', 'cos', 'tan', 'sec', 'ln', 'e']),
          _buildRow(['7', '8', '9', '(', ')']),
          _buildRow(['4', '5', '6', 'x', 'y']),
          _buildRow(['1', '2', '3', '+', '-']),
          _buildRow(['0', '.', '^', '/', 'del']),
          _buildRow(['dx', '=']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    const functionKeys = ['sin', 'cos', 'tan', 'sec', 'ln'];

    return Row(
      children: keys
          .map((k) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: ElevatedButton(
                    onPressed: () {
                      if (k == 'del') {
                        _onBackspace();
                      } else {
                        _onKeyboardPress(functionKeys.contains(k) ? '$k(' : k);
                      }
                    },
                    child: Text(k, style: const TextStyle(fontSize: 18)),
                  ),
                ),
              ))
          .toList(),
    );
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
  String processedExpression = expression.toLowerCase().replaceAll(' ', '');

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

  Expression resultAST;
  if (isDifferentiation) {
    steps.writeln("2. Differentiating with respect to x...\n");
    resultAST = ast.differentiate('x', steps);
  } else {
    steps.writeln("2. Integrating ∫${ast.toInfixString()} dx...\n");
    resultAST = ast.integrate('x', steps);
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
    steps.writeln("   • d/dx[${toInfixString()}] = 0 (Derivative of a Constant)");
    return Constant(0);
  }

  @override
  Expression integrate(String varName, StringBuffer steps) {
    final result = BinaryOp(this, Variable(varName), '*');
    steps.writeln(
        "   • ∫${toInfixString()} dx = ${result.toInfixString()} (Integral of a Constant)");
    return result;
  }

  @override
  Expression simplify() => this;
  @override
  bool isZero() => value == 0;
  @override
  bool isOne() => value == 1;
}

class Variable extends Expression {
  final String name;
  Variable(this.name);

  @override
  String toInfixString() => name;

  @override
  Expression differentiate(String varName, StringBuffer steps) {
    if (name == varName) {
      steps.writeln("   • d/dx[$name] = 1 (Power Rule)");
      return Constant(1);
    } else {
      steps.writeln("   • d/dx[$name] = 0 (Derivative of a constant variable)");
      return Constant(0);
    }
  }

  @override
  Expression integrate(String varName, StringBuffer steps) {
    if (name == varName) {
      final result = BinaryOp(
          BinaryOp(Variable(varName), Constant(2), '^'), Constant(2), '/');
      steps.writeln("   • ∫$name dx = ${result.toInfixString()} (Power Rule)");
      return result;
    }
    final result = BinaryOp(this, Variable(varName), '*');
    steps.writeln("   • ∫$name dx = ${result.toInfixString()} (Integral of a constant variable)");
    return result;
  }

  @override
  Expression simplify() => this;
}

class BinaryOp extends Expression {
  Expression left, right;
  final String op;
  BinaryOp(this.left, this.right, this.op);

  int get _precedence {
    switch (op) {
      case '+':
      case '-':
        return 1;
      case '*':
      case '/':
        return 2;
      case '^':
        return 3;
      default:
        return 0;
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
    if (op == '/') {
        return '$l/$r';
    }
    return '$l $op $r';
  }

  @override
  Expression differentiate(String varName, StringBuffer steps) {
    steps.writeln("   • Applying rule for operator '$op' to ${toInfixString()}");
    switch (op) {
      case '+':
        steps.writeln("     - Sum Rule: d/dx(f+g) = f' + g'");
        return BinaryOp(left.differentiate(varName, steps),
            right.differentiate(varName, steps), '+');
      case '-':
        steps.writeln("     - Difference Rule: d/dx(f-g) = f' - g'");
        return BinaryOp(left.differentiate(varName, steps),
            right.differentiate(varName, steps), '-');
      case '*':
        steps.writeln("     - Product Rule: d/dx(f*g) = f'*g + f*g'");
        return BinaryOp(
            BinaryOp(left.differentiate(varName, steps), right, '*'),
            BinaryOp(left, right.differentiate(varName, steps), '*'),
            '+');
      case '/':
        steps.writeln("     - Quotient Rule: d/dx(f/g) = (f'*g - f*g') / g^2");
        return BinaryOp(
            BinaryOp(
                BinaryOp(left.differentiate(varName, steps), right, '*'),
                BinaryOp(left, right.differentiate(varName, steps), '-'),
                '-'),
            BinaryOp(right, Constant(2), '^'),
            '/');
      case '^':
        if (right is Constant) {
          steps.writeln("     - Power & Chain Rule: d/dx(f^n) = n*f^(n-1)*f'");
          double n = (right as Constant).value;
          Expression newPower = n == 2 ? left : BinaryOp(left, Constant(n - 1), '^');
          return BinaryOp(BinaryOp(Constant(n), newPower, '*'),
              left.differentiate(varName, steps), '*');
        }
        if (left is Constant) {
            steps.writeln("     - Exponential & Chain Rule: d/dx(a^g) = a^g * ln(a) * g'");
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
    if (!simplified.equals(this)) {
        steps.writeln("   • Simplify: ∫$originalInfix dx = ∫${simplified.toInfixString()} dx");
        return simplified.integrate(varName, steps);
    }

    // After this point, we assume the expression is simplified
    final sLeft = (simplified as BinaryOp).left;
    final sRight = (simplified as BinaryOp).right;
    final sOp = (simplified as BinaryOp).op;

    if (sOp == '+' || sOp == '-') {
      steps.writeln("   • Apply Linearity Rule:");
      steps.writeln("     ∫(${sLeft.toInfixString()} $sOp ${sRight.toInfixString()}) dx = ∫${sLeft.toInfixString()} dx $sOp ∫${sRight.toInfixString()} dx");
      return BinaryOp(sLeft.integrate(varName, steps),
          sRight.integrate(varName, steps), sOp);
    }
    if (sOp == '*' && sLeft is Constant) {
      steps.writeln("   • Apply Constant Multiple Rule:");
      steps.writeln("     ∫${originalInfix} dx = ${sLeft.toInfixString()} * ∫${sRight.toInfixString()} dx");
      return BinaryOp(sLeft, sRight.integrate(varName, steps), '*');
    }

    if (sOp == '/') {
        Expression derivativeOfRight = sRight.differentiate(varName, StringBuffer()).simplify();
        if (sLeft.equals(derivativeOfRight)) {
            steps.writeln("   • Apply Reverse Chain Rule: ∫g'(x)/g(x) dx = ln|g(x)|");
            steps.writeln("     - Let g(x) = ${sRight.toInfixString()}, so g'(x) = ${derivativeOfRight.toInfixString()}");
            return FunctionCall('ln', sRight);
        }
    }

    if (sOp == '*') {
       if (sLeft is FunctionCall && sRight is FunctionCall) {
        // sec(x)tan(x)
        if (sLeft.name == 'sec' &&
            sRight.name == 'tan' &&
            sLeft.arg.equals(sRight.arg)) {
          steps.writeln("   • Apply standard integral: ∫sec(u)tan(u)du = sec(u)");
          return FunctionCall('sec', sLeft.arg);
        }
      }
      if(sRight is BinaryOp && sRight.op == '^' && sRight.right is Constant) {
        Expression g = sRight.left;
        Constant n = sRight.right as Constant;
        Expression d_g = g.differentiate(varName, StringBuffer()).simplify();
        if(sLeft.equals(d_g) && n.value != -1) {
           final n_plus_1 = n.value + 1;
           final result = BinaryOp(BinaryOp(g, Constant(n_plus_1), '^'), Constant(n_plus_1), '/');
           steps.writeln("   • Apply Reverse Chain Rule: ∫g'(x) * [g(x)]^n dx = [g(x)]^(n+1)/(n+1)");
           steps.writeln("     - Let g(x) = ${g.toInfixString()}, n = ${n.toInfixString()}, so g'(x) = ${d_g.toInfixString()}");
           steps.writeln("     - Result: ${result.toInfixString()}");
           return result;
        }
      }
    }

    if (sOp == '^' &&
        sLeft is Variable &&
        (sLeft as Variable).name == varName &&
        sRight is Constant) {
      double n = (sRight as Constant).value;
      if (n == -1) {
        final result = FunctionCall('ln', Variable(varName));
        steps.writeln("   • ∫x^-1 dx = ${result.toInfixString()} (Integral of 1/x)");
        return result;
      }
      final n_plus_1 = n+1;
      final result = BinaryOp(
          BinaryOp(sLeft, Constant(n_plus_1), '^'), Constant(n_plus_1), '/');
      steps.writeln("   • Apply Power Rule: ∫x^n dx = (x^(n+1))/(n+1)");
      steps.writeln("     - ∫${originalInfix} dx = ${result.toInfixString()}");
      return result;
    }

    if (sOp == '^' && sLeft is Constant && sRight is Variable && (sRight as Variable).name == varName) {
        final result = BinaryOp(this, FunctionCall('ln', sLeft), '/');
        steps.writeln("   • Apply Exponential Rule: ∫a^x dx = a^x / ln(a)");
        steps.writeln("     - ∫${originalInfix} dx = ${result.toInfixString()}");
        return result;
    }


    throw UnsupportedError(
        "Integration for '$originalInfix' is not supported.");
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
        case '^': return Constant(math.pow(l, r).toDouble());
      }
    }
    
    if ((op == '+' || op == '*') && left.toInfixString().compareTo(right.toInfixString()) > 0) {
        final temp = left;
        left = right;
        right = temp;
    }

    if (op == '*' && left is BinaryOp && (left as BinaryOp).op == '/' && (left as BinaryOp).left.isOne()) {
        return BinaryOp(right, (left as BinaryOp).right, '/').simplify();
    }
    if (op == '*' && right is BinaryOp && (right as BinaryOp).op == '/' && (right as BinaryOp).left.isOne()) {
        return BinaryOp(left, (right as BinaryOp).right, '/').simplify();
    }

    if (op == '*') {
      if (left.isZero() || right.isZero()) return Constant(0);
      if (left.isOne()) return right;
      if (right.isOne()) return left;
      if (left is Constant && (left as Constant).value == -1) {
        return BinaryOp(Constant(0), right, '-');
      }
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
      if (left.isZero()) return Constant(0);
      if (left.isOne()) return Constant(1);
    }
    
    if(op == '*' && left.equals(right)) {
      return BinaryOp(left, Constant(2), '^');
    }

    return this;
  }
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
    steps.writeln("     - d/dx[f(g)] = f'(g) * g'");
    Expression innerDerivative = arg.differentiate(varName, steps);
    Expression outerDerivative;
    switch (name) {
      case 'sin': outerDerivative = FunctionCall('cos', arg); break;
      case 'cos': outerDerivative = BinaryOp(Constant(-1), FunctionCall('sin', arg), '*'); break;
      case 'tan': outerDerivative = BinaryOp(FunctionCall('sec', arg), Constant(2), '^'); break;
      case 'sec': outerDerivative = BinaryOp(FunctionCall('sec', arg), FunctionCall('tan', arg), '*'); break;
      case 'ln': outerDerivative = BinaryOp(Constant(1), arg, '/'); break;
      default: throw UnsupportedError("Differentiation of function '$name' not supported");
    }
    return BinaryOp(outerDerivative, innerDerivative, '*');
  }

  @override
  Expression integrate(String varName, StringBuffer steps) {
    final argDerivative = arg.differentiate(varName, StringBuffer()).simplify();
    if(argDerivative is Constant && !argDerivative.isZero()) {
      steps.writeln("   • Apply U-Substitution for ∫${toInfixString()} dx, with u = ${arg.toInfixString()}");
      steps.writeln("     - du = ${argDerivative.toInfixString()} dx  =>  dx = (1/${argDerivative.toInfixString()}) du");
      steps.writeln("     - The integral becomes: ∫$name(u) * (1/${argDerivative.toInfixString()}) du");
      steps.writeln("     - = (1/${argDerivative.toInfixString()}) * ∫$name(u) du");
      
      final coefficient = BinaryOp(Constant(1), argDerivative, '/');
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
        case 'tan':
           integralOfU = "ln|sec(u)|";
           integralOfF = FunctionCall('ln', FunctionCall('sec', arg));
           break;
        case 'sec':
           integralOfU = "ln|sec(u)+tan(u)|";
           integralOfF = FunctionCall('ln', BinaryOp(FunctionCall('sec', arg), FunctionCall('tan', arg), '+'));
           break;
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

    throw UnsupportedError(
        "Integration of '${toInfixString()}' is not supported. Argument must be linear (e.g., ax+b).");
  }

  @override
  Expression simplify() => FunctionCall(name, arg.simplify());
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
      throw FormatException(
          "Unexpected character at end of expression: ${expr.substring(pos)}");
    }
    return expression;
  }

  Expression parseExpression() {
    var x = parseTerm();
    for (;;) {
      if (eat(43)) { // +
        x = BinaryOp(x, parseTerm(), '+');
      } else if (eat(45)) { // -
        x = BinaryOp(x, parseTerm(), '-');
      } else {
        return x;
      }
    }
  }

  Expression parseTerm() {
    var x = parseFactor();
    for (;;) {
       // Implicit multiplication
      if (ch == 40 || (ch >= 97 && ch <= 122) || (ch >= 48 && ch <= 57 && x is! Constant)) {
        x = BinaryOp(x, parseFactor(), '*');
      } else if (eat(42)) { // *
        x = BinaryOp(x, parseFactor(), '*');
      } else if (eat(47)) { // /
        x = BinaryOp(x, parseFactor(), '/');
      } else {
        return x;
      }
    }
  }

  Expression parseFactor() {
    if (eat(43)) { // unary plus
      return parseFactor();
    }
    if (eat(45)) { // unary minus
      final factor = parseFactor();
      if (factor is Constant) {
        return Constant(-factor.value);
      }
      return BinaryOp(Constant(0), factor, '-');
    }
    var x = parsePower();
     // Handle repeated factors e.g. (x+1)(x+2)
    while(ch == 40 || (ch >= 97 && ch <= 122)) {
      x = BinaryOp(x, parseFactor(), '*');
    }
    return x;
  }

  Expression parsePower() {
    var x = parseBase();
    if (eat(94)) { // ^ is right-associative
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
      while ((ch >= 48 && ch <= 57) || ch == 46) {
        next();
      }
      x = Constant(double.parse(expr.substring(startPos, pos)));
    } else if (ch >= 97 && ch <= 122) { // functions or variables
      while ((ch >= 97 && ch <= 122)) {
        next();
      }
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
      if (ch == -1) {
        throw FormatException('Unexpected end of expression');
      }
      throw FormatException(
          'Unexpected character: ${String.fromCharCode(ch)} at position $pos');
    }
    return x;
  }
}
