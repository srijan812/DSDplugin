import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _picker = ImagePicker();

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
          onCapture: () => _launchImagePicker(context, vm),
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
  Future<void> _launchImagePicker(BuildContext context, DashboardViewModel vm) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Select Image Source',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                title: const Text('Take Photo (Camera)'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryBlue),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final pid = await vm.generateNewPid();
    final List<XFile> images = [];

    if (source == ImageSource.camera) {
      final XFile? singleImage = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
      if (singleImage != null) {
        images.add(singleImage);
      }
    } else {
      final List<XFile> multipleImages = await _picker.pickMultiImage(imageQuality: 90);
      images.addAll(multipleImages);
    }

    if (images.isEmpty) return;

    final paths = images.map((x) => x.path).toList();
    vm.updateScannedImages(paths);
    vm.onScannerResultReceived();
    vm.uploadImagesAndProcess(pid: pid, imageUris: paths);
  }
}
