import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Helper to get a generic TextStyle with test safety fallback
TextStyle _safeTextStyle(
  TextStyle Function() fontGetter, {
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
}) {
  try {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
      );
    }
  } catch (_) {}
  
  // Return the Google Font with parameters merged
  final style = fontGetter();
  return style.copyWith(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// 1. Space Grotesk: Sangat futuristik & geometris, sempurna untuk angka nominal/saldo dan rupiah
TextStyle spaceGroteskStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
}) {
  return _safeTextStyle(
    () => GoogleFonts.spaceGrotesk(),
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// 2. Plus Jakarta Sans: Estetika modern tech/fintech untuk header & judul utama
TextStyle plusJakartaStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
}) {
  return _safeTextStyle(
    () => GoogleFonts.plusJakartaSans(),
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// 3. Inter: Keterbacaan sangat tinggi untuk teks panjang, subjudul, dan informasi detail
TextStyle interStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
}) {
  return _safeTextStyle(
    () => GoogleFonts.inter(),
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// 4. Outfit: Desain minimalis elegan untuk kartu, navigasi, dan elemen kartu kaca
TextStyle outfitStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
}) {
  return _safeTextStyle(
    () => GoogleFonts.outfit(),
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );
}

/// 5. Poppins: Fallback pop-modern untuk kecocokan kompatibilitas lama
TextStyle poppinsStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? letterSpacing,
  double? height,
}) {
  return _safeTextStyle(
    () => GoogleFonts.poppins(),
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    height: height,
  );
}
