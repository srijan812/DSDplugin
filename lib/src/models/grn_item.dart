class GrnItem {
  final String ean;
  final String mrp;
  final String qty;
  final String status;
  final String description;
  final String allMrps;
  final String? batch;
  final String? mDate;
  final String? eDate;

  const GrnItem({
    required this.ean,
    required this.mrp,
    required this.qty,
    required this.status,
    required this.description,
    required this.allMrps,
    this.batch,
    this.mDate,
    this.eDate,
  });

  factory GrnItem.fromMap(Map<String, dynamic> map) {
    return GrnItem(
      ean: map['ean'] as String? ?? 'N/A',
      mrp: map['mrp'] as String? ?? '0.00',
      qty: map['qty'] as String? ?? '0',
      status: map['status'] as String? ?? 'unknown',
      description: map['description'] as String? ?? 'Unknown Product',
      allMrps: map['all_mrps'] as String? ?? '',
      batch: map['batch'] as String?,
      mDate: map['m_date'] as String?,
      eDate: map['e_date'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'ean': ean,
      'mrp': mrp,
      'qty': qty,
      'status': status,
      'description': description,
      'all_mrps': allMrps,
    };
    if (batch != null) m['batch'] = batch;
    if (mDate != null) m['m_date'] = mDate;
    if (eDate != null) m['e_date'] = eDate;
    return m;
  }
}
