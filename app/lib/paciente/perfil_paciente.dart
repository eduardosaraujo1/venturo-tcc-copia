import 'dart:convert';

import 'package:algumacoisa/cuidador/login_screen.dart';
import 'package:algumacoisa/paciente/MeuPerfil_paciente.dart';
import 'package:algumacoisa/paciente/configuracoes_screen.dart';
import 'package:algumacoisa/paciente/historicoregistro_paciente.dart';
import 'package:algumacoisa/paciente/home_paciente.dart';
import 'package:algumacoisa/paciente/meucuidador_paciente.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class PerfilPaciente extends StatefulWidget {
  const PerfilPaciente({super.key});

  @override
  State<PerfilPaciente> createState() => _PerfilPacienteState();
}

class _PerfilPacienteState extends State<PerfilPaciente> {
  Map<String, dynamic> _perfilData = {};
  bool _isLoading = true;
  String _errorMessage = '';

  // Cores do tema
  static const Color corPrincipal = Color.fromARGB(255, 106, 186, 213);

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/paciente/perfil'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _perfilData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar perfil: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Erro de conexão: $error';
        _isLoading = false;
      });
    }
  }

  // Função para obter a letra inicial do nome
  String _getInicial(String nome) {
    if (nome.isEmpty) return '?';
    return nome[0].toUpperCase();
  }

  // Função para gerar uma cor baseada na letra inicial
  Color _getAvatarColor(String letra) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];

    if (letra.isEmpty || letra == '?') return Colors.grey;

    final index = letra.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    final nomeCompleto = _perfilData['nome'] ?? '';
    final inicial = _getInicial(nomeCompleto);
    final avatarColor = _getAvatarColor(inicial);
    final nomeExibicao = nomeCompleto.isNotEmpty
        ? nomeCompleto.split(' ').first
        : 'Paciente';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePaciente()),
            );
          },
        ),
        title: const Text('Meu Perfil'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Avatar com loading
            if (_isLoading)
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                child: CircularProgressIndicator(color: Colors.white),
              )
            else if (_errorMessage.isNotEmpty)
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                child: const Icon(Icons.error, color: Colors.white, size: 40),
              )
            else
              Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: avatarColor,
                    child: Text(
                      inicial,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: corPrincipal,
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 10),

            // Nome com loading
            if (_isLoading)
              const Text(
                'Carregando...',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              )
            else if (_errorMessage.isNotEmpty)
              Text(
                'Erro ao carregar',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              )
            else
              Column(
                children: [
                  Text(
                    nomeCompleto.isNotEmpty
                        ? nomeCompleto
                        : 'Nome não informado',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Email (se disponível)
                  if (_perfilData['email'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        _perfilData['email'],
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),

            const SizedBox(height: 30),

            _buildProfileItem(
              context,
              icon: Icons.person_outline,
              label: 'Perfil',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MeuperfilPaciente()),
                );
              },
            ),

            _buildProfileItem(
              context,
              icon: Icons.favorite_border,
              label: 'Meu Cuidador',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MeuCuidador()),
                );
              },
            ),
            _buildProfileItem(
              context,
              icon: Icons.description_outlined,
              label: 'Histórico De Registros',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoricoDeRegistros(),
                  ),
                );
              },
            ),

            _buildProfileItem(
              context,
              icon: Icons.settings_outlined,
              label: 'Configurações',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConfiguracoesPaciente(),
                  ),
                );
              },
            ),
            _buildProfileItem(
              context,
              icon: Icons.logout,
              label: 'Sair',
              onTap: () {
                _showLogoutDialog(context);
              },
            ),

            // Botão para recarregar em caso de erro
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: _carregarPerfil,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: corPrincipal,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tentar Novamente'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair'),
          content: const Text('Você realmente quer sair?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginUnificadoScreen(),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Sim, Sair'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: corPrincipal),
            const SizedBox(width: 20),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
