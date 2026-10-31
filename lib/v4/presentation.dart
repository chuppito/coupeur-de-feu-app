import 'models.dart';

/// Chapters describe consecutive actions only. Presentation never changes the
/// order chosen by the engine, including documented exceptional sequences.
class SessionChapter {
  final SessionPhase phase;
  final List<int> actionIndices;
  const SessionChapter(this.phase, this.actionIndices);
  String get title => phaseTitle(phase);
  int? number(SessionMode mode) => referenceNumber(phase, mode);
}

SessionPhase actionPhase(PlannedAction a) {
  if (a.phase != null) return a.phase!;
  // Compatibility for V0.4 snapshots that predate persisted phase metadata.
  // These are explicit historical action IDs, never inferred from prose.
  if (a.definition.conventionNumber != null ||
      RegExp(r'^cm\d{2}').hasMatch(a.definition.id) ||
      a.definition.id == 'connexion') {
    return SessionPhase.commonIntentions;
  }
  if (a.definition.id == 'supplement') return SessionPhase.specificIntentions;
  return switch (a.definition.kind) {
    ActionKind.accueil => SessionPhase.accueil,
    ActionKind.assessment => SessionPhase.assessment,
    ActionKind.clearance => SessionPhase.clearance,
    ActionKind.prayer => SessionPhase.prayers,
    ActionKind.circulation => SessionPhase.circulation,
    ActionKind.sweep => SessionPhase.sweep,
    ActionKind.debrief => SessionPhase.debrief,
    ActionKind.intention => SessionPhase.specificIntentions,
    ActionKind.preparation => SessionPhase.preparation,
    _ => SessionPhase.localWork,
  };
}

List<SessionChapter> sessionChapters(SessionPlan plan) {
  final chapters = <SessionChapter>[];
  for (var i = 0; i < plan.actions.length; i++) {
    final phase = actionPhase(plan.actions[i]);
    if (chapters.isEmpty || chapters.last.phase != phase) {
      chapters.add(SessionChapter(phase, [i]));
    } else {
      chapters.last.actionIndices.add(i);
    }
  }
  return chapters;
}

String phaseTitle(SessionPhase p) => switch (p) {
      SessionPhase.preparation => 'Préparation du support',
      SessionPhase.accueil => 'Accueil et prise de contact',
      SessionPhase.assessment => 'Bilan énergétique',
      SessionPhase.clearance => 'Dégagement si nécessaire',
      SessionPhase.commonIntentions => 'Les 14 conventions mentales',
      SessionPhase.specificIntentions => 'Conventions supplémentaires',
      SessionPhase.prayers => 'Prières et travaux spécifiques',
      SessionPhase.localWork => 'Passes et impositions',
      SessionPhase.circulation => 'Circulation entre les chakras',
      SessionPhase.sweep => 'Balayage final',
      SessionPhase.debrief => 'Débriefing et enregistrement',
    };
String chapterTitle(SessionChapter c, SessionMode mode) =>
    c.phase == SessionPhase.localWork && mode == SessionMode.distance
        ? 'Travail sur support anatomique'
        : c.title;
int? referenceNumber(SessionPhase p, SessionMode mode) {
  if (p == SessionPhase.preparation) return null;
  const sequence = [
    SessionPhase.accueil,
    SessionPhase.assessment,
    SessionPhase.clearance,
    SessionPhase.commonIntentions,
    SessionPhase.specificIntentions,
    SessionPhase.prayers,
    SessionPhase.localWork,
    SessionPhase.circulation,
    SessionPhase.sweep,
    SessionPhase.debrief
  ];
  final phases = sequence
      .where((x) =>
          mode == SessionMode.presentiel ||
          (x != SessionPhase.circulation && x != SessionPhase.sweep))
      .toList();
  final i = phases.indexOf(p);
  return i < 0 ? null : i + 1;
}

/// Boilerplate review messages remain in provenance, once, rather than flooding
/// the session. Specific unknowns and all blocking conflicts stay available.
List<PlanIssue> previewIssues(SessionPlan p) => p.issues
    .where((i) => i.blocking || !{'review', 'protocolReview'}.contains(i.code))
    .toList();
List<String> documentaryNotes(SessionPlan p) => {
      for (final s in p.selections) ...strings(s['protocolUnknowns']),
      for (final a in p.actions) ...a.definition.unknowns,
      for (final a in p.actions)
        if (a.definition.review == ReviewState.needsReview &&
            a.definition.unknowns.isEmpty)
          '${a.definition.title} : vérification documentaire encore requise, voir les sources de cette consigne.',
      for (final a in p.actions)
        for (final s in a.sources)
          if (s.review == ReviewState.needsReview)
            '${a.definition.title} — source ${s.lesson} à confirmer : ${s.locator}',
    }.toList();
