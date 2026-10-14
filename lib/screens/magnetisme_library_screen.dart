import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/magnetisme_library_service.dart';

class MagnetismeLibraryScreen extends StatefulWidget {
  const MagnetismeLibraryScreen({super.key});
  @override
  State<MagnetismeLibraryScreen> createState() => _MagnetismeLibraryScreenState();
}

class _MagnetismeLibraryScreenState extends State<MagnetismeLibraryScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _items = [];

  ({IconData icon, Color color}) _categoryStyle(String category) {
    switch (category) {
      case 'Fiches techniques':
        return (icon: Icons.medical_information_outlined, color: Colors.blue);
      case 'Techniques':
        return (icon: Icons.auto_awesome, color: Colors.deepPurple);
      case 'Prières / formulations':
        return (icon: Icons.volunteer_activism, color: Colors.teal);
      case 'Références':
        return (icon: Icons.menu_book_outlined, color: Colors.indigo);
      default:
        return (icon: Icons.apps_outlined, color: Colors.grey);
    }
  }
  String _category = 'Tout';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final all = await MagnetismeLibraryService.loadAll();
    if (!mounted) return;
    setState(() {
      _items = all;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _visible {
    final q = _search.text.trim().toLowerCase();
    return _items.where((e) {
      final cat = (e['categorie'] ?? 'Références').toString();
      final title = (e['titre'] ?? '').toString();
      final aliases = ((e['aliases'] as List?) ?? const []).join(' ');
      final content = (e['contenu'] ?? '').toString();
      return (_category == 'Tout' || cat == _category) &&
          (q.isEmpty || '$title $aliases $content'.toLowerCase().contains(q));
    }).toList()
      ..sort((a, b) => (a['titre'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['titre'] ?? '').toString().toLowerCase()));
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final explanation = TextEditingController();
    final content = TextEditingController();
    final aliases = TextEditingController();
    String type = 'fiche_technique';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Ajouter à la bibliothèque'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'fiche_technique',
                        child: Text('Fiche technique'),
                      ),
                      DropdownMenuItem(
                        value: 'technique',
                        child: Text('Technique'),
                      ),
                      DropdownMenuItem(
                        value: 'priere',
                        child: Text('Prière / formulation'),
                      ),
                      DropdownMenuItem(
                        value: 'reference',
                        child: Text('Référence'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialog(() => type = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Nom / titre'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: explanation,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Explication'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: aliases,
                    decoration: const InputDecoration(
                      labelText: 'Mots-clés / pathologies (séparés par des virgules)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: content,
                    minLines: 5,
                    maxLines: 14,
                    decoration: const InputDecoration(labelText: 'Contenu / prière'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                ctx,
                title.text.trim().isNotEmpty && content.text.trim().isNotEmpty,
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) {
      title.dispose();
      explanation.dispose();
      content.dispose();
      aliases.dispose();
      return;
    }

    final aliasList = aliases.text
        .split(',')
        .map((x) => x.trim())
        .where((x) => x.isNotEmpty)
        .toList();

    if (!aliasList.contains(title.text.trim())) {
      aliasList.add(title.text.trim());
    }

    await MagnetismeLibraryService.add({
      'id': 'custom-${DateTime.now().microsecondsSinceEpoch}',
      'titre': title.text.trim(),
      'source': 'Ajout manuel',
      'type': type,
      'categorie': type == 'priere'
          ? 'Prières / formulations'
          : type == 'fiche_technique'
              ? 'Fiches techniques'
              : type == 'technique'
                  ? 'Techniques'
                  : 'Références',
      'aliases': aliasList,
      'description': explanation.text.trim(),
      'contenu': content.text.trim(),
    });

    title.dispose();
    explanation.dispose();
    content.dispose();
    aliases.dispose();
    await _load();
  }

  Future<void> _edit(Map<String, dynamic> entry) async {
    final title = TextEditingController(text: (entry['titre'] ?? '').toString());
    final description = TextEditingController(text: (entry['description'] ?? '').toString());
    final content = TextEditingController(text: (entry['contenu'] ?? '').toString());
    final aliases = TextEditingController(
      text: ((entry['aliases'] as List?) ?? const []).join(', '),
    );
    final id = (entry['id'] ?? '').toString();
    final isLocal = MagnetismeLibraryService.hasLocalVersion(id);
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier la fiche sur ce téléphone'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: title, decoration: const InputDecoration(labelText: 'Titre')),
              const SizedBox(height: 10),
              TextField(controller: description, minLines: 2, maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              TextField(controller: aliases,
                decoration: const InputDecoration(labelText: 'Mots-clés séparés par des virgules')),
              const SizedBox(height: 10),
              TextField(controller: content, minLines: 8, maxLines: 20,
                decoration: const InputDecoration(labelText: 'Contenu de la fiche')),
              const SizedBox(height: 10),
              const Text('Enregistré uniquement sur cet appareil. Les modifications locales restent prioritaires après mise à jour de l’application.'),
            ]),
          ),
        ),
        actions: [
          if (isLocal)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'reset'),
              child: const Text('Restaurer la version d’origine'),
            ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, 'save'), child: const Text('Enregistrer')),
        ],
      ),
    );
    if (action == 'save' && title.text.trim().isNotEmpty && content.text.trim().isNotEmpty) {
      await MagnetismeLibraryService.saveLocal({
        ...entry,
        'titre': title.text.trim(),
        'description': description.text.trim(),
        'aliases': aliases.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'contenu': content.text.trim(),
      });
      await _load();
    } else if (action == 'reset') {
      await MagnetismeLibraryService.resetLocal(id);
      await _load();
    }
    title.dispose();
    description.dispose();
    content.dispose();
    aliases.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cats = <String>{
      'Tout',
      ..._items.map((e) => (e['categorie'] ?? 'Références').toString()).where((category) => category != 'Protocoles'),
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque magnétisme'),
        actions: [
          IconButton(
            tooltip: 'Ajouter',
            onPressed: _add,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher une fiche, une prière, une formulation…',
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer la recherche',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              scrollDirection: Axis.horizontal,
              itemCount: cats.length,
              itemBuilder: (_, i) {
                final category = cats[i];
                final style = category == 'Tout'
                    ? (icon: Icons.apps_outlined, color: Colors.grey)
                    : _categoryStyle(category);
                final selected = _category == category;

                return ChoiceChip(
                  avatar: Icon(
                    style.icon,
                    size: 18,
                    color: selected
                        ? style.color
                        : style.color.withValues(alpha: 0.75),
                  ),
                  label: Text(category),
                  selected: selected,
                  backgroundColor: style.color.withValues(alpha: 0.06),
                  selectedColor: style.color.withValues(alpha: 0.16),
                  side: BorderSide(
                    color: style.color.withValues(alpha: selected ? 0.45 : 0.18),
                  ),
                  onSelected: (_) => setState(() => _category = category),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 6),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              itemCount: _visible.length,
              itemBuilder: (_, i) {
                final e = _visible[i];
                final type = (e['type'] ?? 'reference').toString();
                final category = (e['categorie'] ?? 'Références').toString();
                final style = _categoryStyle(category);

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: style.color.withValues(alpha: 0.12),
                      child: Icon(style.icon, size: 20, color: style.color),
                    ),
                    title: Text(
                      (e['titre'] ?? '').toString(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      (e['description'] ?? '').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      tooltip: 'Modifier la fiche',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _edit(e),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _LibraryReader(
                          entry: e,
                          onEdit: () {
                            Navigator.pop(context);
                            _edit(e);
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryReader extends StatelessWidget {
  final Map<String, dynamic> entry;
  final VoidCallback onEdit;

  const _LibraryReader({required this.entry, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final type = (entry['type'] ?? 'reference').toString();
    final explanation = (entry['description'] ?? '').toString().trim();
    final content = (entry['contenu'] ?? '').toString().trim();
    final illustration =
        (entry['illustrationAsset'] ?? '').toString().trim();
    final illustrationBase64 =
        (entry['illustrationBase64'] ?? '').toString().trim();
    final inlineAsset =
        (entry['illustrationInlineAsset'] ?? '').toString().trim();
    final inlineAfter =
        (entry['illustrationInlineAfter'] ?? '').toString().trim();

    final inlineIndex = inlineAfter.isNotEmpty
        ? content.indexOf(inlineAfter)
        : -1;
    final hasInline = inlineAsset.isNotEmpty && inlineIndex >= 0;
    final inlineBefore = hasInline ? content.substring(0, inlineIndex) : content;
    final inlineAfterContent = hasInline
        ? content.substring(inlineIndex)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: Text((entry['titre'] ?? '').toString()),
        actions: [IconButton(
          tooltip: 'Modifier cette fiche',
          icon: const Icon(Icons.edit_outlined),
          onPressed: onEdit,
        )],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
          children: [
            if (illustration.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      illustration,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            if (illustrationBase64.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(illustrationBase64),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            if (illustration.isNotEmpty || illustrationBase64.isNotEmpty)
              const SizedBox(height: 8),
            if (explanation.isNotEmpty)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explication',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        explanation,
                        style: const TextStyle(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type == 'priere'
                          ? 'Prière / formulation'
                          : 'Contenu',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      inlineBefore,
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                    if (hasInline) ...[
                      const SizedBox(height: 18),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: SizedBox(
                            height: 520,
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              panEnabled: true,
                              scaleEnabled: true,
                              child: Image.asset(
                                inlineAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Illustration non disponible pour le moment.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SelectableText(
                        inlineAfterContent,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
