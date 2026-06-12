class LineItem {
  final String description;
  final String status;
  final String ean;
  final String mrp;
  final bool mrpConsistent;

  const LineItem({
    required this.description,
    required this.status,
    required this.ean,
    required this.mrp,
    required this.mrpConsistent,
  });

  factory LineItem.fromMap(Map<String, dynamic> map) {
    return LineItem(
      description: map['description'] as String? ?? 'Unknown',
      status: map['status'] as String? ?? 'unknown',
      ean: map['ean'] as String? ?? 'N/A',
      mrp: map['mrp'] as String? ?? '0.00',
      mrpConsistent: map['mrp_consistent'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'description': description,
        'status': status,
        'ean': ean,
        'mrp': mrp,
        'mrp_consistent': mrpConsistent,
      };
}
