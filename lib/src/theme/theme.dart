import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple, brightness: Brightness.light),
  useMaterial3: true,
  fontFamily: GoogleFonts.nunito().fontFamily,
);

final ThemeData darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple, brightness: Brightness.dark),
  useMaterial3: true,
  fontFamily: GoogleFonts.nunito().fontFamily,
);
