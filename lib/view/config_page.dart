import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:vouchers/controller/generate_pdf.dart';
import 'package:csv/csv.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final nomedaRede = TextEditingController(text: "");
  final senha = TextEditingController(text: "");
  FilePickerResult arquivoCSV = const FilePickerResult([]);
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: loading
          ? const SizedBox.shrink()
          : FloatingActionButton(
              onPressed: () => floatingActionButton(),
              child: const Icon(
                Icons.save,
              ),
            ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.only(
            top: 25,
            left: 50,
            right: 50,
          ),
          child: Column(
            children: [
              const Text(
                'Geração de vouchers',
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 20,
                ),
                child: TextFormField(
                  controller: nomedaRede,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text(
                      "Nome da rede (SID)",
                    ),
                  ),
                  maxLength: 18,
                  validator: (value) {
                    if (nomedaRede.text.isEmpty) {
                      return "Nome inválida";
                    } else {
                      return null;
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 20,
                ),
                child: TextFormField(
                  controller: senha,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    label: Text(
                      "Senha da rede",
                    ),
                  ),
                  maxLength: 15,
                  validator: (value) {
                    if (senha.text.isEmpty) {
                      return "Senha inválida";
                    } else {
                      return null;
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: 20,
                ),
                child: ElevatedButton.icon(
                  onPressed: () => lerArquivo(),
                  icon: const Icon(Icons.folder_open),
                  label: Center(
                    child: arquivoCSV.count == 0
                        ? const Text(
                            "Escolher os arquivos de voucher",
                          )
                        : Text(
                            "Arquivo: ${arquivoCSV.files.first.name}",
                          ),
                  ),
                ),
              ),
              Visibility(
                visible: loading,
                child: const Padding(
                  padding: EdgeInsets.only(
                    top: 20,
                  ),
                  child: Text(
                    " Processando o arquivo para gerar os vouchers ",
                    style: TextStyle(
                      backgroundColor: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  lerArquivo() async {
    arquivoCSV = (await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      allowMultiple: false,
      withData: true,
      lockParentWindow: true,
    ))!;
    setState(() {});
  }

  floatingActionButton() async {
    if (_formKey.currentState!.validate()) {
      if (arquivoCSV.files.isEmpty) {
        scaffoldMessenger(message: "Arquivo não selecionado", erro: true);
      } else {
        try {
          setState(() {
            loading = true;
          });
          var arquivo = File(arquivoCSV.paths[0].toString()).openRead();
          var csv = await arquivo
              .transform(utf8.decoder)
              .transform(
                const CsvToListConverter(
                  fieldDelimiter: ' ',
                  eol: '\n',
                ),
              )
              .toList();
          if (csv.isNotEmpty && csv.first.toString().contains(";")) {
            // Caso o arquivo tenha editado usuario ele tem de lindo assim
            arquivo = File(arquivoCSV.paths[0].toString()).openRead();
            csv = await arquivo
                .transform(utf8.decoder)
                .transform(
                  const CsvToListConverter(
                    fieldDelimiter: ';',
                  ),
                )
                .toList();
          }
          List<String> listaDeVouchers = [];
          int linhaNumero = 0; // Inicializando o número da linha
          for (var linha in csv) {
            linhaNumero++;
            if (!linha[0].toString().trim().contains("#") || linha[0].toString().trim().contains("#").toString().isEmpty) {
              if (linha[0].toString().trim().length > 18) {
                throw "Erro: voucher muito grande, linha: $linhaNumero maximo: 18";
              }
              if (linha[0].toString().trim().isNotEmpty) {
                listaDeVouchers.add(linha[0].toString().trim());
              }
            }
          }
          if (listaDeVouchers.isNotEmpty) {
            GeneratePDF generatePdf = GeneratePDF(
              rede: nomedaRede.text,
              senha: senha.text,
              listaDeVouchers: listaDeVouchers,
            );
            generatePdf.generatePDFInvoice();

            scaffoldMessenger(message: "Arquivo gerado com sucesso");
            limpar();
          } else {
            scaffoldMessenger(message: "Erro na leitura do arquivo", erro: true);
          }
        } catch (e) {
          scaffoldMessenger(message: e.toString(), erro: true);
        } finally {
          setState(() {
            loading = false;
          });
        }
      }
    }
  }

  scaffoldMessenger({required String message, bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: erro ? Colors.redAccent : Colors.lightGreen,
        content: Center(
          child: Text(
            message,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  limpar() {
    nomedaRede.text = "";
    senha.text = "";
    arquivoCSV = const FilePickerResult([]);
  }
}
