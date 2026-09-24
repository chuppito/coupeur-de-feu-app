import 'package:flutter/material.dart';

/// Représente une zone cliquable du schéma corporel.
class _BodyZone {
  final String label;
  final Rect rect;
  final bool isCircle;

  const _BodyZone(this.label, this.rect, {this.isCircle = false});
}

/// Dimensions de référence du schéma (coordonnées "design"), redimensionnées
/// automatiquement à la taille disponible.
const double _canvasWidth = 240;
const double _canvasHeight = 400;

/// Zones "communes" : leur position à l'écran ne change pas entre la vue de
/// face et la vue de dos (bras, mains, jambes, pieds, tête), donc elles
/// restent cliquables en permanence, quelle que soit la vue affichée.
///
/// Convention gauche/droite : le côté DROIT du bonhomme est affiché à
/// DROITE de l'écran (et inversement pour la gauche) — c'est-à-dire tel
/// que tu le vois directement à l'écran, sans effet miroir.
const List<_BodyZone> _zonesCommunes = [
  _BodyZone('Tête', Rect.fromLTWH(92, 4, 56, 56), isCircle: true),
  _BodyZone('Oreille gauche', Rect.fromLTWH(78, 22, 18, 20), isCircle: true),
  _BodyZone('Oreille droite', Rect.fromLTWH(144, 22, 18, 20), isCircle: true),
  _BodyZone('Bras gauche', Rect.fromLTWH(52, 66, 30, 116)),
  _BodyZone('Bras droit', Rect.fromLTWH(158, 66, 30, 116)),
  _BodyZone('Main gauche', Rect.fromLTWH(46, 182, 30, 30), isCircle: true),
  _BodyZone('Main droite', Rect.fromLTWH(164, 182, 30, 30), isCircle: true),
  _BodyZone('Hanche gauche', Rect.fromLTWH(90, 188, 30, 18)),
  _BodyZone('Hanche droite', Rect.fromLTWH(120, 188, 30, 18)),
  _BodyZone('Cuisse gauche', Rect.fromLTWH(90, 206, 30, 50)),
  _BodyZone('Cuisse droite', Rect.fromLTWH(120, 206, 30, 50)),
  _BodyZone('Genou gauche', Rect.fromLTWH(90, 256, 30, 20)),
  _BodyZone('Genou droit', Rect.fromLTWH(120, 256, 30, 20)),
  _BodyZone('Tibia gauche', Rect.fromLTWH(90, 276, 30, 56)),
  _BodyZone('Tibia droit', Rect.fromLTWH(120, 276, 30, 56)),
  _BodyZone('Pied gauche', Rect.fromLTWH(82, 332, 38, 26)),
  _BodyZone('Pied droit', Rect.fromLTWH(120, 332, 38, 26)),
];

/// Zones visibles uniquement de face (se superposeraient avec les zones de
/// dos si on les affichait toutes en même temps).
const List<_BodyZone> _zonesFaceSeul = [
  _BodyZone('Torse', Rect.fromLTWH(84, 62, 72, 78)),
  _BodyZone('Abdomen', Rect.fromLTWH(88, 140, 64, 48)),
];

/// Zones visibles uniquement de dos.
const List<_BodyZone> _zonesDosSeul = [
  _BodyZone('Nuque', Rect.fromLTWH(98, 58, 44, 20)),
  _BodyZone('Épaules', Rect.fromLTWH(58, 76, 124, 26)),
  _BodyZone('Dos', Rect.fromLTWH(84, 100, 72, 118)),
];

/// Schéma corporel interactif à deux vues (face / dos) permettant de
/// sélectionner une ou plusieurs zones, y compris un seul côté (bras droit
/// sans le gauche, par ex.). Dessiné entièrement en code (Positioned +
/// InkWell), sans dépendance à un fichier SVG externe.
///
/// Le widget se dimensionne toujours lui-même à partir de la largeur
/// disponible (LayoutBuilder) et clippe son contenu : il ne peut donc
/// jamais déborder de son conteneur, quelle que soit la taille de l'écran.
class InteractiveBody extends StatefulWidget {
  final Set<String> selectedZones;
  final ValueChanged<String> onZoneTap;

  const InteractiveBody({
    super.key,
    required this.selectedZones,
    required this.onZoneTap,
  });

  @override
  State<InteractiveBody> createState() => _InteractiveBodyState();
}

class _InteractiveBodyState extends State<InteractiveBody> {
  bool _vueDeFace = true;

  @override
  Widget build(BuildContext context) {
    final zonesVue = _vueDeFace ? _zonesFaceSeul : _zonesDosSeul;
    final couleurSelection = Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Face'), icon: Icon(Icons.person)),
            ButtonSegment(value: false, label: Text('Dos'), icon: Icon(Icons.person_outline)),
          ],
          selected: {_vueDeFace},
          onSelectionChanged: (s) => setState(() => _vueDeFace = s.first),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            // On calcule une taille qui respecte le ratio du schéma tout en
            // restant strictement à l'intérieur de la largeur disponible et
            // d'une hauteur maximale raisonnable (55% de l'écran), afin que
            // le bonhomme ne puisse jamais dépasser de l'écran.
            final maxWidth = constraints.maxWidth;
            final maxHeightEcran = MediaQuery.of(context).size.height * 0.55;
            double width = maxWidth;
            double height = width * (_canvasHeight / _canvasWidth);
            if (height > maxHeightEcran) {
              height = maxHeightEcran;
              width = height * (_canvasWidth / _canvasHeight);
            }

            return Center(
              child: SizedBox(
                width: width,
                height: height,
                child: ClipRect(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _canvasWidth,
                      height: _canvasHeight,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Zones communes : toujours actives, dans les 2 vues.
                          for (final z in _zonesCommunes)
                            _buildZoneVisual(
                              z,
                              selected: widget.selectedZones.contains(z.label),
                              couleur: couleurSelection,
                              onTap: () => widget.onZoneTap(z.label),
                            ),
                          // Zones spécifiques à la vue affichée (face ou dos).
                          for (final z in zonesVue)
                            _buildZoneVisual(
                              z,
                              selected: widget.selectedZones.contains(z.label),
                              couleur: couleurSelection,
                              onTap: () => widget.onZoneTap(z.label),
                            ),
                          // Repères "Gauche" / "Droite" de part et d'autre du
                          // schéma, pour lever toute ambiguïté visuelle.
                          const Positioned(
                            left: 0,
                            top: 118,
                            width: 46,
                            child: IgnorePointer(
                              child: Text(
                                'GAUCHE',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.black45),
                              ),
                            ),
                          ),
                          const Positioned(
                            right: 0,
                            top: 118,
                            width: 46,
                            child: IgnorePointer(
                              child: Text(
                                'DROITE',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.black45),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildZoneVisual(
    _BodyZone z, {
    required bool selected,
    required Color couleur,
    required VoidCallback onTap,
  }) {
    final couleurRemplissage =
        selected ? couleur.withValues(alpha: 0.75) : couleur.withValues(alpha: 0.28);

    final forme = DecoratedBox(
      decoration: BoxDecoration(
        color: couleurRemplissage,
        shape: z.isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: z.isCircle ? null : BorderRadius.circular(10),
        border: selected
            ? Border.all(color: couleur, width: 2)
            : Border.all(color: Colors.black26, width: 1),
      ),
    );

    return Positioned.fromRect(
      rect: z.rect,
      child: Material(
        color: Colors.transparent,
        shape: z.isCircle
            ? const CircleBorder()
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Tooltip(
          message: z.label,
          child: InkWell(
            customBorder: z.isCircle
                ? const CircleBorder()
                : RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onTap: onTap,
            child: forme,
          ),
        ),
      ),
    );
  }
}
