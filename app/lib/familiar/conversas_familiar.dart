import 'dart:convert';

import 'package:algumacoisa/familiar/chat_familiar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class ConversasFamiliar extends StatelessWidget {
  const ConversasFamiliar({super.key});

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

  // Função para carregar dados do cuidador
  Future<Map<String, dynamic>> _carregarCuidador() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/perfil'),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Erro API Cuidador: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao carregar cuidador: $e');
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

  // Função para obter a inicial do nome
  String _getInicial(String nome) {
    if (nome.isEmpty ||
        nome == 'Paciente' ||
        nome == 'Familiar' ||
        nome == 'Cuidador') {
      return '?';
    }
    // Remove "Sr." ou "Sra." se existirem e pega a primeira letra do primeiro nome
    final nomeLimpo = nome.replaceAll(
      RegExp(r'^Sr\.\s*|^Sra\.\s*', caseSensitive: false),
      '',
    );
    return nomeLimpo.isNotEmpty ? nomeLimpo[0].toUpperCase() : '?';
  }

  // Função para gerar cor baseada no nome (para o CircleAvatar)
  Color _getCorBaseadaNoNome(String nome) {
    final cores = [
      Color(0xFF6ABAD5), // Azul principal
      Color(0xFF4CAF50), // Verde
      Color(0xFF9C27B0), // Roxo
      Color(0xFFFF9800), // Laranja
      Color(0xFFF44336), // Vermelho
      Color(0xFF2196F3), // Azul
      Color(0xFF009688), // Teal
    ];

    if (nome.isEmpty) return cores[0];

    // Gera um índice baseado no código ASCII do primeiro caractere
    final codigo = nome.codeUnits.reduce((a, b) => a + b);
    return cores[codigo % cores.length];
  }

  Widget _buildTab(IconData icon, String title, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF6ABAD5) : Colors.grey),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF6ABAD5) : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context, {
    required String name,
    required String message,
    required String inicial, // Nova propriedade para a inicial
    required Color corAvatar, // Nova propriedade para a cor do avatar
    required int unreadCount,
    String? lastMessageTime,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatName: name,
              imagePath: '', // Agora não usamos mais imagePath
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: corAvatar,
              radius: 28,
              child: Text(
                inicial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (lastMessageTime != null)
                  Text(
                    lastMessageTime,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                SizedBox(height: 4),
                if (unreadCount > 0)
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Text(
                      unreadCount.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(width: 8),
            Icon(Icons.search, color: const Color.fromARGB(255, 106, 186, 213)),
            SizedBox(width: 8),
            Text('Buscar Conversas', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([
          _carregarCuidador(),
          _carregarPaciente(),
          _carregarFamiliar(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando conversas...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erro ao carregar dados',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Verifique se as APIs estão rodando',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final cuidadorData = snapshot.data?[0] ?? {};
          final pacienteData = snapshot.data?[1] ?? {};
          final familiarData = snapshot.data?[2] ?? {};

          // DEBUG: Mostrar dados recebidos
          print('Dados Cuidador: $cuidadorData');
          print('Dados Paciente: $pacienteData');
          print('Dados Familiar: $familiarData');

          // Extrair nomes das APIs - ajuste os campos conforme sua API
          final cuidadorNome =
              cuidadorData['nome'] ?? cuidadorData['name'] ?? 'Cuidador';
          final pacienteNome =
              pacienteData['nome'] ?? pacienteData['name'] ?? 'Paciente';
          final familiarNome =
              familiarData['nome'] ?? familiarData['name'] ?? 'Familiar';

          // Formatar o nome do paciente
          String formatarNomePaciente(String nome) {
            if (nome == 'Paciente') return nome;
            if (!nome.toLowerCase().startsWith('sr.') &&
                !nome.toLowerCase().startsWith('sra.')) {
              return nome;
            }
            return nome;
          }

          final pacienteNomeFormatado = formatarNomePaciente(pacienteNome);

          // Obter iniciais e cores para cada pessoa
          final familiarInicial = _getInicial(familiarNome);
          final pacienteInicial = _getInicial(pacienteNomeFormatado);
          final cuidadorInicial = _getInicial(cuidadorNome);

          final familiarCor = _getCorBaseadaNoNome(familiarNome);
          final pacienteCor = _getCorBaseadaNoNome(pacienteNomeFormatado);
          final cuidadorCor = _getCorBaseadaNoNome(cuidadorNome);

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTab(Icons.message_outlined, 'conversas', true),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Conversa com o Familiar
                _buildChatTile(
                  context,
                  name: '$familiarNome (Cuidador)',
                  message: 'Ele está bem hoje??',
                  inicial: familiarInicial,
                  corAvatar: familiarCor,
                  unreadCount: 4,
                  lastMessageTime: '10:30',
                ),

                // Conversa com o Paciente
                _buildChatTile(
                  context,
                  name: pacienteNomeFormatado,
                  message: 'Eu estou bem',
                  inicial: pacienteInicial,
                  corAvatar: pacienteCor,
                  unreadCount: 0,
                  lastMessageTime: '09:15',
                ),

                // Conversa com o Cuidador
              ],
            ),
          );
        },
      ),
    );
  }
}
