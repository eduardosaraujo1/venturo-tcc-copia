import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart'
    as http; // Importação necessária para requisições HTTP
import 'dart:convert'; // Importação necessária para jsonEncode

// Certifique-se de que o caminho de importação para a próxima tela esteja correto
import 'package:algumacoisa/paciente/comorbidade_paciente.dart';

// --- CONFIGURAÇÃO DA API ---
const String patientBloodTypeApiUrl = '${Config.apiUrl}/api/paciente/sanguineo';

class SanguineoPaciente extends StatefulWidget {
  const SanguineoPaciente({super.key});

  @override
  State<SanguineoPaciente> createState() => _SanguineoPacienteState();
}

class _SanguineoPacienteState extends State<SanguineoPaciente> {
  String? _selectedBloodType;
  String? _selectedRhFactor;
  bool _isLoading = false; // Variável para controlar o estado de carregamento

  // --- FUNÇÃO PARA ENVIAR DADOS PARA A API NODE.JS (POST) ---
  Future<void> sendBloodTypeToApi(String bloodType) async {
    // 1. Log para rastrear no console do Flutter
    print(
      'Enviando tipo sanguíneo: $bloodType para a API: $patientBloodTypeApiUrl',
    );

    final response = await http.post(
      Uri.parse(patientBloodTypeApiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // Envia o tipo sanguíneo completo (ex: A+, O-)
      body: jsonEncode(<String, dynamic>{'tipo_sanguineo': bloodType}),
    );

    // 2. Log da resposta
    print(
      'Resposta da API - Status: ${response.statusCode}, Body: ${response.body}',
    );

    // A API Node.js geralmente retorna 201 (Created) ou 200 (OK)
    if (response.statusCode != 201 && response.statusCode != 200) {
      // Se não for bem-sucedido, lança um erro com detalhes
      throw Exception(
        'Falha no envio de dados. Status: ${response.statusCode}. Detalhe: ${response.body}',
      );
    }
  }
  // --- FIM DA FUNÇÃO DE ENVIO ---

  Widget _buildBloodTypeButton(String type) {
    final isSelected = _selectedBloodType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedBloodType = type;
        });
      },
      child: Container(
        width: 60,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 106, 186, 213).withOpacity(0.2)
              : const Color.fromARGB(255, 106, 186, 213).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          type,
          style: TextStyle(
            color: isSelected
                ? const Color.fromARGB(255, 106, 186, 213)
                : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRhFactorButton(String factor) {
    final isSelected = _selectedRhFactor == factor;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRhFactor = factor;
          });
        },
        child: Container(
          height: 60,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? const Color.fromARGB(255, 106, 186, 213).withOpacity(0.2)
                : const Color.fromARGB(255, 106, 186, 213).withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            factor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? const Color.fromARGB(255, 106, 186, 213)
                  : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  // Verifica se o tipo sanguíneo e o fator Rh foram selecionados
  bool get _isSelectionComplete =>
      _selectedBloodType != null && _selectedRhFactor != null;

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
                'Qual seu tipo sanguíneo?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 106, 186, 213),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBloodTypeButton('A'),
                  _buildBloodTypeButton('B'),
                  _buildBloodTypeButton('AB'),
                  _buildBloodTypeButton('O'),
                ],
              ),
              const SizedBox(height: 80),
              Center(
                child: Text(
                  '${_selectedBloodType ?? ''}${_selectedRhFactor ?? ''}',
                  style: const TextStyle(
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 80),
              Row(
                children: [
                  _buildRhFactorButton('+'),
                  const SizedBox(width: 16),
                  _buildRhFactorButton('-'),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Desabilita o botão se a seleção não estiver completa ou estiver carregando
                  onPressed: (_isSelectionComplete && !_isLoading)
                      ? () async {
                          setState(() {
                            _isLoading = true; // Inicia o carregamento
                          });

                          // Concatena o tipo e o fator Rh (ex: "A" + "+")
                          final String bloodType =
                              _selectedBloodType! + _selectedRhFactor!;

                          try {
                            // 1. Tenta enviar o tipo sanguíneo para o Node.js
                            await sendBloodTypeToApi(bloodType);

                            // 2. Se for bem-sucedido, navega para a próxima tela
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ComorbidadePaciente(),
                                ),
                              );
                            }
                          } catch (e) {
                            // 3. Se falhar, mostra um SnackBar com o erro
                            print('ERRO CAPTURADO: $e');
                            if (mounted) {
                              // Mostra uma mensagem amigável de erro
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Falha ao salvar o tipo sanguíneo. Verifique a conexão com a API.',
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
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 106, 186, 213),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child:
                      _isLoading // Mostra o indicador de progresso ou o texto "Continue"
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
