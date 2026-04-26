import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'equation_solver.dart';
import 'settings_screen.dart';
import 'utils.dart';
import 'history_screen.dart';
import 'theme_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // You might need to pass options if you haven't run 'flutterfire configure'
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  await themeManager.loadTheme();
  runApp(const CalculatorApp());
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
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.orange,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        useMaterial3: true,
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
  List<HistoryItem> _historyList = [];
  final NumberFormat _df = NumberFormat("#.##");

  @override
  void initState() {
    super.initState();
    _loadHistory();
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
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            alignment: Alignment.center,
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
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_calculationText, style: const TextStyle(fontSize: 24, color: Colors.grey)),
                    Text(_display, style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(5),
              child: TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const EquationSolverScreen()));
                },
                style: const ButtonStyle(
                    minimumSize: WidgetStatePropertyAll(Size(double.infinity, 50))
                ),
                child: const Text('EQUATION SOLVER', style: TextStyle(fontSize: 16),),
              ),
            ),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }
  Widget _buildKeypad() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final buttonColor = isDarkMode ? Colors.grey[850] : Colors.grey[200];
    final operatorButtonColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Row(
            children: [
              _buildButton('AC', color: operatorButtonColor, onPressed: _onClearPress),
              _buildButton('+/-', color: operatorButtonColor, onPressed: _onSignPress),
              _buildButton('%', color: operatorButtonColor, onPressed: _onPercentPress),
              _buildButton('÷', color: operatorButtonColor, onPressed: () => _onOperatorPress('/')),
            ],
          ),
          Row(
            children: [
              _buildButton('7', color: buttonColor, onPressed: () => _onNumberPress('7')),
              _buildButton('8', color: buttonColor, onPressed: () => _onNumberPress('8')),
              _buildButton('9', color: buttonColor, onPressed: () => _onNumberPress('9')),
              _buildButton('×', color: operatorButtonColor, onPressed: () => _onOperatorPress('×')),
            ],
          ),
          Row(
            children: [
              _buildButton('4', color: buttonColor, onPressed: () => _onNumberPress('4')),
              _buildButton('5', color: buttonColor, onPressed: () => _onNumberPress('5')),
              _buildButton('6', color: buttonColor, onPressed: () => _onNumberPress('6')),
              _buildButton('-', color: operatorButtonColor, onPressed: () => _onOperatorPress('-')),
            ],
          ),
          Row(
            children: [
              _buildButton('1', color: buttonColor, onPressed: () => _onNumberPress('1')),
              _buildButton('2', color: buttonColor, onPressed: () => _onNumberPress('2')),
              _buildButton('3', color: buttonColor, onPressed: () => _onNumberPress('3')),
              _buildButton('+', color: operatorButtonColor, onPressed: () => _onOperatorPress('+')),
            ],
          ),
          Row(
            children: [
              _buildButton('0', flex: 2, color: buttonColor, onPressed: () => _onNumberPress('0')),
              _buildButton('.', color: buttonColor, onPressed: _onDecimalPress),
              _buildButton('=', color: operatorButtonColor, onPressed: _onEqualsPress),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String text, {int flex = 1, Color? color, required VoidCallback onPressed}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: onPressed,
          child: Text(text, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}
