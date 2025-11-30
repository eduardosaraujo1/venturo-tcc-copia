import 'package:flutter/material.dart';
import '../config.dart';
import 'dart:convert'; // Necessário para converter JSON
import 'package:http/http.dart' as http; // Necessário para requisições HTTP

// Modelo de Dados do Cuidador (Mantenha este modelo)
class CaregiverModel {
  final String nome;
  final String numero;
  final String dataNascimento;
  final String endereco;
  final String infoFisicas;
  final String fotoUrl;

  CaregiverModel({
    required this.nome,
    required this.numero,
    required this.dataNascimento,
    required this.endereco,
    required this.infoFisicas,
    required this.fotoUrl,
  });

  // Método factory para criar o modelo a partir do JSON (resposta do server.js)
  factory CaregiverModel.fromJson(Map<String, dynamic> json) {
    return CaregiverModel(
      nome: json['nome'] ?? 'Nome Indisponível',
      numero: json['numero'] ?? 'Não informado', // Mapeado de 'telefone' no BD
      dataNascimento: json['data_nascimento'] ?? 'Não informada',
      endereco: json['endereco'] ?? 'Não informado',
      infoFisicas: json['info_fisicas'] ?? 'Sem informações físicas',
      fotoUrl:
          json['foto_url'] ??
          'assets/placeholder.png', // Substitua por um asset padrão
    );
  }
}

class MeuCuidador extends StatefulWidget {
  const MeuCuidador({super.key});

  @override
  State<MeuCuidador> createState() => _MeuCuidadorState();
}

class _MeuCuidadorState extends State<MeuCuidador> {
  CaregiverModel? _caregiverData;
  bool _isLoading = true;
  String _errorMessage = '';

  // Cores do tema
  static const Color corPrincipal = Color(0xFF6ABAD5);

  @override
  void initState() {
    super.initState();
    _loadCaregiverData();
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

  // FUNÇÃO ATUALIZADA PARA USAR O SERVER.JS
  Future<void> _loadCaregiverData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      const String urlApi = '${Config.apiUrl}/api/cuidador/perfil';

      final response = await http.get(Uri.parse(urlApi));

      if (response.statusCode == 200) {
        // Sucesso: Decodifica o JSON e cria o modelo
        final Map<String, dynamic> data = json.decode(response.body);
        final realData = CaregiverModel.fromJson(data);

        setState(() {
          _caregiverData = realData;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        throw Exception('Perfil não encontrado (código 404).');
      } else {
        // Tratar outros erros do servidor (500, etc.)
        throw Exception(
          'Falha ao carregar dados. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      // Captura erros de conexão ou exceções lançadas
      setState(() {
        _errorMessage = 'Erro de conexão/servidor: $e';
        _isLoading = false;
      });
    }
  }

  // 3. Widget principal (build)
  @override
  Widget build(BuildContext context) {
    final nomeCompleto = _caregiverData?.nome ?? '';
    final inicial = _getInicial(nomeCompleto);
    final avatarColor = _getAvatarColor(inicial);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Meu Cuidador'),
        centerTitle: true,
      ),
      body: _buildBody(avatarColor, inicial),
    );
  }

  Widget _buildBody(Color avatarColor, String inicial) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando perfil...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Colors.grey,
              child: Icon(Icons.error_outline, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadCaregiverData,
              style: ElevatedButton.styleFrom(
                backgroundColor: corPrincipal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    final caregiver = _caregiverData!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: CircleAvatar(
                backgroundColor: avatarColor,
                radius: 50,
                child: Text(
                  inicial,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoSection('Nome Completo', caregiver.nome),
            _buildInfoSection('Número', caregiver.numero),
            _buildInfoSection('Data de Nascimento', caregiver.dataNascimento),
            _buildInfoSection('Endereço', caregiver.endereco),
            _buildInfoSection('Informações Físicas', caregiver.infoFisicas),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aqui você passaria o objeto 'caregiver' para a tela de edição
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navegar para Tela de Edição (Implementar)'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: corPrincipal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Atualizar dados'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const Divider(),
        const SizedBox(height: 10),
      ],
    );
  }
}
