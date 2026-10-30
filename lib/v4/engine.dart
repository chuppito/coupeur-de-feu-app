import 'models.dart';

class ProtocolValidator {
  static const physicalKinds = {
    ActionKind.rapidPasses,
    ActionKind.slowPasses,
    ActionKind.imposition,
    ActionKind.circulation,
    ActionKind.sweep,
  };
  List<PlanIssue> validate(ProtocolDefinition p) {
    final errors = <PlanIssue>[];
    void fail(String code, String text) =>
        errors.add(PlanIssue(code, '${p.title} : $text', relatedIds: [p.id]));
    if (p.id.trim().isEmpty ||
        p.title.trim().isEmpty ||
        p.category.trim().isEmpty ||
        p.version.trim().isEmpty) {
      fail('identity', 'Identité ou version de fiche manquante.');
    }
    if (p.blocks.isEmpty || p.modes.isEmpty) {
      fail('empty', 'Fiche sans parcours.');
    }
    if (p.unknowns.isNotEmpty) {
      errors.add(PlanIssue(
          'protocolReview', '${p.title} : ${p.unknowns.join(' ; ')}',
          blocking: false, relatedIds: [p.id]));
    }
    final ids = <String>{};
    for (final b in p.blocks) {
      if (b.id.isEmpty || !ids.add(b.id)) {
        fail(
          'duplicateBlock',
          'Identifiant de bloc vide ou dupliqué : ${b.id}.',
        );
      }
      if (!{'none', 'selected', 'fixed'}.contains(b.target)) {
        fail('target', 'Cible inconnue.');
      }
      if (b.target == 'fixed' && b.fixedZones.isEmpty) {
        fail('target', 'Zones fixes manquantes.');
      }
      if (b.shareKey != null && (b.target != 'none' || b.repeatPerZone)) {
        fail('unsafeShare', 'Un bloc local ne peut pas être fusionné.');
      }
      if (b.actions.isEmpty || b.modes.isEmpty) {
        fail('emptyBlock', 'Bloc sans actions ou sans mode.');
      }
      final actionIds = <String>{};
      for (final a in b.actions) {
        if (a.id.isEmpty ||
            !actionIds.add(a.id) ||
            a.title.isEmpty ||
            a.instruction.trim().isEmpty) {
          fail('actionIdentity', 'Action vide ou dupliquée dans ${b.id}.');
        }
        final t = a.duration;
        if ((t.minSeconds == null) != (t.maxSeconds == null) ||
            (t.minSeconds != null &&
                (t.minSeconds! <= 0 || t.maxSeconds! < t.minSeconds!)) ||
            (t.chosenSeconds != null &&
                (t.chosenSeconds! <= 0 ||
                    (t.minSeconds != null &&
                        t.chosenSeconds! < t.minSeconds!) ||
                    (t.maxSeconds != null &&
                        t.chosenSeconds! > t.maxSeconds!)))) {
          fail('duration', 'Durée invalide pour ${a.id}.');
        }
        if (t.chosenSeconds != null && t.origin != 'personal') {
          fail(
            'durationOrigin',
            'Le choix de durée doit porter sa provenance personnelle.',
          );
        }
        if (a.sources.isEmpty) {
          fail('source', 'Action sans référence : ${a.id}.');
        }
        for (final source in a.sources) {
          if (source.id.isEmpty ||
              source.lesson.isEmpty ||
              Uri.tryParse(source.url)?.hasScheme != true) {
            fail('source', 'Référence incomplète pour ${a.id}.');
          }
        }
        if (a.review == ReviewState.conflicting ||
            a.sources.any((s) => s.review == ReviewState.conflicting)) {
          fail('contradiction', 'Source contradictoire : ${a.id}, à arbitrer.');
        }
        if (a.review == ReviewState.needsReview ||
            a.unknowns.isNotEmpty ||
            a.sources.any((s) => s.review == ReviewState.needsReview)) {
          errors.add(
            PlanIssue(
              'review',
              '${a.title} : points à vérifier conservés.',
              blocking: false,
              relatedIds: [p.id, a.id],
            ),
          );
        }
        if (a.kind == ActionKind.prayer &&
            (a.prayerId == null || a.prayerId!.isEmpty)) {
          fail('prayer', 'Prière sans identifiant explicite.');
        }
        if (a.kind != ActionKind.prayer && a.prayerId != null) {
          fail(
            'prayer',
            'Une liaison de prière doit être une action de prière.',
          );
        }
        if (b.modes.contains(SessionMode.distance) &&
            physicalKinds.contains(a.kind)) {
          fail(
            'distancePhysical',
            'Geste corporel présent dans un bloc à distance.',
          );
        }
      }
    }
    for (final c in p.constraints) {
      if (!ids.contains(c.before) || !ids.contains(c.after)) {
        fail('dependency', 'Dépendance vers un bloc inexistant.');
      }
      if (c.before == c.after) {
        fail('dependency', 'Un bloc ne peut pas se précéder lui-même.');
      }
    }
    return errors;
  }
}

/// Pure, deterministic graph assembly. No keyword inference from prose.
class SessionEngine {
  final ProtocolValidator validator;
  SessionEngine({ProtocolValidator? validator})
      : validator = validator ?? ProtocolValidator();
  SessionPlan build({
    required SessionMode mode,
    required List<ProtocolSelection> selections,
    Map<String, bool> facts = const {},
    Set<String> enabledOptionalBlocks = const {},
  }) {
    final issues = <PlanIssue>[];
    final selectionIds = <String>{};
    for (final s in selections) {
      if (!selectionIds.add(s.id) || s.id.isEmpty) {
        issues.add(
          PlanIssue(
            'duplicateSelection',
            'Identifiant de sélection vide ou dupliqué.',
          ),
        );
      }
      issues.addAll(validator.validate(s.protocol));
      if (!s.protocol.modes.contains(mode)) {
        issues.add(
          PlanIssue(
            'unsupportedMode',
            '${s.protocol.title} ne possède pas de parcours ${mode.name}.',
          ),
        );
      }
      if (s.zones.map((z) => z.key).toSet().length != s.zones.length ||
          s.zones.any((z) => z.id.trim().isEmpty || z.label.trim().isEmpty)) {
        issues.add(
          PlanIssue(
            'zone',
            'Zones vides ou dupliquées dans ${s.protocol.title}.',
          ),
        );
      }
    }
    if (selections.isEmpty) {
      issues.add(PlanIssue('noSelection', 'Sélectionnez au moins une fiche.'));
    }
    if (issues.any((i) => i.blocking)) {
      return SessionPlan(
        mode: mode,
        actions: [],
        issues: issues,
        selections: selections.map((s) => s.toJson()).toList(),
      );
    }
    final nodes = <String, PlannedAction>{};
    final edges = <String, Set<String>>{};
    final shares = <String, String>{};
    final phases = <String, SessionPhase>{};
    void edge(String before, String after) {
      if (before != after) edges.putIfAbsent(before, () => {}).add(after);
    }

    for (final selection in selections) {
      final blockNodes = <String, List<String>>{};
      String? previous;
      for (final block in selection.protocol.blocks) {
        if (!block.modes.contains(mode)) continue;
        if (block.optional &&
            !enabledOptionalBlocks.contains(block.id) &&
            !enabledOptionalBlocks.contains('${selection.id}/${block.id}')) {
          continue;
        }
        if (block.condition != null) {
          if (!facts.containsKey(block.condition)) {
            issues.add(
              PlanIssue(
                'missingFact',
                'Condition à renseigner : ${block.condition}.',
                relatedIds: [selection.id, block.id],
              ),
            );
            continue;
          }
          if (facts[block.condition] != true) continue;
        }
        final targets = block.target == 'selected'
            ? selection.zones
            : block.target == 'fixed'
                ? block.fixedZones
                : <BodyZone>[];
        if (block.target == 'selected' && targets.isEmpty) {
          issues.add(
            PlanIssue(
              'missingZone',
              'Choisissez une zone pour ${selection.protocol.title}.',
              relatedIds: [selection.id, block.id],
            ),
          );
          continue;
        }
        final groups = block.repeatPerZone
            ? targets.map((z) => [z]).toList()
            : <List<BodyZone>>[targets];
        final signature = fingerprint({
          'mode': mode.name,
          'target': block.target,
          'condition': block.condition,
          'optional': block.optional,
          'phase': block.phase?.name,
          'actions': block.actions.map((a) => a.semanticJson).toList(),
        });
        if (block.shareKey != null) {
          final prior = shares[block.shareKey];
          if (prior != null && prior != signature) {
            issues.add(
              PlanIssue(
                'incompatibleShare',
                '${block.shareKey} : variantes différentes conservées séparément.',
                blocking: false,
              ),
            );
          }
          shares[block.shareKey!] = signature;
        }
        for (final zones in groups) {
          for (final action in block.actions) {
            final id = fingerprint(
              block.shareKey != null
                  ? ['shared', block.shareKey, signature, action.id]
                  : [
                      'local',
                      selection.id,
                      block.id,
                      zones.map((z) => z.key).toList(),
                      action.id,
                    ],
            );
            final existing = nodes[id];
            final origins = <String>{
              ...?existing?.origins,
              selection.id,
            }.toList()
              ..sort();
            final sources = <String, SourceRef>{
              for (final s in [...?existing?.sources, ...action.sources])
                fingerprint(s.toJson()): s,
            };
            nodes[id] = PlannedAction(
              id: id,
              definition: action,
              zones: zones,
              origins: origins,
              sources: sources.values.toList(),
            );
            if (block.phase != null) phases[id] = block.phase!;
            edges.putIfAbsent(id, () => {});
            blockNodes.putIfAbsent(block.id, () => []).add(id);
            if (previous != null) edge(previous, id);
            previous = id;
          }
        }
      }
      for (final c in selection.protocol.constraints) {
        for (final before in blockNodes[c.before] ?? <String>[]) {
          for (final after in blockNodes[c.after] ?? <String>[]) {
            edge(before, after);
          }
        }
      }
    }
    // Explicit phases add constraints; they never remove the documented local order.
    // A contradictory exception therefore produces an orderConflict, not a silent reorder.
    for (final before in phases.entries) {
      for (final after in phases.entries) {
        if (before.value.index < after.value.index) edge(before.key, after.key);
      }
    }
    if (selections.length > 1 &&
        selections.any((s) => s.protocol.blocks.any((b) => b.phase == null))) {
      issues.add(PlanIssue('phaseReview',
          'Certaines fiches ne déclarent pas leurs phases : vérifier leur enchaînement global dans l’aperçu.',
          blocking: false));
    }
    final indegree = {for (final id in nodes.keys) id: 0};
    for (final successors in edges.values) {
      for (final id in successors) {
        indegree[id] = indegree[id]! + 1;
      }
    }
    final order = nodes.keys.toList();
    final result = <PlannedAction>[];
    final ready = order.where((id) => indegree[id] == 0).toList();
    while (ready.isNotEmpty) {
      ready.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
      final id = ready.removeAt(0);
      result.add(nodes[id]!);
      for (final next in edges[id]!) {
        indegree[next] = indegree[next]! - 1;
        if (indegree[next] == 0) ready.add(next);
      }
    }
    if (result.length != nodes.length) {
      final cycle = order.where((id) => indegree[id]! > 0).toList();
      issues.add(
        PlanIssue(
          'orderConflict',
          'Ordres incompatibles : aucune séance ne peut démarrer avant arbitrage.',
          relatedIds: cycle,
        ),
      );
      result.addAll(cycle.map((id) => nodes[id]!));
    }
    // A global time guideline never silently truncates a local protocol.
    final local = result
        .where(
          (a) =>
              a.id.isNotEmpty &&
              ProtocolValidator.physicalKinds.contains(a.definition.kind) &&
              a.definition.kind != ActionKind.circulation &&
              a.definition.kind != ActionKind.sweep,
        )
        .fold<int>(0, (sum, a) => sum + (a.duration.seconds ?? 0));
    if (local > 900) {
      issues.add(
        PlanIssue(
          'localTimeBudget',
          'Travail local chronométré supérieur au repère de 10–15 min de 13.02 ; aucune durée n’a été raccourcie.',
          blocking: false,
        ),
      );
    }
    return SessionPlan(
      mode: mode,
      actions: result,
      issues: issues,
      selections: selections.map((s) => s.toJson()).toList(),
    );
  }
}
