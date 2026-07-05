import 'package:cloud_firestore/cloud_firestore.dart';

String? asString(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is num || value is bool) return value.toString();
  return null;
}

int? asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

bool asBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' ||
        normalized == 'yes' ||
        normalized == '1' ||
        normalized == 'active' ||
        normalized == 'verified';
  }
  return fallback;
}

DateTime? asDateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value.trim());
  if (value is num) {
    final millis = value > 9999999999 ? value.toInt() : value.toInt() * 1000;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
  return null;
}

Map<String, dynamic> asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return const {};
}

List<String> asStringList(Object? value) {
  if (value is Iterable) {
    return value.map(asString).whereType<String>().toList();
  }
  final single = asString(value);
  return single == null ? const [] : [single];
}

String firstString(
  Map<String, dynamic> data,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = asString(data[key]);
    if (value != null) return value;
  }
  return fallback;
}

DateTime? firstDate(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = asDateTime(data[key]);
    if (value != null) return value;
  }
  return null;
}

int? firstInt(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = asInt(data[key]);
    if (value != null) return value;
  }
  return null;
}

bool firstBool(
  Map<String, dynamic> data,
  List<String> keys, {
  bool fallback = false,
}) {
  for (final key in keys) {
    if (!data.containsKey(key)) continue;
    return asBool(data[key], fallback: fallback);
  }
  return fallback;
}
