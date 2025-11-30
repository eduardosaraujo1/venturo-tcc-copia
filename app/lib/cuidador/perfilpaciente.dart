import 'package:flutter/material.dart';
import '../config.dart';
import 'dart:convert'; // Para decodificar a resposta JSON
import 'package:http/http.dart'
    as http; // Adicionar esta biblioteca no pubspec.yaml
import 'perfil_screen.dart';
import 'configuracoes_screen.dart';
import 'politica_privacidade_screen.dart';
import 'historico_registros_screen.dart';
import 'login_screen.dart';

// Modelo de Dados Mínimo para o Perfil
class PacientePerfil {
  final String nome;

  PacientePerfil({required this.nome});

  factory PacientePerfil.fromJson(Map<String, dynamic> json) {
    return PacientePerfil(
      nome:
          json['nome'] ??
          'Nome Desconhecido', // Garante que o campo 'nome' seja usado
    );
  }
}

// O widget precisa ser Stateful para gerenciar o estado da requisição (loading/data)
class MeuPerfilScreen extends StatefulWidget {
  const MeuPerfilScreen({super.key});

  @override
  State<MeuPerfilScreen> createState() => _MeuPerfilScreenState();
}

class _MeuPerfilScreenState extends State<MeuPerfilScreen> {
  // Future que armazena o resultado da requisição HTTP
  late Future<PacientePerfil> _perfilFuture;

  // URL da API. Use o IP especial 10.0.2.2 para emuladores Android

  final String apiUrl = '${Config.apiUrl}/api/pacientes/perfil';

  @override
  void initState() {
    super.initState();
    _perfilFuture = _fetchProfileData();
  }

  // Função para buscar os dados do perfil na API
  Future<PacientePerfil> _fetchProfileData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        // Sucesso: Decodifica o JSON e retorna o objeto Perfil
        final data = json.decode(response.body);
        return PacientePerfil.fromJson(data);
      } else {
        // Erro na API (400, 404, 500 etc.)
        throw Exception(
          'Falha ao carregar o perfil: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      // Erro de rede ou parse
      print('Erro de requisição: $e');
      throw Exception('Erro de conexão ou servidor: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Meu Perfil'),
        centerTitle: true,
      ),
      body: FutureBuilder<PacientePerfil>(
        future: _perfilFuture,
        builder: (context, snapshot) {
          // 1. Se estiver carregando, mostra um indicador
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // 2. Se houver erro, mostra a mensagem de erro
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro: ${snapshot.error}',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          // 3. Se houver dados, exibe a tela
          if (snapshot.hasData) {
            final perfil = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    // Deixei o asset fixo, mas você pode usar 'perfil.foto_url' aqui se implementado
                    backgroundImage: AssetImage('assets/carolina.png'),
                  ),
                  SizedBox(height: 10),
                  // AQUI está o campo que PUXA o nome do DB
                  Text(
                    perfil.nome,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 30),
                  _buildProfileItem(
                    context,
                    icon: Icons.person_outline,
                    label: 'Perfil',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PerfilScreen()),
                      );
                    },
                  ),
                  _buildProfileItem(
                    context,
                    icon: Icons.lock_outline,
                    label: 'Política de Privacidade',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PoliticaPrivacidadeScreen(),
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
                  _buildProfileItem(
                    context,
                    icon: Icons.assignment_outlined,
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
                ],
              ),
            );
          }

          // Caso padrão (nunca deve acontecer se o código estiver certo)
          return Center(child: Text('Nenhum dado encontrado.'));
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sair'),
          content: Text('você realmente quer sair?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
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
              child: Text('Sim, Sair'),
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
            SizedBox(width: 20),
            Expanded(child: Text(label, style: TextStyle(fontSize: 16))),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
