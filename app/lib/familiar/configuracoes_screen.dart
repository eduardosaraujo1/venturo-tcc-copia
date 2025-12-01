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
          title: const Text('Deletar Conta'),
          content: const Text(
            'Tem certeza que deseja deletar sua conta? Esta ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _confirmarDelecao(context);
              },
              child: const Text('Deletar', style: TextStyle(color: Colors.red)),
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
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
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
      if (context.mounted) Navigator.of(context).pop();

      if (response['success']) {
        // Conta deletada com sucesso - navegar para tela de login
        if (context.mounted) {
          _navegarParaLogin(context);
        }
      } else {
        // Erro ao deletar conta
        if (context.mounted) {
          _mostrarErro(context, response['message']);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        _mostrarErro(context, 'Erro de conexão: $e');
      }
    }
  }

  void _navegarParaLogin(BuildContext context) {
    // Navegar para a tela de login inicial removendo todas as rotas anteriores
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Certifique-se de que esta rota está definida no seu MaterialApp
      (Route<dynamic> route) => false, // Remove todas as rotas da pilha
    );
  }

  void _mostrarErro(BuildContext context, String mensagem) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Erro'),
          content: Text(mensagem),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Função para chamar a API
  Future<Map<String, dynamic>> deletarContaAPI() async {
    try {
      // **IMPORTANTE: Use o IP da sua máquina, não localhost**
      const String baseUrl =
          Config.apiUrl; // Substitua pelo IP do seu servidor

      final userId = await _obterUserId();

      if (userId.isEmpty) {
        return {'success': false, 'message': 'Usuário não encontrado'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/familiar/delete-account'),
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
        return responseData;
      } else {
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'message': errorData['message'] ?? 'Erro ao deletar conta',
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Erro HTTP ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      print('Erro na API: $e');
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Função para obter o userId
  Future<String> _obterUserId() async {
    try {
      // Para teste, retorne '1'
      // Depois implemente com SharedPreferences ou seu gerenciamento de estado
      return '1';
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
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Configurações'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildSettingsItem(
              context,
              icon: Icons.notifications_outlined,
              label: 'Notificações',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificacoesFamiliar(),
                  ),
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
            const SizedBox(width: 20),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
