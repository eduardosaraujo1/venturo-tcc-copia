import 'package:algumacoisa/cuidador/login_screen.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Novo: para requisições HTTP
import 'dart:convert'; // Novo: para jsonEncode

// Próxima tela (mantendo a importação original)

// --- CONFIGURAÇÃO DA API ---
const String comorbidadeApiUrl = '${Config.apiUrl}/api/paciente/comorbidade';

class ComorbidadePaciente extends StatefulWidget {
  const ComorbidadePaciente({super.key});

  @override
  State<ComorbidadePaciente> createState() => _ComorbidadePacienteState();
}

class _ComorbidadePacienteState extends State<ComorbidadePaciente> {
  // Controller para capturar o texto digitado
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false; // Estado de carregamento para o botão "Continue"

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // --- FUNÇÃO PARA ENVIAR DADOS PARA A API NODE.JS (POST) ---
  Future<void> sendComorbidadeToApi() async {
    final comorbidadeText = _controller.text.trim();

    // Se o texto estiver vazio, envia uma string vazia.
    // O backend irá tratar isso como "Nenhuma/Não Informado" (como configurado no server.js)
    if (comorbidadeText.isEmpty) {
      print('Comorbidade vazia. Prosseguindo...');
    }

    print(
      'Enviando comorbidade: ${comorbidadeText.isEmpty ? 'Vazia' : comorbidadeText} para a API...',
    );

    final response = await http.post(
      Uri.parse(comorbidadeApiUrl),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      // Envia o texto da comorbidade
      body: jsonEncode(<String, dynamic>{'comorbidade': comorbidadeText}),
    );

    print(
      'Resposta da API - Status: ${response.statusCode}, Body: ${response.body}',
    );

    // Verifica se a requisição foi bem-sucedida
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Falha no envio de dados. Status: ${response.statusCode}. Detalhe: ${response.body}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Removi o MaterialApp daqui, pois esta tela deve ser um Scaffold para navegação
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              // Header com seta de voltar, barra de progresso e botão "Pular"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: LinearProgressIndicator(
                        value: 0.75, // Ajustado para 75%
                        backgroundColor: Colors.grey[300],
                        color: const Color.fromARGB(255, 106, 186, 213),
                        minHeight: 8.0,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  TextButton(
                    // Botão Pular: envia dados (pode ser vazio) e avança
                    onPressed: () async {
                      // Se o usuário pular, tentamos salvar o estado atual (vazio ou preenchido)
                      try {
                        await sendComorbidadeToApi();
                      } catch (e) {
                        print('Erro ao tentar salvar no Pular: $e');
                      } finally {
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginUnificadoScreen(),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text(
                      'Pular',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              // Título
              const Text(
                'Cite se tiver alguma\ncomorbidade ou\ntranstorno:',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 30),
              // Campo de texto
              Expanded(
                child: TextField(
                  controller: _controller, // Adiciona o controller
                  maxLines: null, // Permite múltiplas linhas
                  expands: true,
                  decoration: InputDecoration(
                    hintText: 'Descreva:',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFE3F2FD),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Botão "Continue"
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            // 1. Tenta enviar a comorbidade para o Node.js
                            await sendComorbidadeToApi();

                            // 2. Se for bem-sucedido, navega para a próxima tela
                            if (mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LoginUnificadoScreen(),
                                ),
                              );
                            }
                          } catch (e) {
                            // 3. Se falhar, mostra um SnackBar com o erro
                            print('ERRO AO SALVAR COMORBIDADE: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Falha ao salvar comorbidade. Verifique a conexão com a API.',
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 106, 186, 213),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
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
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
