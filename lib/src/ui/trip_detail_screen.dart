import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../theme/app_theme.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  final VoidCallback onBack;
  final VoidCallback onCapture;
  final VoidCallback onGrnClick;

  const TripDetailScreen({
    super.key,
    required this.tripId,
    required this.onBack,
    required this.onCapture,
    required this.onGrnClick,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> with WidgetsBindingObserver {
  bool _showFullScreenViewer = false;
  bool _showReasonDialog = false;
  bool _showGrnDialog = false;
  bool _showPostDialog = false;
  bool _showPostImage = false;
  bool _showEditHeaderDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final vm = context.read<DashboardViewModel>();
      if (vm.verificationStatus == 'passed') {
        vm.getPersistedPid().then((pid) {
          if (pid != null) vm.performMatchedItemsCall(pid);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: AppBar(
            title: Text(
              widget.tripId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: widget.onBack,
            ),
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Step 1: Capture ───────────────────────────────
                Expanded(
                  child: _TimelineRow(
                    icon: Icons.camera_alt_outlined,
                    label: 'Capture',
                    status: vm.verificationStatus,
                    onIconTap: widget.onCapture,
                    showLine: true,
                    lineActive: vm.verificationStatus == 'passed',
                    content: _CaptureContent(
                      scannedImages: vm.scannedImages,
                      status: vm.verificationStatus,
                      onImageClick: () => setState(() => _showFullScreenViewer = true),
                      onInfoClick: () => setState(() => _showReasonDialog = true),
                      onRemove: () => vm.removeScannedImages(),
                    ),
                  ),
                ),

                // ── Step 2: GRN ────────────────────────────────────
                Expanded(
                  child: Opacity(
                    opacity: vm.verificationStatus == 'passed' ? 1.0 : 0.5,
                    child: _TimelineRow(
                      icon: Icons.description_outlined,
                      label: 'GRN',
                      status: vm.grnIconGreen ? 'passed' : vm.grnStatus,
                      onIconTap: () {
                        if (vm.verificationStatus == 'passed' && vm.grnStatus == 'completed') {
                          widget.onGrnClick();
                        }
                      },
                      showLine: true,
                      lineActive: vm.grnStatus == 'completed',
                      content: _GRNContent(
                        status: vm.grnStatus,
                        counts: vm.grnCounts,
                        onInfoClick: () => setState(() => _showGrnDialog = true),
                      ),
                    ),
                  ),
                ),

                // ── Step 3: Post ───────────────────────────────────
                Expanded(
                  child: Opacity(
                    opacity: vm.grnStatus == 'completed' ? 1.0 : 0.5,
                    child: _TimelineRow(
                      icon: Icons.send_outlined,
                      label: 'Post',
                      status: vm.postIconGreen ? 'passed' : vm.postStatus,
                      onIconTap: () async {
                        if (vm.grnStatus != 'completed') return;
                        if (vm.postStatus == 'completed') {
                          setState(() => _showPostDialog = true);
                        } else if (vm.postStatus != 'loading') {
                          final pid = await vm.getPersistedPid();
                          if (pid != null) vm.performPostProcess(pid);
                        }
                      },
                      showLine: false,
                      lineActive: false,
                      content: _PostContent(
                        enabled: vm.grnStatus == 'completed',
                        status: vm.postStatus,
                        hasImage: vm.postAnnotatedImage != null || vm.postAnnotatedBase64 != null,
                        onInfoClick: () => setState(() => _showPostDialog = true),
                        onImageClick: () => setState(() => _showPostImage = true),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Dialogs ────────────────────────────────────────────────
        if (_showFullScreenViewer && vm.scannedImages.isNotEmpty)
          _FullScreenImageViewer(
            images: vm.scannedImages,
            onDismiss: () => setState(() => _showFullScreenViewer = false),
          ),

        if (_showPostImage && (vm.postAnnotatedImage != null || vm.postAnnotatedBase64 != null))
          _FullScreenImageViewer(
            images: [if (vm.postAnnotatedImage != null) vm.postAnnotatedImage! else vm.postAnnotatedBase64!],
            onDismiss: () => setState(() => _showPostImage = false),
          ),

        if (_showReasonDialog)
          _ReasonDialog(
            vm: vm,
            onDismiss: () => setState(() => _showReasonDialog = false),
            onEditHeader: () => setState(() {
              _showReasonDialog = false;
              _showEditHeaderDialog = true;
            }),
          ),

        if (_showGrnDialog)
          _GrnDialog(vm: vm, onDismiss: () => setState(() => _showGrnDialog = false)),

        if (_showPostDialog)
          _PostDialog(
            vm: vm,
            onDismiss: () => setState(() => _showPostDialog = false),
            onViewImage: () => setState(() {
              _showPostDialog = false;
              _showPostImage = true;
            }),
          ),

        if (_showEditHeaderDialog && vm.headerData != null)
          _EditHeaderDialog(
            headerData: vm.headerData!,
            onDismiss: () => setState(() => _showEditHeaderDialog = false),
            onConfirm: (updated) async {
              setState(() => _showEditHeaderDialog = false);
              final pid = await vm.getPersistedPid();
              if (pid != null) {
                vm.updateHeaderItem(pid: pid, updatedHeader: updated);
              }
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline Row
// ─────────────────────────────────────────────────────────────────────────────
class _TimelineRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? status;
  final VoidCallback onIconTap;
  final bool showLine;
  final bool lineActive;
  final Widget content;

  const _TimelineRow({
    required this.icon,
    required this.label,
    required this.status,
    required this.onIconTap,
    required this.showLine,
    required this.lineActive,
    required this.content,
  });

  Color get _iconColor {
    switch (status) {
      case 'passed':
        return AppColors.statusGreen;
      case 'failed':
      case 'missing':
        return AppColors.statusFailed;
      case 'loading':
        return AppColors.statusLoading;
      default:
        return Colors.grey.shade300;
    }
  }

  Color get _labelColor {
    switch (status) {
      case 'passed':
        return AppColors.statusPassed;
      case 'failed':
      case 'missing':
        return AppColors.statusFailed;
      case 'loading':
        return AppColors.statusLoading;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Timeline icon + line
        SizedBox(
          width: 56,
          child: Column(
            children: [
              GestureDetector(
                onTap: onIconTap,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
              ),
              if (showLine)
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      color: lineActive ? AppColors.statusGreen : Colors.grey.shade200,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _labelColor,
                  ),
                ),
              ),
              content,
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Capture Content
// ─────────────────────────────────────────────────────────────────────────────
class _CaptureContent extends StatelessWidget {
  final List<String> scannedImages;
  final String? status;
  final VoidCallback onImageClick;
  final VoidCallback onInfoClick;
  final VoidCallback onRemove;

  const _CaptureContent({
    required this.scannedImages,
    required this.status,
    required this.onImageClick,
    required this.onInfoClick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (scannedImages.isEmpty) {
      return const Text('No images captured yet.', style: TextStyle(color: Colors.grey));
    }
    return Row(
      children: [
        GestureDetector(
          onTap: onImageClick,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  scannedImages.first,
                  width: 80,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 100,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              // Remove badge
              Positioned(
                top: -8,
                right: -8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.statusFailed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 16),
                  ),
                ),
              ),
              // Count badge
              if (scannedImages.length > 1)
                Positioned(
                  bottom: -8,
                  right: -8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${scannedImages.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        if (status == 'loading')
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          )
        else
          IconButton(
            onPressed: onInfoClick,
            icon: Icon(
              Icons.info_outline,
              size: 28,
              color: status == 'passed'
                  ? AppColors.statusPassed
                  : status == 'failed' || status == 'missing'
                      ? AppColors.statusFailed
                      : Colors.grey,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRN Content
// ─────────────────────────────────────────────────────────────────────────────
class _GRNContent extends StatelessWidget {
  final String? status;
  final Map<String, int> counts;
  final VoidCallback onInfoClick;

  const _GRNContent({required this.status, required this.counts, required this.onInfoClick});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: Column(
              children: [
                _GrnRow('Total Article', '${counts['total'] ?? 0}', Colors.black),
                const SizedBox(height: 8),
                _GrnRow('MRP Mismatch', '${counts['mrp_mismatches'] ?? 0}', AppColors.statusFailed),
                const SizedBox(height: 8),
                _GrnRow('Multiple MRP', '${counts['multiple_mrp'] ?? 0}', AppColors.statusOrange),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        if (status == 'completed' || status == 'failed')
          IconButton(
            onPressed: onInfoClick,
            icon: Icon(
              Icons.info_outline,
              size: 28,
              color: status == 'completed' ? AppColors.statusPassed : AppColors.statusFailed,
            ),
          )
        else if (status == 'loading' || status == 'line_items_completed')
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
          ),
      ],
    );
  }
}

class _GrnRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _GrnRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Post Content
// ─────────────────────────────────────────────────────────────────────────────
class _PostContent extends StatelessWidget {
  final bool enabled;
  final String? status;
  final bool hasImage;
  final VoidCallback onInfoClick;
  final VoidCallback onImageClick;

  const _PostContent({
    required this.enabled,
    required this.status,
    required this.hasImage,
    required this.onInfoClick,
    required this.onImageClick,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
            ),
            child: enabled
                ? Column(
                    children: [
                      _PostRow('Scroll Number:', status == 'completed' ? '10188234' : status == 'loading' ? 'Processing...' : 'TBD', status == 'completed'),
                      const SizedBox(height: 12),
                      _PostRow('Trip Number:', status == 'completed' ? '7019882231' : 'TBD', status == 'completed'),
                      const SizedBox(height: 12),
                      _PostRow('GRN Number:', status == 'completed' ? '5099233810' : 'TBD', status == 'completed'),
                    ],
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Complete GRN to view post details',
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ),
          ),
        ),
        if (enabled && (status == 'completed' || hasImage)) ...[
          const SizedBox(width: 16),
          Column(
            children: [
              IconButton(
                onPressed: onInfoClick,
                icon: Icon(Icons.info_outline, size: 28,
                    color: status == 'completed' ? AppColors.statusPassed : Colors.grey),
              ),
              if (hasImage)
                IconButton(
                  onPressed: onImageClick,
                  icon: const Icon(Icons.description_outlined, size: 28, color: AppColors.accent),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isCompleted;
  const _PostRow(this.label, this.value, this.isCompleted);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600)),
        Text(value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCompleted ? Colors.black : Colors.grey.shade600,
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full Screen Image Viewer
// ─────────────────────────────────────────────────────────────────────────────
class _FullScreenImageViewer extends StatefulWidget {
  final List<dynamic> images;
  final VoidCallback onDismiss;
  const _FullScreenImageViewer({required this.images, required this.onDismiss});

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final img = widget.images[index];
              Widget imageWidget;
              if (img is Uint8List) {
                imageWidget = Image.memory(img, fit: BoxFit.contain);
              } else if (img is String && img.startsWith('data:')) {
                final base64Data = img.split('base64,').last;
                imageWidget = Image.memory(base64Decode(base64Data), fit: BoxFit.contain);
              } else {
                imageWidget = Image.network(
                  img.toString(),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white, size: 64),
                  ),
                );
              }
              return Center(child: imageWidget);
            },
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),

          // Page indicator
          if (widget.images.length > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dialogs
// ─────────────────────────────────────────────────────────────────────────────

/// Verification reason + extracted headers dialog
class _ReasonDialog extends StatelessWidget {
  final DashboardViewModel vm;
  final VoidCallback onDismiss;
  final VoidCallback onEditHeader;
  const _ReasonDialog({required this.vm, required this.onDismiss, required this.onEditHeader});

  @override
  Widget build(BuildContext context) {
    return _DialogOverlay(
      onDismiss: onDismiss,
      title: 'Verification Result',
      confirmLabel: 'OK',
      onConfirm: onDismiss,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status: ${vm.verificationStatus?.toUpperCase() ?? 'Unknown'}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (vm.verificationReason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Reason: ${vm.verificationReason}', style: const TextStyle(fontSize: 14)),
          ],
          if (vm.verificationExtraDetails.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Extracted Headers:', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  onPressed: onEditHeader,
                  icon: const Icon(Icons.edit, color: AppColors.accent, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                vm.verificationExtraDetails,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// GRN line items dialog
class _GrnDialog extends StatelessWidget {
  final DashboardViewModel vm;
  final VoidCallback onDismiss;
  const _GrnDialog({required this.vm, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return _DialogOverlay(
      onDismiss: onDismiss,
      title: 'Line Item Matching Results',
      confirmLabel: 'OK',
      onConfirm: onDismiss,
      content: vm.grnStatus == 'loading'
          ? const Row(children: [
              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Processing line items...'),
            ])
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Total Items: ${vm.grnCounts['total'] ?? 0}'),
                Text('Matched: ${vm.grnCounts['matched'] ?? 0}'),
                Text('Not Found: ${vm.grnCounts['not_found'] ?? 0}'),
                Text('MRP Mismatches: ${vm.grnCounts['mrp_mismatches'] ?? 0}'),
                const SizedBox(height: 16),
                const Text('Item Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...vm.lineItems.map((item) {
                  final isMrpMismatch = item['mrp_consistent'] == false;
                  final status = item['status'] as String? ?? 'unknown';
                  final isPassed = status.contains('pass') || status.contains('match');
                  final statusColor = isMrpMismatch
                      ? Colors.red
                      : isPassed
                          ? AppColors.statusPassed
                          : AppColors.statusOrange;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: isMrpMismatch ? Border.all(color: Colors.red, width: 2) : null,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['description'] as String? ?? '',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isMrpMismatch ? Colors.red : Colors.black,
                                ),
                              ),
                            ),
                            Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EAN: ${item['ean']} | MRP: ${item['mrp']}',
                          style: TextStyle(fontSize: 12, color: isMrpMismatch ? Colors.red : Colors.grey),
                        ),
                        if (isMrpMismatch)
                          const Text('⚠️ MRP MISMATCH DETECTED',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
    );
  }
}

/// Post process audit dialog
class _PostDialog extends StatelessWidget {
  final DashboardViewModel vm;
  final VoidCallback onDismiss;
  final VoidCallback onViewImage;
  const _PostDialog({required this.vm, required this.onDismiss, required this.onViewImage});

  @override
  Widget build(BuildContext context) {
    return _DialogOverlay(
      onDismiss: onDismiss,
      title: 'Invoice Finalized',
      confirmLabel: 'OK',
      onConfirm: onDismiss,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('The invoice has been successfully annotated and processed.',
              style: TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          const Text('Audit Numbers:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Scroll No: ${vm.postAuditDetails['scroll_no'] ?? 'N/A'}'),
          Text('Trip No: ${vm.postAuditDetails['trip_no'] ?? 'N/A'}'),
          Text('GRN No: ${vm.postAuditDetails['grn_no'] ?? 'N/A'}'),
          if (vm.postAnnotatedImage != null || vm.postAnnotatedBase64 != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onViewImage,
                icon: const Icon(Icons.info_outline),
                label: const Text('View Annotated Invoice'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Edit header dialog (dynamic fields from JSON)
class _EditHeaderDialog extends StatefulWidget {
  final Map<String, dynamic> headerData;
  final VoidCallback onDismiss;
  final Future<void> Function(Map<String, dynamic>) onConfirm;

  const _EditHeaderDialog({
    required this.headerData,
    required this.onDismiss,
    required this.onConfirm,
  });

  @override
  State<_EditHeaderDialog> createState() => _EditHeaderDialogState();
}

class _EditHeaderDialogState extends State<_EditHeaderDialog> {
  final Map<String, TextEditingController> _controllers = {};
  static const _skipKeys = {'status', 'reason', 'extra_details', 'panchnama_status', 'panchnama_reason'};

  @override
  void initState() {
    super.initState();
    widget.headerData.forEach((key, value) {
      if (_skipKeys.contains(key)) return;
      String strValue;
      if (value is List) {
        strValue = value.join(', ');
      } else {
        strValue = value.toString();
      }
      _controllers[key] = TextEditingController(text: strValue);
    });

    // Ensure standard fields are present
    for (final field in ['invoice_number', 'invoice_date', 'consignee_name', 'consignor_name', 'hsn_code']) {
      if (!_controllers.containsKey(field)) {
        _controllers[field] = TextEditingController(text: '');
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _sortedKeys {
    return _controllers.keys.toList()
      ..sort((a, b) {
        final order = {'invoice_number': '0', 'invoice_date': '1', 'invoice_amount': '2', 'invoice_value': '2'};
        return (order[a] ?? '3_$a').compareTo(order[b] ?? '3_$b');
      });
  }

  @override
  Widget build(BuildContext context) {
    return _DialogOverlay(
      onDismiss: widget.onDismiss,
      title: 'Edit Extracted Headers',
      confirmLabel: 'Submit',
      onConfirm: () async {
        final updated = Map<String, dynamic>.from(widget.headerData);
        for (final entry in _controllers.entries) {
          final trimmed = entry.value.text.trim();
          if (trimmed.isEmpty) continue;
          if (entry.key.contains('hsn')) {
            updated[entry.key] = trimmed.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          } else {
            updated[entry.key] = trimmed;
          }
        }
        await widget.onConfirm(updated);
      },
      dismissLabel: 'Cancel',
      content: Column(
        children: _sortedKeys.map((key) {
          final label = key.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: _controllers[key],
              decoration: InputDecoration(labelText: label),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic Dialog Overlay (replaces AlertDialog for scrollable custom dialogs)
// ─────────────────────────────────────────────────────────────────────────────
class _DialogOverlay extends StatelessWidget {
  final String title;
  final Widget content;
  final String confirmLabel;
  final VoidCallback onDismiss;
  final VoidCallback onConfirm;
  final String? dismissLabel;

  const _DialogOverlay({
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.onDismiss,
    required this.onConfirm,
    this.dismissLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: SizedBox(width: double.infinity, child: content),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (dismissLabel != null)
                      TextButton(
                        onPressed: onDismiss,
                        child: Text(dismissLabel!),
                      ),
                    TextButton(
                      onPressed: onConfirm,
                      child: Text(confirmLabel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
