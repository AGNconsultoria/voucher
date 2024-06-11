import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' show AnchorElement;

class GeneratePDF {
  String rede;
  String senha;
  List<String> listaDeVouchers;
  GeneratePDF({
    required this.rede,
    required this.senha,
    required this.listaDeVouchers,
  });

  /// Cria e Imprime a fatura
  generatePDFInvoice() async {
    final pw.Document doc = pw.Document(version: PdfVersion.pdf_1_5, compress: false, pageMode: PdfPageMode.fullscreen);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape.copyWith(
          marginBottom: 1,
          marginLeft: 1,
          marginRight: 1,
          marginTop: 1,
        ),
        build: (context) => [
          _contentTable(context),
        ],
      ),
    );

    if (kIsWeb) {
      AnchorElement(href: 'data:application/octet-stream;charset=utf-16le;base64,${base64.encode(await doc.save() as List<int>)}')
        ..setAttribute('download', 'voucher.pdf')
        ..click();
    } else {
      final String path = (await getApplicationSupportDirectory()).path;
      final String fileName = Platform.isWindows ? '$path\\voucher.pdf' : '$path/voucher.pdf';
      final File file = File(fileName);
      file.writeAsBytesSync(await doc.save(), flush: true);
      var res = await OpenFilex.open(fileName);
      if (res.message != 'done') {
        if (kDebugMode) {
          print("Nenhum APP encontrado para abrir este arquivo。${res.message}");
        }
      }
    }
  }

  pw.Widget _contentTable(pw.Context context) {
    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.black,
        width: 1,
      ),
      tableWidth: pw.TableWidth.min,
      children: [
        for (int i = 0; i < listaDeVouchers.length; i++) // Ajuste o número de iterações conforme necessário
          pw.TableRow(
            children: [
              for (int j = 0; j < 6; j++) // Cria 6 colunas
                pw.Padding(
                  padding: const pw.EdgeInsets.all(5),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          titulo("Rede:"),
                          corpo(rede),
                        ],
                      ),
                      pw.Row(
                        children: [
                          titulo("Senha:"),
                          corpo(senha),
                        ],
                      ),
                      pw.Row(
                        children: [
                          titulo("Voucher:"),
                          corpo(listaDeVouchers[i]),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
      ],
    );
  }

  titulo(nome) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(right: 2),
      child: pw.Text(
        nome,
        style: const pw.TextStyle(
          fontSize: 10,
        ),
      ),
    );
  }

  corpo(nome) {
    return pw.Text(
      nome,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 9.5,
      ),
    );
  }
}
