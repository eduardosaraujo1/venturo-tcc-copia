import 'package:flutter/material.dart';
import '../config.dart';
import 'perfil_screen.dart';
import 'package:algumacoisa/cuidador/login_screen.dart';
import 'configuracoes_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MeuPerfilfamiliar extends StatefulWidget {
  const MeuPerfilfamiliar({super.key});

  @override
  State<MeuPerfilfamiliar> createState() => _MeuPerfilfamiliarState();
}

class _MeuPerfilfamiliarState extends State<MeuPerfilfamiliar> {
  Map<String, dynamic> _perfilData = {};
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/familiar/perfil'),
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
        : 'Usuário';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
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
                child: Icon(Icons.error, color: Colors.white, size: 40),
              )
            else
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
                  MaterialPageRoute(builder: (context) => PerfilFamiliar()),
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
                    builder: (context) => ConfiguracoesScreen(),
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
                    backgroundColor: const Color.fromARGB(255, 106, 186, 213),
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
            Icon(icon, color: const Color.fromARGB(255, 106, 186, 213)),
            const SizedBox(width: 20),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
