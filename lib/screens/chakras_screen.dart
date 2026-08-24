import 'package:flutter/material.dart';
import '../data/chakras_data.dart';

class ChakrasScreen extends StatelessWidget {
  const ChakrasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Les 7 chakras")),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const _ChakraSilhouette(),
          const SizedBox(height: 16),
          _CartePratique(
            icone: Icons.park_outlined,
            titre: "Comment t'ancrer",
            couleur: Colors.brown,
            texte: conseilsAncrage,
          ),
          const SizedBox(height: 10),
          _CartePratique(
            icone: Icons.front_hand_outlined,
            titre: "Scanner et harmoniser un chakra",
            couleur: Colors.deepPurple,
            texte: methodeScanEtHarmonisation,
          ),
          const SizedBox(height: 16),
          const Text(
            "Touchez une fiche pour voir sa signification, ses signes de blocage, la prière et l'intention associées.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          for (final chakra in chakras) _ChakraCard(chakra: chakra),
        ],
      ),
    );
  }
}

/// Carte pleine largeur pour les conseils pratiques généraux (ancrage,
/// méthode de scan), avant la liste des fiches par chakra.
class _CartePratique extends StatelessWidget {
  final IconData icone;
  final String titre;
  final Color couleur;
  final String texte;

  const _CartePratique({
    required this.icone,
    required this.titre,
    required this.couleur,
    required this.texte,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: couleur.withOpacity(0.3)),
      ),
      child: ExpansionTile(
        leading: Icon(icone, color: couleur),
        title: Text(titre, style: TextStyle(fontWeight: FontWeight.bold, color: couleur)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(alignment: Alignment.centerLeft, child: Text(texte)),
          ),
        ],
      ),
    );
  }
}

class _ChakraCard extends StatelessWidget {
  final Chakra chakra;
  const _ChakraCard({required this.chakra});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: chakra.couleur.withOpacity(0.35)),
      ),
      child: ExpansionTile(
        leading: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: chakra.couleur,
            boxShadow: [BoxShadow(color: chakra.couleur.withOpacity(0.5), blurRadius: 6)],
          ),
        ),
        title: Text(chakra.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${chakra.nomSanskrit} · ${chakra.emplacement}", style: const TextStyle(fontSize: 12)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (chakra.zonesAssociees.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      const Icon(Icons.accessibility_new, size: 14, color: Colors.black45),
                      for (final zone in chakra.zonesAssociees)
                        Chip(
                          label: Text(zone, style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: chakra.couleur.withOpacity(0.1),
                          side: BorderSide(color: chakra.couleur.withOpacity(0.3)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                _sousTitre("Signification", chakra.couleur),
                Text(chakra.signification),
                const SizedBox(height: 12),
                _sousTitre("Signes de blocage", chakra.couleur),
                Text(chakra.blocages),
                const SizedBox(height: 12),
                _sousTitre("Harmonisation", chakra.couleur),
                Text(chakra.harmonisation),
                const SizedBox(height: 12),
                _sousTitre("Intention (à dire au patient)", chakra.couleur),
                Text(chakra.intention, style: const TextStyle(fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),
                _sousTitre("Prière", chakra.couleur),
                Text(chakra.priere),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sousTitre(String texte, Color couleur) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(
          texte,
          style: TextStyle(fontWeight: FontWeight.w700, color: couleur, fontSize: 13),
        ),
      );
}

/// Silhouette simplifiée avec les 7 points de chakra reliés par un dégradé,
/// dessinée directement (pas d'image externe : évite tout souci de droits
/// et rend net sur n'importe quelle taille d'écran).
class _ChakraSilhouette extends StatelessWidget {
  const _ChakraSilhouette();

  @override
  Widget build(BuildContext context) {
    // Du sommet (Couronne) à la base (Racine) pour l'affichage de haut en bas.
    final ordreAffichage = chakras.reversed.toList();

    return SizedBox(
      height: 300,
      child: Center(
        child: SizedBox(
          width: 120,
          height: 280,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Silhouette (tête + buste), en arrière-plan
              Positioned(
                top: 36,
                child: Container(
                  width: 64,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.13), shape: BoxShape.circle),
                ),
              ),
              // Ligne d'énergie en dégradé arc-en-ciel, reliant les 7 points
              Positioned(
                top: 20,
                bottom: 6,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: ordreAffichage.map((c) => c.couleur).toList(),
                    ),
                  ),
                ),
              ),
              // Les 7 points de chakra
              for (final entry in ordreAffichage.asMap().entries)
                Positioned(
                  top: 12.0 + entry.key * 38.0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: entry.value.couleur,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: entry.value.couleur.withOpacity(0.6), blurRadius: 8, spreadRadius: 1)],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
