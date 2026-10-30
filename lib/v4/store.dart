import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';
import 'engine.dart';
import 'runner.dart';

String newId() {
  final random = Random.secure();
  final b = List<int>.generate(16, (_) => random.nextInt(256));
  b[6] = (b[6] & 15) | 64;
  b[8] = (b[8] & 63) | 128;
  final s = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
  return '${s.substring(0, 8)}-${s.substring(8, 12)}-${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
}

String foldFrench(String s) {
  const accents = 'àâäéèêëîïôöùûüçœ';
  const normal = [
    'a',
    'a',
    'a',
    'e',
    'e',
    'e',
    'e',
    'i',
    'i',
    'o',
    'o',
    'u',
    'u',
    'u',
    'c',
    'oe'
  ];
  var v = s.toLowerCase();
  for (var i = 0; i < accents.length; i++) {
    v = v.replaceAll(accents[i], normal[i]);
  }
  return v;
}

class V4Store {
  static const patientsBox = 'v4_patients',
      sessionsBox = 'v4_sessions',
      customBox = 'v4_custom_protocols',
      metaBox = 'v4_meta';
  static Future<void> open() async {
    for (final n in [patientsBox, sessionsBox, customBox, metaBox]) {
      if (!Hive.isBoxOpen(n)) await Hive.openBox(n);
    }
  }

  static ValueListenable<Box> patientsListenable() =>
      Hive.box(patientsBox).listenable();
  static ValueListenable<Box> sessionsListenable() =>
      Hive.box(sessionsBox).listenable();
  static List<Json> patients({String search = ''}) {
    final q = foldFrench(search);
    final list = Hive.box(patientsBox)
        .values
        .whereType<Map>()
        .map(jsonMap)
        .where(
            (p) => foldFrench('${p['firstName']} ${p['lastName']}').contains(q))
        .toList();
    list.sort((a, b) =>
        foldFrench('${a['lastName']} ${a['firstName']} ${a['id']}').compareTo(
            foldFrench('${b['lastName']} ${b['firstName']} ${b['id']}')));
    return list;
  }

  static Future<String> createPatient(String first, String last) async {
    if (first.trim().isEmpty) throw ArgumentError('Prénom requis.');
    final id = newId();
    await Hive.box(patientsBox).put(id, {
      'id': id,
      'firstName': first.trim(),
      'lastName': last.trim(),
      'createdAt': DateTime.now().toUtc().toIso8601String()
    });
    await Hive.box(patientsBox).flush();
    return id;
  }

  static Future<void> renamePatient(
      String id, String first, String last) async {
    if (!Hive.box(patientsBox).containsKey(id) || first.trim().isEmpty) {
      throw ArgumentError('Patient inconnu ou prénom vide.');
    }
    final p = jsonMap(Hive.box(patientsBox).get(id));
    await Hive.box(patientsBox)
        .put(id, {...p, 'firstName': first.trim(), 'lastName': last.trim()});
    await Hive.box(patientsBox).flush();
  }

  static List<Json> sessions(String patientId) {
    final result = Hive.box(sessionsBox)
        .values
        .whereType<Map>()
        .map(jsonMap)
        .where((s) => s['patientId'] == patientId)
        .toList();
    result.sort((a, b) =>
        (b['updatedAt'] as String).compareTo(a['updatedAt'] as String));
    return result;
  }

  static Future<void> saveSession(
      {required String id,
      required String patientId,
      required SessionRunner runner,
      String notes = '',
      Json assessment = const {}}) async {
    if (!Hive.box(patientsBox).containsKey(patientId)) {
      throw ArgumentError('Patient V4 inconnu.');
    }
    final prior = Hive.box(sessionsBox).get(id);
    if (prior is Map && prior['patientId'] != patientId) {
      throw StateError('Une séance ne change pas de patient implicitement.');
    }
    await Hive.box(sessionsBox).put(id, {
      'id': id,
      'patientId': patientId,
      'runner': runner.toJson(),
      'notes': notes,
      'assessment': jsonDecode(jsonEncode(assessment)),
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'createdAt': prior is Map
          ? prior['createdAt']
          : DateTime.now().toUtc().toIso8601String(),
      'completed': runner.finished
    });
    await Hive.box(sessionsBox).flush();
  }

  static Future<List<ProtocolDefinition>> catalog() async {
    final data = jsonMap(
        jsonDecode(await rootBundle.loadString('assets/data/v4_catalog.json')));
    if (data['schemaVersion'] != 4) {
      throw const FormatException('Catalogue V4 invalide.');
    }
    final blocks = jsonMap(data['blocks']);
    final merged = <String, ProtocolDefinition>{};
    for (final raw in data['protocols'] as List) {
      final j = jsonMap(raw);
      j['blocks'] = (j['blocks'] as List)
          .map((id) =>
              blocks[id] ?? (throw FormatException('Bloc inconnu : $id')))
          .toList();
      final p = ProtocolDefinition.fromJson(j);
      merged[p.id] = p;
    }
    for (final raw in Hive.box(customBox).values.whereType<Map>()) {
      final p = ProtocolDefinition.fromJson(jsonMap(raw));
      merged[p.id] = p;
    }
    return merged.values.toList()
      ..sort((a, b) => foldFrench(a.title).compareTo(foldFrench(b.title)));
  }

  static Future<void> saveLocalProtocol(Json data) async {
    final p = ProtocolDefinition.fromJson(data);
    final blocking =
        ProtocolValidator().validate(p).where((x) => x.blocking).toList();
    if (blocking.isNotEmpty) {
      throw FormatException(blocking.map((x) => x.message).join('\n'));
    }
    final box = Hive.box(customBox);
    if (box.containsKey(p.id)) {
      await Hive.box(metaBox)
          .put('protocolBackup:${p.id}:${newId()}', box.get(p.id));
    }
    await Hive.box(metaBox).flush();
    await box.put(p.id, p.toJson());
    await box.flush();
  }

  static Json exportData() => {
        'schemaVersion': 4,
        'patients': Hive.box(patientsBox).values.toList(),
        'sessions': Hive.box(sessionsBox).values.toList(),
        'customProtocols': Hive.box(customBox).values.toList(),
        'meta': Map.fromEntries(Hive.box(metaBox)
            .toMap()
            .entries
            .where((e) => !e.key.toString().startsWith('beforeImport:'))
            .map((e) => MapEntry(e.key.toString(), e.value)))
      };
  static Future<int> importData(Json data) async {
    if (data['schemaVersion'] != 4) {
      throw const FormatException('Sauvegarde V4 attendue.');
    }
    final patients = (data['patients'] as List).map(jsonMap).toList(),
        sessions = (data['sessions'] as List).map(jsonMap).toList(),
        custom = (data['customProtocols'] as List).map(jsonMap).toList();
    final incomingMeta = jsonMap(data['meta'] ?? {});
    final localMeta = Hive.box(metaBox);
    for (final e in incomingMeta.entries) {
      if (e.key.startsWith('beforeImport:')) {
        throw const FormatException('Sauvegarde imbriquée non admise.');
      }
      if (localMeta.containsKey(e.key) &&
          fingerprint(localMeta.get(e.key)) != fingerprint(e.value)) {
        throw FormatException('Conflit de métadonnées : ${e.key}.');
      }
    }
    final incomingIds = <String>{};
    for (final p in patients) {
      if (p['id'] is! String ||
          (p['id'] as String).isEmpty ||
          p['firstName'] is! String ||
          (p['firstName'] as String).trim().isEmpty ||
          p['lastName'] is! String ||
          !incomingIds.add(p['id'] as String)) {
        throw const FormatException('Identité patient invalide ou dupliquée.');
      }
    }
    final sessionIds = <String>{};
    for (final s in sessions) {
      if (s['id'] is! String ||
          !sessionIds.add(s['id'] as String) ||
          s['updatedAt'] is! String ||
          s['createdAt'] is! String ||
          (!incomingIds.contains(s['patientId']) &&
              !Hive.box(patientsBox).containsKey(s['patientId']))) {
        throw const FormatException('Séance orpheline ou invalide.');
      }
      SessionRunner.fromJson(jsonMap(s['runner']));
    }
    final protocolIds = <String>{};
    for (final j in custom) {
      final p = ProtocolDefinition.fromJson(j);
      if (!protocolIds.add(p.id) ||
          ProtocolValidator().validate(p).any((x) => x.blocking)) {
        throw const FormatException('Fiche locale invalide ou dupliquée.');
      }
    }
    // Validate every item and conflict before the first write. Never overwrite local changes.
    final sets = {
      patientsBox: patients,
      sessionsBox: sessions,
      customBox: custom
    };
    for (final entry in sets.entries) {
      final box = Hive.box(entry.key);
      for (final j in entry.value) {
        final prior = box.get(j['id']);
        if (prior != null && fingerprint(prior) != fingerprint(j)) {
          throw FormatException(
              'Conflit local pour ${j['id']} ; aucune donnée remplacée.');
        }
      }
    }
    final hasNew = incomingMeta.keys.any((k) => !localMeta.containsKey(k)) ||
        sets.entries.any(
            (e) => e.value.any((j) => !Hive.box(e.key).containsKey(j['id'])));
    if (!hasNew) return 0;
    await Hive.box(metaBox)
        .put('beforeImport:${newId()}', jsonDecode(jsonEncode(exportData())));
    await Hive.box(metaBox).flush();
    var added = 0;
    for (final entry in sets.entries) {
      final box = Hive.box(entry.key);
      for (final j in entry.value) {
        if (!box.containsKey(j['id'])) {
          await box.put(j['id'], j);
          added++;
        }
      }
      await box.flush();
    }
    for (final e in incomingMeta.entries) {
      if (!localMeta.containsKey(e.key)) {
        await localMeta.put(e.key, e.value);
        added++;
      }
    }
    await localMeta.flush();
    return added;
  }
}
