import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../widgets/interactive_body.dart';
import '../services/magnetisme_library_service.dart';
import 'models.dart';
import 'engine.dart';
import 'runner.dart';
import 'store.dart';
import 'migration.dart';

const traditionalNotice =
    'Méthodes traditionnelles de bien-être. Les observations ne sont pas des diagnostics et ne remplacent pas les soins médicaux.';
String patientLabel(Json p) => '${p['firstName']} ${p['lastName']}'.trim();
void showError(BuildContext context, Object e) => ScaffoldMessenger.of(context)
    .showSnackBar(SnackBar(content: Text(e.toString())));

class V4Workspace extends StatefulWidget {
  final String? firstName, lastName;
  const V4Workspace({super.key, this.firstName, this.lastName});
  @override
  State<V4Workspace> createState() => _V4WorkspaceState();
}

class _V4WorkspaceState extends State<V4Workspace> {
  late final Future<void> ready = V4Store.open();
  String search = '';
  bool library = false;
  Future<void> _patient() async {
    final first = TextEditingController(text: widget.firstName),
        last = TextEditingController(text: widget.lastName);
    final save = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Créer un patient V4'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text(
                      'Chaque fiche possède un identifiant distinct, y compris pour les homonymes. Les données V3 restent conservées.'),
                  TextField(
                      controller: first,
                      decoration: const InputDecoration(labelText: 'Prénom')),
                  TextField(
                      controller: last,
                      decoration: const InputDecoration(labelText: 'Nom'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Annuler')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Créer'))
                ]));
    if (save == true) {
      try {
        await V4Store.createPatient(first.text, last.text);
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
    first.dispose();
    last.dispose();
  }

  Future<void> _transfer(bool importing) async {
    final text = TextEditingController(
        text: importing
            ? ''
            : const JsonEncoder.withIndent('  ').convert(V4Store.exportData()));
    final go = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: Text(
                    importing ? 'Importer une sauvegarde V4' : 'Sauvegarde V4'),
                content: SizedBox(
                    width: 600,
                    child: SingleChildScrollView(
                        child: importing
                            ? TextField(
                                controller: text,
                                minLines: 8,
                                maxLines: 16,
                                decoration: const InputDecoration(
                                    labelText: 'Coller la sauvegarde JSON V4'))
                            : SelectableText(text.text))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Fermer')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(importing
                          ? 'Importer sans écraser'
                          : 'Copier la sauvegarde'))
                ]));
    if (go == true) {
      try {
        if (importing) {
          final n = await V4Store.importData(jsonMap(jsonDecode(text.text)));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$n élément(s) ajouté(s).')));
          }
        } else {
          await Clipboard.setData(ClipboardData(text: text.text));
        }
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
    text.dispose();
  }

  Future<void> _migration() async {
    try {
      final count =
          await LegacyMigration.stage(LegacyMigration.captureOpenV3Boxes());
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (c) => StatefulBuilder(
              builder: (c, refresh) => AlertDialog(
                      title: const Text('Revue des données V3'),
                      content: SizedBox(
                          width: 600,
                          child: ListView(shrinkWrap: true, children: [
                            Text(
                                '$count original(aux) ajouté(s). Les données V3 restent intactes. Associer uniquement les éléments dont vous avez vérifié l’identité ; les fiches personnelles ne sont pas converties automatiquement en protocoles.'),
                            for (final record in LegacyMigration.records())
                              ExpansionTile(
                                  title: Text(
                                      '${record['collection']} — ${record['legacyKey']}'),
                                  subtitle: Text(LegacyMigration.linkedPatient(
                                              record['id'] as String) ==
                                          null
                                      ? 'À vérifier'
                                      : 'Association conservée'),
                                  children: [
                                    SelectableText(
                                        const JsonEncoder.withIndent('  ')
                                            .convert(record['original'])),
                                    DropdownButtonFormField<String>(
                                        initialValue:
                                            LegacyMigration.linkedPatient(
                                                record['id'] as String),
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                            labelText:
                                                'Associer explicitement au patient'),
                                        items: V4Store.patients()
                                            .map((p) => DropdownMenuItem(
                                                value: p['id'] as String,
                                                child: Text(
                                                    '${patientLabel(p)} (${(p['id'] as String).substring(0, 8)})')))
                                            .toList(),
                                        onChanged: LegacyMigration
                                                    .linkedPatient(record['id']
                                                        as String) !=
                                                null
                                            ? null
                                            : (id) async {
                                                if (id == null) return;
                                                try {
                                                  await LegacyMigration.link(
                                                      record['id'] as String,
                                                      id);
                                                  if (c.mounted) refresh(() {});
                                                } catch (e) {
                                                  if (c.mounted) {
                                                    showError(c, e);
                                                  }
                                                }
                                              }),
                                  ])
                          ])),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(c),
                            child: const Text('Fermer'))
                      ])));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
      future: ready,
      builder: (context, state) {
        if (state.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (state.hasError) {
          return Scaffold(
              body: Center(
                  child: Text('Ouverture V4 impossible : ${state.error}')));
        }
        return Scaffold(
            appBar: AppBar(title: const Text('Magnétisme V4'), actions: [
              IconButton(
                  tooltip: library ? 'Patients' : 'Fiches V4',
                  icon: Icon(library ? Icons.people : Icons.menu_book),
                  onPressed: () => setState(() => library = !library)),
              PopupMenuButton<String>(
                  onSelected: (s) => s == 'migration'
                      ? _migration()
                      : _transfer(s == 'import'),
                  itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'migration',
                            child: Text('Préparer la migration V3')),
                        PopupMenuItem(
                            value: 'export', child: Text('Exporter V4')),
                        PopupMenuItem(
                            value: 'import', child: Text('Importer V4'))
                      ])
            ]),
            floatingActionButton: library
                ? null
                : FloatingActionButton.extended(
                    onPressed: _patient,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Nouveau patient')),
            body: library ? _library() : _patients());
      });
  Widget _patients() => ValueListenableBuilder<Box>(
      valueListenable: V4Store.patientsListenable(),
      builder: (_, box, __) => ValueListenableBuilder<Box>(
          valueListenable: V4Store.sessionsListenable(),
          builder: (_, sessions, __) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  children: [
                    const Text(traditionalNotice),
                    const SizedBox(height: 12),
                    TextField(
                        decoration: const InputDecoration(
                            labelText: 'Rechercher un patient',
                            prefixIcon: Icon(Icons.search)),
                        onChanged: (s) => setState(() => search = s)),
                    if (V4Store.patients(search: search).isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                              'Aucun patient V4. Les dossiers V3 restent disponibles dans l’écran précédent.')),
                    ...V4Store.patients(search: search).map((p) => Card(
                            child: ExpansionTile(
                                title: Text(patientLabel(p)),
                                subtitle: Text(
                                    'Identifiant : ${(p['id'] as String).substring(0, 8)}'),
                                children: [
                              FilledButton.icon(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => V4SetupScreen(
                                              patientId: p['id'] as String,
                                              patientName: patientLabel(p)))),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Nouvelle séance V4')),
                              TextButton(
                                  onPressed: () => _rename(p),
                                  child: const Text(
                                      'Modifier le nom sans changer l’historique')),
                              ...V4Store.sessions(p['id'] as String).map((s) =>
                                  ListTile(
                                      leading: Icon(s['completed'] == true
                                          ? Icons.check_circle
                                          : Icons.pause_circle),
                                      title: Text(s['completed'] == true
                                          ? 'Séance terminée'
                                          : 'Séance en pause'),
                                      subtitle: Text(s['updatedAt'] as String),
                                      onTap: () => _resume(s, patientLabel(p))))
                            ])))
                  ])));
  Future<void> _rename(Json p) async {
    final first = TextEditingController(text: p['firstName'] as String),
        last = TextEditingController(text: p['lastName'] as String);
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Modifier le patient V4'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(
                      controller: first,
                      decoration: const InputDecoration(labelText: 'Prénom')),
                  TextField(
                      controller: last,
                      decoration: const InputDecoration(labelText: 'Nom'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Annuler')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Enregistrer'))
                ]));
    if (ok == true) {
      try {
        await V4Store.renamePatient(p['id'] as String, first.text, last.text);
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
    first.dispose();
    last.dispose();
  }

  void _resume(Json s, String name) {
    try {
      final runner = SessionRunner.fromJson(jsonMap(s['runner']));
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => V4PlayerScreen(
                  runner: runner,
                  sessionId: s['id'] as String,
                  patientId: s['patientId'] as String,
                  patientName: name,
                  initialAssessment: jsonMap(s['assessment'] ?? {}),
                  initialNotes: s['notes'] as String? ?? '')));
    } catch (e) {
      showError(context, 'Sauvegarde conservée, reprise impossible : $e');
    }
  }

  Widget _library() => FutureBuilder<List<ProtocolDefinition>>(
      future: V4Store.catalog(),
      builder: (_, state) {
        if (state.hasError) {
          return Center(child: Text('Catalogue invalide : ${state.error}'));
        }
        if (!state.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(padding: const EdgeInsets.all(16), children: [
          const Text(
              'Migration progressive : quatre fiches présentielles et une trame distance. Les autres fiches personnelles restent dans la bibliothèque V3.'),
          ...state.data!.map((p) => Card(
              child: ListTile(
                  title: Text(p.title),
                  subtitle: Text(p.category),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    await editProtocol(context, p);
                    if (mounted) setState(() {});
                  })))
        ]);
      });
}

Future<void> editProtocol(
    BuildContext context, ProtocolDefinition protocol) async {
  final data = jsonMap(jsonDecode(jsonEncode(protocol.toJson())));
  final changed = <String>{};
  final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
              title: Text('Version personnelle — ${protocol.title}'),
              content: SizedBox(
                  width: 640,
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text(
                        'Édition locale V4. Les sources restent référencées ; les modifications sont identifiées comme personnelles. La bibliothèque V3 reste intacte.'),
                    TextFormField(
                        initialValue: data['title'] as String,
                        decoration: const InputDecoration(labelText: 'Titre'),
                        onChanged: (v) => data['title'] = v),
                    for (final raw in data['blocks'] as List) ...[
                      for (final a in jsonMap(raw)['actions'] as List) ...[
                        const SizedBox(height: 12),
                        Text(jsonMap(a)['title'] as String,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        TextFormField(
                            initialValue: jsonMap(a)['instruction'] as String,
                            minLines: 2,
                            maxLines: 6,
                            decoration: const InputDecoration(
                                labelText: 'Consigne personnelle'),
                            onChanged: (v) {
                              (a as Map)['instruction'] = v;
                              changed.add((a['id'] as String));
                            }),
                        TextFormField(
                            initialValue: DurationSpec.fromJson(
                                        jsonMap(jsonMap(a)['duration']))
                                    .seconds
                                    ?.toString() ??
                                '',
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText:
                                    'Durée personnelle en secondes (vide = inconnue)'),
                            onChanged: (v) {
                              final n = int.tryParse(v);
                              (a as Map)['duration'] = {
                                'minSeconds': n,
                                'maxSeconds': n,
                                'precision': v.trim().isEmpty
                                    ? 'inconnue'
                                    : 'choix personnel',
                                'origin': 'personal'
                              };
                              changed.add(a['id'] as String);
                            })
                      ]
                    ]
                  ]))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(c, false),
                    child: const Text('Annuler')),
                FilledButton(
                    onPressed: () => Navigator.pop(c, true),
                    child: const Text('Enregistrer localement'))
              ]));
  if (ok == true) {
    try {
      for (final b in data['blocks'] as List) {
        for (final a in jsonMap(b)['actions'] as List) {
          if (changed.contains(jsonMap(a)['id'])) {
            (a as Map)['review'] = 'personal';
            (a['sources'] as List).add(const SourceRef(
                    id: 'personal-edit',
                    lesson: 'personnel',
                    url: 'personal:local',
                    locator: 'modification locale',
                    review: ReviewState.personal)
                .toJson());
          }
        }
      }
      data['version'] = 'personal-${DateTime.now().toUtc().toIso8601String()}';
      await V4Store.saveLocalProtocol(data);
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }
}

class V4SetupScreen extends StatefulWidget {
  final String patientId, patientName;
  final Future<List<ProtocolDefinition>>? catalog;
  const V4SetupScreen(
      {super.key,
      required this.patientId,
      required this.patientName,
      this.catalog});
  @override
  State<V4SetupScreen> createState() => _V4SetupScreenState();
}

class _V4SetupScreenState extends State<V4SetupScreen> {
  late final Future<List<ProtocolDefinition>> catalog =
      widget.catalog ?? V4Store.catalog();
  SessionMode mode = SessionMode.presentiel;
  final selected = <String>[];
  final zones = <String, List<BodyZone>>{};
  final faces = <String, String>{};
  bool clearance = false;
  SessionPlan? plan;
  void _zone(String protocol, String label) {
    final face = faces[protocol] ?? 'antérieure';
    final side = label.endsWith('gauche')
        ? 'gauche'
        : label.endsWith('droit') || label.endsWith('droite')
            ? 'droite'
            : 'non renseigné';
    final z = BodyZone(id: label, label: label, side: side, face: face);
    setState(() {
      final list = zones.putIfAbsent(protocol, () => []);
      final i = list.indexWhere((x) => x.key == z.key);
      if (i < 0) {
        list.add(z);
      } else {
        list.removeAt(i);
      }
      plan = null;
    });
  }

  void _build(List<ProtocolDefinition> all) {
    setState(() => plan = SessionEngine().build(
        mode: mode,
        selections: selected
            .map((id) => ProtocolSelection(
                id: id,
                protocol: all.firstWhere((p) => p.id == id),
                zones: zones[id] ?? []))
            .toList(),
        enabledOptionalBlocks: clearance ? {'degagement-${mode.name}'} : {}));
  }

  Future<void> _duration(PlannedAction a) async {
    final text = TextEditingController();
    final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
                title: const Text('Choisir la durée personnelle'),
                content: TextField(
                    controller: text,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: a.duration.label)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Annuler')),
                  FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Utiliser cette durée'))
                ]));
    if (ok == true) {
      try {
        final value = int.parse(text.text);
        setState(() => plan = plan!.chooseDuration(a.id, value));
      } catch (e) {
        if (mounted) showError(context, e);
      }
    }
    text.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('Préparer — ${widget.patientName}')),
      body: FutureBuilder<List<ProtocolDefinition>>(
          future: catalog,
          builder: (_, state) {
            if (state.hasError) {
              return Center(
                  child: Text('Catalogue indisponible : ${state.error}'));
            }
            if (!state.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = state.data!;
            return ListView(padding: const EdgeInsets.all(16), children: [
              const Text(traditionalNotice),
              const SizedBox(height: 12),
              SegmentedButton<SessionMode>(
                  segments: const [
                    ButtonSegment(
                        value: SessionMode.presentiel,
                        label: Text('Présentiel')),
                    ButtonSegment(
                        value: SessionMode.distance, label: Text('Distance'))
                  ],
                  selected: {
                    mode
                  },
                  onSelectionChanged: (s) => setState(() {
                        mode = s.first;
                        selected.clear();
                        plan = null;
                      })),
              const SizedBox(height: 12),
              const Text('Fiches — ordre de priorité de sélection'),
              for (final p in all.where((p) => p.modes.contains(mode))) ...[
                CheckboxListTile(
                    title: Text(p.title),
                    subtitle: Text(p.unknowns.join('\n')),
                    value: selected.contains(p.id),
                    onChanged: (v) => setState(() {
                          if (v == true) {
                            selected.add(p.id);
                          } else {
                            selected.remove(p.id);
                          }
                          plan = null;
                        })),
                if (selected.contains(p.id))
                  Card(
                      child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text('Zones — ${p.title}'),
                          subtitle: Text((zones[p.id] ?? [])
                              .map((z) => '${z.label}, ${z.face}')
                              .join(' ; ')),
                          children: [
                        const Padding(
                            padding: EdgeInsets.all(8),
                            child: Text(
                                'Côtés anatomiques du consultant : vue de face en miroir, vue de dos directe.')),
                        InteractiveBody(
                            key: ValueKey(p.id),
                            anatomicalOrientation: true,
                            selectedZones: (zones[p.id] ?? [])
                                .where((z) =>
                                    z.face == (faces[p.id] ?? 'antérieure'))
                                .map((z) => z.label)
                                .toSet(),
                            onViewChanged: (front) => setState(() =>
                                faces[p.id] =
                                    front ? 'antérieure' : 'postérieure'),
                            onZoneTap: (s) => _zone(p.id, s))
                      ]))
              ],
              CheckboxListTile(
                  value: clearance,
                  title: const Text('Inclure le dégagement facultatif'),
                  subtitle: const Text(
                      'Sa variante détaillée reste à vérifier dans le parcours V3/personnel.'),
                  onChanged: (v) => setState(() {
                        clearance = v ?? false;
                        plan = null;
                      })),
              FilledButton.icon(
                  onPressed: selected.isEmpty ? null : () => _build(all),
                  icon: const Icon(Icons.preview),
                  label: const Text('Voir l’aperçu complet')),
              if (plan != null) ...[
                const SizedBox(height: 16),
                Text(
                    'Durées connues : ${plan!.timedSeconds ~/ 60} min${plan!.hasUntimed ? ' + étapes manuelles ou durées à choisir' : ''}'),
                ...plan!.issues.map((i) => ListTile(
                    leading: Icon(i.blocking ? Icons.block : Icons.info_outline,
                        color: i.blocking ? Colors.red : Colors.orange),
                    title: Text(i.message))),
                for (var i = 0; i < plan!.actions.length; i++)
                  Card(
                      child: ExpansionTile(
                          title: Text(
                              '${i + 1}. ${plan!.actions[i].definition.title}'),
                          subtitle: Text(plan!.actions[i].duration.label),
                          children: [
                        actionDetails(plan!.actions[i]),
                        if (plan!.actions[i].duration.seconds == null)
                          TextButton(
                              onPressed: () => _duration(plan!.actions[i]),
                              child: const Text(
                                  'Choisir une durée dans les limites documentées'))
                      ])),
                FilledButton.icon(
                    onPressed: plan!.canStart
                        ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => V4PlayerScreen(
                                    runner: SessionRunner(plan!),
                                    sessionId: newId(),
                                    patientId: widget.patientId,
                                    patientName: widget.patientName)))
                        : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Commencer cette séance'))
              ]
            ]);
          }));
}

Widget actionDetails(PlannedAction a) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SelectableText(a.definition.instruction),
      if (a.zones.isNotEmpty)
        Text(
            'Cibles : ${a.zones.map((z) => '${z.label}, ${z.side}, ${z.face}').join(' ; ')}'),
      Text('Motifs / sélections : ${a.origins.join(', ')}'),
      if (a.definition.gesture != null)
        Text(a.definition.gesture!
            .toJson()
            .entries
            .where((e) => e.value != null && e.value.toString().isNotEmpty)
            .map((e) => '${{
                  'direction': 'Direction',
                  'start': 'Départ',
                  'end': 'Arrivée',
                  'hands': 'Mains',
                  'position': 'Position',
                  'repetitions': 'Répétitions',
                  'conditions': 'Conditions',
                  'heightCm': 'Hauteur en cm'
                }[e.key]} : ${e.value}')
            .join('\n')),
      for (final u in a.definition.unknowns) Text('À vérifier : $u'),
      for (final s in a.sources)
        SelectableText('Source ${s.lesson} — ${s.locator}\n${s.url}')
    ]));

class V4PlayerScreen extends StatefulWidget {
  final SessionRunner runner;
  final Future<void> Function(SessionRunner, String, Json)? persist;
  final Json initialAssessment;
  final String sessionId, patientId, patientName, initialNotes;
  const V4PlayerScreen(
      {super.key,
      required this.runner,
      required this.sessionId,
      required this.patientId,
      required this.patientName,
      this.persist,
      this.initialNotes = '',
      this.initialAssessment = const {}});
  @override
  State<V4PlayerScreen> createState() => _V4PlayerScreenState();
}

class _V4PlayerScreenState extends State<V4PlayerScreen>
    with WidgetsBindingObserver {
  final scroll = ScrollController();
  late final Json assessment =
      jsonMap(jsonDecode(jsonEncode(widget.initialAssessment)));
  late final notes = TextEditingController(text: widget.initialNotes);
  Timer? timer;
  final clock = Stopwatch();
  Duration last = Duration.zero;
  String? error;
  Future<void> writes = Future.value();
  int? savedSecond;
  String? actionId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wake(true);
    clock.start();
    _save();
    timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final now = clock.elapsed;
      final before = widget.runner.current?.id;
      widget.runner.elapse(now - last);
      last = now;
      if (mounted) setState(() {});
      if (savedSecond != widget.runner.remainingSeconds ||
          before != widget.runner.current?.id) {
        savedSecond = widget.runner.remainingSeconds;
        _save();
      }
      if (before != widget.runner.current?.id) _top();
    });
  }

  void _wake(bool on) {
    unawaited((on ? WakelockPlus.enable() : WakelockPlus.disable())
        .catchError((Object e) {
      if (mounted) {
        setState(() => error = 'Maintien de l’écran indisponible : $e');
      }
    }));
  }

  Future<void> _save() {
    final snapshot = widget.runner.toJson(), text = notes.text;
    final assessmentSnapshot = jsonMap(jsonDecode(jsonEncode(assessment)));
    writes = writes.catchError((Object _) {}).then((_) async {
      final copy =
          SessionRunner.fromJson(jsonMap(jsonDecode(jsonEncode(snapshot))));
      if (widget.persist != null) {
        await widget.persist!(copy, text, assessmentSnapshot);
      } else {
        await V4Store.saveSession(
            id: widget.sessionId,
            patientId: widget.patientId,
            runner: SessionRunner.fromJson(
                jsonMap(jsonDecode(jsonEncode(snapshot)))),
            notes: text,
            assessment: assessmentSnapshot);
      }
      if (mounted && error?.startsWith('Sauvegarde non confirmée') == true) {
        setState(() => error = null);
      }
    }).catchError((Object e) {
      widget.runner.pause();
      if (mounted) setState(() => error = 'Sauvegarde non confirmée : $e');
    });
    return writes;
  }

  void _top() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(0);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      widget.runner.pause();
      _save();
    }
    _wake(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    widget.runner.pause();
    _save();
    timer?.cancel();
    clock.stop();
    WidgetsBinding.instance.removeObserver(this);
    _wake(false);
    scroll.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> _prayer(String id) async {
    try {
      final all = await MagnetismeLibraryService.loadAll();
      final matches = all.where((e) => e['id'] == id);
      if (matches.isEmpty) {
        throw StateError('Prière absente : consulter la source personnelle.');
      }
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
                  title: Text(matches.first['titre'] as String),
                  content: SingleChildScrollView(
                      child: SelectableText(
                          MagnetismeLibraryService.personalized(
                              matches.first['contenu'] as String,
                              prenom: widget.patientName,
                              nom: ''))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Fermer'))
                  ]));
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Widget _assessmentForm() {
    Widget text(String id, String label) => TextFormField(
        key: ValueKey(id),
        initialValue: assessment[id]?.toString() ?? '',
        decoration: InputDecoration(labelText: label),
        onChanged: (v) {
          assessment[id] = v;
          _save();
        });
    Widget choice(String id, String label, List<String> values) =>
        DropdownButtonFormField<String>(
            key: ValueKey(id),
            initialValue: values.contains(assessment[id])
                ? assessment[id] as String
                : values.first,
            isExpanded: true,
            decoration: InputDecoration(labelText: label),
            items: values
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) {
              assessment[id] = v;
              _save();
            });
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Observations radiesthésiques personnelles',
          style: TextStyle(fontWeight: FontWeight.bold)),
      text('demande', 'Motifs et symptômes rapportés'),
      text('diagnosticRapporte', 'Diagnostic médical rapporté, si connu'),
      text('vitalite',
          'Vitalité 0–100 selon le cadran (observation personnelle)'),
      text('vibrationPhysique', 'Vibration physique selon le cadran utilisé'),
      for (var i = 2; i <= 7; i++)
        choice('corps$i', 'Corps symbolique $i',
            ['Non renseigné', 'Fluide', 'Saccadé', 'Indéterminé']),
      for (final chakra in [
        'Racine',
        'Sacré',
        'Plexus',
        'Cœur',
        'Gorge',
        'Troisième œil',
        'Couronne'
      ])
        choice('chakra:$chakra', chakra, [
          'Non renseigné',
          'Équilibré',
          'Déficient',
          'Excès',
          'Indéterminé'
        ]),
      const Text(
          'Saisie directe du résultat personnel ; aucune conversion automatique gauche/droite.'),
      for (final part in [
        'Tête et cou',
        'Tronc organes',
        'Tronc osseux',
        'Appareil uro-génital'
      ])
        text('scan:$part', 'Scan — $part'),
      text('sang',
          'Appréciation énergétique du sang (pas une analyse biologique)'),
      text('autres', 'Autres observations personnelles facultatives'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.runner, a = r.current;
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          r.pause();
          await _save();
          if (context.mounted) Navigator.pop(context);
        },
        child: Scaffold(
            appBar: AppBar(title: Text('Séance — ${widget.patientName}')),
            body: ListView(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  if (error != null)
                    MaterialBanner(content: Text(error!), actions: [
                      TextButton(
                          onPressed: () async {
                            await _save();
                          },
                          child: const Text('Réessayer'))
                    ]),
                  if (a == null) ...[
                    const Icon(Icons.check_circle, size: 52),
                    const Text('Séance terminée',
                        style: TextStyle(fontSize: 24)),
                    const Text(
                        'L’instantané et les observations sont conservés.')
                  ] else ...[
                    Text(a.definition.title,
                        key: const ValueKey('v4-current-title'),
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    Text(
                        r.remainingSeconds == null
                            ? a.duration.label
                            : '${r.remainingSeconds! ~/ 60}:${(r.remainingSeconds! % 60).toString().padLeft(2, '0')}',
                        key: const ValueKey('v4-countdown'),
                        style: Theme.of(context).textTheme.displaySmall),
                    Text('Durée de l’étape : ${a.duration.label}'),
                    actionDetails(a),
                    if (a.definition.kind == ActionKind.assessment)
                      _assessmentForm(),
                    if (a.definition.prayerId != null)
                      OutlinedButton(
                          onPressed: () => _prayer(a.definition.prayerId!),
                          child: const Text('Ouvrir ma prière conservée')),
                    Row(children: [
                      Expanded(
                          child: FilledButton.icon(
                              onPressed: () {
                                setState(() => r.paused ? r.play() : r.pause());
                                _save();
                              },
                              icon: Icon(
                                  r.paused ? Icons.play_arrow : Icons.pause),
                              label: Text(r.paused ? 'Reprendre' : 'Pause'))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: OutlinedButton(
                              onPressed: () {
                                setState(r.completeCurrent);
                                _save();
                                _top();
                              },
                              child: const Text('Terminer cette étape')))
                    ]),
                    Text(
                        '${r.completed.length} / ${r.plan.actions.length} actions terminées')
                  ],
                  const SizedBox(height: 24),
                  TextField(
                      controller: notes,
                      minLines: 3,
                      maxLines: 8,
                      decoration: const InputDecoration(
                          labelText: 'Observations personnelles / débriefing'),
                      onChanged: (_) => _save()),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                      onPressed: () async {
                        r.pause();
                        await _save();
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer et mettre en pause')),
                  const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Text(traditionalNotice))
                ])));
  }
}
