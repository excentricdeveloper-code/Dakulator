import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'utils.dart';
import 'main.dart';
import 'history_screen.dart';

class LinearSolverScreen extends StatefulWidget {
  const LinearSolverScreen({super.key});

  @override
  State<LinearSolverScreen> createState() => _LinearSolverScreenState();
}

class _LinearSolverScreenState extends State<LinearSolverScreen> {
  final TextEditingController _eq1Controller = TextEditingController();
  final TextEditingController _eq2Controller = TextEditingController();
  TextEditingController? _activeController;

  String _solutionText = '';
  String _stepsText = '';
  String _solveMethod = 'Elimination';
  bool _isKeyboardVisible = false;
  List<HistoryItem> _historyList = [];

  List<double>? _graphParams;
  Offset? _intersection;

  // Graph state
  double _graphScale = 20.0;
  Offset _graphOffset = Offset.zero;
  Offset? _panStartOffset;

  @override
  void initState() {
    super.initState();
    _activeController = _eq1Controller;
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _historyList = await loadHistory('linear_equation_history');
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
    String eq1 = _eq1Controller.text;
    String eq2 = _eq2Controller.text;

    if (eq1.isEmpty || eq2.isEmpty) {
      setState(() => _solutionText = 'Please enter both equations');
      return;
    }

    try {
      List<Fraction> coeffs1 = _parseEquation(eq1);
      List<Fraction> coeffs2 = _parseEquation(eq2);

      Fraction a1 = coeffs1[0], b1 = coeffs1[1], c1 = coeffs1[2];
      Fraction a2 = coeffs2[0], b2 = coeffs2[1], c2 = coeffs2[2];

      String result = '';
      if (_solveMethod == 'Elimination') {
        result = _solveByElimination(a1, b1, c1, a2, b2, c2);
      } else if (_solveMethod == 'Substitution') {
        result = _solveBySubstitution(a1, b1, c1, a2, b2, c2);
      } else {
        result = _solveByGraphing(a1, b1, c1, a2, b2, c2);
      }

      setState(() {
        _solutionText = result;
        _historyList.insert(0, HistoryItem("$eq1\n$eq2\n$result"));
        saveHistory('linear_equation_history', _historyList);
      });
    } catch (e) {
      setState(() {
        _solutionText = 'Invalid equation format';
        _stepsText = '';
        _graphParams = null;
        _intersection = null;
      });
    }
  }

  List<Fraction> _parseEquation(String equation) {
    equation = equation.replaceAll(' ', '').toLowerCase();
    List<String> sides = equation.split('=');
    if (sides.length != 2) throw Exception("Invalid Equation: Must contain one '='.");

    Map<String, Fraction> left = _parseSide(sides[0]);
    Map<String, Fraction> right = _parseSide(sides[1]);

    return [
      left['x']!.subtract(right['x']!), // a
      left['y']!.subtract(right['y']!), // b
      right['c']!.subtract(left['c']!)  // c
    ];
  }

  Map<String, Fraction> _parseSide(String side) {
    Fraction x = Fraction(0, 1), y = Fraction(0, 1), c = Fraction(0, 1);
    if (side.isEmpty) return {'x': x, 'y': y, 'c': c};

    String processed = side.replaceAll('-', '+-');
    if (processed.startsWith('+')) processed = processed.substring(1);
    if (processed.isEmpty) return {'x': x, 'y': y, 'c': c};
    List<String> terms = processed.split('+');

    for (var term in terms) {
      if (term.isEmpty) continue;
      if (term.contains('x')) {
        x = x.add(_parseCoeff(term.replaceAll('x', '')));
      } else if (term.contains('y')) {
        y = y.add(_parseCoeff(term.replaceAll('y', '')));
      } else {
        c = c.add(_parseCoeff(term));
      }
    }
    return {'x': x, 'y': y, 'c': c};
  }

  Fraction _parseCoeff(String coeff) {
    if (coeff.isEmpty || coeff == '+') return Fraction(1, 1);
    if (coeff == '-') return Fraction(-1, 1);
    if (coeff.contains('/')) {
      List<String> parts = coeff.split('/');
      return Fraction(int.parse(parts[0]), int.parse(parts[1]));
    }
    return Fraction.fromDouble(double.parse(coeff));
  }

   String _solveByElimination(Fraction a1, Fraction b1, Fraction c1, Fraction a2, Fraction b2, Fraction c2) {
    setState(() => _graphParams = null); // Hide graph
    Fraction det = a1.multiply(b2).subtract(a2.multiply(b1));
    if (det.numerator == 0) {
      _stepsText = "The determinant is zero. No unique solution exists (lines are parallel or coincident).";
      return "No unique solution";
    }

    Fraction x = c1.multiply(b2).subtract(c2.multiply(b1)).divide(det);
    Fraction y = a1.multiply(c2).subtract(a2.multiply(c1)).divide(det);

    String steps = "1. Given Equations:\n   Eq1: ${a1}x + ${b1}y = $c1\n   Eq2: ${a2}x + ${b2}y = $c2\n\n";
    steps += "2. Use Cramer's Rule (Elimination):\n   x = (c₁b₂ - c₂b₁) / (a₁b₂ - a₂b₁) = $x\n";
    steps += "   y = (a₁c₂ - a₂c₁) / (a₁b₂ - a₂b₁) = $y\n";

    _stepsText = steps;
    return "Solution: x = $x, y = $y";
  }

  String _solveBySubstitution(Fraction a1, Fraction b1, Fraction c1, Fraction a2, Fraction b2, Fraction c2) {
    setState(() => _graphParams = null); // Hide graph
    if (b1.numerator == 0 && b2.numerator == 0) {
      _stepsText = "Cannot solve for y in either equation.";
      return "Cannot solve by substitution";
    }
    
    bool swapped = false;
    if (b1.numerator == 0) { // If we can't solve Eq1 for y, swap them.
      var tempA=a1; var tempB=b1; var tempC=c1; a1=a2; b1=b2; c1=c2; a2=tempA; b2=tempB; c2=tempC; 
      swapped = true;
    }

    String steps = "1. Given Equations:\n   ${swapped ? 'Eq2' : 'Eq1'}: ${a1}x + ${b1}y = $c1\n   ${swapped ? 'Eq1' : 'Eq2'}: ${a2}x + ${b2}y = $c2\n\n";
    steps += "2. Solve first equation for y:\n   y = ($c1 - ${a1}x) / $b1\n\n";
    steps += "3. Substitute into second equation:\n   ${a2}x + $b2( ($c1 - ${a1}x) / $b1 ) = $c2\n\n";
    
    Fraction det = a1.multiply(b2).subtract(a2.multiply(b1));
    if (det.numerator == 0) return "No unique solution";
    
    Fraction x = c1.multiply(b2).subtract(c2.multiply(b1)).divide(det.negate());
    Fraction y = c1.subtract(a1.multiply(x)).divide(b1);

    steps += "4. Solve for x: x = $x\n\n";
    steps += "5. Substitute x back to find y: y = $y";

    _stepsText = steps;
    return "Solution: x = $x, y = $y";
  }

  String _solveByGraphing(Fraction a1, Fraction b1, Fraction c1, Fraction a2, Fraction b2, Fraction c2) {
    double det = a1.doubleValue() * b2.doubleValue() - a2.doubleValue() * b1.doubleValue();
    _graphParams = [a1.doubleValue(), b1.doubleValue(), -c1.doubleValue(), a2.doubleValue(), b2.doubleValue(), -c2.doubleValue()];
    
    if (det.abs() < 1e-9) {
      _intersection = null;
      _stepsText = "The lines are parallel or coincident, so there is no unique intersection point.";
      return "No unique solution";
    }

    double x = (c1.doubleValue() * b2.doubleValue() - c2.doubleValue() * b1.doubleValue()) / det;
    double y = (a1.doubleValue() * c2.doubleValue() - a2.doubleValue() * c1.doubleValue()) / det;
    _intersection = Offset(x, y);
    _stepsText = "The intersection point on the graph is (${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}).";
    return "Solution: (${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linear System Solver'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen(storageKey: 'linear_equation_history', title: 'Linear History')))),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildEqField(_eq1Controller, 'Equation 1: ax + by = c'),
            const SizedBox(height: 10),
            _buildEqField(_eq2Controller, 'Equation 2: dx + ey = f'),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['Elimination', 'Substitution', 'Graphing'].map((m) => Row(mainAxisSize: MainAxisSize.min, children: [Radio<String>(value: m, groupValue: _solveMethod, onChanged: (v) => setState(() => _solveMethod = v!)), Text(m)])).toList()),
            const SizedBox(height: 10),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _solve, style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), child: const Text('SOLVE'))),
            const SizedBox(height: 20),
            Text(_solutionText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const Divider(color: Colors.orange),
            if (_solveMethod == 'Graphing' && _graphParams != null)
              Column(
                children: [
                  GestureDetector(
                    onScaleStart: (details) {
                      _panStartOffset = details.localFocalPoint - _graphOffset;
                    },
                    onScaleUpdate: (details) {
                      if (details.scale != 1.0) {
                         setState(() {
                            _graphScale *= details.scale;
                            _graphScale = _graphScale.clamp(5.0, 150.0); // Clamp zoom level
                         });
                      } else if (details.pointerCount == 1 && _panStartOffset != null) {
                         setState(() {
                           _graphOffset = details.localFocalPoint - _panStartOffset!;
                         });
                      }
                    },
                    child: Container(
                      height: 350, 
                      width: double.infinity, 
                      margin: const EdgeInsets.symmetric(vertical: 10), 
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[700]!), color: Colors.grey[850]), 
                      child: ClipRect(child: CustomPaint(painter: LinearGraphPainter(p: _graphParams!, intersection: _intersection, scale: _graphScale, panOffset: _graphOffset)))
                    ),
                  ),
                  const Text("Use two fingers to zoom and one finger to pan.")
                ],
              ),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: Text(_stepsText, style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.5))),
          ]))),
          if (_isKeyboardVisible) _buildKeyboard(),
        ]),
      ),
    );
  }

  Widget _buildEqField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      readOnly: true,
      showCursor: true,
      onTap: () => setState(() { _activeController = controller; _isKeyboardVisible = true; }),
      decoration: InputDecoration(hintText: hint, border: const OutlineInputBorder(), focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.orange))),
    );
  }

  Widget _buildKeyboard() {
    return Container(
      color: Colors.black, padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4), child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [IconButton(icon: const Icon(Icons.keyboard_hide, color: Colors.white), onPressed: () => setState(() => _isKeyboardVisible = false))]),
        _buildRow(['1', '2', '3', 'x', 'del']),
        _buildRow(['4', '5', '6', 'y', '(']),
        _buildRow(['7', '8', '9', '=', ')']),
        _buildRow(['.', '0', '+', '-', '/']),
      ]),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(children: keys.map((k) => Expanded(child: Padding(padding: const EdgeInsets.all(2), child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[900], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))), onPressed: () => k == 'del' ? _onBackspace() : _onKeyboardPress(k), child: Text(k, style: const TextStyle(fontSize: 18)))) )).toList());
  }
}

class LinearGraphPainter extends CustomPainter {
  final List<double> p;
  final Offset? intersection;
  final double scale;
  final Offset panOffset;

  LinearGraphPainter({required this.p, this.intersection, required this.scale, required this.panOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.4)..strokeWidth = 0.5..isAntiAlias = true;
    final axisPaint = Paint()..color = Colors.grey[500]!..strokeWidth = 1..isAntiAlias = true;
    final line1Paint = Paint()..color = Colors.blueAccent..strokeWidth = 2.5..isAntiAlias = true..style = PaintingStyle.stroke;
    final line2Paint = Paint()..color = Colors.redAccent..strokeWidth = 2.5..isAntiAlias = true..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = Colors.orangeAccent..style = PaintingStyle.fill..isAntiAlias = true;
    final textStyle = TextStyle(color: Colors.grey[400], fontSize: 10);

    final origin = Offset(size.width / 2, size.height / 2) + panOffset;

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    _drawGridAndLabels(canvas, size, origin, scale, gridPaint, textStyle);

    canvas.drawLine(Offset(0, origin.dy), Offset(size.width, origin.dy), axisPaint); // X-axis
    canvas.drawLine(Offset(origin.dx, 0), Offset(origin.dx, size.height), axisPaint); // Y-axis

    _drawGraphLine(canvas, size, p[0], p[1], p[2], origin, scale, line1Paint);
    _drawGraphLine(canvas, size, p[3], p[4], p[5], origin, scale, line2Paint);

    _drawLegend(canvas, size);

    if (intersection != null) {
      final screenIntersection = Offset(origin.dx + intersection!.dx * scale, origin.dy - intersection!.dy * scale);
      if (screenIntersection.dx > 0 && screenIntersection.dx < size.width && screenIntersection.dy > 0 && screenIntersection.dy < size.height) {
          canvas.drawCircle(screenIntersection, 6, pointPaint);
          _drawIntersectionLabel(canvas, size, screenIntersection, intersection!, textStyle.copyWith(color: Colors.orangeAccent, backgroundColor: Colors.black.withOpacity(0.6)));
      }
    }
  }

  double _getGridStep(double scale) {
    const double targetPixelsPerStep = 70.0;
    double val = targetPixelsPerStep / scale;
    double p10 = math.pow(10, (math.log(val) / math.ln10).floor()).toDouble();
    if (val / p10 >= 10) return p10 * 10;
    if (val / p10 >= 5) return p10 * 5;
    if (val / p10 >= 2) return p10 * 2;
    return p10;
  }

  void _drawGridAndLabels(Canvas canvas, Size size, Offset origin, double scale, Paint gridPaint, TextStyle textStyle) {
      final step = _getGridStep(scale);
      final format = step < 1 ? '0.0' : '0';

      // Vertical grid lines and X-axis labels
      for (int i = 0; ; i++) {
          double realVal = i * step;
          double xPosRight = origin.dx + realVal * scale;
          double xPosLeft = origin.dx - realVal * scale;
          bool rightDone = xPosRight > size.width, leftDone = xPosLeft < 0;

          if (!rightDone) {
              canvas.drawLine(Offset(xPosRight, 0), Offset(xPosRight, size.height), gridPaint);
              _drawText(canvas, realVal.toStringAsFixed(realVal==0?0:1), Offset(xPosRight, origin.dy), textStyle, anchor: Alignment.topCenter);
          }
          if (i != 0 && !leftDone) {
              canvas.drawLine(Offset(xPosLeft, 0), Offset(xPosLeft, size.height), gridPaint);
              _drawText(canvas, (-realVal).toStringAsFixed(realVal==0?0:1), Offset(xPosLeft, origin.dy), textStyle, anchor: Alignment.topCenter);
          }
          if (rightDone && leftDone) break;
      }
      // Horizontal grid lines and Y-axis labels
      for (int i = 0; ; i++) {
          double realVal = i * step;
          double yPosUp = origin.dy - realVal * scale;
          double yPosDown = origin.dy + realVal * scale;
          bool upDone = yPosUp < 0, downDone = yPosDown > size.height;
          
          if (i!=0 && !upDone) {
              canvas.drawLine(Offset(0, yPosUp), Offset(size.width, yPosUp), gridPaint);
              _drawText(canvas, realVal.toStringAsFixed(1), Offset(origin.dx, yPosUp), textStyle, anchor: Alignment.centerLeft);
          }
          if (!downDone) {
              canvas.drawLine(Offset(0, yPosDown), Offset(size.width, yPosDown), gridPaint);
              _drawText(canvas, (-realVal).toStringAsFixed(1), Offset(origin.dx, yPosDown), textStyle, anchor: Alignment.centerLeft);
          }
          if (upDone && downDone) break;
      }
  }

  void _drawText(Canvas canvas, String text, Offset pos, TextStyle style, {Alignment anchor = Alignment.topLeft}) {
      final textPainter = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
      final offset = pos + Offset(-textPainter.width * (anchor.x + 1)/2, -textPainter.height * (anchor.y + 1)/2);
      textPainter.paint(canvas, offset);
  }
  

  void _drawGraphLine(Canvas canvas, Size size, double a, double b, double c, Offset origin, double scale, Paint paint) {
    Path path = Path();
    if (b.abs() < 1e-9) { // Vertical line x = k
      if (a.abs() > 1e-9) {
        double x = c / a;
        double screenX = origin.dx + x * scale;
        path.moveTo(screenX, 0); path.lineTo(screenX, size.height);
      }
    } else if (a.abs() < 1e-9) { // Horizontal line y = k
      double y = c / b;
      double screenY = origin.dy - y * scale;
      path.moveTo(0, screenY); path.lineTo(size.width, screenY);
    } else {
      // y = (c - ax) / b
      double x1_real = (0 - origin.dx) / scale;
      double y1_real = (c - a * x1_real) / b;
      double y1_screen = origin.dy - y1_real * scale;

      double x2_real = (size.width - origin.dx) / scale;
      double y2_real = (c - a * x2_real) / b;
      double y2_screen = origin.dy - y2_real * scale;

      path.moveTo(0, y1_screen);
      path.lineTo(size.width, y2_screen);
    }
    canvas.drawPath(path, paint);
  }

  void _drawIntersectionLabel(Canvas canvas, Size size, Offset screenPos, Offset realPos, TextStyle style) {
    String label = '(${realPos.dx.toStringAsFixed(2)}, ${realPos.dy.toStringAsFixed(2)})';
    final textPainter = TextPainter(text: TextSpan(text: label, style: style), textDirection: TextDirection.ltr)..layout();
    
    double x = screenPos.dx + 10;
    double y = screenPos.dy - 10 - textPainter.height;

    if (x + textPainter.width > size.width) x = screenPos.dx - 10 - textPainter.width;
    if (y < 0) y = screenPos.dy + 10;

    final bgRect = RRect.fromRectAndRadius(Rect.fromLTWH(x-4, y-2, textPainter.width+8, textPainter.height+4), const Radius.circular(4));
    canvas.drawRRect(bgRect, Paint()..color = style.backgroundColor! ..isAntiAlias=true);
    textPainter.paint(canvas, Offset(x,y));
  }

  void _drawLegend(Canvas canvas, Size size) {
    final legendItems = {
      'Eq 1': Colors.blueAccent,
      'Eq 2': Colors.redAccent,
    };
    double yOffset = 10;
    for (var item in legendItems.entries) {
      final textPainter = TextPainter(text: TextSpan(text: item.key, style: TextStyle(color: item.value, fontSize: 12)), textDirection: TextDirection.ltr)..layout();
      canvas.drawLine(Offset(10, yOffset + 6), Offset(30, yOffset + 6), Paint()..color=item.value..strokeWidth=2..isAntiAlias=true);
      textPainter.paint(canvas, Offset(35, yOffset));
      yOffset += 18;
    }
  }

  @override
  bool shouldRepaint(covariant LinearGraphPainter old) => p != old.p || intersection != old.intersection || scale != old.scale || panOffset != old.panOffset;
}
