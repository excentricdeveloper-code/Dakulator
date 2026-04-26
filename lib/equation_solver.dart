import 'package:flutter/material.dart';
import 'quadratic_solver.dart';
import 'linear_solver.dart';
import 'polynomial_solver.dart';
import 'calculus_solver.dart';
import 'scientific_notation_solver.dart';
import 'settings_screen.dart';
import 'ui_components.dart';

class EquationSolverScreen extends StatelessWidget {
  const EquationSolverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 32),
            const SizedBox(width: 12),
            const Text('Solvers', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
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
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              const SizedBox(height: 10),
              _buildMenuButton(
                context,
                'Quadratic Equation',
                'Solve ax² + bx + c = 0',
                Icons.grid_3x3_rounded,
                const QuadraticSolverScreen(),
              ),
              _buildMenuButton(
                context,
                'Linear Equation',
                'Solve ax + b = 0',
                Icons.linear_scale_rounded,
                const LinearSolverScreen(),
              ),
              _buildMenuButton(
                context,
                'Polynomial Equation',
                'Solve degree n equations',
                Icons.layers_rounded,
                const PolynomialSolverScreen(),
              ),
              _buildMenuButton(
                context,
                'Calculus',
                'Integrals and Derivatives',
                Icons.show_chart_rounded,
                const CalculusSolverScreen(),
              ),
               _buildMenuButton(
                context,
                'Scientific Notation',
                'Standard index form',
                Icons.science_rounded,
                const ScientificNotationSolverScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, String subtitle, IconData icon, Widget screen) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        opacity: isDarkMode ? 0.08 : 0.15,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? TechColors.primary.withAlpha(25) : Colors.orange.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isDarkMode ? TechColors.primary : Colors.orange),
          ),
          title: Text(
            title, 
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: isDarkMode ? Colors.white54 : Colors.black54),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => screen),
            );
          },
        ),
      ),
    );
  }
}
