import 'package:flutter/material.dart';

/// Two distinct manual operations, under one end-of-session heading.
/// Indicative source ranges are not automatic completion deadlines.
class EnergyEndingGuidance extends StatelessWidget {
  const EnergyEndingGuidance({
    super.key,
    required this.circulation,
    required this.instructions,
    required this.validation,
  });

  final bool circulation;
  final Widget instructions;
  final Widget validation;

  static const heading = 'Balayage et équilibrage énergétique';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(heading, style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          circulation
              ? '1/2 · Fiche L — Check-out énergétique 1'
              : '2/2 · Fiche M — Check-out énergétique 2',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(circulation
            ? 'Durée indicative du coffret : environ 5 minutes.'
            : 'Durée indicative du coffret : 30 secondes à 1 minute, pour les deux séries.'),
        const Text('Validez après avoir terminé les gestes ; cette durée reste indicative.'),
        if (circulation) const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Repère de la fiche L : main gauche à 30 cm au-dessus du chakra couronne, '
            'main droite au troisième œil ; inversez si vous êtes gaucher ou selon votre ressenti. '
            'Gardez la couronne comme départ pendant les contrôles successifs.',
          ),
        ),
        const SizedBox(height: 12),
        instructions,
        ExpansionTile(
          title: const Text('Sources de cette technique'),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(circulation
                  ? 'Stéphane Langlade, coffret, fiche L (recto et verso, date non indiquée). '
                    'Circulation : couronne → troisième œil, gorge, cœur, plexus, sacré, racine. '
                    'Fiche M : réaliser ensuite le balayage. Photos consultées le 6 novembre 2026.'
                  : 'Stéphane Langlade, coffret, fiche M (recto et verso, date non indiquée). '
                    'Vidéo M10C1 — Comment procéder : 00:07–00:22 (fin de séance et durée), '
                    '00:41–00:50 (vitesse et hauteur), 01:36–02:01 (répétitions). '
                    'Analyse existante par transcription automatique et images échantillonnées ; '
                    'ordre détaillé des six zones retenu de la fiche M. '
                    'https://enligne.formationmagnetisme.fr/school/course/praticien/lecture/3962181'),
            ),
          ],
        ),
        validation,
      ],
    );
  }
}
