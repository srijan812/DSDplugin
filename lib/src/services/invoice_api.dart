import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_service.dart';

/// All 7 API endpoints mirroring DashboardViewModel.kt
class InvoiceApi {
  final ApiService _api = ApiService();

  // ──────────────────────────────────────────────────────────────
  // 1. /invoice-process — SSE streaming upload
  // ──────────────────────────────────────────────────────────────
  Stream<Map<String, dynamic>> uploadInvoice({
    required String pid,
    required List<String> filePaths,
  }) async* {
    final form = FormData();
    form.fields.addAll([
      MapEntry('pid', '"$pid"'),
      MapEntry('user_id', '"Rajkishore"'),
      MapEntry('qr_code', '"true"'),
    ]);

    for (int i = 0; i < filePaths.length; i++) {
      final path = filePaths[i];
      final fileName = path.split('/').last;

      // Skip blob/data URIs (web platform) — not file-accessible
      if (path.startsWith('data:') || path.startsWith('blob:')) continue;

      form.files.add(MapEntry(
        'files',
        await MultipartFile.fromFile(path, filename: fileName),
      ));
    }

    yield* _api.postMultipartStream('/invoice-process', form);
  }

  // ──────────────────────────────────────────────────────────────
  // 2. /line-item
  // ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchLineItems(String pid) async {
    final form = FormData.fromMap({'pid': pid});
    return _api.postMultipart('/line-item', form);
  }

  // ──────────────────────────────────────────────────────────────
  // 3. /matched-items
  // ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchMatchedItems(String pid) async {
    final form = FormData.fromMap({'pid': pid});
    return _api.postMultipart('/matched-items', form);
  }

  // ──────────────────────────────────────────────────────────────
  // 4. /grn-validation
  // ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchGrnValidation(String pid) async {
    final form = FormData.fromMap({'pid': pid});
    return _api.postMultipart('/grn-validation', form);
  }

  // ──────────────────────────────────────────────────────────────
  // 5. /update-matched-item
  // ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateMatchedItem({
    required String pid,
    required String ean,
    required int acceptedQty,
    required int rejectedQty,
    required List<Map<String, dynamic>> batches,
  }) async {
    return _api.postJson('/update-matched-item', {
      'pid': pid,
      'ean': ean,
      'accepted_qty': acceptedQty,
      'rejected_qty': rejectedQty,
      'neoqcr_batches': batches,
    });
  }

  // ──────────────────────────────────────────────────────────────
  // 6. /update-header-item
  // ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateHeaderItem({
    required String pid,
    required Map<String, dynamic> headerJson,
  }) async {
    final body = Map<String, dynamic>.from(headerJson);
    body['pid'] = pid;
    return _api.postJson('/update-header-item', body);
  }

  // ──────────────────────────────────────────────────────────────
  // 7. /generate-annotated-invoice  →  PDF bytes or base64 image
  // Returns: { 'imageBytes': Uint8List?, 'base64': String?, 'mime': String, 'auditNumbers': Map? }
  // ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> generateAnnotatedInvoice(String pid) async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://neovlm.neophyte.live/rel-icr-api',
      connectTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(minutes: 30),
    ));

    final form = FormData.fromMap({'pid': pid});

    final response = await dio.post<List<int>>(
      '/generate-annotated-invoice',
      data: form,
      options: Options(responseType: ResponseType.bytes),
    );

    final contentType = response.headers.value('content-type') ?? '';
    final bytes = response.data;

    if (contentType.contains('application/pdf')) {
      return {
        'imageBytes': Uint8List.fromList(bytes ?? []),
        'mime': 'application/pdf',
      };
    }

    // JSON response with base64 or audit numbers
    if (bytes != null) {
      final bodyStr = String.fromCharCodes(bytes);
      try {
        final json = jsonDecode(bodyStr) as Map<String, dynamic>;
        return {
          'base64': json['image_base64'],
          'mime': json['mime_type'] ?? 'image/png',
          'auditNumbers': json['audit_numbers'],
        };
      } catch (_) {
        return {'imageBytes': Uint8List.fromList(bytes), 'mime': contentType};
      }
    }

    return {};
  }
}
