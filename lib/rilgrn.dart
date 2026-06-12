/// NeoICR Flutter Plugin
/// 
/// A cross-platform (Android, iOS, Web, Windows, macOS, Linux) Flutter plugin
/// that provides the full NeoICR automated GRN processing UI and API integration.
///
/// Usage:
/// ```dart
/// import 'package:rilgrn/rilgrn.dart';
///
/// // Run as standalone app
/// runApp(const NeoICRApp());
///
/// // Or embed in your app
/// MaterialApp(
///   home: NeoICRApp(
///     onScanRequested: (products) { /* launch QCR scanner */ },
///   ),
/// )
/// ```

library rilgrn;

// App entry point
export 'src/app_navigator.dart';

// Screens (for custom navigation)
export 'src/ui/dashboard_screen.dart';
export 'src/ui/trip_detail_screen.dart';
export 'src/ui/grn_screen.dart';

// ViewModel
export 'src/viewmodels/dashboard_view_model.dart';

// Models
export 'src/models/trip.dart';
export 'src/models/line_item.dart';
export 'src/models/grn_item.dart';

// Theme
export 'src/theme/app_theme.dart';
