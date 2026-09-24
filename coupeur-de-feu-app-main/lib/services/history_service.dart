import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/patient_session.dart';

/// Gère la persistance des séances patient via Hive.
/// Remplace l'ancienne implémentation SharedPreferences/JSON :
/// Hive était déjà initialisé dans main.dart mais n'était pas utilisé,
/// pendant que SharedPreferences stockait les données en parallèle.
/// Il n'y a maintenant qu'une seule source de vérité.
class HistoryService {
  static Box<PatientSession> get _box => Hive.box<PatientSession>('sessions');

  /// Permet d'écouter les changements de la box (utilisé par
  /// ValueListenableBuilder pour rafraîchir l'UI automatiquement).
  static ValueListenable<Box<PatientSession>> listenable() =>
      _box.listenable();

  static Future<void> saveEntry(
    String nom,
    String maladie,
    String zones, {
    String nomFamille = '',
    String observation = '',
    int? intensiteAvant,
    int? intensiteApres,
    String? protocoleTitre,
  }) async {
    final session = PatientSession(
      nomPatient: nom,
      nomFamille: nomFamille,
      maladie: maladie,
      zone: zones,
      observation: observation,
      intensiteAvant: intensiteAvant,
      intensiteApres: intensiteApres,
      protocoleTitre: protocoleTitre,
      date: DateTime.now(),
    );
    await _box.add(session);
  }

  static List<PatientSession> getHistory() {
    final list = _box.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date)); // plus récent en premier
    return list;
  }

  /// Renomme toutes les séances d'un patient (identifié par son nom complet
  /// actuel) avec un nouveau prénom / nom de famille.
  static Future<void> renamePatient(
    String oldNomComplet,
    String newNomPatient,
    String newNomFamille,
  ) async {
    final concernes = _box.values.where((s) => s.nomComplet == oldNomComplet);
    for (final session in concernes) {
      session.nomPatient = newNomPatient;
      session.nomFamille = newNomFamille;
      await session.save();
    }
  }

  /// Supprime tout l'historique d'un patient (identifié par son nom complet)
  /// et renvoie un instantané des séances supprimées, pour permettre un
  /// "Annuler" juste après (voir [restoreSnapshot]).
  static Future<List<Map<String, dynamic>>> deletePatientAndSnapshot(
      String nomComplet) async {
    final aSupprimer =
        _box.values.where((s) => s.nomComplet == nomComplet).toList();
    final snapshot = aSupprimer.map(_toMap).toList();
    for (final session in aSupprimer) {
      await session.delete();
    }
    return snapshot;
  }

  /// Réinsère des séances précédemment supprimées (utilisé par le bouton
  /// "Annuler" du SnackBar de suppression, et par la restauration de
  /// sauvegarde).
  static Future<void> restoreSnapshot(List<Map<String, dynamic>> snapshot) async {
    for (final m in snapshot) {
      await _box.add(_fromMap(m));
    }
  }

  /// Marque (ou démarque) une séance comme guérie, en horodatant le moment
  /// de la validation.
  static Future<void> toggleGuerison(PatientSession session) async {
    session.guerie = !session.guerie;
    session.dateGuerison = session.guerie ? DateTime.now() : null;
    await session.save();
  }

  /// Ajoute ou modifie la note libre associée à une séance.
  static Future<void> updateObservation(PatientSession session, String note) async {
    session.observation = note;
    await session.save();
  }

  // ---------------------------------------------------------------------
  // Sauvegarde / restauration
  // ---------------------------------------------------------------------

  static Map<String, dynamic> _toMap(PatientSession s) => {
        'nomPatient': s.nomPatient,
        'nomFamille': s.nomFamille,
        'zone': s.zone,
        'observation': s.observation,
        'intensiteAvant': s.intensiteAvant,
        'intensiteApres': s.intensiteApres,
        'date': s.date.toIso8601String(),
        'maladie': s.maladie,
        'guerie': s.guerie,
        'dateGuerison': s.dateGuerison?.toIso8601String(),
        'protocoleTitre': s.protocoleTitre,
      };

  static PatientSession _fromMap(Map<String, dynamic> m) => PatientSession(
        nomPatient: m['nomPatient'] as String? ?? '',
        nomFamille: m['nomFamille'] as String? ?? '',
        zone: m['zone'] as String? ?? '',
        observation: m['observation'] as String? ?? '',
        intensiteAvant: (m['intensiteAvant'] as num?)?.toInt(),
        intensiteApres: (m['intensiteApres'] as num?)?.toInt(),
        date: DateTime.parse(m['date'] as String),
        maladie: m['maladie'] as String? ?? '',
        guerie: m['guerie'] as bool? ?? false,
        dateGuerison: m['dateGuerison'] != null
            ? DateTime.parse(m['dateGuerison'] as String)
            : null,
        protocoleTitre: m['protocoleTitre'] as String?,
      );

  /// Sérialise tout l'historique en JSON (format utilisé pour l'export de
  /// sauvegarde). Le champ `version` permet de faire évoluer le format sans
  /// casser la compatibilité avec d'anciennes sauvegardes.
  static String exportAllToJson() {
    final all = _box.values.map(_toMap).toList();
    final payload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'sessions': all,
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// Réimporte des séances depuis un JSON généré par [exportAllToJson].
  /// Les séances importées s'ajoutent à celles déjà présentes (aucune
  /// déduplication : une restauration répétée du même fichier dupliquera
  /// les entrées).
  static Future<int> importFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    final sessions = (data['sessions'] as List).cast<Map<String, dynamic>>();
    for (final m in sessions) {
      await _box.add(_fromMap(m));
    }
    return sessions.length;
  }
}
