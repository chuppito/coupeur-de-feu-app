import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'history_service.dart';
import 'body_scan_service.dart';
import 'energy_assessment_service.dart';
import 'pendulum_care_service.dart';
import 'magnetisme_session_service.dart';
import 'protocole_service.dart';

/// Gère l'export/import de sauvegarde, sous forme de fichiers JSON lisibles
/// (pas de chiffrement : le téléphone est considéré comme déjà protégé en
/// amont). Deux sauvegardes indépendantes :
///  - l'historique patient (sessions, voir HistoryService)
///  - la bibliothèque de techniques de magnétisme (voir ProtocoleService)
class BackupService {
  static Future<File> _writeFile(String contenu, String suffixe) async {
    final dir = await getTemporaryDirectory();
    final horodatage =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${dir.path}/coupeur_de_feu_sauvegarde_${suffixe}_$horodatage.json');
    return file.writeAsString(contenu);
  }

  static Future<void> _partager(File file, String texte) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: texte),
    );
  }

  // ---------------------------------------------------------------------
  // Historique patient
  // ---------------------------------------------------------------------

  /// Génère le fichier de sauvegarde de l'historique patient et ouvre le
  /// menu de partage natif (email, Drive, fichiers, etc.).
  static Future<void> exportSessionsAndShare() async {
    final history = jsonDecode(HistoryService.exportAllToJson()) as Map<String, dynamic>;
    final scans = jsonDecode(BodyScanService.exportAllToJson()) as List<dynamic>;
    final bilans = jsonDecode(EnergyAssessmentService.exportAllToJson()) as List<dynamic>;
    final soins = jsonDecode(PendulumCareService.exportAllToJson()) as List<dynamic>;
    final payload = <String, dynamic>{
      ...history,
      'version': 4,
      'bodyScans': scans,
      'energyAssessments': bilans,
      'pendulumCares': soins,
      'magnetismeSessions': jsonDecode(MagnetismeSessionService.exportAllToJson()) as List<dynamic>,
    };
    final file = await _writeFile(
      const JsonEncoder.withIndent('  ').convert(payload),
      'patients',
    );
    await _partager(file, 'Sauvegarde Coupeur de Feu - patients, scans, bilans et soins au pendule');
  }

  /// Lit un fichier de sauvegarde JSON et réimporte les séances qu'il
  /// contient (s'ajoutent à l'existant). Renvoie le nombre importé.
  static Future<int> importSessionsFromFile(File file) async {
    final content = await file.readAsString();
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Format de sauvegarde patients invalide.');
    }

    // Compatibilité avec les sauvegardes historiques (sessions uniquement).
    final sessionsPayload = <String, dynamic>{
      'version': decoded['version'] ?? 1,
      'exportedAt': decoded['exportedAt'],
      'sessions': decoded['sessions'] ?? const [],
    };
    final nbSessions = await HistoryService.importFromJson(
      const JsonEncoder.withIndent('  ').convert(sessionsPayload),
    );

    final scans = decoded['bodyScans'];
    if (scans is List) {
      await BodyScanService.importFromJson(
        const JsonEncoder.withIndent('  ').convert(scans),
      );
    }
    final soins = decoded['pendulumCares'];
    if (soins is List) {
      await PendulumCareService.importFromJson(
        const JsonEncoder.withIndent('  ').convert(soins),
      );
    }
    final magnetisme = decoded['magnetismeSessions'];
    if (magnetisme is List) {
      await MagnetismeSessionService.importFromJson(
        const JsonEncoder.withIndent('  ').convert(magnetisme),
      );
    }

    final bilans = decoded['energyAssessments'];
    if (bilans is List) {
      await EnergyAssessmentService.importFromJson(
        const JsonEncoder.withIndent('  ').convert(bilans),
      );
    }
    return nbSessions;
  }

  // ---------------------------------------------------------------------
  // Bibliothèque de techniques de magnétisme
  // ---------------------------------------------------------------------

  /// Génère le fichier de sauvegarde de la bibliothèque de techniques
  /// (prières, protocoles, tes propres ajouts) et ouvre le partage natif.
  static Future<void> exportProtocolesAndShare() async {
    final file = await _writeFile(ProtocoleService.exportAllToJson(), 'techniques');
    await _partager(file, 'Sauvegarde Coupeur de Feu - techniques de magnétisme');
  }

  /// Lit un fichier de sauvegarde JSON et réimporte la bibliothèque de
  /// techniques qu'il contient. Les fiches dont le titre existe déjà sont
  /// remplacées (utile pour revenir à une ancienne version d'une prière) ;
  /// les autres sont ajoutées. Renvoie le nombre de fiches traitées.
  static Future<int> importProtocolesFromFile(File file) async {
    final content = await file.readAsString();
    return ProtocoleService.importFromJson(content);
  }
}
