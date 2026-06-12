import 'package:flutter/material.dart';

enum TripStatus { completed, pending }

class Trip {
  final String invoiceNumber;
  final String vendorName;
  final TripStatus status;
  final Color backgroundColor;

  const Trip({
    required this.invoiceNumber,
    required this.vendorName,
    required this.status,
    required this.backgroundColor,
  });
}
