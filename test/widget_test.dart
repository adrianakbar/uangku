// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uangku/main.dart';

void main() {
  // Inisialisasi SQLite database factory FFI untuk pengujian
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  // Nonaktifkan fetching font dari internet saat pengujian untuk mencegah error HTTP
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('App startup auth shell smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UangkuApp());

    // Memverifikasi bahwa aplikasi menampilkan loading indicator pada startup awal untuk inisialisasi
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
