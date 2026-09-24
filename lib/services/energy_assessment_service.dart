import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Stockage des bilans énergétiques au pendule, indépendant des séances.
class EnergyAssessmentService {
  static const String boxName = 'energy_assessments';
  static Box get _box => Hive.box(boxName);

  static ValueListenable<Box> listenable() => _box.listenable();

  static Future<void> save(Map<String, dynamic> assessment) async {
    await _box.add(Map<String, dynamic>.from(assessment));
  }

  static List<Map<String, dynamic>> getForPatient(String nomComplet) {
    final list = _box.toMap().entries.where((entry) => entry.value is Map).map((entry) {
      final e = Map<String, dynamic>.from(entry.value as Map);
      e['_hiveKey'] = entry.key;
      return e;
    }).where((e) {
      final prenom = (e['nomPatient'] ?? '').toString().trim();
      final nom = (e['nomFamille'] ?? '').toString().trim();
      return (nom.isEmpty ? prenom : '$prenom $nom') == nomComplet;
    }).toList();
    list.sort((a, b) {
      final da = DateTime.tryParse((a['date'] ?? '').toString()) ?? DateTime(1970);
      final db = DateTime.tryParse((b['date'] ?? '').toString()) ?? DateTime(1970);
      return db.compareTo(da);
    });
    return list;
  }

  static Future<void> renamePatient(String ancienNomComplet, String prenom, String nom) async {
    final entries = _box.toMap().entries.where((entry) {
      final value = entry.value;
      if (value is! Map) return false;
      final p = (value['nomPatient'] ?? '').toString().trim();
      final n = (value['nomFamille'] ?? '').toString().trim();
      return (n.isEmpty ? p : '$p $n') == ancienNomComplet;
    }).toList();
    for (final entry in entries) {
      final value = Map<String, dynamic>.from(entry.value as Map);
      value['nomPatient'] = prenom.trim();
      value['nomFamille'] = nom.trim();
      await _box.put(entry.key, value);
    }
  }

  static Future<List<Map<String, dynamic>>> deletePatient(String nomComplet) async {
    final entries = _box.toMap().entries.where((entry) {
      final value = entry.value;
      if (value is! Map) return false;
      final p = (value['nomPatient'] ?? '').toString().trim();
      final n = (value['nomFamille'] ?? '').toString().trim();
      return (n.isEmpty ? p : '$p $n') == nomComplet;
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
    if (decoded is! List) throw const FormatException('Format de bilans énergétiques invalide.');
    var count = 0;
    for (final item in decoded) {
      if (item is Map) { await _box.add(Map<String, dynamic>.from(item)); count++; }
    }
    return count;
  }
}
