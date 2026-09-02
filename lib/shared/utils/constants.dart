// lib/shared/utils/constants.dart
//
// Shared Scholaris constants. Values referenced across features live here so
// they can be tuned in one place.

import 'package:flutter/material.dart' show Color;

import '../theme/app_theme.dart';

/// Tagline shown with the wordmark on the auth screens and splash.
const String kTagline = 'Find scholarships that fit you';

/// One-line brand wordmark widget used by splash/auth/home surfaces.
String get kAppName => 'Scholaris';

/// Scholarship amount formatting helper — 50000 → "₱50,000".
String formatPeso(double amount) {
  final whole = amount.round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < whole.length; i++) {
    final fromEnd = whole.length - 1 - i;
    buffer.write(whole[i]);
    if (fromEnd > 0 && fromEnd % 3 == 0) buffer.write(',');
  }
  return '₱$buffer';
}

/// True when [days] until the scholarship deadline should be treated as
/// "closing soon".
bool isClosingSoon(int days) => days <= 14;

/// True when [deadline]'s calendar day has passed relative to [now]'s — the
/// scholarship no longer accepts applications. Day-granular so it stays
/// consistent with [deadlineLabel] ("Closed" vs "Closes today"), and so a
/// deadline later today is not mistaken for an expired one.
bool isDeadlinePassed(DateTime deadline, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final anchor = DateTime(today.year, today.month, today.day);
  final day = DateTime(deadline.year, deadline.month, deadline.day);
  return day.isBefore(anchor);
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Human-friendly deadline label relative to [now]: "Today", "3 days left",
/// or a plain "Closes Oct 15" once it is far enough out.
String deadlineLabel(DateTime deadline, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final anchor = DateTime(today.year, today.month, today.day);
  final day = DateTime(deadline.year, deadline.month, deadline.day);
  final diff = day.difference(anchor).inDays;

  if (diff < 0) return 'Closed';
  if (diff == 0) return 'Closes today';
  if (diff == 1) return 'Closes tomorrow';
  if (diff <= 30) return '$diff days left';
  return 'Closes ${_months[deadline.month - 1]} ${deadline.day}';
}

/// Soft green tint used for chip / focus surfaces.
Color get primarySoft => kPrimarySoft;
