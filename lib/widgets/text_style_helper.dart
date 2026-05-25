import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Helper to get Poppins text style, automatically falling back to standard
/// TextStyle when running in a Flutter test environment to avoid font load exceptions.
TextStyle poppinsStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
}) {
  try {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      );
    }
  } catch (_) {}
  return GoogleFonts.poppins(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
  );
}
