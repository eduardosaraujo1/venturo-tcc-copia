import 'dart:convert';

import 'package:algumacoisa/familiar/agenda_familiar.dart';
import 'package:algumacoisa/familiar/consultas_familiar.dart';
import 'package:algumacoisa/familiar/conversas_familiar.dart';
import 'package:algumacoisa/familiar/emergencias_familiar.dart';
import 'package:algumacoisa/familiar/medicamentos_familiar.dart';
import 'package:algumacoisa/familiar/meu_perfil_screen.dart';
import 'package:algumacoisa/familiar/notificacoes_screen.dart';
import 'package:algumacoisa/familiar/tarefas_familiar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class HomeFamiliar extends StatefulWidget {
  const HomeFamiliar({super.key});

  @override
  _HomeFamiliarState createState() => _HomeFamiliarState();
}

class _HomeFamiliarState extends State<HomeFamiliar> {
  Map<String, dynamic> _perfilData = {};
  Map<String, dynamic> _pacienteData = {};
  bool _isLoading = true;
  bool _isLoadingPaciente = true;
  String _errorMessage = '';
  String _errorMessagePaciente = '';

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
    _carregarPaciente();
  }

  Future<void> _carregarPerfil() async {
    try {
      final response = await http
          .get(Uri.parse('${Config.apiUrl}/api/familiar/perfil'))
          .timeout(const Duration(seconds: 10));

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
        _errorMessage =
            'Erro de conexão: $error\n\nVerifique:\n1. Se o servidor está rodando\n2. Se a URL está correta\n3. Sua conexão com a internet';
        _isLoading = false;
      });
    }
  }

  Future<void> _carregarPaciente() async {
    try {
      final response = await http
          .get(Uri.parse('${Config.apiUrl}/api/familiar/paciente'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          _pacienteData = json.decode(response.body);
          _isLoadingPaciente = false;
        });
      } else {
        setState(() {
          _errorMessagePaciente =
              'Erro ao carregar dados do paciente: ${response.statusCode}';
          _isLoadingPaciente = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessagePaciente = 'Erro de conexão ao carregar paciente: $error';
        _isLoadingPaciente = false;
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

  void _navegarParaPerfil(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MeuPerfilfamiliar()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nomeUsuario = _perfilData['nome']?.split(' ').first ?? 'Usuário';
    final inicial = _getInicial(nomeUsuario);
    final avatarColor = _getAvatarColor(inicial);

    // Dados do paciente
    final nomePaciente = _pacienteData['nome'] ?? 'Carregando...';
    final parentesco = _pacienteData['parentesco'] ?? 'parente';
    final idade = _pacienteData['idade']?.toString() ?? '';
    final tipoSanguineo = _pacienteData['tipo_sanguineo'] ?? '';
    final comorbidade = _pacienteData['comorbidade'] ?? '';

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 106, 186, 213),
                const Color.fromARGB(255, 106, 186, 213),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _navegarParaPerfil(context),
                  child: Row(
                    children: [
                      if (_isLoading)
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[300],
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else if (_errorMessage.isNotEmpty)
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[300],
                          child: const Icon(Icons.error, color: Colors.white),
                        )
                      else
                        CircleAvatar(
                          backgroundColor: avatarColor,
                          radius: 24,
                          child: Text(
                            inicial,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      if (_isLoading)
                        const Text(
                          'Carregando...',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      else if (_errorMessage.isNotEmpty)
                        const Text(
                          'Erro ao carregar',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      else
                        Text(
                          'Bem-vindo, $nomeUsuario',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificacoesFamiliar(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            _buildPacienteInfoBox(
              nomePaciente,
              parentesco,
              idade,
              tipoSanguineo,
              comorbidade,
            ),
            const SizedBox(height: 16),

            _buildInfoCard(
              icon: Icons.access_time,
              title: 'Consultas Hoje',
              subtitle: 'clique para vizualizar',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConsultasFamiliar()),
              ),
            ),
            _buildInfoCard(
              icon: Icons.medical_services_outlined,
              title: 'Medicamentos a administrar',
              subtitle: 'clique para vizualizar',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MedicamentosFamiliar()),
              ),
            ),
            _buildInfoCard(
              icon: Icons.warning_amber_outlined,
              title: 'Emergências recentes',
              subtitle: '1 Alerta hoje',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EmergenciasScreen()),
              ),
            ),
            _buildInfoCard(
              icon: Icons.task_alt,
              title: 'Tarefas Pendentes',
              subtitle: 'clique para vizualizar',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TarefasFamiliar()),
              ),
            ),

            if (_errorMessage.isNotEmpty || _errorMessagePaciente.isNotEmpty)
              _buildErrorCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildPacienteInfoBox(
    String nomePaciente,
    String parentesco,
    String idade,
    String tipoSanguineo,
    String comorbidade,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 106, 186, 213).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 106, 186, 213).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.family_restroom,
                color: const Color.fromARGB(255, 106, 186, 213),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Esta é a Agenda do(a) seu parente:',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 106, 186, 213),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingPaciente)
            const Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color.fromARGB(255, 106, 186, 213),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Carregando informações do paciente...',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            )
          else if (_errorMessagePaciente.isNotEmpty)
            Row(
              children: [
                Icon(Icons.error_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Erro ao carregar dados do paciente',
                  style: TextStyle(color: Colors.orange, fontSize: 14),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomePaciente,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (idade.isNotEmpty ||
                    tipoSanguineo.isNotEmpty ||
                    comorbidade.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  if (idade.isNotEmpty) _buildInfoRow('Idade:', '$idade anos'),
                  if (tipoSanguineo.isNotEmpty)
                    _buildInfoRow('Tipo Sanguíneo:', tipoSanguineo),
                  if (comorbidade.isNotEmpty)
                    _buildInfoRow('Comorbidades:', comorbidade),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: const Color.fromARGB(255, 106, 186, 213),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_errorMessage.isNotEmpty)
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              if (_errorMessagePaciente.isNotEmpty) ...[
                if (_errorMessage.isNotEmpty) const SizedBox(height: 10),
                Text(
                  _errorMessagePaciente,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (_errorMessage.isNotEmpty)
                    ElevatedButton(
                      onPressed: _carregarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          106,
                          186,
                          213,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Recarregar Perfil'),
                    ),
                  if (_errorMessagePaciente.isNotEmpty)
                    ElevatedButton(
                      onPressed: _carregarPaciente,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          106,
                          186,
                          213,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Recarregar Paciente'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          IconButton(
            icon: const Icon(
              Icons.home,
              color: Color.fromARGB(255, 106, 186, 213),
            ),
            onPressed: () =>
                Navigator.popUntil(context, (route) => route.isFirst),
          ),
          IconButton(
            icon: const Icon(
              Icons.message_outlined,
              color: Color.fromARGB(255, 106, 186, 213),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ConversasFamiliar()),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Color.fromARGB(255, 106, 186, 213),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AgendaFamiliar()),
            ),
          ),
        ],
      ),
    );
  }
}
