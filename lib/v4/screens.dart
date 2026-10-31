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
import 'presentation.dart';
import '../screens/patients_screen.dart';
import 'package:intl/intl.dart';

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
                  onSelected: (s) => s == 'legacy'
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PatientsScreen()))
                      : s == 'migration'
                          ? _migration()
                          : _transfer(s == 'import'),
                  itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'legacy',
                            child: Text('Parcours et bibliothèque précédents')),
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
                                    '${V4Store.sessions(p['id'] as String).length} séance(s) enregistrée(s)'),
                                children: [
                              FilledButton.icon(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => V4SetupScreen(
                                              patientId: p['id'] as String,
                                              patientName: patientLabel(p)))),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Nouvelle séance')),
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
                                      subtitle: Text(
                                          DateFormat('dd/MM/yyyy à HH:mm')
                                              .format(DateTime.parse(
                                                      s['updatedAt'] as String)
                                                  .toLocal())),
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
              'Fiches utilisables et documents en cours de préparation. Vos versions personnelles sont conservées.'),
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
                              changed.add('${raw['id']}/${a['id']}');
                            }),
                        if (jsonMap(a)['formulation'] != null)
                          TextFormField(
                              initialValue: jsonMap(a)['formulation'] as String,
                              minLines: 2,
                              maxLines: 12,
                              decoration: const InputDecoration(
                                  labelText:
                                      'Formulation / prière personnelle'),
                              onChanged: (v) {
                                (a as Map)['formulation'] = v;
                                changed.add('${raw['id']}/${a['id']}');
                              }),
                        TextFormField(
                            initialValue: DurationSpec.fromJson(
                                        jsonMap(jsonMap(a)['duration']))
                                    .seconds
                                    ?.toString() ??
                                '',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
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
                              changed.add('${raw['id']}/${a['id']}');
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
          if (changed.contains('${b['id']}/${a['id']}')) {
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
  bool clearance = false,
      showIncomplete = false,
      includeMedication = true,
      usePendulum = false;
  int shortIntentSeconds = 20;
  String search = '';
  bool _incomplete(ProtocolDefinition p) => p.blocks.any((b) =>
      b.modes.contains(mode) && !b.optional && b.essentialUnknowns.isNotEmpty);
  Future<void> _zones(ProtocolDefinition p) async {
    final picked = List<BodyZone>.from(zones[p.id] ?? []);
    var face = 'antérieure';
    final done = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (c) => StatefulBuilder(builder: (c, refresh) {
              void toggle(String label) {
                final side = label.endsWith('gauche')
                    ? 'gauche'
                    : label.endsWith('droit') || label.endsWith('droite')
                        ? 'droite'
                        : 'non renseigné';
                final z =
                    BodyZone(id: label, label: label, side: side, face: face);
                refresh(() {
                  final i = picked.indexWhere((x) => x.key == z.key);
                  if (i < 0) {
                    picked.add(z);
                  } else {
                    picked.removeAt(i);
                  }
                });
              }

              return SizedBox(
                  height: MediaQuery.sizeOf(c).height * .92,
                  child: Column(children: [
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Zones — ${p.title}',
                            style: Theme.of(c).textTheme.titleLarge)),
                    Expanded(
                        child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(children: [
                              InteractiveBody(
                                  anatomicalOrientation: true,
                                  selectedZones: picked
                                      .where((z) => z.face == face)
                                      .map((z) => z.label)
                                      .toSet(),
                                  onViewChanged: (front) => refresh(() => face =
                                      front ? 'antérieure' : 'postérieure'),
                                  onZoneTap: toggle),
                              const SizedBox(height: 12),
                              const Text('Choix précis des articulations'),
                              Wrap(spacing: 8, children: [
                                for (final label in [
                                  'Épaule droite',
                                  'Épaule gauche',
                                  'Coude droit',
                                  'Coude gauche',
                                  'Poignet droit',
                                  'Poignet gauche',
                                  'Genou droit',
                                  'Genou gauche',
                                  'Cheville droite',
                                  'Cheville gauche'
                                ])
                                  FilterChip(
                                      key: ValueKey('zone-$label'),
                                      label: Text(label),
                                      selected: picked.any((z) =>
                                          z.label == label && z.face == face),
                                      onSelected: (_) => toggle(label))
                              ]),
                              if (picked.isNotEmpty)
                                Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text(picked
                                        .map((z) => '${z.label} (${z.face})')
                                        .join(' • '))),
                            ]))),
                    SafeArea(
                        top: false,
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                    key: const ValueKey('confirm-zones'),
                                    onPressed: () => Navigator.pop(c, true),
                                    child: Text(
                                        'Valider les zones (${picked.length})')))))
                  ]));
            }));
    if (done == true && mounted) setState(() => zones[p.id] = picked);
  }

  Future<void> _preview(List<ProtocolDefinition> all) async {
    var plan = SessionEngine().build(
        mode: mode,
        selections: selected
            .map((id) => ProtocolSelection(
                id: id,
                protocol: all.firstWhere((p) => p.id == id),
                zones: zones[id] ?? []))
            .toList(),
        enabledOptionalBlocks: clearance ? {'degagement-${mode.name}'} : {},
        facts: {
          'medication': includeMedication,
          'thotPresentiel': usePendulum
        });
    // This choice is shown in preparation and captured in the snapshot. Only
    // documented ranges for the two short sub-intentions are preselected.
    for (final a in plan.actions.where((a) =>
        a.definition.conventionNumber == 9 &&
        a.duration.minSeconds == 15 &&
        a.duration.maxSeconds == 20)) {
      plan = plan.chooseDuration(a.id, shortIntentSeconds);
    }
    if (!mounted) return;
    final done = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
            builder: (_) => V4PreviewScreen(
                plan: plan,
                patientId: widget.patientId,
                patientName: widget.patientName)));
    if (done == true && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ProtocolDefinition>>(
      future: catalog,
      builder: (context, state) {
        final all = state.data ?? <ProtocolDefinition>[];
        final available = all.where((p) => p.modes.contains(mode)).toList();
        final chosen = all.where((p) => selected.contains(p.id)).toList();
        final ready = selected.isNotEmpty &&
            chosen.every((p) =>
                !_incomplete(p) &&
                (!(p.blocks.any((b) =>
                        b.modes.contains(mode) && b.target == 'selected')) ||
                    (zones[p.id]?.isNotEmpty ?? false)));
        return Scaffold(
            appBar: AppBar(title: const Text('Préparer la séance')),
            bottomNavigationBar: SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                        key: const ValueKey('session-preview'),
                        onPressed: ready ? () => _preview(all) : null,
                        icon: const Icon(Icons.preview),
                        label: const Text('Voir l’aperçu de la séance')))),
            body: state.hasError
                ? Center(child: Text('Catalogue indisponible : ${state.error}'))
                : !state.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(padding: const EdgeInsets.all(16), children: [
                        Text(widget.patientName,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        SegmentedButton<SessionMode>(
                            segments: const [
                              ButtonSegment(
                                  value: SessionMode.presentiel,
                                  label: Text('Présentiel')),
                              ButtonSegment(
                                  value: SessionMode.distance,
                                  label: Text('Distance'))
                            ],
                            selected: {
                              mode
                            },
                            onSelectionChanged: (s) => setState(() {
                                  mode = s.first;
                                  selected.removeWhere((id) => !all.any((p) =>
                                      p.id == id && p.modes.contains(mode)));
                                })),
                        const SizedBox(height: 16),
                        const Text('Motifs de la séance',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextField(
                            decoration: const InputDecoration(
                                labelText: 'Rechercher une fiche',
                                prefixIcon: Icon(Icons.search)),
                            onChanged: (v) => setState(() => search = v)),
                        for (final p in available.where((p) =>
                            (showIncomplete || !_incomplete(p)) &&
                            foldFrench(p.title).contains(foldFrench(search))))
                          CheckboxListTile(
                              key: ValueKey('motif-${p.id}'),
                              contentPadding: EdgeInsets.zero,
                              title: Text(p.title),
                              subtitle: _incomplete(p)
                                  ? const Text(
                                      'Fiche incomplète — consultation en bibliothèque')
                                  : null,
                              value: selected.contains(p.id),
                              onChanged: _incomplete(p)
                                  ? null
                                  : (v) => setState(() {
                                        if (v == true) {
                                          selected.add(p.id);
                                        } else {
                                          selected.remove(p.id);
                                        }
                                      })),
                        if (available.any(_incomplete))
                          TextButton(
                              onPressed: () => setState(
                                  () => showIncomplete = !showIncomplete),
                              child: Text(showIncomplete
                                  ? 'Masquer les fiches incomplètes'
                                  : 'Voir les fiches encore incomplètes')),
                        if (chosen.isNotEmpty) ...[
                          const Divider(),
                          const Text('Zones par motif',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          for (final p in chosen)
                            ListTile(
                                key: ValueKey('zones-${p.id}'),
                                contentPadding: EdgeInsets.zero,
                                title: Text(p.title),
                                subtitle: Text((zones[p.id]?.isNotEmpty ??
                                        false)
                                    ? zones[p.id]!
                                        .map((z) => '${z.label} · ${z.face}')
                                        .join('\n')
                                    : 'Choisir au moins une zone'),
                                trailing: const Icon(Icons.edit_location_alt),
                                onTap: () => _zones(p))
                        ],
                        ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: const Text('Options de séance'),
                            children: [
                              CheckboxListTile(
                                  value: clearance,
                                  title: const Text(
                                      'Inclure le dégagement facultatif'),
                                  onChanged: (v) =>
                                      setState(() => clearance = v ?? false)),
                              CheckboxListTile(
                                  value: usePendulum,
                                  title: const Text(
                                      'Complément au Thot documenté'),
                                  subtitle: const Text(
                                      'Entorse : décharge, deux frappes et recharge, entre les rapides et les lentes. Aucun ajout aux autres motifs sans source.'),
                                  onChanged: mode == SessionMode.presentiel
                                      ? (v) => setState(
                                          () => usePendulum = v ?? false)
                                      : null),
                              CheckboxListTile(
                                  value: includeMedication,
                                  title: const Text('Inclure la convention 8'),
                                  subtitle: const Text(
                                      'Peut être omise si aucun traitement médicamenteux n’est rapporté.'),
                                  onChanged: (v) => setState(
                                      () => includeMedication = v ?? true)),
                              DropdownButtonFormField<int>(
                                  initialValue: shortIntentSeconds,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                      labelText:
                                          'Convention 9 : équilibrage et recharge'),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 15,
                                        child: Text(
                                            '15 s chacune — variante vidéo')),
                                    DropdownMenuItem(
                                        value: 20,
                                        child: Text(
                                            '20 s chacune — variante vidéo'))
                                  ],
                                  onChanged: (v) => setState(
                                      () => shortIntentSeconds = v ?? 20)),
                            ]),
                        const SizedBox(height: 16),
                        const Text(traditionalNotice),
                      ]));
      });
}

class V4PreviewScreen extends StatelessWidget {
  final SessionPlan plan;
  final String patientId, patientName;
  const V4PreviewScreen(
      {super.key,
      required this.plan,
      required this.patientId,
      required this.patientName});
  @override
  Widget build(BuildContext context) {
    final chapters = sessionChapters(plan),
        issues = previewIssues(plan),
        notes = documentaryNotes(plan);
    return Scaffold(
        appBar: AppBar(title: const Text('Aperçu de la séance')),
        bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                    key: const ValueKey('session-start'),
                    onPressed: !plan.canStart
                        ? null
                        : () async {
                            final done = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => V4PlayerScreen(
                                        runner: SessionRunner(plan)..play(),
                                        sessionId: newId(),
                                        patientId: patientId,
                                        patientName: patientName)));
                            if (done == true && context.mounted) {
                              Navigator.pop(context, true);
                            }
                          },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Commencer la séance')))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Text(patientName, style: Theme.of(context).textTheme.titleLarge),
          Text(plan.mode == SessionMode.presentiel
              ? 'Présentiel · trame en 10 étapes'
              : 'Distance · trame en 8 étapes'),
          const SizedBox(height: 12),
          Text(
              '${plan.timedSeconds ~/ 60} min chronométrées${plan.hasUntimed ? ' + gestes à votre rythme' : ''}'),
          if (plan.hasUntimed)
            const Text('Les gestes sans durée se valident avec Suivant.'),
          for (final i in issues)
            ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(i.blocking ? Icons.block : Icons.info_outline,
                    color: i.blocking ? Colors.red : null),
                title: Text(i.message)),
          const Divider(),
          for (final c in chapters)
            ExpansionTile(
                key: ValueKey('chapter-${c.phase.name}'),
                tilePadding: EdgeInsets.zero,
                title: Text(
                    '${c.number(plan.mode) == null ? 'Préparation' : '${c.number(plan.mode)}.'} ${chapterTitle(c, plan.mode)}'),
                subtitle: c.phase == SessionPhase.commonIntentions
                    ? const Text('14 conventions, sous-intentions regroupées')
                    : null,
                children: [
                  for (final i in c.actionIndices)
                    ListTile(
                        title: Text(plan.actions[i].definition.title),
                        subtitle: Text(plan.actions[i].duration.seconds == null
                            ? 'Progression manuelle'
                            : plan.actions[i].duration.label))
                ]),
          ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Sources et incertitudes'),
              subtitle: Text(notes.isEmpty
                  ? 'Références documentaires'
                  : '${notes.length} note(s) consultables'),
              children: [
                ...notes.map((n) => ListTile(title: Text(n))),
                for (final c in chapters)
                  for (final i in c.actionIndices)
                    actionDetails(plan.actions[i])
              ]),
          const SizedBox(height: 16),
          const Text(traditionalNotice)
        ]));
  }
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
  final Future<void> Function(bool)? maintainAwake;
  final Json initialAssessment;
  final Duration Function()? elapsed;
  final String sessionId, patientId, patientName, initialNotes;
  const V4PlayerScreen(
      {super.key,
      required this.runner,
      required this.sessionId,
      required this.patientId,
      required this.patientName,
      this.persist,
      this.maintainAwake,
      this.elapsed,
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
  final clock = Stopwatch();
  Duration last = Duration.zero;
  Timer? timer;
  Future<void> writes = Future.value();
  int saveGeneration = 0;
  String? saveError, awakeError;
  bool leaving = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wake(true);
    clock.start();
    _save();
    timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final r = widget.runner,
          before = r.current?.id,
          seconds = r.remainingSeconds;
      final now = widget.elapsed?.call() ?? clock.elapsed;
      r.elapse(now - last);
      last = now;
      if (before != r.current?.id || seconds != r.remainingSeconds) {
        if (mounted) setState(() {});
        _save();
        if (before != r.current?.id) _top();
      }
    });
  }

  void _wake(bool on) {
    final task = widget.maintainAwake?.call(on) ??
        (on ? WakelockPlus.enable() : WakelockPlus.disable());
    unawaited(task.catchError((Object e) {
      if (mounted) {
        setState(() => awakeError = 'Maintien de l’écran indisponible.');
      }
    }));
  }

  Future<bool> _save() async {
    final generation = ++saveGeneration;
    final snapshot = jsonMap(jsonDecode(jsonEncode(widget.runner.toJson()))),
        text = notes.text,
        copyAssessment = jsonMap(jsonDecode(jsonEncode(assessment)));
    var success = true;
    writes = writes.catchError((Object _) {}).then((_) async {
      if (generation != saveGeneration) return;
      final copy = SessionRunner.fromJson(snapshot);
      if (widget.persist != null) {
        await widget.persist!(copy, text, copyAssessment);
      } else {
        await V4Store.saveSession(
            id: widget.sessionId,
            patientId: widget.patientId,
            runner: copy,
            notes: text,
            assessment: copyAssessment);
      }
      if (mounted && saveError != null) setState(() => saveError = null);
    }).catchError((Object e) {
      success = false;
      widget.runner.pause();
      if (mounted) setState(() => saveError = 'Sauvegarde non confirmée : $e');
    });
    await writes;
    return success;
  }

  void _top() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) scroll.jumpTo(0);
    });
  }

  void _next() {
    setState(widget.runner.completeCurrent);
    _save();
    _top();
  }

  void _previous() {
    setState(widget.runner.previous);
    _save();
    _top();
  }

  Future<void> _leave({bool finished = false}) async {
    if (leaving) return;
    setState(() => leaving = true);
    widget.runner.pause();
    FocusScope.of(context).unfocus();
    final ok = await _save();
    await writes;
    if (mounted) {
      if (ok && saveError == null) {
        Navigator.pop(context, finished);
      } else {
        setState(() => leaving = false);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      widget.runner.pause();
      _save();
      if (mounted) setState(() {});
    }
    _wake(state == AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    widget.runner.pause();
    if (!leaving) _save();
    timer?.cancel();
    clock.stop();
    WidgetsBinding.instance.removeObserver(this);
    _wake(false);
    scroll.dispose();
    notes.dispose();
    super.dispose();
  }

  String _personalize(String text) {
    final names = {
      for (final s in widget.runner.plan.selections)
        s['id']: (s['title'] ?? s['protocolId']).toString()
    };
    final motifs = widget.runner.current?.origins
            .map((id) => names[id] ?? id)
            .join(', ') ??
        '';
    return MagnetismeLibraryService.personalized(text,
            prenom: widget.patientName, nom: '', pathologie: motifs)
        .replaceAll(
            RegExp(
                r'\[(?:pr[eé]nom\s*(?:\+|et)?\s*nom|nom\s*(?:et)?\s*pr[eé]nom)\]',
                caseSensitive: false),
            widget.patientName);
  }

  void _sources(PlannedAction a) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => FractionallySizedBox(
          heightFactor: .85,
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sources et notes',
                        style: Theme.of(c).textTheme.titleLarge),
                    actionDetails(a),
                    const Text(traditionalNotice)
                  ]))));
  Widget _notes() => TextField(
      key: const ValueKey('session-notes'),
      controller: notes,
      readOnly: leaving,
      minLines: 4,
      maxLines: 10,
      decoration: const InputDecoration(
          labelText: 'Observations et débriefing',
          hintText: 'Ressenti rapporté, observations, suites convenues…'),
      onChanged: (_) => _save());
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
    final r = widget.runner, a = r.current, chapters = sessionChapters(r.plan);
    SessionChapter? chapter;
    if (a != null) {
      chapter =
          chapters.firstWhere((c) => c.actionIndices.contains(r.currentIndex));
    }
    final number = chapter?.number(r.plan.mode),
        total = r.plan.mode == SessionMode.presentiel ? 10 : 8;
    final names = {
      for (final s in r.plan.selections)
        s['id']: (s['title'] ?? s['protocolId']).toString()
    };
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _leave();
        },
        child: Scaffold(
            appBar: AppBar(
                title: Text(a == null
                    ? 'Fin de séance'
                    : number == null
                        ? 'Préparation du support'
                        : 'Étape $number sur $total'),
                leading: IconButton(
                    tooltip: 'Quitter et enregistrer',
                    onPressed: leaving ? null : () => _leave(),
                    icon: const Icon(Icons.close)),
                actions: [
                  if (a != null)
                    IconButton(
                        tooltip: 'Sources de cette étape',
                        onPressed: () => _sources(a),
                        icon: const Icon(Icons.info_outline))
                ]),
            bottomNavigationBar: SafeArea(
                top: false,
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: a == null
                        ? FilledButton.icon(
                            key: const ValueKey('session-finish'),
                            onPressed:
                                leaving ? null : () => _leave(finished: true),
                            icon: const Icon(Icons.save),
                            label: Text(leaving
                                ? 'Enregistrement…'
                                : 'Enregistrer et revenir au patient'))
                        : Row(children: [
                            Expanded(
                                child: OutlinedButton(
                                    key: const ValueKey('session-previous'),
                                    onPressed: r.canGoBack ? _previous : null,
                                    child: const Text('Précédent'))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: OutlinedButton(
                                    key: const ValueKey('session-pause'),
                                    onPressed: () {
                                      setState(() =>
                                          r.paused ? r.play() : r.pause());
                                      last = widget.elapsed?.call() ??
                                          clock.elapsed;
                                      _save();
                                    },
                                    child: Text(
                                        r.paused ? 'Reprendre' : 'Pause'))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: FilledButton(
                                    key: const ValueKey('session-next'),
                                    onPressed: _next,
                                    child: const Text('Suivant')))
                          ]))),
            body: ListView(
                key: const ValueKey('session-scroll'),
                controller: scroll,
                padding: const EdgeInsets.all(16),
                children: [
                  if (saveError != null)
                    MaterialBanner(content: Text(saveError!), actions: [
                      TextButton(
                          onPressed: _save, child: const Text('Réessayer'))
                    ]),
                  if (awakeError != null)
                    Text(awakeError!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  LinearProgressIndicator(
                      value: r.plan.actions.isEmpty
                          ? 0
                          : r.completed.length / r.plan.actions.length),
                  const SizedBox(height: 8),
                  Text(
                      '${(r.completed.length / r.plan.actions.length * 100).round()} % · ${widget.patientName}'),
                  const SizedBox(height: 16),
                  if (a == null) ...[
                    const Icon(Icons.check_circle_outline, size: 48),
                    const Text('Séance terminée',
                        style: TextStyle(fontSize: 26)),
                    const SizedBox(height: 16),
                    _notes()
                  ] else ...[
                    Text(chapterTitle(chapter!, r.plan.mode),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (a.definition.conventionNumber != null)
                      Text('Convention ${a.definition.conventionNumber} / 14',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold))
                    else if (chapter.actionIndices.length > 1)
                      Text(
                          'Consigne ${chapter.actionIndices.indexOf(r.currentIndex) + 1} / ${chapter.actionIndices.length}'),
                    Text(a.definition.title,
                        key: const ValueKey('v4-current-title'),
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    if (a.zones.isNotEmpty)
                      Text(
                          a.zones
                              .map((z) => '${z.label} · ${z.face}')
                              .join('\n'),
                          key: const ValueKey('session-current-zone'),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (a.origins.length < r.plan.selections.length)
                      Text(a.origins.map((id) => names[id] ?? id).join(' · ')),
                    const SizedBox(height: 12),
                    SelectableText(_personalize(a.definition.instruction),
                        style: const TextStyle(fontSize: 18, height: 1.45)),
                    if (a.definition.gesture != null) ...[
                      const SizedBox(height: 12),
                      Text(
                          a.definition.gesture!
                              .toJson()
                              .entries
                              .where((e) =>
                                  e.value != null &&
                                  e.value.toString().isNotEmpty)
                              .map((e) => '${const {
                                    'direction': 'Sens',
                                    'start': 'Départ',
                                    'end': 'Arrivée',
                                    'hands': 'Mains',
                                    'position': 'Position',
                                    'repetitions': 'Répétitions',
                                    'conditions': 'Conditions',
                                    'heightCm': 'Hauteur (cm)'
                                  }[e.key]} : ${e.value}')
                              .join('\n'),
                          style: const TextStyle(height: 1.5))
                    ],
                    if ((a.definition.formulation ?? '').isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                          a.definition.kind == ActionKind.prayer
                              ? 'Prière de votre bibliothèque'
                              : 'Intention traditionnelle à formuler',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      SelectableText(_personalize(a.definition.formulation!),
                          key: const ValueKey('session-formulation'),
                          style: const TextStyle(fontSize: 19, height: 1.5))
                    ],
                    const SizedBox(height: 20),
                    if (r.remainingSeconds != null) ...[
                      Text(
                          '${r.remainingSeconds! ~/ 60}:${(r.remainingSeconds! % 60).toString().padLeft(2, '0')}',
                          key: const ValueKey('v4-countdown'),
                          style: Theme.of(context).textTheme.displayMedium),
                      Text(!r.requiresManualCompletion
                          ? 'Enchaînement automatique · ${r.paused ? 'en pause' : 'en cours'}'
                          : 'À la fin du repère, validez avec Suivant.')
                    ] else
                      const Text(
                          'À votre rythme\nAppuyez sur Suivant lorsque le geste est terminé.',
                          key: ValueKey('session-manual')),
                    if (a.definition.kind == ActionKind.intention &&
                        a.duration.seconds != null)
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                              'Prolonger manuellement si nécessaire'),
                          value: r.holdingCurrent,
                          onChanged: (v) {
                            setState(() => r.holdCurrent(v));
                            _save();
                          }),
                    if (r.remainingSeconds == 0 && r.holdingCurrent)
                      const Text(
                          'Repère atteint. Continuez à votre rythme, puis validez avec Suivant.'),
                    if (a.definition.kind == ActionKind.assessment) ...[
                      const SizedBox(height: 16),
                      _assessmentForm()
                    ],
                    if (a.definition.kind == ActionKind.accueil) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                          initialValue: assessment['demande']?.toString() ?? '',
                          decoration: const InputDecoration(
                              labelText: 'Demandes et éléments rapportés'),
                          onChanged: (v) {
                            assessment['demande'] = v;
                            _save();
                          })
                    ],
                    if (a.definition.kind == ActionKind.debrief) ...[
                      const SizedBox(height: 16),
                      _notes()
                    ],
                    const SizedBox(height: 24),
                    if (a.definition.unknowns.isNotEmpty)
                      ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Notes propres à cette consigne'),
                          children: [
                            for (final note in a.definition.unknowns) Text(note)
                          ]),
                  ],
                ])));
  }
}
