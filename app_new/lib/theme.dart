import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const purple = Color(0xFF9453D6);
const purpleDark = Color(0xFF7B3DBD);
const pink = Color(0xFFD92F7C);
const green = Color(0xFF188A42);
const ink = Color(0xFF2D3142);
const grey = Color(0xFF6B7280);
const soft = Color(0xFFF1E4FF);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: purple, primary: purple),
    scaffoldBackgroundColor: Colors.white,
  );
  return base.copyWith(
    textTheme: GoogleFonts.montserratTextTheme(base.textTheme).apply(bodyColor: ink, displayColor: ink),
  );
}
