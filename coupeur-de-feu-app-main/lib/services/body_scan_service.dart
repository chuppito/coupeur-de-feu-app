import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Enregistre les observations du scan du corps au pendule.
///
/// Les données sont conservées dans une box Hive indépendante de l'historique
/// des soins afin de ne pas modifier le modèle PatientSession existant.
class BodyScanService {
  static const String _boxName = 'body_scans';

  static Box get _box => Hive.box(_boxName);

  static ValueListenable<Box> listenable() => _box.listenable();

  static Future<void> saveScan({
    required String nomPatient,
    String nomFamille = '',
    required List<Map<String, dynamic>> zones,
    String observation = '',
  }) async {
    await _box.add({
      'nomPatient': nomPatient.trim(),
      'nomFamille': nomFamille.trim(),
      'date': DateTime.now().toIso8601String(),
      'zones': zones,
      'observation': observation.trim(),
    });
  }

  static List<Map<String, dynamic>> getScans({String? nomComplet}) {
    final scans = _box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((e) {
          if (nomComplet == null || nomComplet.trim().isEmpty) return true;
          final prenom = (e['nomPatient'] ?? '').toString().trim();
          final famille = (e['nomFamille'] ?? '').toString().trim();
          final complet = famille.isEmpty ? prenom : '$prenom $famille';
          return complet == nomComplet;
        })
        .toList();

    scans.sort((a, b) => DateTime.parse(b['date'].toString())
        .compareTo(DateTime.parse(a['date'].toString())));
    return scans;
  }


  /// Met à jour le nom associé aux scans lorsqu'une fiche patient est renommée.
  static Future<void> renamePatientScans(
    String ancienNomComplet,
    String nouveauPrenom,
    String nouveauNomFamille,
  ) async {
    final scans = _box.toMap().entries.where((entry) {
      final value = entry.value;
      if (value is! Map) return false;
      final prenom = (value['nomPatient'] ?? '').toString().trim();
      final famille = (value['nomFamille'] ?? '').toString().trim();
      final complet = famille.isEmpty ? prenom : '$prenom $famille';
      return complet == ancienNomComplet;
    }).toList();

    for (final entry in scans) {
      final scan = Map<String, dynamic>.from(entry.value as Map);
      scan['nomPatient'] = nouveauPrenom.trim();
      scan['nomFamille'] = nouveauNomFamille.trim();
      await _box.put(entry.key, scan);
    }
  }

  /// Supprime les scans associés au patient supprimé.
  static Future<List<Map<String, dynamic>>> deletePatientScans(String nomComplet) async {
    final entries = _box.toMap().entries.where((entry) {
      final value = entry.value;
      if (value is! Map) return false;
      final prenom = (value['nomPatient'] ?? '').toString().trim();
      final famille = (value['nomFamille'] ?? '').toString().trim();
      final complet = famille.isEmpty ? prenom : '$prenom $famille';
      return complet == nomComplet;
    }).toList();

    final snapshot = entries
        .map((entry) => Map<String, dynamic>.from(entry.value as Map))
        .toList();
    await _box.deleteAll(entries.map((entry) => entry.key).toList());
    return snapshot;
  }

  static Future<void> restorePatientScans(List<Map<String, dynamic>> scans) async {
    for (final scan in scans) {
      await _box.add(Map<String, dynamic>.from(scan));
    }
  }

  static Future<void> deleteScan(dynamic key) async {
    await _box.delete(key);
  }

  static String exportAllToJson() {
    return const JsonEncoder.withIndent('  ').convert(
      _box.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  static Future<int> importFromJson(String content) async {
    final decoded = jsonDecode(content);
    if (decoded is! List) throw const FormatException('Format de sauvegarde invalide.');
    var count = 0;
    for (final item in decoded) {
      if (item is Map) {
        await _box.add(Map<String, dynamic>.from(item));
        count++;
      }
    }
    return count;
  }
}
