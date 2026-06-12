import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../theme/app_theme.dart';

class GrnScreen extends StatefulWidget {
  final VoidCallback onBack;
  final void Function(List<Map<String, String>>) onScan;

  const GrnScreen({super.key, required this.onBack, required this.onScan});

  @override
  State<GrnScreen> createState() => _GrnScreenState();
}

class _GrnScreenState extends State<GrnScreen> with WidgetsBindingObserver {
  String _selectedFilter = 'ALL';
  bool _showEditDialog = false;
  Map<String, dynamic>? _editingItem;
  Map<String, dynamic>? _editingMatchedInfo;

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
      vm.getPersistedPid().then((pid) {
        if (pid != null) {
          vm.loadCachedMatchedItems();
          vm.performMatchedItemsCall(pid);
        }
      });
    }
  }

  List<Map<String, dynamic>> _filteredItems(List<Map<String, dynamic>> items) {
    switch (_selectedFilter) {
      case 'MULTIPLE MRP':
        return items.where((i) => (i['status'] as String? ?? '').toLowerCase().contains('multiple')).toList();
      case 'MISMATCHED MRP':
        return items.where((i) => (i['status'] as String? ?? '').toLowerCase().contains('mismatch')).toList();
      default:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DashboardViewModel>();
    final isRefreshing = vm.grnStatus == 'loading';
    final filtered = _filteredItems(vm.grnItems);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: AppColors.scaffoldBg,
          appBar: AppBar(
            title: const Text('GRN', style: TextStyle(fontWeight: FontWeight.bold)),
            leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.qr_code_scanner, size: 40, color: Colors.white),
              onPressed: () {
                final productList = vm.grnItems.where((item) {
                  final ean = item['ean'] as String? ?? '';
                  return ean.isNotEmpty;
                }).map((item) => {
                  'ean': item['ean'] as String,
                  'mrp': (item['all_mrps'] as String? ?? item['mrp'] as String? ?? '0.00'),
                }).toList();
                widget.onScan(productList);
              },
            ),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              final pid = await vm.getPersistedPid();
              if (pid != null) await vm.performMatchedItemsCall(pid);
            },
            child: Column(
              children: [
                // Loading indicator
                if (isRefreshing)
                  const LinearProgressIndicator(color: AppColors.accent),

                // Filter tabs
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      _FilterTab('ALL', _selectedFilter == 'ALL', () => setState(() => _selectedFilter = 'ALL')),
                      const SizedBox(width: 8),
                      _FilterTab('MULTIPLE MRP', _selectedFilter == 'MULTIPLE MRP',
                          () => setState(() => _selectedFilter = 'MULTIPLE MRP')),
                      const SizedBox(width: 8),
                      _FilterTab('MISMATCHED MRP', _selectedFilter == 'MISMATCHED MRP',
                          () => setState(() => _selectedFilter = 'MISMATCHED MRP')),
                    ],
                  ),
                ),

                // Items list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final ean = item['ean'] as String? ?? '';
                      Map<String, dynamic>? matchedInfo;
                      if (vm.matchedItemsData?['items'] != null) {
                        final itemsMap = vm.matchedItemsData!['items'] as Map<String, dynamic>?;
                        matchedInfo = itemsMap?[ean] as Map<String, dynamic>?;
                      }
                      return _GrnItemCard(
                        item: item,
                        matchedInfo: matchedInfo,
                        onEdit: () {
                          setState(() {
                            _editingItem = item;
                            _editingMatchedInfo = matchedInfo;
                            _showEditDialog = true;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Edit Item Dialog
        if (_showEditDialog && _editingItem != null)
          _EditItemDialog(
            item: _editingItem!,
            matchedInfo: _editingMatchedInfo,
            onDismiss: () => setState(() => _showEditDialog = false),
            onConfirm: (acceptedQty, rejectedQty, batches) async {
              setState(() => _showEditDialog = false);
              final pid = await vm.getPersistedPid();
              final ean = _editingItem!['ean'] as String? ?? '';
              if (pid != null && ean.isNotEmpty) {
                await vm.updateMatchedItem(
                  pid: pid,
                  ean: ean,
                  acceptedQty: acceptedQty,
                  rejectedQty: rejectedQty,
                  batches: batches,
                );
              }
            },
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Tab
// ─────────────────────────────────────────────────────────────────────────────
class _FilterTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onClick;
  const _FilterTab(this.label, this.isSelected, this.onClick);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
          boxShadow: isSelected
              ? [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 4)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRN Item Card
// ─────────────────────────────────────────────────────────────────────────────
class _GrnItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic>? matchedInfo;
  final VoidCallback onEdit;

  const _GrnItemCard({required this.item, required this.matchedInfo, required this.onEdit});

  Color get _indicatorColor {
    final status = item['status'] as String? ?? '';
    if (status == 'matched' || status == 'pass') return AppColors.statusPassed;
    if (status.contains('multiple')) return AppColors.statusOrange;
    if (status.contains('mismatch')) return AppColors.statusFailed;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final status = item['status'] as String? ?? 'unknown';
    final batch = item['batch'] as String?;
    final mDate = item['m_date'] as String?;
    final eDate = item['e_date'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Stack(
        children: [
          // Left color indicator
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 6,
              decoration: BoxDecoration(
                color: _indicatorColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
          ),

          // Edit icon top right
          Positioned(
            right: 4,
            top: 4,
            child: IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, color: AppColors.accent, size: 18),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PO/INV data (if available)
                if (matchedInfo != null) ...[
                  Text(
                    'PO MRP: ${matchedInfo!['po_mrp'] ?? 0} | PO QTY: ${matchedInfo!['po_qty'] ?? 0} | INV MRP: ${matchedInfo!['inv_mrp'] ?? 0} | INV QTY: ${matchedInfo!['inv_qty'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xCC6B8AFF),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // EAN / QTY / BATCH + status dot
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'EAN: ${item['ean']} | QTY: ${item['qty'] ?? '0'}${batch != null ? ' | BATCH: $batch' : ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: _indicatorColor, shape: BoxShape.circle),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                Text(
                  item['description'] as String? ?? 'Unknown Product',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),

                Text(
                  '₹${item['mrp']}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),

                // Batches from matchedInfo
                if (matchedInfo != null && matchedInfo!.containsKey('neoqcr_batches')) ...[
                  const SizedBox(height: 8),
                  const Text('NEOQCR BATCHES:',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  ...((matchedInfo!['neoqcr_batches'] as List<dynamic>? ?? []).map((b) {
                    final bMap = b as Map<String, dynamic>;
                    return Text(
                      '• ${bMap['batch_no'] ?? 'N/A'} (Qty: ${bMap['qty'] ?? 0}, MRP: ₹${bMap['mrp'] ?? 0})',
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                    );
                  })),
                ],

                // M/E dates
                if (mDate != null || eDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (mDate != null)
                        Text('M: $mDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      if (mDate != null && eDate != null) const SizedBox(width: 16),
                      if (eDate != null)
                        Text('E: $eDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Edit Item Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _EditItemDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map<String, dynamic>? matchedInfo;
  final VoidCallback onDismiss;
  final Future<void> Function(int acceptedQty, int rejectedQty, List<Map<String, dynamic>> batches) onConfirm;

  const _EditItemDialog({
    required this.item,
    required this.matchedInfo,
    required this.onDismiss,
    required this.onConfirm,
  });

  @override
  State<_EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<_EditItemDialog> {
  late final TextEditingController _acceptedQtyCtrl;
  late final TextEditingController _rejectedQtyCtrl;
  late final List<Map<String, TextEditingController>> _batchControllers;

  @override
  void initState() {
    super.initState();
    _acceptedQtyCtrl = TextEditingController();
    _rejectedQtyCtrl = TextEditingController();

    _batchControllers = [];
    final batches = widget.matchedInfo?['neoqcr_batches'] as List<dynamic>?;
    if (batches != null) {
      for (final b in batches) {
        final bMap = b as Map<String, dynamic>;
        _batchControllers.add({
          'batch_no': TextEditingController(text: bMap['batch_no']?.toString() ?? ''),
          'qty': TextEditingController(text: bMap['qty']?.toString() ?? '0'),
          'mrp': TextEditingController(text: bMap['mrp']?.toString() ?? '0.0'),
        });
      }
    }
  }

  @override
  void dispose() {
    _acceptedQtyCtrl.dispose();
    _rejectedQtyCtrl.dispose();
    for (final m in _batchControllers) {
      m.values.forEach((c) => c.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  'Edit Item: ${widget.item['ean']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.item['description'] as String? ?? 'Unknown Product',
                          style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _acceptedQtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Accepted Qty'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _rejectedQtyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Rejected Qty'),
                            ),
                          ),
                        ],
                      ),

                      if (_batchControllers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Batches', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ..._batchControllers.asMap().entries.map((entry) {
                          final ctrls = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Batch: ${ctrls['batch_no']!.text}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: ctrls['qty'],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Qty'),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextField(
                                        controller: ctrls['mrp'],
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        decoration: const InputDecoration(labelText: 'MRP'),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: widget.onDismiss, child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        final batches = _batchControllers.map((ctrls) => {
                          'batch_no': ctrls['batch_no']!.text,
                          'qty': int.tryParse(ctrls['qty']!.text) ?? 0,
                          'mrp': double.tryParse(ctrls['mrp']!.text) ?? 0.0,
                        }).toList();
                        widget.onConfirm(
                          int.tryParse(_acceptedQtyCtrl.text) ?? 0,
                          int.tryParse(_rejectedQtyCtrl.text) ?? 0,
                          batches,
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      child: const Text('Submit', style: TextStyle(color: Colors.white)),
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
