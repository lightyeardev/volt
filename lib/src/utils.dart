import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:volt/volt.dart';

String toStableKey<T>(
  VoltQuery<T> query,
  List<String> Function(List<String>) keyTransformer,
) {
  return sha256
      .convert(utf8.encode(keyTransformer(query.queryKey.map((e) => e ?? '').toList()).join(',')))
      .toString();
}
