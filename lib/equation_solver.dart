import 'package:flutter/material.dart';
import 'quadratic_solver.dart';
import 'linear_solver.dart';
import 'polynomial_solver.dart';
import 'calculus_solver.dart';
import 'scientific_notation_solver.dart';
import 'settings_screen.dart';

class EquationSolverScreen extends StatelessWidget {
  const EquationSolverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equation Solver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildMenuButton(
              context,
              'Quadratic Equation',
              const QuadraticSolverScreen(),
            ),
            _buildMenuButton(
              context,
              'Linear Equation',
              const LinearSolverScreen(),
            ),
            _buildMenuButton(
              context,
              'Polynomial Equation',
              const PolynomialSolverScreen(),
            ),
            _buildMenuButton(
              context,
              'Calculus',
              const CalculusSolverScreen(),
            ),
             _buildMenuButton(
              context,
              'Scientific Notation',
              const ScientificNotationSolverScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, Widget screen) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(title, style: const TextStyle(fontSize: 18)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screen),
          );
        },
      ),
    );
  }
}
