import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'utils.dart';
import 'main.dart';
import 'history_screen.dart';
import 'ui_components.dart';

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
  bool _isSolving = false;
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

  Future<void> _solve() async {
    if (_isSolving) return;
    performVibration();
    String eq1 = _eq1Controller.text.trim();
    String eq2 = _eq2Controller.text.trim();

    if (eq1.isEmpty || eq2.isEmpty) {
      setState(() => _solutionText = 'Please enter both equations');
      return;
    }

    setState(() {
      _isSolving = true;
      _solutionText = 'Solving...';
      _stepsText = '';
    });

    try {
      final result = await compute(_solveLinearIsolate, {
        'eq1': eq1,
        'eq2': eq2,
        'method': _solveMethod,
      });

      setState(() {
        _solutionText = result['solution'] ?? 'Error';
        _stepsText = result['steps'] ?? '';
        _graphParams = result['graphParams'] != null 
            ? List<double>.from(result['graphParams'] as List) 
            : null;
        _intersection = result['intersection'] != null 
            ? Offset((result['intersection'] as List)[0], (result['intersection'] as List)[1]) 
            : null;
            
        if (_solutionText.isNotEmpty && !_solutionText.startsWith('Error') && !_solutionText.contains('Invalid')) {
          _historyList.insert(0, HistoryItem("$eq1\n$eq2\n$_solutionText"));
          saveHistory('linear_equation_history', _historyList);
        }
      });
    } catch (e) {
      setState(() {
        _solutionText = 'Error';
        _stepsText = 'An unexpected error occurred: $e';
        _graphParams = null;
        _intersection = null;
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
        title: const Text('Linear Solver'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded), 
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen(storageKey: 'linear_equation_history', title: 'Linear History')))
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
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      GlassCard(
                        opacity: isDarkMode ? 0.05 : 0.2,
                        child: Column(
                          children: [
                            _buildEqField(_eq1Controller, 'Eq 1: ax + by = c'),
                            const Divider(height: 24, indent: 40),
                            _buildEqField(_eq2Controller, 'Eq 2: dx + ey = f'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        opacity: isDarkMode ? 0.05 : 0.1,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['Elimination', 'Substitution', 'Graphing'].map((m) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(m), 
                                selected: _solveMethod == m, 
                                onSelected: (selected) => setState(() => _solveMethod = m),
                                selectedColor: isDarkMode ? TechColors.primary.withAlpha(76) : Colors.orange.withAlpha(76),
                              ),
                            )).toList(),
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
                              : const FittedBox(child: Text('SOLVE SYSTEM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)))
                        )
                      ),
                      if (_solutionText.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        GlassCard(
                          opacity: isDarkMode ? 0.1 : 0.2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Solution",
                                style: TextStyle(
                                  fontSize: 14, 
                                  fontWeight: FontWeight.bold, 
                                  color: isDarkMode ? TechColors.primary : Colors.orange,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _solutionText, 
                                style: TextStyle(
                                  fontSize: 20, 
                                  fontWeight: FontWeight.bold, 
                                  color: isDarkMode ? Colors.white : Colors.black87
                                )
                              ),
                              if (_solveMethod == 'Graphing' && _graphParams != null) ...[
                                const Divider(height: 32),
                                _buildGraphView(),
                              ],
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
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal, 
                                  child: Text(
                                    _stepsText, 
                                    style: TextStyle(
                                      fontFamily: 'monospace', 
                                      fontSize: 14, 
                                      height: 1.5,
                                      color: isDarkMode ? Colors.white70 : Colors.black87,
                                    )
                                  )
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

  Widget _buildGraphView() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: GestureDetector(
            onScaleStart: (details) {
              _panStartOffset = details.localFocalPoint - _graphOffset;
            },
            onScaleUpdate: (details) {
              if (details.scale != 1.0) {
                 setState(() {
                    _graphScale *= details.scale;
                    _graphScale = _graphScale.clamp(5.0, 150.0);
                 });
              } else if (details.pointerCount == 1 && _panStartOffset != null) {
                 setState(() {
                   _graphOffset = details.localFocalPoint - _panStartOffset!;
                 });
              }
            },
            child: Container(
              height: 300, 
              width: double.infinity, 
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black38 : Colors.grey[100],
                border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
              ), 
              child: CustomPaint(
                painter: LinearGraphPainter(
                  p: _graphParams!, 
                  intersection: _intersection, 
                  scale: _graphScale, 
                  panOffset: _graphOffset,
                  isDarkMode: isDarkMode,
                )
              )
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Pinch to zoom • Drag to pan", 
          style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white38 : Colors.black38),
        )
      ],
    );
  }

  Widget _buildEqField(TextEditingController controller, String hint) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: controller,
      readOnly: true,
      showCursor: true,
      style: const TextStyle(fontSize: 16),
      onTap: () => setState(() { _activeController = controller; _isKeyboardVisible = true; }),
      decoration: InputDecoration(
        labelText: hint, 
        labelStyle: TextStyle(color: isDarkMode ? Colors.white60 : Colors.black54),
        border: InputBorder.none,
        prefixIcon: Icon(Icons.linear_scale_rounded, color: isDarkMode ? TechColors.primary : Colors.orange, size: 20),
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
              TextButton.icon(
                onPressed: () => setState(() => _isKeyboardVisible = false),
                icon: const Icon(Icons.keyboard_hide_rounded, size: 20),
                label: const Text('HIDE'),
              ),
            ],
          ),
          _buildRow(['1', '2', '3', 'x', 'del']),
          _buildRow(['4', '5', '6', 'y', '(']),
          _buildRow(['7', '8', '9', '=', ')']),
          _buildRow(['.', '0', '+', '-', '/']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: keys.map((k) => Expanded(
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => k == 'del' ? _onBackspace() : _onKeyboardPress(k),
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
                    k,
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: (k == 'del' || k == 'x' || k == 'y' || k == '=') 
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
Map<String, dynamic> _solveLinearIsolate(Map<String, dynamic> params) {
  String eq1 = params['eq1'];
  String eq2 = params['eq2'];
  String method = params['method'];

  try {
    List<Fraction> coeffs1 = _parseEquationStatic(eq1);
    List<Fraction> coeffs2 = _parseEquationStatic(eq2);

    Fraction a1 = coeffs1[0], b1 = coeffs1[1], c1 = coeffs1[2];
    Fraction a2 = coeffs2[0], b2 = coeffs2[1], c2 = coeffs2[2];

    String solution = '';
    String steps = '';
    List<double>? graphParams;
    List<double>? intersection;

    if (method == 'Graphing') {
      double da1 = a1.doubleValue;
      double db1 = b1.doubleValue;
      double dc1 = c1.doubleValue;
      double da2 = a2.doubleValue;
      double db2 = b2.doubleValue;
      double dc2 = c2.doubleValue;

      double det = da1 * db2 - da2 * db1;
      graphParams = [da1, db1, dc1, da2, db2, dc2];
      
      if (det.abs() < 1e-9) {
        solution = "No unique solution";
        steps = "The lines are parallel or coincident, so there is no unique intersection point.";
      } else {
        double x = (dc1 * db2 - dc2 * db1) / det;
        double y = (da1 * dc2 - da2 * dc1) / det;
        intersection = [x, y];
        solution = "Solution: x = ${formatRoot(x)}, y = ${formatRoot(y)}";
        steps = "The intersection point on the graph is (${formatRoot(x)}, ${formatRoot(y)}).";
      }
    } else {
      Fraction det = a1.multiply(b2).subtract(a2.multiply(b1));
      if (det.numerator == 0) {
        solution = "No unique solution";
        steps = "The determinant is zero. No unique solution exists (lines are parallel or coincident).";
      } else {
        if (method == 'Substitution') {
          // Substitution logic
          if (b1.numerator == 0 && b2.numerator == 0) {
            solution = "Cannot solve by substitution";
            steps = "Cannot solve for y in either equation.";
          } else {
            bool swapped = false;
            Fraction sa1 = a1, sb1 = b1, sc1 = c1, sa2 = a2, sb2 = b2, sc2 = c2;
            if (sb1.numerator == 0) {
              sa1 = a2; sb1 = b2; sc1 = c2; sa2 = a1; sb2 = b1; sc2 = c1;
              swapped = true;
            }
            steps = "1. Given Equations:\n   ${swapped ? 'Eq2' : 'Eq1'}: ($sa1)x + ($sb1)y = $sc1\n   ${swapped ? 'Eq1' : 'Eq2'}: ($sa2)x + ($sb2)y = $sc2\n\n";
            steps += "2. Solve first equation for y:\n   y = ($sc1 - ($sa1)x) / $sb1\n\n";
            steps += "3. Substitute into second equation:\n   ($sa2)x + $sb2( ($sc1 - ($sa1)x) / $sb1 ) = $sc2\n\n";
            Fraction x = sc1.multiply(sb2).subtract(sc2.multiply(sb1)).divide(det);
            Fraction y = sc1.subtract(sa1.multiply(x)).divide(sb1);
            steps += "4. Solve for x: x = $x\n\n";
            steps += "5. Substitute x back to find y: y = $y";
            solution = "Solution: x = ${formatRoot(x.doubleValue)}, y = ${formatRoot(y.doubleValue)}";
          }
        } else {
          // Elimination logic
          Fraction x = c1.multiply(b2).subtract(c2.multiply(b1)).divide(det);
          Fraction y = a1.multiply(c2).subtract(a2.multiply(c1)).divide(det);
          steps = "1. Given Equations:\n   Eq1: ($a1)x + ($b1)y = $c1\n   Eq2: ($a2)x + ($b2)y = $c2\n\n";
          steps += "2. Use Cramer's Rule (Elimination):\n   x = (c₁b₂ - c₂b₁) / (a₁b₂ - a₂b₁) = $x\n";
          steps += "   y = (a₁c₂ - a₂c₁) / (a₁b₂ - a₂b₁) = $y\n";
          solution = "Solution: x = ${formatRoot(x.doubleValue)}, y = ${formatRoot(y.doubleValue)}";
        }
      }
    }

    return {
      'solution': solution,
      'steps': steps,
      'graphParams': graphParams,
      'intersection': intersection,
    };
  } catch (e) {
    return {
      'solution': 'Error',
      'steps': 'Invalid equation format or calculation error: $e',
    };
  }
}

List<Fraction> _parseEquationStatic(String equation) {
  equation = equation.replaceAll(' ', '').toLowerCase();
  List<String> sides = equation.split('=');
  if (sides.length != 2) throw Exception("Equation must contain exactly one '='.");

  Map<String, Fraction> left = _parseSideStatic(sides[0]);
  Map<String, Fraction> right = _parseSideStatic(sides[1]);

  return [
    left['x']!.subtract(right['x']!), // a
    left['y']!.subtract(right['y']!), // b
    right['c']!.subtract(left['c']!)  // c
  ];
}

Map<String, Fraction> _parseSideStatic(String side) {
  Fraction x = Fraction(0, 1), y = Fraction(0, 1), c = Fraction(0, 1);
  if (side.isEmpty) return {'x': x, 'y': y, 'c': c};

  String processed = side.replaceAll('-', '+-');
  if (processed.startsWith('+')) processed = processed.substring(1);
  if (processed.isEmpty) return {'x': x, 'y': y, 'c': c};
  List<String> terms = processed.split('+');

  for (var term in terms) {
    if (term.isEmpty) continue;
    if (term.contains('x')) {
      x = x.add(_parseCoeffStatic(term.replaceAll('x', '')));
    } else if (term.contains('y')) {
      y = y.add(_parseCoeffStatic(term.replaceAll('y', '')));
    } else {
      c = c.add(_parseCoeffStatic(term));
    }
  }
  return {'x': x, 'y': y, 'c': c};
}

Fraction _parseCoeffStatic(String coeff) {
  if (coeff.isEmpty || coeff == '+') return Fraction(1, 1);
  if (coeff == '-') return Fraction(-1, 1);
  if (coeff.contains('/')) {
    List<String> parts = coeff.split('/');
    if (parts.length == 2) {
      int? n = int.tryParse(parts[0]);
      int? d = int.tryParse(parts[1]);
      if (n != null && d != null && d != 0) return Fraction(n, d);
    }
  }
  double? val = double.tryParse(coeff);
  if (val != null) return Fraction.fromDouble(val);
  return Fraction(0, 1);
}

class LinearGraphPainter extends CustomPainter {
  final List<double> p;
  final Offset? intersection;
  final double scale;
  final Offset panOffset;
  final bool isDarkMode;

  LinearGraphPainter({
    required this.p, 
    this.intersection, 
    required this.scale, 
    required this.panOffset,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = (isDarkMode ? Colors.white12 : Colors.black12)..strokeWidth = 0.5..isAntiAlias = true;
    final axisPaint = Paint()..color = (isDarkMode ? Colors.white30 : Colors.black38)..strokeWidth = 1.2..isAntiAlias = true;
    final line1Paint = Paint()..color = TechColors.primary..strokeWidth = 3..isAntiAlias = true..style = PaintingStyle.stroke;
    final line2Paint = Paint()..color = Colors.orangeAccent..strokeWidth = 3..isAntiAlias = true..style = PaintingStyle.stroke;
    final pointPaint = Paint()..color = Colors.redAccent..style = PaintingStyle.fill..isAntiAlias = true;
    final textStyle = TextStyle(color: isDarkMode ? Colors.white38 : Colors.black38, fontSize: 10);

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
          _drawIntersectionLabel(canvas, size, screenIntersection, intersection!, textStyle.copyWith(color: Colors.orangeAccent, backgroundColor: Colors.black.withAlpha(153)));
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
    if (b.abs() < 1e-9) { // Vertical line ax = c => x = c/a
      if (a.abs() > 1e-9) {
        double x = c / a;
        double screenX = origin.dx + x * scale;
        path.moveTo(screenX, 0); path.lineTo(screenX, size.height);
      }
    } else if (a.abs() < 1e-9) { // Horizontal line by = c => y = c/b
      double y = c / b;
      double screenY = origin.dy - y * scale;
      path.moveTo(0, screenY); path.lineTo(size.width, screenY);
    } else {
      // y = (c - ax) / b
      double x1Real = (0 - origin.dx) / scale;
      double y1Real = (c - a * x1Real) / b;
      double y1Screen = origin.dy - y1Real * scale;

      double x2Real = (size.width - origin.dx) / scale;
      double y2Real = (c - a * x2Real) / b;
      double y2Screen = origin.dy - y2Real * scale;

      path.moveTo(0, y1Screen);
      path.lineTo(size.width, y2Screen);
    }
    canvas.drawPath(path, paint);
  }

  void _drawIntersectionLabel(Canvas canvas, Size size, Offset screenPos, Offset realPos, TextStyle style) {
    String label = '(${formatRoot(realPos.dx)}, ${formatRoot(realPos.dy)})';
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
  bool shouldRepaint(covariant LinearGraphPainter old) => p != old.p || intersection != old.intersection || scale != old.scale || panOffset != old.panOffset || isDarkMode != old.isDarkMode;
}
