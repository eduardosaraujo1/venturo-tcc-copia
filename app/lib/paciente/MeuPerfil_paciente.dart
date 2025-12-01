import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import 'editar_perfil_paciente_screen.dart.dart';

class MeuperfilPaciente extends StatefulWidget {
  const MeuperfilPaciente({super.key});

  @override
  State<MeuperfilPaciente> createState() => _MeuperfilPacienteState();
}

class _MeuperfilPacienteState extends State<MeuperfilPaciente> {
  Map<String, dynamic> _pacienteData = {};
  bool _isLoading = true;
  String _errorMessage = '';

  // Cores do tema
  static const Color corPrincipal = Color.fromARGB(255, 106, 186, 213);

  @override
  void initState() {
    super.initState();
    _carregarDadosPaciente();
  }

  Future<void> _carregarDadosPaciente() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/paciente/perfil'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _pacienteData = data;
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

  void _navegarParaEdicao() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarPerfilPaciente(perfilData: _pacienteData),
      ),
    ).then((dadosAtualizados) {
      // Atualiza a tela quando retornar da edição
      if (dadosAtualizados != null) {
        _carregarDadosPaciente(); // Recarrega os dados
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nomeCompleto = _pacienteData['nome'] ?? '';
    final inicial = _getInicial(nomeCompleto);
    final avatarColor = _getAvatarColor(inicial);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? _buildErrorWidget()
          : _buildProfileWidget(nomeCompleto, inicial, avatarColor),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _carregarDadosPaciente,
              style: ElevatedButton.styleFrom(
                backgroundColor: corPrincipal,
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileWidget(
    String nomeCompleto,
    String inicial,
    Color avatarColor,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Avatar e informações básicas
            _buildProfileHeader(nomeCompleto, inicial, avatarColor),
            const SizedBox(height: 30),

            // Seção de informações pessoais
            _buildPersonalInfoSection(),

            // Seção de informações médicas
            _buildMedicalInfoSection(),

            const SizedBox(height: 30),

            // Botão de editar perfil
            _buildEditButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    String nomeCompleto,
    String inicial,
    Color avatarColor,
  ) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
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
          const SizedBox(height: 16),
          Text(
            nomeCompleto.isNotEmpty ? nomeCompleto : 'Nome não informado',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          if (_pacienteData['email'] != null &&
              _pacienteData['email'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                _pacienteData['email'],
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoSection(
          icon: Icons.person_outline,
          label: 'Nome Completo',
          value: _pacienteData['nome'] ?? 'Não informado',
        ),
        _buildInfoSection(
          icon: Icons.email_outlined,
          label: 'Email',
          value: _pacienteData['email'] ?? 'Não informado',
        ),
        _buildInfoSection(
          icon: Icons.cake_outlined,
          label: 'Data de Nascimento',
          value: _pacienteData['data_nascimento'] ?? 'Não informada',
        ),
        _buildInfoSection(
          icon: Icons.location_on_outlined,
          label: 'Endereço',
          value: _pacienteData['endereco'] ?? 'Não informado',
        ),
      ],
    );
  }

  Widget _buildMedicalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Informações Médicas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: corPrincipal,
          ),
        ),
        const SizedBox(height: 10),

        _buildInfoSection(
          icon: Icons.bloodtype_outlined,
          label: 'Tipo Sanguíneo',
          value: _pacienteData['tipo_sanguineo'] ?? 'Não informado',
        ),
        _buildInfoSection(
          icon: Icons.numbers_outlined,
          label: 'Idade',
          value: _pacienteData['idade'] != null
              ? '${_pacienteData['idade']} anos'
              : 'Não informada',
        ),
        _buildInfoSection(
          icon: Icons.monitor_weight_outlined,
          label: 'Peso',
          value: _pacienteData['peso'] != null
              ? '${_pacienteData['peso']} kg'
              : 'Não informado',
        ),
        _buildInfoSection(
          icon: Icons.medical_services_outlined,
          label: 'Comorbidades',
          value: _pacienteData['comorbidade'] ?? 'Não informadas',
        ),
      ],
    );
  }

  Widget _buildEditButton() {
    return ElevatedButton(
      onPressed: _navegarParaEdicao,
      style: ElevatedButton.styleFrom(
        backgroundColor: corPrincipal,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text(
        'Editar Perfil',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: corPrincipal, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
