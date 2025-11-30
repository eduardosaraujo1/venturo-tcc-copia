import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http; // Adicionar o pacote http
import 'dart:convert'; // Necessário para jsonEncode

// Certifique-se de que o caminho de importação esteja correto no seu projeto
import 'package:algumacoisa/paciente/idade_paciente.dart';

// --- CONFIGURAÇÃO DA API ---
// É uma URL diferente (peso)
const String patientWeightApiUrl = '${Config.apiUrl}/api/paciente/peso';

class PesoPaciente extends StatefulWidget {
  const PesoPaciente({super.key});

  @override
  State<PesoPaciente> createState() => _PesoPacienteState();
}

class _PesoPacienteState extends State<PesoPaciente> {
  // Estado inicial do peso. O slider vai de 30 a 200.
  double _currentWeight = 140.0;
  bool _isLoading = false; // Variável para controlar o estado de carregamento

  // --- FUNÇÃO PARA ENVIAR DADOS PARA A API NODE.JS (POST) ---
  Future<void> sendWeightToApi(double weight) async {
    // 1. Log para rastrear no console do Flutter
    print('Enviando peso: $weight kg para a API: $patientWeightApiUrl');

    final response = await http.post(
      Uri.parse(patientWeightApiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // Passa o peso como um double para o JSON
      body: jsonEncode(<String, dynamic>{
        'peso': weight,
        // Você pode adicionar outros dados do paciente aqui, se necessário
      }),
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
                'Qual é o seu peso?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 106, 186, 213),
                ),
              ),
              const SizedBox(height: 100),
              Center(
                child: Column(
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            // Mostra o peso com zero casas decimais (ou ajuste se precisar de precisão)
                            text: _currentWeight.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 80,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const TextSpan(
                            text: ' Kg',
                            style: TextStyle(fontSize: 24, color: Colors.black),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    SliderTheme(
                      data: SliderThemeData(
                        thumbColor: const Color.fromARGB(255, 106, 186, 213),
                        activeTrackColor: const Color.fromARGB(
                          255,
                          106,
                          186,
                          213,
                        ),
                        inactiveTrackColor: const Color.fromARGB(
                          255,
                          106,
                          186,
                          213,
                        ).withOpacity(0.1),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: _currentWeight,
                        min: 30,
                        max: 200,
                        divisions:
                            170, // 200 - 30 = 170 divisões para passos de 1kg
                        onChanged: (double value) {
                          setState(() {
                            // Arredonda para o número inteiro mais próximo, já que divisions está em 1kg
                            _currentWeight = value.roundToDouble();
                          });
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('30', style: TextStyle(color: Colors.grey[600])),
                        Text('200', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 200,
              ), // Espaçamento para empurrar o botão para baixo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  // Desabilita o botão enquanto carrega
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true; // Inicia o carregamento
                          });

                          try {
                            // 1. Tenta enviar o peso para o Node.js
                            await sendWeightToApi(_currentWeight);

                            // 2. Se for bem-sucedido, navega para a próxima tela (IdadePaciente)
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const IdadePaciente(),
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
                                    'Falha ao salvar o peso. Por favor, verifique sua conexão com a API e tente novamente.',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading =
                                    false; // Finaliza o carregamento, independentemente do sucesso/falha
                              });
                            }
                          }
                        },
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
