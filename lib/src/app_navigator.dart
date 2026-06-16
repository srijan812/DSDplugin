import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qcrplugin/qcrplugin.dart';
import 'viewmodels/dashboard_view_model.dart';
import 'ui/dashboard_screen.dart';
import 'ui/trip_detail_screen.dart';
import 'ui/grn_screen.dart';
import 'theme/app_theme.dart';

/// Root navigator widget — mirrors MainActivity.kt currentScreen state-machine.
/// Screens: 'dashboard' → 'tripDetail' → 'grn'
class NeoICRApp extends StatefulWidget {
  /// Called when the user taps the Scan FAB on the GRN screen.
  /// Receives the product list (ean + mrp per item).
  final void Function(List<Map<String, String>> products)? onScanRequested;

  const NeoICRApp({super.key, this.onScanRequested});

  @override
  State<NeoICRApp> createState() => _NeoICRAppState();
}

class _NeoICRAppState extends State<NeoICRApp> {
  String _currentScreen = 'dashboard';

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardViewModel(),
      child: MaterialApp(
        title: 'NeoICR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: _buildCurrentScreen(),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    // We need context for provider so we wrap in Builder
    return Builder(builder: (context) {
      final vm = context.watch<DashboardViewModel>();

      if (_currentScreen == 'dashboard') {
        return DashboardScreen(
          onStartNewTrip: () => setState(() => _currentScreen = 'tripDetail'),
        );
      }

      if (_currentScreen == 'tripDetail') {
        return TripDetailScreen(
          tripId: vm.activeTripId ?? 'TRIP-UNKNOWN',
          onBack: () => setState(() => _currentScreen = 'dashboard'),
          onCapture: () => _launchQcrCapture(context, vm),
          onGrnClick: () => setState(() => _currentScreen = 'grn'),
        );
      }

      if (_currentScreen == 'grn') {
        return GrnScreen(
          onBack: () => setState(() => _currentScreen = 'tripDetail'),
          onScan: (productList) {
            widget.onScanRequested?.call(productList);
          },
        );
      }

      return const SizedBox.shrink();
    });
  }

  /// Cross-platform image pick — replaces ML Kit Document Scanner.
  Future<void> _launchQcrCapture(
      BuildContext context, DashboardViewModel vm) async {
    final pid = await vm.generateNewPid();
    // Launch QCR SDK with default user and pid
    await Qcrplugin.startQcrCapture(context,
        userId: "default", pid: pid, captureType: "qcr");

    // Check verification status from backend by resuming/refreshing logic if needed.
    // DSDplugin dashboard view model depends on stream/updates.
    // QCRplugin handles uploading so we mark loading.
  }
}
