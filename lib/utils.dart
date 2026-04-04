import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'main.dart';

class Fraction {
  final int numerator;
  final int denominator;

  Fraction(this.numerator, this.denominator) {
    if (denominator == 0) throw Exception("Denominator cannot be zero");
  }

  double get doubleValue => numerator / denominator;

  Fraction simplify() {
    if (numerator == 0) return Fraction(0, 1);
    int common = _gcd(numerator.abs(), denominator.abs());
    int sign = (numerator * denominator < 0) ? -1 : 1;
    return Fraction(sign * (numerator.abs() ~/ common), denominator.abs() ~/ common);
  }

  Fraction add(Fraction other) => Fraction(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  ).simplify();

  Fraction subtract(Fraction other) => Fraction(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  ).simplify();

  Fraction multiply(Fraction other) => Fraction(numerator * other.numerator, denominator * other.denominator).simplify();

  Fraction divide(Fraction other) => Fraction(numerator * other.denominator, denominator * other.numerator).simplify();

  Fraction negate() => Fraction(-numerator, denominator).simplify();

  Fraction abs() => Fraction(numerator.abs(), denominator.abs()).simplify();

  static int _gcd(int a, int b) {
    while (b != 0) {
      int t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  @override
  String toString() {
    if (denominator == 1) return numerator.toString();
    return "$numerator/$denominator";
  }

  static Fraction fromDouble(double value) {
    if (value.isInfinite || value.isNaN) return Fraction(0, 1);
    if (value == 0) return Fraction(0, 1);
    
    // Check if it's already an integer
    if (value == value.roundToDouble()) return Fraction(value.toInt(), 1);

    // Continued fraction algorithm for better precision and smaller denominators
    double x = value.abs();
    int sign = value < 0 ? -1 : 1;
    double tolerance = 1.0e-6;
    
    double h1 = 1, h2 = 0, k1 = 0, k2 = 1;
    double b = x;
    do {
      double a = b.floorToDouble();
      double aux = h1;
      h1 = a * h1 + h2;
      h2 = aux;
      aux = k1;
      k1 = a * k1 + k2;
      k2 = aux;
      b = 1 / (b - a);
    } while ((x - h1 / k1).abs() > x * tolerance && b.isFinite);

    return Fraction((sign * h1).toInt(), k1.toInt()).simplify();
  }
}

class ComplexResult {
  final String realPart;
  final String imaginaryPart;
  final bool isComplex;

  ComplexResult({required this.realPart, required this.imaginaryPart, this.isComplex = false});

  @override
  String toString() {
    if (!isComplex) return realPart;
    if (realPart == "0") {
        if (imaginaryPart == "1") return "i";
        if (imaginaryPart == "-1") return "-i";
        return "${imaginaryPart}i";
    }
    String sign = imaginaryPart.startsWith('-') ? "-" : "+";
    String absImg = imaginaryPart.startsWith('-') ? imaginaryPart.substring(1) : imaginaryPart;
    if (absImg == "1") return "($realPart $sign i)";
    return "($realPart $sign ${absImg}i)";
  }
}

String formatRoot(double value) {
  if (value == 0) return "0";
  
  // Try to represent as simple square root sqrt(n)/d
  for (int d = 1; d <= 20; d++) {
    double target = value * d;
    double squared = target * target;
    int n = squared.round();
    if ((math.sqrt(n) / d - value).abs() < 1e-6) {
      if (n == 0) return "0";
      String rootStr = _simplifyRoot(n);
      if (d == 1) return rootStr;
      return "$rootStr/$d";
    }
  }

  // Fallback to Fraction
  Fraction f = Fraction.fromDouble(value);
  if (f.denominator <= 100) return f.toString();

  return value.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), "");
}

String _simplifyRoot(int n) {
  if (n < 0) return "i√${-n}";
  int outside = 1;
  int inside = n;
  for (int i = math.sqrt(n).floor(); i >= 2; i--) {
    if (inside % (i * i) == 0) {
      outside *= i;
      inside ~/= (i * i);
    }
  }
  if (inside == 1) return outside.toString();
  if (outside == 1) return "√$inside";
  return "${outside}√$inside";
}

Future<void> performVibration() async {
  await HapticFeedback.mediumImpact();
}

Future<void> saveHistory(String key, List<HistoryItem> historyList) async {
  final prefs = await SharedPreferences.getInstance();
  final String json = jsonEncode(historyList.map((e) => e.toJson()).toList());
  await prefs.setString(key, json);
}

Future<List<HistoryItem>> loadHistory(String key) async {
  final prefs = await SharedPreferences.getInstance();
  final String? jsonStr = prefs.getString(key);
  if (jsonStr != null) {
    Iterable l = jsonDecode(jsonStr);
    return List<HistoryItem>.from(l.map((model) => HistoryItem.fromJson(model)));
  }
  return [];
}
