import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Historique des soins au pendule, associé au patient.
class PendulumCareService {
  static const String boxName = 'pendulum_cares';
  static Box get _box => Hive.box(boxName);

  static ValueListenable<Box> listenable() => _box.listenable();

  static Future<void> save(Map<String, dynamic> care) async {
    await _box.add(Map<String, dynamic>.from(care));
  }

  static List<Map<String, dynamic>> getForPatient(String nomComplet) {
    final entries = _box.toMap().entries.where((e) => e.value is Map).map((e) {
      final value = Map<String, dynamic>.from(e.value as Map);
      value['_hiveKey'] = e.key;
      return value;
    }).where((e) {
      final prenom = (e['nomPatient'] ?? '').toString().trim();
      final nom = (e['nomFamille'] ?? '').toString().trim();
      return (nom.isEmpty ? prenom : '$prenom $nom') == nomComplet;
    }).toList();
    entries.sort((a, b) {
      final da = DateTime.tryParse((a['date'] ?? '').toString()) ?? DateTime(1970);
      final db = DateTime.tryParse((b['date'] ?? '').toString()) ?? DateTime(1970);
      return db.compareTo(da);
    });
    return entries;
  }

  static Future<void> renamePatient(String oldFullName, String firstName, String lastName) async {
    for (final entry in _box.toMap().entries) {
      if (entry.value is! Map) continue;
      final value = Map<String, dynamic>.from(entry.value as Map);
      final p = (value['nomPatient'] ?? '').toString().trim();
      final n = (value['nomFamille'] ?? '').toString().trim();
      if ((n.isEmpty ? p : '$p $n') == oldFullName) {
        value['nomPatient'] = firstName.trim();
        value['nomFamille'] = lastName.trim();
        await _box.put(entry.key, value);
      }
    }
  }

  static Future<List<Map<String, dynamic>>> deletePatient(String fullName) async {
    final entries = _box.toMap().entries.where((e) {
      if (e.value is! Map) return false;
      final v = e.value as Map;
      final p = (v['nomPatient'] ?? '').toString().trim();
      final n = (v['nomFamille'] ?? '').toString().trim();
      return (n.isEmpty ? p : '$p $n') == fullName;
    }).toList();
    final snapshot = entries.map((e) => Map<String, dynamic>.from(e.value as Map)).toList();
    await _box.deleteAll(entries.map((e) => e.key).toList());
    return snapshot;
  }

  static Future<void> restore(List<Map<String, dynamic>> values) async {
    for (final value in values) { await _box.add(Map<String, dynamic>.from(value)); }
  }

  static Future<void> deleteByKey(dynamic key) => _box.delete(key);

  static String exportAllToJson() => const JsonEncoder.withIndent('  ').convert(
    _box.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());

  static Future<int> importFromJson(String content) async {
    final decoded = jsonDecode(content);
    if (decoded is! List) throw const FormatException('Format des soins au pendule invalide.');
    var count = 0;
    for (final item in decoded) {
      if (item is Map) { await _box.add(Map<String, dynamic>.from(item)); count++; }
    }
    return count;
  }
}
