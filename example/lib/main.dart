import 'package:flutter/material.dart';
import 'package:rilgrn/rilgrn.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return NeoICRApp(
      onScanRequested: (products) {
        // Called when the user taps the QR scan FAB on the GRN screen.
        // products is a List<Map<String, String>> with 'ean' and 'mrp' keys.
        // Here you can launch your QCR scanner or any other action.
        debugPrint('Scan requested for ${products.length} products');
      },
    );
  }
}
