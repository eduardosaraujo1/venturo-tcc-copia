import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http; // Adicionar o pacote http
import 'dart:convert'; // Necessário para jsonEncode
import 'sanguineo_paciente.dart';

// --- CONFIGURAÇÃO DA API ---
// Use o IP 10.0.2.2 se estiver usando o emulador Android!
// Mude a porta e o endpoint se necessário.
const String patientAgeApiUrl = '${Config.apiUrl}/api/paciente/idade';

class IdadePaciente extends StatefulWidget {
  const IdadePaciente({super.key});

  @override
  State<IdadePaciente> createState() => _IdadePacienteState();
}

class _IdadePacienteState extends State<IdadePaciente> {
  final FixedExtentScrollController _scrollController =
      FixedExtentScrollController(initialItem: 19);
  int _currentAge = 19;
  bool _isLoading = false; // Variável para controlar o estado de carregamento

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        // Atualiza a idade selecionada
        _currentAge = _scrollController.selectedItem;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // --- FUNÇÃO PARA ENVIAR DADOS PARA A API NODE.JS (POST) ---
  Future<void> sendAgeToApi(int age) async {
    // 1. Log para rastrear no console do Flutter
    print('Enviando idade: $age para a API: $patientAgeApiUrl');

    final response = await http.post(
      Uri.parse(patientAgeApiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'idade': age,
        // Você pode adicionar outros dados do paciente aqui, se necessário
      }),
    );

    // 2. Log da resposta
    print(
      'Resposta da API - Status: ${response.statusCode}, Body: ${response.body}',
    );

    if (response.statusCode != 201) {
      // Se não for '201 Created', lança um erro com detalhes
      throw Exception(
        'Falha no envio de dados. Status: ${response.statusCode}. Detalhe: ${response.body}',
      );
    }
  }
  // --- FIM DA FUNÇÃO DE ENVIO ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Qual é a sua idade?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 106, 186, 213),
                ),
              ),
              const SizedBox(height: 50),
              SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  controller: _scrollController,
                  itemExtent: 70,
                  perspective: 0.005,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    // Já atualiza _currentAge no listener do controller
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      final isSelected = index == _currentAge;
                      return Center(
                        child: Text(
                          index.toString(),
                          style: TextStyle(
                            fontSize: isSelected ? 48 : 24,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? const Color.fromARGB(255, 106, 186, 213)
                                : Colors.grey[400],
                          ),
                        ),
                      );
                    },
                    childCount: 100,
                  ),
                ),
              ),
              const SizedBox(height: 100),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // --- MODIFICAÇÃO PRINCIPAL AQUI ---
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true; // Inicia o carregamento
                          });

                          try {
                            // 1. Tenta enviar o dado para o Node.js
                            await sendAgeToApi(_currentAge);

                            // 2. Se for bem-sucedido, navega para a próxima tela
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SanguineoPaciente(),
                                ),
                              );
                            }
                          } catch (e) {
                            // 3. Se falhar, mostra um SnackBar com o erro
                            print('ERRO CAPTURADO: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Falha ao salvar a idade: Tente novamente. Detalhe: ${e.toString()}',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false; // Finaliza o carregamento
                              });
                            }
                          }
                        },
                  // --- FIM DA MODIFICAÇÃO PRINCIPAL ---
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 106, 186, 213),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(color: Colors.white, fontSize: 18),
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
