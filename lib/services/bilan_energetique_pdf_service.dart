import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class BilanEnergetiquePdfService {
  static Future<File> generate({
    required String prenom,
    required String nom,
    required DateTime date,
    required String vitalite,
    required String vibratoire,
    required Map<String, String> corps,
    required Map<String, String> chakras,
    required String entites,
    required String magieNoire,
    required Map<String, String> teteCou,
    required Map<String, String> troncOrganes,
    required Map<String, String> troncOsseux,
    required Map<String, String> uroGenital,
    required String sang,
    required String notes,
  }) async {
    final pdf = pw.Document();
    final patient = [prenom.trim(), nom.trim()].where((e) => e.isNotEmpty).join(' ');
    final d = date.day.toString().padLeft(2, '0') + '/' +
        date.month.toString().padLeft(2, '0') + '/' +
        date.year.toString();

    final grey = PdfColor.fromInt(0xFFE3E7EA);
    final green = PdfColor.fromInt(0xFF8EBB72);
    final blue = PdfColor.fromInt(0xFF8FC6D0);
    final orange = PdfColor.fromInt(0xFFE1B08D);
    final yellow = PdfColor.fromInt(0xFFD5B75A);
    final teal = PdfColor.fromInt(0xFF8CC9BD);

    pw.Widget text(String value, {bool bold = false, double size = 6.4}) =>
        pw.Text(value, style: pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal));

    pw.Widget cell(String value, {bool bold = false, double size = 6.2, PdfColor? color}) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      color: color,
      child: text(value, bold: bold, size: size),
    );

    pw.Widget section(String title, PdfColor color, List<List<String>> rows, {List<double>? widths}) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(top: 4),
        decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: .5)),
        child: pw.Table(
          columnWidths: widths == null ? null : {
            for (var i = 0; i < widths.length; i++) i: pw.FlexColumnWidth(widths[i]),
          },
          border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: PdfColors.grey500, width: .35)),
          children: [
            pw.TableRow(children: [
              pw.Container(
                color: color,
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: pw.Text(title, style: pw.TextStyle(fontSize: 7.2, fontWeight: pw.FontWeight.bold)),
              ),
              ...List.generate((widths?.length ?? 2) - 1, (_) => pw.Container(color: color, height: 1)),
            ]),
            ...rows.map((r) => pw.TableRow(children: r.map((v) => cell(v)).toList())),
          ],
        ),
      );
    }

    final corpsRows = <List<String>>[
      ['6 corps énergétiques', '2  3  4  5  6  7'],
    ];
    for (final n in ['2', '3', '4', '5', '6', '7']) {
      corpsRows.add(['Corps énergétique ' + n, corps[n] ?? '']);
    }

    final chakraRows = <List<String>>[
      ['Chakra racine (rouge)', chakras['Chakra racine'] ?? '', 'Chakra gorge (bleu)', chakras['Chakra gorge'] ?? ''],
      ['Chakra sacré (orange)', chakras['Chakra sacré'] ?? '', 'Chakra troisième œil (indigo)', chakras['Chakra troisième œil'] ?? ''],
      ['Chakra plexus solaire (jaune)', chakras['Chakra plexus solaire'] ?? '', 'Chakra couronne (violet)', chakras['Chakra couronne'] ?? ''],
      ['Chakra cœur (vert)', chakras['Chakra cœur'] ?? '', '', ''],
    ];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(20, 18, 20, 18),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              color: green,
              padding: const pw.EdgeInsets.symmetric(vertical: 5),
              child: pw.Center(child: pw.Text('BILAN ÉNERGÉTIQUE AU PENDULE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold))),
            ),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey600, width: .5),
              columnWidths: const {0: pw.FlexColumnWidth(1), 1: pw.FlexColumnWidth(3)},
              children: [
                pw.TableRow(children: [cell('Nom, prénom :', bold: true, size: 7), cell(patient)]),
                pw.TableRow(children: [cell('Date :', bold: true, size: 7), cell(d)]),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey600, width: .5),
              columnWidths: const {0: pw.FlexColumnWidth(2.2), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(1.7), 3: pw.FlexColumnWidth(1)},
              children: [
                pw.TableRow(children: [
                  cell('Taux de vitalité / Taux vibratoire', bold: true, color: grey),
                  cell(vitalite + ' / ' + vibratoire),
                  cell('6 corps énergétiques', bold: true, color: grey),
                  cell('2  3  4  5  6  7'),
                ]),
              ],
            ),
            section('CORPS ÉNERGÉTIQUES', green, corpsRows, widths: const [2.5, 1]),
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 4),
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: .5)),
              child: pw.Table(
                border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: PdfColors.grey500, width: .35)),
                columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(2), 3: pw.FlexColumnWidth(1)},
                children: chakraRows.map((r) => pw.TableRow(children: r.map((v) => cell(v)).toList())).toList(),
              ),
            ),
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 4),
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey600, width: .5),
                columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(1), 2: pw.FlexColumnWidth(2), 3: pw.FlexColumnWidth(1)},
                children: [
                  pw.TableRow(children: [
                    cell('Entités bas astral', bold: true, color: grey), cell(entites),
                    cell('Magie noire', bold: true, color: grey), cell(magieNoire),
                  ]),
                ],
              ),
            ),
            section('Tête & cou', blue, _pairRows(teteCou), widths: const [2.4, 1, 2.4, 1]),
            section('Tronc organes', orange, _pairRows(troncOrganes), widths: const [2.4, 1, 2.4, 1]),
            section('Tronc osseux', yellow, _pairRows(troncOsseux), widths: const [2.4, 1, 2.4, 1]),
            section('Appareil uro-génital', teal, _pairRows(uroGenital), widths: const [2.4, 1, 2.4, 1]),
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 4),
              child: pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey600, width: .5),
                columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(1)},
                children: [
                  pw.TableRow(children: [
                    cell('Qualité énergétique du sang', bold: true, color: grey),
                    cell('Mesure de 0 à 100 %'),
                    cell(sang),
                  ]),
                ],
              ),
            ),
            pw.Container(
              margin: const pw.EdgeInsets.only(top: 4),
              height: 72,
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: .5)),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                cell('Notes', bold: true, size: 7),
                pw.Padding(padding: const pw.EdgeInsets.all(4), child: text(notes, size: 6.5)),
              ]),
            ),
          ],
        ),
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final safe = patient.isEmpty ? 'patient' : patient.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final file = File(dir.path + '/bilan_energetique_' + safe + '_' + date.millisecondsSinceEpoch.toString() + '.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static List<List<String>> _pairRows(Map<String, String> values) {
    final entries = values.entries.toList();
    final rows = <List<String>>[];
    for (var i = 0; i < entries.length; i += 2) {
      final left = entries[i];
      final right = i + 1 < entries.length ? entries[i + 1] : const MapEntry('', '');
      rows.add([left.key, left.value, right.key, right.value]);
    }
    return rows;
  }
}
