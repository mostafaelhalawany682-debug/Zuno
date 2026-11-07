import 'package:flutter/material.dart';

const zunoInk = Color(0xFF090B12);
const zunoPanel = Color(0xFF151925);
const zunoGold = Color(0xFFFFC857);
const zunoMuted = Color(0xFF9BA3B4);
const zunoAccent = Color(0xFF8A5CF6);

ThemeData buildZunoTheme() => ThemeData.dark().copyWith(
      scaffoldBackgroundColor: zunoInk,
      colorScheme: const ColorScheme.dark(
        primary: zunoGold,
        secondary: zunoAccent,
        surface: zunoPanel,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: zunoInk, elevation: 0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: zunoPanel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
