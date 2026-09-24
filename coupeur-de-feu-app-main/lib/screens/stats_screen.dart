import 'package:flutter/material.dart';
import '../models/patient_session.dart';
import '../services/history_service.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sessions = HistoryService.getHistory();

    if (sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Statistiques")),
        body: const Center(child: Text("Aucune donnée pour le moment.")),
      );
    }

    final nbPatients = sessions.map((s) => s.nomComplet).toSet().length;
    final nbGueris = sessions.where((s) => s.guerie).length;
    final tauxGuerison = nbGueris / sessions.length;

    // Répartition par pathologie, du plus fréquent au moins fréquent.
    final parMaladie = <String, List<PatientSession>>{};
    for (final s in sessions) {
      parMaladie.putIfAbsent(s.maladie, () => []).add(s);
    }
    final maladiesTriees = parMaladie.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    // Délai moyen de guérison (en jours), sur les séances marquées guéries
    // avec une date de guérison renseignée.
    final delais = sessions
        .where((s) => s.guerie && s.dateGuerison != null)
        .map((s) => s.dateGuerison!.difference(s.date).inDays)
        .toList();
    final delaiMoyen =
        delais.isEmpty ? null : delais.reduce((a, b) => a + b) / delais.length;

    return Scaffold(
      appBar: AppBar(title: const Text("Statistiques")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatCard(
            titre: "Vue d'ensemble",
            enfants: [
              _ligneStat("Total de soins enregistrés", "${sessions.length}"),
              _ligneStat("Patients suivis", "$nbPatients"),
              _ligneStat("Soins marqués guéris", "$nbGueris"),
              _ligneStat("Taux de guérison global",
                  "${(tauxGuerison * 100).round()} %"),
              if (delaiMoyen != null)
                _ligneStat("Délai moyen de guérison",
                    "${delaiMoyen.toStringAsFixed(1)} j"),
            ],
          ),
          const SizedBox(height: 16),
          _StatCard(
            titre: "Répartition par pathologie",
            enfants: [
              for (final entry in maladiesTriees)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(entry.key.isEmpty ? "(non renseigné)" : entry.key)),
                          Text("${entry.value.length}"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value.length / sessions.length,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ligneStat(String label, String valeur) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(valeur, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  final String titre;
  final List<Widget> enfants;
  const _StatCard({required this.titre, required this.enfants});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            ...enfants,
          ],
        ),
      ),
    );
  }
}
