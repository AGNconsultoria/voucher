// ignore_for_file: use_build_context_synchronously
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
          ? const CircularProgressIndicator()
          : FloatingActionButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  if (arquivoCSV.files.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Arquivo selecionado "),
                      ),
                    );
                  } else {
                    try {
                      setState(() {
                        loading = true;
                      });
                      var arquivo = File(arquivoCSV.paths[0].toString()).openRead();
                      var csv = await arquivo
                          .transform(utf8.decoder)
                          .transform(const CsvToListConverter(
                            fieldDelimiter: ' ',
                            eol: '\n',
                          ))
                          .toList();
                      List<String> listaDeVouchers = [];
                      for (var linha in csv) {
                        if (!linha[0].toString().trim().contains("#") || linha[0].toString().trim().contains("#").toString().isEmpty) {
                          if (linha[0].toString().trim().length > 18) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Center(
                                  child: Text("Erro voucher muito grande ${linha.length}"),
                                ),
                              ),
                            );
                            throw Exception("Erro voucher muito grande ${linha.length}");
                          }
                          listaDeVouchers.add(linha[0].toString().trim());
                        }
                      }
                      GeneratePDF generatePdf = GeneratePDF(
                        rede: nomedaRede.text,
                        senha: senha.text,
                        listaDeVouchers: listaDeVouchers,
                      );
                      generatePdf.generatePDFInvoice();
                      nomedaRede.text = "";
                      senha.text = "";
                      arquivoCSV = const FilePickerResult([]);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Center(child: Text("Arquivo gerado com sucesso")),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Center(child: Text("Erro ao gerar vouchers")),
                        ),
                      );
                    } finally {
                      setState(() {
                        loading = false;
                      });
                    }
                  }
                }
              },
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
              const Text('Geração de vouchers', style: TextStyle(fontSize: 20)),
              Padding(
                padding: const EdgeInsets.only(top: 20),
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
                padding: const EdgeInsets.only(top: 20),
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
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    arquivoCSV = (await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['csv'],
                      allowMultiple: false,
                      withData: true,
                      lockParentWindow: true,
                    ))!;
                    setState(() {});
                  },
                  icon: const Icon(Icons.folder_open),
                  label: arquivoCSV.count == 0 ? const Text("Escolher os arquivos de voucher ") : Text("Arquivo selecionado: ${arquivoCSV.files.first.name}"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
