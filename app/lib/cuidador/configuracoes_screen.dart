import 'package:algumacoisa/cuidador/trocadesenha.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notificacoes_screen.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  void _deletarConta(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Deletar Conta'),
          content: Text(
            'Tem certeza que deseja deletar sua conta? Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _confirmarDelecao(context);
              },
              child: Text('Deletar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmarDelecao(BuildContext context) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Deletando conta..."),
                ],
              ),
            ),
          );
        },
      );

      // Chamar API para deletar conta
      final response = await deletarContaAPI();

      // Fechar loading
      Navigator.of(context).pop();

      if (response['success']) {
        // Conta deletada com sucesso - Navegar direto para login
        _navegarParaLogin(context);
      } else {
        // Erro ao deletar conta
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Erro'),
              content: Text(response['message'] ?? 'Erro ao deletar conta.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Erro'),
            content: Text('Erro de conexão. Tente novamente.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  // Função para navegar para login
  void _navegarParaLogin(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  // Função para chamar a API
  Future<Map<String, dynamic>> deletarContaAPI() async {
    try {
      // Substitua pela URL do seu servidor
      const String baseUrl = Config.apiUrl; // ou seu IP

      // Obter o userId real
      final userId = await _obterUserId();

      if (userId.isEmpty) {
        return {'success': false, 'message': 'Usuário não encontrado'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/delete-account'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'confirmacao': 'CONFIRMAR_DELECAO',
        }),
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ?? 'Conta deletada com sucesso',
        };
      } else {
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Erro ao deletar conta',
        };
      }
    } catch (e) {
      print('Erro na API: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Função para obter o userId
  Future<String> _obterUserId() async {
    try {
      // Por enquanto, retorne um ID fixo para teste
      // Depois implemente com SharedPreferences
      return '1'; // Substitua pelo ID real do usuário logado
    } catch (e) {
      print('Erro ao obter userId: $e');
      return '';
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
        title: Text('Configurações'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            _buildSettingsItem(
              context,
              icon: Icons.notifications_outlined,
              label: 'Notificações',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotificacoesScreen()),
                );
              },
            ),
            _buildSettingsItem(
              context,
              icon: Icons.vpn_key_outlined,
              label: 'Senhas',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Trocadesenha()),
                );
              },
            ),
            _buildSettingsItem(
              context,
              icon: Icons.delete_outline,
              label: 'Deletar Conta',
              onTap: () {
                _deletarConta(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: const Color.fromARGB(255, 25, 182, 210)),
            SizedBox(width: 20),
            Expanded(child: Text(label, style: TextStyle(fontSize: 16))),
            Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
