import 'dart:convert';

import 'package:crypto/crypto.dart';

typedef Json = Map<String, dynamic>;

enum SessionMode { presentiel, distance }

enum ReviewState { documented, needsReview, conflicting, personal }

enum ActionKind {
  preparation,
  accueil,
  assessment,
  clearance,
  intention,
  prayer,
  rapidPasses,
  slowPasses,
  imposition,
  circulation,
  sweep,
  support,
  debrief,
}

Object? canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((e) => e.toString()).toList()..sort();
    return {for (final k in keys) k: canonical(value[k])};
  }
  if (value is List) return value.map(canonical).toList();
  return value;
}

Object? immutableJson(Object? value) {
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable(
        value.map((k, v) => MapEntry(k.toString(), immutableJson(v))));
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(immutableJson));
  }
  return value;
}

String fingerprint(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(canonical(value)))).toString();
List<String> strings(Object? x) =>
    (x as List? ?? const []).map((e) => e as String).toList();
Json jsonMap(Object? x) => Map<String, dynamic>.from(x as Map);

class SourceRef {
  final String id, lesson, url, locator;
  final ReviewState review;
  const SourceRef({
    required this.id,
    required this.lesson,
    required this.url,
    this.locator = '',
    this.review = ReviewState.documented,
  });
  factory SourceRef.fromJson(Json j) => SourceRef(
        id: j['id'] as String,
        lesson: j['lesson'] as String,
        url: j['url'] as String,
        locator: j['locator'] as String? ?? '',
        review:
            ReviewState.values.byName(j['review'] as String? ?? 'documented'),
      );
  Json toJson() => {
        'id': id,
        'lesson': lesson,
        'url': url,
        'locator': locator,
        'review': review.name,
      };
}

/// Missing and ranged durations never acquire an implicit one-minute timer.
class DurationSpec {
  final int? minSeconds, maxSeconds, chosenSeconds;
  final String precision, origin;
  const DurationSpec({
    this.minSeconds,
    this.maxSeconds,
    this.chosenSeconds,
    this.precision = 'inconnue',
    this.origin = 'source',
  });
  const DurationSpec.exact(int seconds)
      : minSeconds = seconds,
        maxSeconds = seconds,
        chosenSeconds = null,
        precision = 'exacte',
        origin = 'source';
  int? get seconds =>
      chosenSeconds ??
      (minSeconds != null && minSeconds == maxSeconds ? minSeconds : null);
  String get label {
    if (seconds != null) {
      return '${seconds! ~/ 60} min ${seconds! % 60} s${precision == 'environ' ? ' environ' : ''}';
    }
    if (minSeconds != null && maxSeconds != null) {
      return '$minSeconds à $maxSeconds s — à choisir';
    }
    return 'Durée non renseignée — progression manuelle';
  }

  DurationSpec choose(int value) {
    if (value <= 0 ||
        (minSeconds != null && value < minSeconds!) ||
        (maxSeconds != null && value > maxSeconds!)) {
      throw ArgumentError('Durée hors des limites documentées.');
    }
    return DurationSpec(
      minSeconds: minSeconds,
      maxSeconds: maxSeconds,
      chosenSeconds: value,
      precision: precision,
      origin: 'personal',
    );
  }

  factory DurationSpec.fromJson(Json j) => DurationSpec(
        minSeconds: j['minSeconds'] as int?,
        maxSeconds: j['maxSeconds'] as int?,
        chosenSeconds: j['chosenSeconds'] as int?,
        precision: j['precision'] as String? ?? 'inconnue',
        origin: j['origin'] as String? ?? 'source',
      );
  Json toJson() => {
        'minSeconds': minSeconds,
        'maxSeconds': maxSeconds,
        'chosenSeconds': chosenSeconds,
        'precision': precision,
        'origin': origin,
      };
}

class BodyZone {
  final String id, label, side, face;
  const BodyZone({
    required this.id,
    required this.label,
    this.side = 'non renseigné',
    this.face = 'non renseignée',
  });
  String get key => '$id|$side|$face';
  factory BodyZone.fromJson(Json j) => BodyZone(
        id: j['id'] as String,
        label: j['label'] as String,
        side: j['side'] as String? ?? 'non renseigné',
        face: j['face'] as String? ?? 'non renseignée',
      );
  Json toJson() => {'id': id, 'label': label, 'side': side, 'face': face};
}

class GestureSpec {
  final String direction, start, end, hands, position, repetitions, conditions;
  final double? heightCm;
  const GestureSpec({
    this.direction = '',
    this.start = '',
    this.end = '',
    this.hands = '',
    this.position = '',
    this.repetitions = '',
    this.conditions = '',
    this.heightCm,
  });
  factory GestureSpec.fromJson(Json j) => GestureSpec(
        direction: j['direction'] as String? ?? '',
        start: j['start'] as String? ?? '',
        end: j['end'] as String? ?? '',
        hands: j['hands'] as String? ?? '',
        position: j['position'] as String? ?? '',
        repetitions: j['repetitions'] as String? ?? '',
        conditions: j['conditions'] as String? ?? '',
        heightCm: (j['heightCm'] as num?)?.toDouble(),
      );
  Json toJson() => {
        'direction': direction,
        'start': start,
        'end': end,
        'hands': hands,
        'position': position,
        'repetitions': repetitions,
        'conditions': conditions,
        'heightCm': heightCm,
      };
}

class ActionDefinition {
  final String id, title, instruction;
  final ActionKind kind;
  final DurationSpec duration;
  final GestureSpec? gesture;
  final String? prayerId, techniqueId;
  final bool autoAdvance;
  final ReviewState review;
  final List<SourceRef> sources;
  final List<String> unknowns;
  ActionDefinition({
    required this.id,
    required this.title,
    required this.instruction,
    required this.kind,
    this.duration = const DurationSpec(),
    this.gesture,
    this.prayerId,
    this.techniqueId,
    this.autoAdvance = false,
    this.review = ReviewState.documented,
    List<SourceRef> sources = const [],
    List<String> unknowns = const [],
  })  : sources = List.unmodifiable(sources),
        unknowns = List.unmodifiable(unknowns);
  factory ActionDefinition.fromJson(Json j) => ActionDefinition(
        id: j['id'] as String,
        title: j['title'] as String,
        instruction: j['instruction'] as String,
        kind: ActionKind.values.byName(j['kind'] as String),
        duration: DurationSpec.fromJson(jsonMap(j['duration'] ?? {})),
        gesture: j['gesture'] == null
            ? null
            : GestureSpec.fromJson(jsonMap(j['gesture'])),
        prayerId: j['prayerId'] as String?,
        techniqueId: j['techniqueId'] as String?,
        autoAdvance: j['autoAdvance'] as bool? ?? false,
        review:
            ReviewState.values.byName(j['review'] as String? ?? 'documented'),
        sources: (j['sources'] as List? ?? [])
            .map((x) => SourceRef.fromJson(jsonMap(x)))
            .toList(),
        unknowns: strings(j['unknowns']),
      );
  Json toJson() => {
        'id': id,
        'title': title,
        'instruction': instruction,
        'kind': kind.name,
        'duration': duration.toJson(),
        'gesture': gesture?.toJson(),
        'prayerId': prayerId,
        'techniqueId': techniqueId,
        'autoAdvance': autoAdvance,
        'review': review.name,
        'sources': sources.map((s) => s.toJson()).toList(),
        'unknowns': unknowns,
      };
  Json get semanticJson {
    final j = toJson();
    j.remove('sources');
    return j;
  }
}

class ProtocolBlock {
  final String id;
  final String? shareKey, condition;
  final bool optional, repeatPerZone;
  final String target; // none, selected, or fixed (explicit zones).
  final List<BodyZone> fixedZones;
  final Set<SessionMode> modes;
  final List<ActionDefinition> actions;
  ProtocolBlock({
    required this.id,
    required List<ActionDefinition> actions,
    this.shareKey,
    this.condition,
    this.optional = false,
    this.repeatPerZone = false,
    this.target = 'none',
    List<BodyZone> fixedZones = const [],
    Set<SessionMode> modes = const {
      SessionMode.presentiel,
      SessionMode.distance,
    },
  })  : actions = List.unmodifiable(actions),
        fixedZones = List.unmodifiable(fixedZones),
        modes = Set.unmodifiable(modes);
  factory ProtocolBlock.fromJson(Json j) => ProtocolBlock(
        id: j['id'] as String,
        actions: (j['actions'] as List)
            .map((x) => ActionDefinition.fromJson(jsonMap(x)))
            .toList(),
        shareKey: j['shareKey'] as String?,
        condition: j['condition'] as String?,
        optional: j['optional'] as bool? ?? false,
        repeatPerZone: j['repeatPerZone'] as bool? ?? false,
        target: j['target'] as String? ?? 'none',
        fixedZones: (j['fixedZones'] as List? ?? [])
            .map((x) => BodyZone.fromJson(jsonMap(x)))
            .toList(),
        modes: (j['modes'] as List? ?? ['presentiel', 'distance'])
            .map((x) => SessionMode.values.byName(x as String))
            .toSet(),
      );
  Json toJson() => {
        'id': id,
        'shareKey': shareKey,
        'condition': condition,
        'optional': optional,
        'repeatPerZone': repeatPerZone,
        'target': target,
        'fixedZones': fixedZones.map((x) => x.toJson()).toList(),
        'modes': modes.map((x) => x.name).toList()..sort(),
        'actions': actions.map((x) => x.toJson()).toList(),
      };
}

class OrderConstraint {
  final String before, after;
  const OrderConstraint(this.before, this.after);
  factory OrderConstraint.fromJson(Json j) =>
      OrderConstraint(j['before'] as String, j['after'] as String);
  Json toJson() => {'before': before, 'after': after};
}

class ProtocolDefinition {
  final String id, title, category, version;
  final List<String> motifs, unknowns;
  final List<ProtocolBlock> blocks;
  final List<OrderConstraint> constraints;
  final Set<SessionMode> modes;
  ProtocolDefinition({
    required this.id,
    required this.title,
    required this.category,
    this.version = '1',
    List<String> motifs = const [],
    List<String> unknowns = const [],
    required List<ProtocolBlock> blocks,
    List<OrderConstraint> constraints = const [],
    Set<SessionMode> modes = const {
      SessionMode.presentiel,
      SessionMode.distance,
    },
  })  : motifs = List.unmodifiable(motifs),
        unknowns = List.unmodifiable(unknowns),
        blocks = List.unmodifiable(blocks),
        constraints = List.unmodifiable(constraints),
        modes = Set.unmodifiable(modes);
  factory ProtocolDefinition.fromJson(Json j) {
    if (j['schemaVersion'] != 4) {
      throw const FormatException('Version de schéma V4 attendue.');
    }
    return ProtocolDefinition(
      id: j['id'] as String,
      title: j['title'] as String,
      category: j['category'] as String,
      version: j['version'] as String? ?? '1',
      motifs: strings(j['motifs']),
      unknowns: strings(j['unknowns']),
      blocks: (j['blocks'] as List)
          .map((x) => ProtocolBlock.fromJson(jsonMap(x)))
          .toList(),
      constraints: (j['constraints'] as List? ?? [])
          .map((x) => OrderConstraint.fromJson(jsonMap(x)))
          .toList(),
      modes: (j['modes'] as List? ?? ['presentiel', 'distance'])
          .map((x) => SessionMode.values.byName(x as String))
          .toSet(),
    );
  }
  Json toJson() => {
        'schemaVersion': 4,
        'id': id,
        'title': title,
        'category': category,
        'version': version,
        'motifs': motifs,
        'unknowns': unknowns,
        'blocks': blocks.map((x) => x.toJson()).toList(),
        'constraints': constraints.map((x) => x.toJson()).toList(),
        'modes': modes.map((x) => x.name).toList()..sort(),
      };
}

class ProtocolSelection {
  final String id;
  final ProtocolDefinition protocol;
  final List<BodyZone> zones;
  ProtocolSelection({
    required this.id,
    required this.protocol,
    List<BodyZone> zones = const [],
  }) : zones = List.unmodifiable(zones);
  Json toJson() => {
        'id': id,
        'protocolId': protocol.id,
        'version': protocol.version,
        'zones': zones.map((x) => x.toJson()).toList(),
      };
}

class PlanIssue {
  final String code, message;
  final bool blocking;
  final List<String> relatedIds;
  PlanIssue(
    this.code,
    this.message, {
    this.blocking = true,
    List<String> relatedIds = const [],
  }) : relatedIds = List.unmodifiable(relatedIds);
  Json toJson() => {
        'code': code,
        'message': message,
        'blocking': blocking,
        'relatedIds': relatedIds,
      };
}

class PlannedAction {
  final String id;
  final ActionDefinition definition;
  final List<BodyZone> zones;
  final List<String> origins;
  final List<SourceRef> sources;
  final DurationSpec duration;
  PlannedAction({
    required this.id,
    required this.definition,
    required List<BodyZone> zones,
    required List<String> origins,
    required List<SourceRef> sources,
    DurationSpec? duration,
  })  : zones = List.unmodifiable(zones),
        origins = List.unmodifiable(origins),
        sources = List.unmodifiable(sources),
        duration = duration ?? definition.duration;
  PlannedAction chooseDuration(int seconds) => PlannedAction(
        id: id,
        definition: definition,
        zones: zones,
        origins: origins,
        sources: sources,
        duration: duration.choose(seconds),
      );
  Json toJson() => {
        'id': id,
        'definition': definition.toJson(),
        'zones': zones.map((x) => x.toJson()).toList(),
        'origins': origins,
        'sources': sources.map((x) => x.toJson()).toList(),
        'duration': duration.toJson(),
      };
  factory PlannedAction.fromJson(Json j) => PlannedAction(
        id: j['id'] as String,
        definition: ActionDefinition.fromJson(jsonMap(j['definition'])),
        zones: (j['zones'] as List)
            .map((x) => BodyZone.fromJson(jsonMap(x)))
            .toList(),
        origins: strings(j['origins']),
        sources: (j['sources'] as List)
            .map((x) => SourceRef.fromJson(jsonMap(x)))
            .toList(),
        duration: DurationSpec.fromJson(jsonMap(j['duration'])),
      );
}

class SessionPlan {
  static const engineVersion = '4.0.0';
  final SessionMode mode;
  final List<PlannedAction> actions;
  final List<PlanIssue> issues;
  final List<Json> selections;
  SessionPlan({
    required this.mode,
    required List<PlannedAction> actions,
    List<PlanIssue> issues = const [],
    List<Json> selections = const [],
  })  : actions = List.unmodifiable(actions),
        issues = List.unmodifiable(issues),
        selections =
            List.unmodifiable(selections.map((j) => immutableJson(j) as Json));
  bool get canStart => actions.isNotEmpty && !issues.any((x) => x.blocking);
  String get id => fingerprint(toJson());
  int get timedSeconds =>
      actions.fold(0, (n, a) => n + (a.duration.seconds ?? 0));
  bool get hasUntimed => actions.any((a) => a.duration.seconds == null);
  SessionPlan chooseDuration(String actionId, int seconds) {
    if (!actions.any((a) => a.id == actionId)) {
      throw ArgumentError('Action inconnue.');
    }
    return SessionPlan(
      mode: mode,
      actions: actions
          .map((a) => a.id == actionId ? a.chooseDuration(seconds) : a)
          .toList(),
      issues: issues,
      selections: selections,
    );
  }

  Json toJson() => {
        'schemaVersion': 4,
        'engineVersion': engineVersion,
        'mode': mode.name,
        'actions': actions.map((x) => x.toJson()).toList(),
        'issues': issues.map((x) => x.toJson()).toList(),
        'selections': selections,
      };
  factory SessionPlan.fromJson(Json j) {
    if (j['schemaVersion'] != 4 || j['engineVersion'] != engineVersion) {
      throw const FormatException('Version de plan non prise en charge.');
    }
    return SessionPlan(
      mode: SessionMode.values.byName(j['mode'] as String),
      actions: (j['actions'] as List)
          .map((x) => PlannedAction.fromJson(jsonMap(x)))
          .toList(),
      issues: (j['issues'] as List).map((x) {
        final d = jsonMap(x);
        return PlanIssue(
          d['code'] as String,
          d['message'] as String,
          blocking: d['blocking'] as bool,
          relatedIds: strings(d['relatedIds']),
        );
      }).toList(),
      selections: (j['selections'] as List).map(jsonMap).toList(),
    );
  }
}
