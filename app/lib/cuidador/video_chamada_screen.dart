import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideoChamadaScreen extends StatelessWidget {
  final String? nomeContato;

  const VideoChamadaScreen({super.key, this.nomeContato});

  // Função para carregar dados do paciente
  Future<Map<String, dynamic>> _carregarPaciente() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/paciente/perfil'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erro API Paciente: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao carregar paciente: $e');
    }
    return {};
  }

  // Função para carregar dados do familiar
  Future<Map<String, dynamic>> _carregarFamiliar() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/familiar/perfil'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erro API Familiar: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao carregar familiar: $e');
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          // Fundo da chamada (pode ser um stream de vídeo real)
          Container(
            color: Colors.black,
            child: Center(
              child: Text(
                '[Stream de vídeo principal do paciente]',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: FutureBuilder(
                future: Future.wait([_carregarPaciente(), _carregarFamiliar()]),
                builder: (context, snapshot) {
                  String nomeExibicao = 'Contato';
                  String tempoChamada = '02:35';

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    nomeExibicao = 'Carregando...';
                  } else if (snapshot.hasError) {
                    nomeExibicao = nomeContato ?? 'Contato';
                  } else if (snapshot.hasData) {
                    final pacienteData = snapshot.data?[0] ?? {};
                    final familiarData = snapshot.data?[1] ?? {};

                    // Extrair nomes das APIs
                    final pacienteNome =
                        pacienteData['nome'] ??
                        pacienteData['name'] ??
                        'Paciente';
                    final familiarNome =
                        familiarData['nome'] ??
                        familiarData['name'] ??
                        'Familiar';

                    // Se um nome foi passado como parâmetro, usa ele
                    if (nomeContato != null) {
                      nomeExibicao = nomeContato!;
                    } else {
                      // Lógica para decidir qual nome mostrar
                      // Remove " (Familiar)" se existir
                      nomeExibicao =
                          pacienteNome; // ou familiarNome, dependendo da lógica
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nomeExibicao,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.0),
                              Text(
                                tempoChamada,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                          // Janela de vídeo pequena (self-view)
                          Container(
                            width: 80.0,
                            height: 100.0,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                'Você',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      // Botões de controle na parte inferior
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: <Widget>[
                            _buildBottomButton(Icons.mic_off, 'Mutar', () {}),
                            _buildBottomButton(
                              Icons.cameraswitch,
                              'Virar',
                              () {},
                            ),
                            _buildBottomButton(Icons.call_end, 'Encerrar', () {
                              Navigator.pop(context);
                            }, isEndCall: true),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isEndCall = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30.0),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isEndCall ? Colors.red : Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28.0),
          ),
        ),
        SizedBox(height: 4.0),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12.0)),
      ],
    );
  }
}
