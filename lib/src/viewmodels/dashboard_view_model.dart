import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/trip.dart';
import '../models/line_item.dart';
import '../models/grn_item.dart';
import '../services/invoice_api.dart';
import 'package:flutter/material.dart' show Color;

/// Full 1:1 port of DashboardViewModel.kt using ChangeNotifier instead of StateFlow.
class DashboardViewModel extends ChangeNotifier {
  final InvoiceApi _api = InvoiceApi();

  // ─── Trips ───────────────────────────────────────────────────
  List<Trip> _trips = const [
    Trip(
      invoiceNumber: 'AMUL2512174',
      vendorName: 'Geeta Enterprises',
      status: TripStatus.completed,
      backgroundColor: Color(0xFFE8F6EF),
    ),
    Trip(
      invoiceNumber: '125140108778',
      vendorName: 'Yakult Danone India Private Limited',
      status: TripStatus.completed,
      backgroundColor: Color(0xFFE8F6EF),
    ),
    Trip(
      invoiceNumber: 'S1/53',
      vendorName: 'Premier Distributor',
      status: TripStatus.pending,
      backgroundColor: Color(0xFFFFF7E6),
    ),
  ];
  List<Trip> get trips => _trips;

  // ─── Search ──────────────────────────────────────────────────
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void onSearchQueryChange(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Trip> get filteredTrips => _trips.where((t) {
        final q = _searchQuery.toLowerCase();
        return t.invoiceNumber.toLowerCase().contains(q) ||
            t.vendorName.toLowerCase().contains(q);
      }).toList();

  // ─── Active Trip ─────────────────────────────────────────────
  String? _activeTripId;
  String? get activeTripId => _activeTripId;

  // ─── Scanned Images ──────────────────────────────────────────
  List<String> _scannedImages = [];
  List<String> get scannedImages => _scannedImages;

  void updateScannedImages(List<String> images) {
    _scannedImages = images;
    notifyListeners();
  }

  // ─── Verification ────────────────────────────────────────────
  /// null | 'loading' | 'passed' | 'failed' | 'missing'
  String? _verificationStatus;
  String? get verificationStatus => _verificationStatus;

  String _verificationReason = '';
  String get verificationReason => _verificationReason;

  String _verificationExtraDetails = '';
  String get verificationExtraDetails => _verificationExtraDetails;

  // ─── GRN ─────────────────────────────────────────────────────
  /// null | 'loading' | 'line_items_completed' | 'completed' | 'failed'
  String? _grnStatus;
  String? get grnStatus => _grnStatus;

  String _grnDetails = '';
  String get grnDetails => _grnDetails;

  Map<String, int> _grnCounts = {};
  Map<String, int> get grnCounts => _grnCounts;

  List<Map<String, dynamic>> _lineItems = [];
  List<Map<String, dynamic>> get lineItems => _lineItems;

  List<Map<String, dynamic>> _grnItems = [];
  List<Map<String, dynamic>> get grnItems => _grnItems;

  bool _grnIconGreen = false;
  bool get grnIconGreen => _grnIconGreen;

  // ─── Post Process ─────────────────────────────────────────────
  bool _postIconGreen = false;
  bool get postIconGreen => _postIconGreen;

  /// null | 'loading' | 'completed' | 'failed'
  String? _postStatus;
  String? get postStatus => _postStatus;

  Map<String, String> _postAuditDetails = {};
  Map<String, String> get postAuditDetails => _postAuditDetails;

  Uint8List? _postAnnotatedImage;
  Uint8List? get postAnnotatedImage => _postAnnotatedImage;

  String? _postAnnotatedBase64;
  String? get postAnnotatedBase64 => _postAnnotatedBase64;

  // ─── Loading ─────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // ─── Matched Items & Header ───────────────────────────────────
  Map<String, dynamic>? _matchedItemsData;
  Map<String, dynamic>? get matchedItemsData => _matchedItemsData;

  Map<String, dynamic>? _headerData;
  Map<String, dynamic>? get headerData => _headerData;

  // ═════════════════════════════════════════════════════════════
  // Trip management
  // ═════════════════════════════════════════════════════════════

  void startNewTrip() {
    removeScannedImages();
    _postAnnotatedImage = null;
    _postAnnotatedBase64 = null;
    _activeTripId = null;
    _isLoading = true;
    notifyListeners();
  }

  Future<String> generateNewPid() async {
    final newPid = const Uuid().v4();
    _activeTripId = newPid;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('persisted_pid', newPid);
    notifyListeners();
    return newPid;
  }

  Future<String?> getPersistedPid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('persisted_pid');
  }

  void onScannerResultReceived() {
    _isLoading = false;
    notifyListeners();
  }

  void removeScannedImages() {
    _scannedImages = [];
    _verificationStatus = null;
    _verificationReason = '';
    _verificationExtraDetails = '';
    _grnStatus = null;
    _grnDetails = '';
    _grnCounts = {};
    _grnItems = [];
    _lineItems = [];
    _postStatus = null;
    _postAuditDetails = {};
    _grnIconGreen = false;
    _postIconGreen = false;
    notifyListeners();
  }

  Future<void> loadCachedMatchedItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('matched_items');
    if (cached != null) {
      try {
        _matchedItemsData = jsonDecode(cached) as Map<String, dynamic>;
        notifyListeners();
      } catch (_) {}
    }
  }

  // ═════════════════════════════════════════════════════════════
  // API 1 — /invoice-process (SSE stream)
  // ═════════════════════════════════════════════════════════════

  Future<void> uploadImagesAndProcess({
    required String pid,
    required List<String> imageUris,
  }) async {
    _verificationStatus = 'loading';
    _verificationReason = 'Uploading documents...';
    notifyListeners();

    try {
      await for (final json in _api.uploadInvoice(pid: pid, filePaths: imageUris)) {
        if (json.containsKey('status')) {
          _verificationStatus = json['status'] as String?;
          _verificationReason = json['reason'] as String? ?? '';
          _headerData = json;
          notifyListeners();

          if (_verificationStatus == 'passed') {
            performLineItemMatching(pid);
          }
        }

        // Build extra details
        if (json.containsKey('extra_details') || json.length > 2) {
          final buf = StringBuffer();
          json.forEach((key, value) {
            if (key == 'status' || key == 'reason') return;
            if (key == 'extra_details') {
              final extra = value.toString();
              if (extra.isNotEmpty) {
                _verificationExtraDetails = _verificationExtraDetails.isEmpty
                    ? extra
                    : '$_verificationExtraDetails\n$extra';
              }
            } else {
              buf.write(
                  '${_capitalize(key.replaceAll('_', ' '))}: $value\n');
            }
          });
          if (buf.isNotEmpty) {
            _verificationExtraDetails = _verificationExtraDetails.isEmpty
                ? buf.toString()
                : '$_verificationExtraDetails\n${buf.toString()}';
          }
          notifyListeners();
        }
      }
    } catch (e) {
      _verificationStatus = 'failed';
      _verificationReason = 'Error: $e';
      notifyListeners();
    }
  }

  // ═════════════════════════════════════════════════════════════
  // API 2 — /line-item
  // ═════════════════════════════════════════════════════════════

  Future<void> performLineItemMatching(String pid) async {
    _grnStatus = 'loading';
    notifyListeners();

    try {
      final json = await _api.fetchLineItems(pid);

      final counts = <String, int>{};
      counts['total'] = (json['total_invoice_items'] as num?)?.toInt() ?? 0;
      counts['matched'] = (json['matched'] as num?)?.toInt() ?? 0;
      counts['not_found'] = (json['not_found'] as num?)?.toInt() ?? 0;
      counts['mrp_mismatches'] = (json['mrp_mismatches'] as num?)?.toInt() ?? 0;
      _grnCounts = counts;

      final itemsList = <Map<String, dynamic>>[];
      final itemsArray = json['items'] as List<dynamic>?;
      if (itemsArray != null) {
        for (final item in itemsArray) {
          final m = item as Map<String, dynamic>;
          itemsList.add({
            'description': m['description'] ?? 'Unknown',
            'status': m['status'] ?? 'unknown',
            'ean': m['ean'] ?? 'N/A',
            'mrp': m['mrp']?.toString() ?? '0.00',
            'mrp_consistent': m['mrp_consistent'] ?? true,
          });
        }
      }
      _lineItems = itemsList;
      _grnIconGreen = true;
      _grnStatus = 'line_items_completed';
      notifyListeners();

      await performMatchedItemsCall(pid);
    } catch (e) {
      _grnStatus = 'failed';
      notifyListeners();
    }
  }

  // ═════════════════════════════════════════════════════════════
  // API 3 — /matched-items
  // ═════════════════════════════════════════════════════════════

  Future<void> performMatchedItemsCall(String pid) async {
    _grnStatus = 'loading';
    notifyListeners();

    try {
      final json = await _api.fetchMatchedItems(pid);
      _matchedItemsData = json;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('matched_items', jsonEncode(json));
    } catch (_) {}

    // Always continue
    await performGrnValidation(pid);
  }

  // ═════════════════════════════════════════════════════════════
  // API 4 — /grn-validation
  // ═════════════════════════════════════════════════════════════

  Future<void> performGrnValidation(String pid) async {
    try {
      final json = await _api.fetchGrnValidation(pid);

      final results = json['results'] as List<dynamic>?;
      int mismatchCount = 0;
      int multipleCount = 0;
      if (results != null) {
        for (final r in results) {
          final status = (r as Map<String, dynamic>)['status'] as String? ?? '';
          if (status.contains('mismatch')) mismatchCount++;
          if (status.contains('multiple')) multipleCount++;
        }
      }

      final currentCounts = Map<String, int>.from(_grnCounts);
      currentCounts['total'] = (json['total_invoice_items'] as num?)?.toInt() ?? (currentCounts['total'] ?? 0);
      currentCounts['matched'] = (json['grn_done_count'] as num?)?.toInt() ?? (currentCounts['matched'] ?? 0);
      currentCounts['mrp_mismatches'] = mismatchCount;
      currentCounts['multiple_mrp'] = multipleCount;
      _grnCounts = currentCounts;

      // Build EAN → description lookup from line-items
      final eanToDescription = <String, String>{};
      for (final li in _lineItems) {
        final ean = li['ean'] as String?;
        final desc = li['description'] as String?;
        if (ean != null && ean.isNotEmpty && ean != 'N/A' && desc != null && desc != 'Unknown') {
          eanToDescription[ean] = desc;
        }
      }

      final itemsList = <Map<String, dynamic>>[];
      if (results != null) {
        for (final r in results) {
          final res = r as Map<String, dynamic>;
          final invoiceEan = res['invoice_ean'] as String? ?? 'N/A';
          final mrpsArray = res['neoqcr_mrps'] as List<dynamic>?;
          final mrpsList = mrpsArray?.map((e) => e.toString()).toList() ?? [];
          final invoiceMrp = res['invoice_mrp'] as String? ?? '';
          if (invoiceMrp.isNotEmpty && !mrpsList.contains(invoiceMrp)) {
            mrpsList.add(invoiceMrp);
          }

          final item = <String, dynamic>{
            'ean': invoiceEan,
            'mrp': invoiceMrp,
            'qty': res['invoice_qty']?.toString() ?? '0',
            'status': res['status'] ?? 'unknown',
            'all_mrps': mrpsList.join(','),
            'description': eanToDescription[invoiceEan] ?? 'Unknown Product',
          };
          if (res.containsKey('batch')) item['batch'] = res['batch'];
          if (res.containsKey('m_date')) item['m_date'] = res['m_date'];
          if (res.containsKey('e_date')) item['e_date'] = res['e_date'];
          itemsList.add(item);
        }
      }
      _grnItems = itemsList;
      _grnStatus = 'completed';
      notifyListeners();
    } catch (e) {
      _grnStatus = 'failed';
      notifyListeners();
    }
  }

  // ═════════════════════════════════════════════════════════════
  // API 5 — /update-matched-item
  // ═════════════════════════════════════════════════════════════

  Future<void> updateMatchedItem({
    required String pid,
    required String ean,
    required int acceptedQty,
    required int rejectedQty,
    required List<Map<String, dynamic>> batches,
  }) async {
    _grnStatus = 'loading';
    notifyListeners();

    try {
      await _api.updateMatchedItem(
        pid: pid,
        ean: ean,
        acceptedQty: acceptedQty,
        rejectedQty: rejectedQty,
        batches: batches,
      );
      await performMatchedItemsCall(pid);
    } catch (e) {
      _grnStatus = 'failed';
      notifyListeners();
    }
  }

  // ═════════════════════════════════════════════════════════════
  // API 6 — /update-header-item
  // ═════════════════════════════════════════════════════════════

  Future<void> updateHeaderItem({
    required String pid,
    required Map<String, dynamic> updatedHeader,
  }) async {
    _verificationStatus = 'loading';
    notifyListeners();

    try {
      final result = await _api.updateHeaderItem(pid: pid, headerJson: updatedHeader);

      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        if (data != null) {
          _headerData = data;
          final panchnamaStatus = data['panchnama_status'] as String? ?? 'passed';
          final panchnamaReason = data['panchnama_reason'] as String? ?? '';
          _verificationStatus = panchnamaStatus;
          _verificationReason = panchnamaReason;

          final buf = StringBuffer();
          data.forEach((key, value) {
            if (['panchnama_status', 'panchnama_reason', 'status', 'reason'].contains(key)) return;
            buf.write('${_capitalize(key.replaceAll('_', ' '))}: $value\n');
          });
          _verificationExtraDetails = buf.toString();

          if (panchnamaStatus == 'passed') {
            await performLineItemMatching(pid);
          }
        }
      } else {
        _verificationStatus = 'failed';
      }
      notifyListeners();
    } catch (e) {
      _verificationStatus = 'failed';
      notifyListeners();
    }
  }

  // ═════════════════════════════════════════════════════════════
  // API 7 — /generate-annotated-invoice
  // ═════════════════════════════════════════════════════════════

  Future<void> performPostProcess(String pid) async {
    _postStatus = 'loading';
    notifyListeners();

    try {
      final result = await _api.generateAnnotatedInvoice(pid);

      final imageBytes = result['imageBytes'] as Uint8List?;
      final base64Str = result['base64'] as String?;
      final mime = result['mime'] as String? ?? 'image/png';
      final auditNumbers = result['auditNumbers'] as Map<String, dynamic>?;

      if (auditNumbers != null) {
        _postAuditDetails = {
          'scroll_no': auditNumbers['scroll_no']?.toString() ?? 'N/A',
          'trip_no': auditNumbers['trip_no']?.toString() ?? 'N/A',
          'grn_no': auditNumbers['grn_no']?.toString() ?? 'N/A',
        };
      }

      if (imageBytes != null && imageBytes.isNotEmpty) {
        _postAnnotatedImage = imageBytes;
      } else if (base64Str != null && base64Str.isNotEmpty) {
        // Strip data URI prefix if present
        final cleanBase64 = base64Str.contains('base64,')
            ? base64Str.split('base64,').last
            : base64Str.contains(',')
                ? base64Str.split(',').last
                : base64Str;

        if (mime.contains('pdf')) {
          // Store as raw PDF bytes for rendering
          _postAnnotatedImage = base64Decode(cleanBase64);
        } else {
          _postAnnotatedImage = base64Decode(cleanBase64);
        }
        _postAnnotatedBase64 = 'data:$mime;base64,$cleanBase64';
      }

      _postIconGreen = true;
      _postStatus = 'completed';
      notifyListeners();
    } catch (e) {
      _postStatus = 'failed';
      notifyListeners();
    }
  }

  // ═════════════════════════════════════════════════════════════
  // Helpers
  // ═════════════════════════════════════════════════════════════

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void openPendingGRNs() {}
  void openCompletedTrips() {}
}
