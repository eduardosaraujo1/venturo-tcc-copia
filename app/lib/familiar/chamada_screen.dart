import 'package:flutter/material.dart';
import '../config.dart';
import 'video_chamada_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChamadaScreen extends StatelessWidget {
  final String? nomeContato; // Nome passado como parâmetro

  const ChamadaScreen({super.key, this.nomeContato});

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
        Uri.parse('${Config.apiUrl}/api/cuidador/perfil'),
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder(
          future: Future.wait([_carregarPaciente(), _carregarFamiliar()]),
          builder: (context, snapshot) {
            String nomeExibicao = 'Contato';
            String statusChamada = 'Chamando...';

            if (snapshot.connectionState == ConnectionState.waiting) {
              nomeExibicao = 'Carregando...';
              statusChamada = 'Conectando...';
            } else if (snapshot.hasError) {
              nomeExibicao = nomeContato ?? 'Contato';
            } else if (snapshot.hasData) {
              final pacienteData = snapshot.data?[0] ?? {};
              final familiarData = snapshot.data?[1] ?? {};

              // Extrair nomes das APIs
              final pacienteNome =
                  pacienteData['nome'] ?? pacienteData['name'] ?? 'Paciente';
              final familiarNome =
                  familiarData['nome'] ?? familiarData['name'] ?? 'Familiar';

              // Se um nome foi passado como parâmetro, usa ele
              // Caso contrário, decide qual nome mostrar baseado no contexto
              if (nomeContato != null) {
                nomeExibicao = nomeContato!;
              } else {
                // Lógica para decidir qual nome mostrar
                // Por exemplo, se estiver chamando o paciente ou familiar
                nomeExibicao =
                    pacienteNome; // ou familiarNome, dependendo da lógica
              }
            }

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 48.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Nome e status da chamada
                  Column(
                    children: [
                      Text(
                        nomeExibicao,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        statusChamada,
                        style: TextStyle(color: Colors.white70, fontSize: 18.0),
                      ),
                    ],
                  ),
                  // Botões de controle de áudio
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildControlButton(Icons.mic_off, 'mutar', () {}),
                          _buildControlButton(Icons.dialpad, 'keypad', () {}),
                          _buildControlButton(
                            Icons.volume_up,
                            'viva voz',
                            () {},
                          ),
                        ],
                      ),
                      SizedBox(height: 32.0),
                      _buildControlButton(Icons.videocam, 'videochamada', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VideoChamadaScreen(nomeContato: nomeExibicao),
                          ),
                        );
                      }),
                    ],
                  ),
                  // Botão de encerrar chamada
                  FloatingActionButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.call_end,
                      color: Colors.white,
                      size: 36.0,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40.0),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 32.0),
          ),
        ),
        SizedBox(height: 8.0),
        Text(label, style: TextStyle(color: Colors.white, fontSize: 14.0)),
      ],
    );
  }
}
