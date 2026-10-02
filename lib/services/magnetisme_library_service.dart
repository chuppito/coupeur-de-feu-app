import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive_flutter/hive_flutter.dart';

class MagnetismeLibraryService {
  static const String boxName = 'magnetisme_library_custom';
  static Box get _box => Hive.box(boxName);

  static Future<List<Map<String, dynamic>>> loadAll() async {
    final raw = await rootBundle.loadString('assets/data/magnetisme_protocoles.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final base = (data['fiches'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final techniquesRaw =
        await rootBundle.loadString('assets/data/magnetisme_techniques.json');
    final techniquesData =
        jsonDecode(techniquesRaw) as Map<String, dynamic>;
    final techniques = (techniquesData['techniques'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final custom = _box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return [...base, ...techniques, ...custom];
  }

  static Future<void> add(Map<String, dynamic> entry) async =>
      _box.add(Map<String, dynamic>.from(entry));

  static Future<void> delete(dynamic key) => _box.delete(key);

  static String personalized(
    String text, {
    required String prenom,
    required String nom,
    String? pathologie,
  }) {
    final full = [prenom.trim(), nom.trim()]
        .where((x) => x.isNotEmpty)
        .join(' ');
    final inverse = [nom.trim(), prenom.trim()]
        .where((x) => x.isNotEmpty)
        .join(' ');
    var result = text;
    result = result
        .replaceAll('[nom et prénom]', full)
        .replaceAll('[nom et prenom]', full)
        .replaceAll('[prénom nom]', full)
        .replaceAll('[prenom nom]', full)
        .replaceAll('[nom prénom]', inverse)
        .replaceAll('[nom prenom]', inverse);
    if (pathologie != null && pathologie.trim().isNotEmpty) {
      result = result
          .replaceAll('[dire le nom de la maladie]', pathologie.trim())
          .replaceAll('[nom de la maladie]', pathologie.trim());
    }
    return result;
  }
}
