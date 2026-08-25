import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/cadran.dart';
import '../services/cadran_service.dart';

/// Affiche un cadran en plein écran. L'écran est maintenu allumé tant que
/// cette page est ouverte (WakelockPlus), pour pouvoir travailler au
/// pendule sans que le téléphone ne se verrouille pendant la séance.
class CadranFullscreenScreen extends StatefulWidget {
  final Cadran cadran;
  const CadranFullscreenScreen({super.key, required this.cadran});

  @override
  State<CadranFullscreenScreen> createState() => _CadranFullscreenScreenState();
}

class _CadranFullscreenScreenState extends State<CadranFullscreenScreen> {
  bool _barresVisibles = true;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _barresVisibles
          ? AppBar(
              backgroundColor: Colors.black54,
              elevation: 0,
              title: Text(widget.cadran.titre),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: "Supprimer ce cadran",
                  onPressed: () => _confirmerSuppression(context),
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: () => setState(() => _barresVisibles = !_barresVisibles),
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.file(File(widget.cadran.cheminImage)),
          ),
        ),
      ),
    );
  }

  void _confirmerSuppression(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Supprimer"),
        content: Text("Supprimer le cadran « ${widget.cadran.titre} » ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              await CadranService.delete(widget.cadran);
              if (!context.mounted) return;
              Navigator.pop(context); // ferme le dialogue
              Navigator.pop(context); // ferme l'écran plein écran
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
