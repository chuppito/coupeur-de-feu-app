import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/patient_session.dart';
import '../models/protocole.dart';
import 'models.dart';
import 'store.dart';

/// Stages originals for explicit review. Never writes a V3 box or joins by name.
class LegacyMigration {
  static Json captureOpenV3Boxes() {
    final result = <String, dynamic>{};
    if (Hive.isBoxOpen('sessions')) {
      result['sessions'] = {
        for (final e in Hive.box<PatientSession>('sessions').toMap().entries)
          '${e.key.runtimeType}:${e.key}': {
            'nomPatient': e.value.nomPatient,
            'nomFamille': e.value.nomFamille,
            'zone': e.value.zone,
            'observation': e.value.observation,
            'intensiteAvant': e.value.intensiteAvant,
            'intensiteApres': e.value.intensiteApres,
            'date': e.value.date.toIso8601String(),
            'maladie': e.value.maladie,
            'guerie': e.value.guerie,
            'dateGuerison': e.value.dateGuerison?.toIso8601String(),
            'protocoleTitre': e.value.protocoleTitre
          }
      };
    }
    if (Hive.isBoxOpen('protocoles')) {
      result['protocoles'] = {
        for (final e in Hive.box<Protocole>('protocoles').toMap().entries)
          '${e.key.runtimeType}:${e.key}': {
            'titre': e.value.titre,
            'priere': e.value.priere,
            'etapes': e.value.etapes,
            'dateAjout': e.value.dateAjout.toIso8601String(),
            'estParDefaut': e.value.estParDefaut
          }
      };
    }
    for (final name in [
      'body_scans',
      'energy_assessments',
      'pendulum_cares',
      'magnetisme_sessions',
      'magnetisme_library_custom'
    ]) {
      if (Hive.isBoxOpen(name)) {
        result[name] = {
          for (final e in Hive.box(name).toMap().entries)
            '${e.key.runtimeType}:${e.key}': e.value
        };
      }
    }
    // Reject non-serializable data before any migration write; originals stay untouched.
    return jsonMap(jsonDecode(jsonEncode(result)));
  }

  static Future<int> stage(Json snapshot) async {
    for (final box in snapshot.values) {
      if (box is! Map) throw const FormatException('Instantané V3 invalide.');
    }
    final copy = jsonMap(jsonDecode(jsonEncode(snapshot))),
        meta = Hive.box(V4Store.metaBox);
    final backupId = 'legacy-backup:${fingerprint(copy)}';
    if (!meta.containsKey(backupId)) {
      await meta.put(backupId, {
        'schemaVersion': 4,
        'source': 'V3',
        'snapshot': copy,
        'createdAt': DateTime.now().toUtc().toIso8601String()
      });
      await meta.flush();
    }
    var count = 0;
    for (final collection in copy.entries) {
      for (final row in jsonMap(collection.value).entries) {
        final id = 'legacy-record:${fingerprint([
              collection.key,
              row.key,
              row.value
            ])}';
        if (!meta.containsKey(id)) {
          await meta.put(id, {
            'id': id,
            'collection': collection.key,
            'legacyKey': row.key,
            'original': row.value,
            'backupId': backupId,
            'review': 'needsReview'
          });
          count++;
        }
      }
    }
    await meta.flush();
    return count;
  }

  static List<Json> records() => Hive.box(V4Store.metaBox)
      .toMap()
      .entries
      .where((e) => e.key.toString().startsWith('legacy-record:'))
      .map((e) => jsonMap(e.value))
      .toList();
  static String? linkedPatient(String recordId) =>
      Hive.box(V4Store.metaBox).get('legacy-link:$recordId') as String?;
  static Future<void> link(String recordId, String patientId) async {
    final meta = Hive.box(V4Store.metaBox);
    if (!meta.containsKey(recordId) ||
        !Hive.box(V4Store.patientsBox).containsKey(patientId)) {
      throw ArgumentError('Référence inconnue.');
    }
    final existing = linkedPatient(recordId);
    if (existing != null && existing != patientId) {
      throw StateError(
          'Association existante conservée ; arbitrage manuel requis.');
    }
    await meta.put('legacy-link:$recordId', patientId);
    await meta.flush();
  }
}
