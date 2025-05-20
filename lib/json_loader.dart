import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class JsonLoader {
  static Future<List<Map<String, dynamic>>> loadList(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = json.decode(raw);

    if (decoded is List) {
      return decoded.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e)).toList();
    } else {
      throw FormatException('Expected a list at root of JSON: $path');
    }
  }
}
