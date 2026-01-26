import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'main.dart';

class Fraction {
  final int numerator;
  final int denominator;

  Fraction(this.numerator, this.denominator) {
    if (denominator == 0) throw Exception("Denominator cannot be zero");
  }

  double doubleValue() => numerator / denominator;

  Fraction add(Fraction other) {
    return Fraction(
      numerator * other.denominator + other.numerator * denominator,
      denominator * other.denominator,
    ).simplify();
  }

  Fraction subtract(Fraction other) {
    return Fraction(
      numerator * other.denominator - other.numerator * denominator,
      denominator * other.denominator,
    ).simplify();
  }

  Fraction multiply(Fraction other) {
    return Fraction(numerator * other.numerator, denominator * other.denominator).simplify();
  }

  Fraction divide(Fraction other) {
    return Fraction(numerator * other.denominator, denominator * other.numerator).simplify();
  }

  Fraction negate() => Fraction(-numerator, denominator);

  Fraction abs() => Fraction(numerator.abs(), denominator.abs());

  Fraction simplify() {
    int common = _gcd(numerator.abs(), denominator.abs());
    int sign = (numerator * denominator < 0) ? -1 : 1;
    return Fraction(sign * (numerator.abs() ~/ common), denominator.abs() ~/ common);
  }

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
    String s = value.toString();
    if (!s.contains('.')) return Fraction(value.toInt(), 1);
    int digitsDec = s.length - 1 - s.indexOf('.');
    int den = 1;
    for (int i = 0; i < digitsDec; i++) den *= 10;
    int num = (value * den).round();
    return Fraction(num, den).simplify();
  }
}

Future<void> performVibration() async {
  // Use HapticFeedback as a safe alternative to the failing vibration package
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
