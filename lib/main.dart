import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'equation_solver.dart';
import 'settings_screen.dart';
import 'utils.dart';
import 'history_screen.dart';
import 'theme_manager.dart';
import 'ui_components.dart';
import 'about_us_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  await themeManager.loadTheme();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const CalculatorApp());
  });
}

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {

  @override
  void initState() {
    super.initState();
    themeManager.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dakulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.orange,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.light,
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: const CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: const CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themeMode: themeManager.value,
      home: const CalculatorHome(),
    );
  }
}

class HistoryItem {
  final String equation;
  HistoryItem(this.equation);

  Map<String, dynamic> toJson() => {'equation': equation};
  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(json['equation']);
}

class CalculatorHome extends StatefulWidget {
  const CalculatorHome({super.key});

  @override
  State<CalculatorHome> createState() => _CalculatorHomeState();
}

class _CalculatorHomeState extends State<CalculatorHome> {
  String _display = '0';
  String _calculationText = '';
  double _firstNumber = 0;
  String? _operation;
  bool _justCalculated = false;
  bool _isScientific = false;
  List<HistoryItem> _historyList = [];
  final NumberFormat _df = NumberFormat("###,###.########");

  // Keys for walkthrough
  final GlobalKey _keyHistory = GlobalKey();
  final GlobalKey _keySettings = GlobalKey();
  final GlobalKey _keyDisplay = GlobalKey();
  final GlobalKey _keySolver = GlobalKey();
  final GlobalKey _keyKeypad = GlobalKey();

  late TutorialCoachMark tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstSeen();
    });
  }

  Future<void> _checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool seen = (prefs.getBool('walkthrough_seen') ?? false);
    if (!seen) {
      _showWalkthrough();
      await prefs.setBool('walkthrough_seen', true);
    }
  }

  void _showWalkthrough() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.orange,
      textSkip: "SKIP",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () => debugPrint("Walkthrough finished"),
      onClickTarget: (target) => debugPrint("Clicked target"),
      onSkip: () {
        debugPrint("Walkthrough skipped");
        return true;
      },
    )..show(context: context);
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      TargetFocus(
        identify: "Display",
        keyTarget: _keyDisplay,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Calculator Display", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("Here you can see your current calculation and the result.", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "Solver",
        keyTarget: _keySolver,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Advanced Solvers", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("Click here to access Quadratic, Linear, Polynomial, and Calculus solvers!", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "History",
        keyTarget: _keyHistory,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Calculation History", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("Review your previous calculations anytime.", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "Settings",
        keyTarget: _keySettings,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("App Settings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("Change theme or send us feedback from here.", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
    targets.add(
      TargetFocus(
        identify: "Keypad",
        keyTarget: _keyKeypad,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Modern Keypad", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20)),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text("Experience haptic feedback and an expandable scientific mode for complex math.", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
    return targets;
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String json = jsonEncode(_historyList.map((e) => e.toJson()).toList());
    await prefs.setString('calculator_history', json);
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('calculator_history');
    if (jsonStr != null) {
      setState(() {
        Iterable l = jsonDecode(jsonStr);
        _historyList = List<HistoryItem>.from(l.map((model) => HistoryItem.fromJson(model)));
      });
    }
  }

  void _onNumberPress(String text) {
    performVibration();
    setState(() {
      if (_justCalculated || _display == '0') {
        _display = text;
        _justCalculated = false;
      } else {
        _display += text;
      }
      _updateCalculationText();
    });
  }

  void _onOperatorPress(String text) {
    performVibration();
    setState(() {
      _justCalculated = false;
      _firstNumber = double.tryParse(_display) ?? 0;
      _display = '0';
      _operation = text;
      _updateCalculationText();
    });
  }

  void _onEqualsPress() {
    performVibration();
    if (_operation != null) {
      double secondNumber = double.tryParse(_display) ?? 0;
      double result = 0;
      bool error = false;

      setState(() {
        switch (_operation) {
          case '+':
            result = _firstNumber + secondNumber;
            break;
          case '-':
            result = _firstNumber - secondNumber;
            break;
          case '×':
            result = _firstNumber * secondNumber;
            break;
          case '/':
            if (secondNumber != 0) {
              result = _firstNumber / secondNumber;
            } else {
              _display = 'Error';
              _calculationText = '';
              error = true;
            }
            break;
        }

        if (!error) {
          String equation = "${_df.format(_firstNumber)} $_operation ${_df.format(secondNumber)} = ${_df.format(result)}";
          _display = _df.format(result);
          _calculationText = equation;
          _historyList.add(HistoryItem(equation));
          _saveHistory();
          _firstNumber = result;
          _operation = null;
          _justCalculated = true;
        }
      });
    }
  }

  void _onClearPress() {
    performVibration();
    setState(() {
      _display = '0';
      _calculationText = '';
      _firstNumber = 0;
      _operation = null;
      _justCalculated = false;
    });
  }

  void _onDecimalPress() {
    performVibration();
    setState(() {
      if (!_display.contains('.')) {
        _display += '.';
        _updateCalculationText();
      }
    });
  }

  void _onSignPress() {
    performVibration();
    setState(() {
      double val = double.tryParse(_display) ?? 0;
      val *= -1;
      _display = _df.format(val);
      _updateCalculationText();
    });
  }

  void _onPercentPress() {
    performVibration();
    setState(() {
      double val = double.tryParse(_display) ?? 0;
      val /= 100;
      _display = _df.format(val);
      _updateCalculationText();
    });
  }

  void _onScientificPress(String op) {
    performVibration();
    setState(() {
      double val = double.tryParse(_display) ?? 0;
      double result = 0;
      String equation = "";

      switch (op) {
        case 'sin':
          result = math.sin(val * math.pi / 180);
          equation = "sin(${_df.format(val)}) = ${_df.format(result)}";
          break;
        case 'cos':
          result = math.cos(val * math.pi / 180);
          equation = "cos(${_df.format(val)}) = ${_df.format(result)}";
          break;
        case 'tan':
          result = math.tan(val * math.pi / 180);
          equation = "tan(${_df.format(val)}) = ${_df.format(result)}";
          break;
        case 'log':
          if (val > 0) {
            result = math.log(val) / math.ln10;
            equation = "log(${_df.format(val)}) = ${_df.format(result)}";
          } else {
            _display = 'Error';
            return;
          }
          break;
        case 'ln':
          if (val > 0) {
            result = math.log(val);
            equation = "ln(${_df.format(val)}) = ${_df.format(result)}";
          } else {
            _display = 'Error';
            return;
          }
          break;
        case '√':
          if (val >= 0) {
            result = math.sqrt(val);
            equation = "√(${_df.format(val)}) = ${_df.format(result)}";
          } else {
            _display = 'Error';
            return;
          }
          break;
        case 'x²':
          result = val * val;
          equation = "(${_df.format(val)})² = ${_df.format(result)}";
          break;
        case 'π':
          result = math.pi;
          _display = _df.format(result);
          _justCalculated = false;
          _updateCalculationText();
          return;
        case 'e':
          result = math.e;
          _display = _df.format(result);
          _justCalculated = false;
          _updateCalculationText();
          return;
      }

      _display = _df.format(result);
      _calculationText = equation;
      _historyList.add(HistoryItem(equation));
      _saveHistory();
      _justCalculated = true;
    });
  }

  void _updateCalculationText() {
    if (_justCalculated) {
      _calculationText = '';
      return;
    }
    String firstNumStr = _df.format(_firstNumber);
    _calculationText = "${_firstNumber != 0 ? firstNumStr : ""} ${_operation ?? ""} ${_display == '0' ? "" : _display}".trim();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutUsScreen()),
            );
          },
          child: Container(
            width: 40,
            padding: const EdgeInsets.only(left: 16.0),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
        ),
        leadingWidth: 60,
        actions: [
          IconButton(
            key: _keyHistory,
            icon: const Icon(Icons.history_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(
                    storageKey: 'calculator_history',
                    title: 'History',
                  ),
                ),
              );
            },
          ),
          IconButton(
            key: _keySettings,
            icon: const Icon(Icons.settings_suggest_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Display Area
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        key: _keyDisplay,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: _isScientific ? 12 : 24,
                        ),
                        alignment: Alignment.bottomRight,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                style: TextStyle(
                                  fontSize: _isScientific ? 18 : 22,
                                  color: isDarkMode ? Colors.white70 : Colors.black45,
                                  letterSpacing: 1.2,
                                ),
                                child: Text(_calculationText),
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                style: TextStyle(
                                  fontSize: _isScientific ? 50 : 80,
                                  fontWeight: FontWeight.w300,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                  letterSpacing: -1,
                                ),
                                child: Text(_display),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bottom section: Solvers + Keypad
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GlassCard(
                                    padding: EdgeInsets.zero,
                                    opacity: isDarkMode ? 0.05 : 0.1,
                                    child: Container(
                                      key: _keySolver,
                                      child: TextButton(
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const EquationSolverScreen()));
                                        },
                                        style: TextButton.styleFrom(
                                          minimumSize: const Size(double.infinity, 50),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'SOLVERS',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.5,
                                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GlassCard(
                                  padding: EdgeInsets.zero,
                                  opacity: isDarkMode ? 0.05 : 0.1,
                                  child: IconButton(
                                    onPressed: () {
                                      performVibration();
                                      setState(() => _isScientific = !_isScientific);
                                    },
                                    icon: Icon(
                                      _isScientific ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up,
                                      color: isDarkMode ? TechColors.accent : Colors.orange,
                                    ),
                                    tooltip: 'Scientific Mode',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildKeypad(),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),


      ),
    );
  }

  Widget _buildKeypad() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final operatorColor = isDarkMode 
        ? TechColors.accent.withAlpha(102) 
        : Colors.orange.withAlpha(180);
    final buttonPadding = _isScientific ? 12.0 : 16.0;

    return Container(
      key: _keyKeypad,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black26 : Colors.white24,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isScientific ? _buildScientificKeypad() : const SizedBox(height: 0),
          ),
          Row(
            children: [
              TechButton(text: 'AC', isOperator: true, verticalPadding: buttonPadding, onPressed: _onClearPress),
              TechButton(text: '+/-', isOperator: true, verticalPadding: buttonPadding, onPressed: _onSignPress),
              TechButton(text: '%', isOperator: true, verticalPadding: buttonPadding, onPressed: _onPercentPress),
              TechButton(text: '÷', isOperator: true, color: operatorColor, textColor: Colors.white, verticalPadding: buttonPadding, onPressed: () => _onOperatorPress('/')),
            ],
          ),
          Row(
            children: [
              TechButton(text: '7', verticalPadding: buttonPadding, onPressed: () => _onNumberPress('7')),
              TechButton(text: '8', verticalPadding: buttonPadding, onPressed: () => _onNumberPress('8')),
              TechButton(text: '9', verticalPadding: buttonPadding, onPressed: () => _onNumberPress('9')),
              TechButton(text: '×', isOperator: true, color: operatorColor, textColor: Colors.white, verticalPadding: buttonPadding, onPressed: () => _onOperatorPress('×')),
            ],
          ),
          Row(
            children: [
              TechButton(text: '4', verticalPadding: buttonPadding, onPressed: () => _onNumberPress('4')),
              TechButton(text: '5', verticalPadding: buttonPadding, onPressed: () => _onNumberPress('5')),
              TechButton(text: '6', verticalPadding: buttonPadding, onPressed: () => _onNumberPress('6')),
              TechButton(text: '-', isOperator: true, color: operatorColor, textColor: Colors.white, verticalPadding: buttonPadding, onPressed: () => _onOperatorPress('-')),
            ],
          ),
          Row(
            children: [
              TechButton(text: '1', verticalPadding: buttonPadding, onPressed: () => _onNumberPress('1')),
              TechButton(text: '2', verticalPadding: buttonPadding, onPressed: () => _onNumberPress('2')),
              TechButton(text: '3', verticalPadding: buttonPadding, onPressed: () => _onNumberPress('3')),
              TechButton(text: '+', isOperator: true, color: operatorColor, textColor: Colors.white, verticalPadding: buttonPadding, onPressed: () => _onOperatorPress('+')),
            ],
          ),
          Row(
            children: [
              TechButton(text: '0', flex: 2, verticalPadding: buttonPadding, onPressed: () => _onNumberPress('0')),
              TechButton(text: '.', verticalPadding: buttonPadding, onPressed: _onDecimalPress),
              TechButton(
                text: '=', 
                isOperator: true, 
                color: Colors.orange, 
                textColor: Colors.white,
                verticalPadding: buttonPadding,
                onPressed: _onEqualsPress
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScientificKeypad() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final sciColor = isDarkMode 
        ? Colors.white.withAlpha(15) 
        : Colors.grey[200];
    const buttonPadding = 12.0;

    return Column(
      children: [
        Row(
          children: [
            TechButton(text: 'sin', color: sciColor, verticalPadding: buttonPadding, onPressed: () => _onScientificPress('sin')),
            TechButton(text: 'cos', color: sciColor, verticalPadding: buttonPadding, onPressed: () => _onScientificPress('cos')),
            TechButton(text: 'tan', color: sciColor, verticalPadding: buttonPadding, onPressed: () => _onScientificPress('tan')),
            TechButton(text: 'π', color: sciColor, verticalPadding: buttonPadding, onPressed: () => _onScientificPress('π')),
          ],
        ),
        Row(
          children: [
            TechButton(text: 'log', color: sciColor, verticalPadding: buttonPadding, onPressed: () => _onScientificPress('log')),
            TechButton(text: 'ln', color: sciColor, verticalPadding: buttonPadding, onPressed: () => _onScientificPress('ln')),
            TechButton(text: '√', color: sciColor, verticalPadding: buttonPadding, onPressed: () => _onScientificPress('√')),
            TechButton(text: 'e', color: sciColor, verticalPadding: buttonPadding, onPressed: () => _onScientificPress('e')),
          ],
        ),
        Row(
          children: [
            TechButton(text: 'x²', flex: 1, color: sciColor, verticalPadding: buttonPadding, onPressed: () => _onScientificPress('x²')),
            const Expanded(flex: 3, child: SizedBox.shrink()),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Divider(
            height: 1, 
            thickness: 1,
            color: isDarkMode ? Colors.white10 : Colors.black12,
          ),
        ),
      ],
    );
  }

  // Remove the old _buildButton method as we use TechButton now
}
