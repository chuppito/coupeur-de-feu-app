import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle, AssetBundle;
import 'package:hive_flutter/hive_flutter.dart';

class MagnetismeLibraryService {
  static const String boxName = 'magnetisme_library_custom';
  static Box get _box => Hive.box(boxName);

  static Future<List<Map<String, dynamic>>> loadAll({AssetBundle? assets}) async {
    final bundle=assets ?? rootBundle;
    final raw = await bundle.loadString('assets/data/magnetisme_protocoles.json');
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final base = (data['fiches'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final techniquesRaw =
        await bundle.loadString('assets/data/magnetisme_techniques.json');
    final techniquesData =
        jsonDecode(techniquesRaw) as Map<String, dynamic>;
    final techniques = (techniquesData['techniques'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final chakrasRaw =
        await bundle.loadString('assets/data/magnetisme_techniques_chakras.json');
    final chakrasData =
        jsonDecode(chakrasRaw) as Map<String, dynamic>;
    final chakras = (chakrasData['techniques'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final guide = jsonDecode(await bundle.loadString('assets/data/guide_v33.json')) as Map<String,dynamic>;
    for (final entry in base) {
      final actions=guide[entry['id']];
      if(actions!=null) entry['guideV33']=actions;
    }

    final custom = _box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    final overrides = <String, Map<String, dynamic>>{};
    for (final entry in custom) {
      final id = (entry['id'] ?? '').toString();
      if (id.isNotEmpty) overrides[id] = entry;
    }
    final builtIn = [...base, ...techniques, ...chakras];
    final merged = builtIn.map((entry) {
      final id = (entry['id'] ?? '').toString();
      final local = overrides.remove(id);
      if(local==null)return entry;
      final mergedEntry = {...entry, ...local};
      // Une modification personnelle reste prioritaire et n'est jamais effacée.
      // Sans guide explicite propre, montrer son texte intégral plutôt que l'ancien guide intégré.
      if(local['contenu'] != null && local['contenu'] != entry['contenu'] && (local['guideV33']==null || jsonEncode(local['guideV33'])==jsonEncode(entry['guideV33']))) {
        mergedEntry['guideV33'] = [
          {'id':'personnel','kind':'personnel','text':local['contenu'].toString(),'target':'selection','source':'Fiche personnelle locale','distanceText':''}
        ];
      }
      return mergedEntry;
    }).toList();
    return [...merged, ...overrides.values];
  }

  static Future<void> add(Map<String, dynamic> entry) async =>
      _box.add(Map<String, dynamic>.from(entry));

  static Future<void> delete(dynamic key) => _box.delete(key);

  /// Enregistre une version locale sans modifier les ressources intégrées.
  static Future<void> saveLocal(Map<String, dynamic> entry) async {
    final id = (entry['id'] ?? '').toString();
    if (id.isEmpty) throw ArgumentError('Identifiant de fiche manquant');
    await _box.put(id, Map<String, dynamic>.from(entry));
  }

  static bool hasLocalVersion(String id) => _box.containsKey(id);

  static Future<void> resetLocal(String id) => _box.delete(id);


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
        .replaceAll('[NOM]', full)
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
