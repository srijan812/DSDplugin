import 'package:flutter/material.dart';
import 'package:rilgrn/rilgrn.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Rilgrn Scanner Example'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  try {
                    final paths = await Rilgrn.scanDocument();
                    debugPrint('Scanned Document Paths: $paths');
                  } catch (e) {
                    debugPrint('Error scanning document: $e');
                  }
                },
                child: const Text('Scan Invoice Document'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NeoICRApp(
                        onScanRequested: (products) {
                          debugPrint('Scan requested for ${products.length} products');
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Open Full NeoICR Flow'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
