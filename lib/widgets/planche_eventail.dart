import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dessine un cadran de radiesthésie classique "en éventail" : un
/// demi-cercle divisé en secteurs égaux, un libellé par secteur, dessiné
/// nativement (pas d'image) à partir d'une simple liste ordonnée de
/// libellés.
///
/// Support optionnel d'un anneau extérieur de regroupement (`groupes`),
/// lui-même divisé en parts égales indépendamment du nombre de secteurs
/// fins (ex: 31 jours à l'intérieur, 12 mois à l'extérieur — les deux
/// anneaux n'ont pas besoin de s'aligner exactement).
class PlancheEventail extends StatelessWidget {
  final String titre;
  final List<String> labels;
  final List<String>? groupes;
  final String? attribution;
  final Color couleur;

  const PlancheEventail({
    super.key,
    required this.titre,
    required this.labels,
    this.groupes,
    this.attribution,
    this.couleur = Colors.deepPurple,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final largeur = constraints.maxWidth;
            return SizedBox(
              width: largeur,
              height: largeur * 0.62,
              child: CustomPaint(
                painter: _EventailPainter(
                  nbSecteurs: labels.length,
                  nbGroupes: groupes?.length,
                  couleur: couleur,
                ),
                child: _LabelsEventail(labels: labels, groupes: groupes, couleur: couleur),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          titre,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        if (attribution != null && attribution!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            attribution!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: Colors.black45),
          ),
        ],
      ],
    );
  }
}

/// Dessine l'arc extérieur et les traits séparant chaque secteur (et,
/// s'il y a un anneau de groupes, ses propres divisions indépendantes).
class _EventailPainter extends CustomPainter {
  final int nbSecteurs;
  final int? nbGroupes;
  final Color couleur;
  _EventailPainter({required this.nbSecteurs, required this.nbGroupes, required this.couleur});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height);
    final rayonMax = math.min(size.width / 2, size.height) - 4;
    final aGroupes = nbGroupes != null && nbGroupes! > 0;
    final rayonSecteurs = aGroupes ? rayonMax * 0.78 : rayonMax;

    final traitEpais = Paint()
      ..color = couleur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final traitFin = Paint()
      ..color = couleur.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawArc(Rect.fromCircle(center: centre, radius: rayonMax), math.pi, math.pi, false, traitEpais);

    for (int i = 0; i <= nbSecteurs; i++) {
      final angle = math.pi + (i / nbSecteurs) * math.pi;
      final point = Offset(centre.dx + rayonSecteurs * math.cos(angle), centre.dy + rayonSecteurs * math.sin(angle));
      canvas.drawLine(centre, point, i == 0 || i == nbSecteurs ? traitEpais : traitFin);
    }

    if (aGroupes) {
      canvas.drawArc(Rect.fromCircle(center: centre, radius: rayonSecteurs), math.pi, math.pi, false, traitFin);
      for (int i = 0; i <= nbGroupes!; i++) {
        final angle = math.pi + (i / nbGroupes!) * math.pi;
        final p1 = Offset(centre.dx + rayonSecteurs * math.cos(angle), centre.dy + rayonSecteurs * math.sin(angle));
        final p2 = Offset(centre.dx + rayonMax * math.cos(angle), centre.dy + rayonMax * math.sin(angle));
        canvas.drawLine(p1, p2, traitEpais);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EventailPainter oldDelegate) => true;
}

/// Positionne chaque libellé (secteurs fins + éventuels groupes) autour du
/// cadran, orienté comme un rayon partant du centre.
class _LabelsEventail extends StatelessWidget {
  final List<String> labels;
  final List<String>? groupes;
  final Color couleur;
  const _LabelsEventail({required this.labels, required this.groupes, required this.couleur});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centre = Offset(constraints.maxWidth / 2, constraints.maxHeight);
        final rayonMax = math.min(constraints.maxWidth / 2, constraints.maxHeight) - 4;
        final aGroupes = groupes != null && groupes!.isNotEmpty;
        final rayonSecteurs = aGroupes ? rayonMax * 0.78 : rayonMax;
        final n = labels.length;

        final enfants = <Widget>[
          for (int i = 0; i < n; i++)
            _labelAAngle(
              labels[i],
              math.pi + ((i + 0.5) / n) * math.pi,
              centre,
              rayonSecteurs * 0.6,
              math.min(rayonSecteurs * math.pi / n, 90),
              11,
            ),
        ];

        if (aGroupes) {
          final g = groupes!.length;
          for (int i = 0; i < g; i++) {
            enfants.add(_labelAAngle(
              groupes![i],
              math.pi + ((i + 0.5) / g) * math.pi,
              centre,
              (rayonSecteurs + rayonMax) / 2,
              (rayonMax * math.pi / g).clamp(40.0, 160.0),
              12,
              gras: true,
            ));
          }
        }

        return Stack(children: enfants);
      },
    );
  }

  Widget _labelAAngle(String texte, double angle, Offset centre, double rayonTexte, double largeur, double taillePolice, {bool gras = false}) {
    final point = Offset(centre.dx + rayonTexte * math.cos(angle), centre.dy + rayonTexte * math.sin(angle));
    final rotation = angle - math.pi / 2;

    return Positioned(
      left: point.dx - largeur / 2,
      top: point.dy - 10,
      width: largeur,
      child: Transform.rotate(
        angle: rotation,
        child: Text(
          texte,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: taillePolice,
            color: couleur.withOpacity(gras ? 1 : 0.9),
            fontWeight: gras ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
