import 'package:flutter/material.dart';
import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_cuidador_screen.dart';

// Models
class Patient {
  final String id;
  final String nome;
  final String idade;
  final String imagePath;

  Patient({
    required this.id,
    required this.nome,
    required this.idade,
    required this.imagePath,
  });
}

// Main Screen
class PatientTaskSelectionScreen extends StatefulWidget {
  final String descricao;
  final String motivo;
  final DateTime data;
  final String hora;

  const PatientTaskSelectionScreen({
    super.key,
    required this.descricao,
    required this.motivo,
    required this.data,
    required this.hora,
  });

  @override
  State<PatientTaskSelectionScreen> createState() =>
      _PatientTaskSelectionScreenState();
}

class _PatientTaskSelectionScreenState
    extends State<PatientTaskSelectionScreen> {
  List<Patient> _patients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    const apiUrl = '${Config.apiUrl}/api/cuidador/SelecionarPacienteTarefa';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = json.decode(response.body);

        if (responseBody['success'] == true && responseBody['data'] is List) {
          final List<dynamic> data = responseBody['data'];

          final fetchedPatients = data.map<Patient>((item) {
            return Patient(
              id: item['id']?.toString() ?? '0',
              nome: item['nome']?.toString() ?? 'Nome não informado',
              idade: item['idade']?.toString() ?? 'Idade não informada',
              imagePath: 'assets/images/default_avatar.png',
            );
          }).toList();

          setState(() {
            _patients = fetchedPatients;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Estrutura de resposta inesperada da API';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Erro no servidor: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error =
            'Erro de conexão: $e\n\nVerifique:\n1. Servidor está rodando\n2. URL correta\n3. CORS habilitado';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Para qual paciente é\nessa Tarefa?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 106, 186, 213),
                ),
              ),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 24),
              if (_isLoading)
                _buildLoadingWidget()
              else if (_error != null)
                _buildErrorWidget()
              else
                _buildPatientList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(color: Color.fromARGB(255, 106, 186, 213)),
          SizedBox(height: 16),
          Text('Carregando pacientes...'),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 64),
        const SizedBox(height: 16),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.red, fontSize: 16),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _fetchPatients,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 106, 186, 213),
          ),
          child: const Text(
            'Tentar Novamente',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientList() {
    if (_patients.isEmpty) {
      return const Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum paciente encontrado.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index];
        return _buildPatientCard(patient);
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80.0),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nova Tarefa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB3E5FC), Color.fromARGB(255, 106, 186, 213)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Buscar pacientes',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(
            Icons.search,
            color: Color.fromARGB(255, 106, 186, 213),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPatientCard(Patient patient) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 4,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: const Color.fromARGB(
            255,
            106,
            186,
            213,
          ).withOpacity(0.2),
          child: const Icon(
            Icons.person,
            color: Color.fromARGB(255, 106, 186, 213),
            size: 30,
          ),
        ),
        title: Text(
          patient.nome,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          'Idade: ${patient.idade}',
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            _navigateToConfirmationScreen(context, patient);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 106, 186, 213),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Selecionar',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _navigateToConfirmationScreen(BuildContext context, Patient patient) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskNotificationScreen(
          paciente: patient.nome,
          data: widget.data,
          hora: widget.hora,
          descricao: widget.descricao,
          motivo: widget.motivo,
        ),
      ),
    );
  }
}

// Notification Screen (Versão Corrigida)
class TaskNotificationScreen extends StatelessWidget {
  final String paciente;
  final String descricao;
  final String motivo;
  final DateTime data;
  final String hora;

  const TaskNotificationScreen({
    super.key,
    required this.paciente,
    required this.descricao,
    required this.motivo,
    required this.data,
    required this.hora,
  });

  String _formatarData(DateTime data) {
    final diasSemana = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
    ];

    final meses = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];

    // CORREÇÃO: data.weekday retorna 1-7 (Segunda-Domingo), precisa ajustar o índice
    final diaSemana = diasSemana[data.weekday % 7];
    final mesExtenso = meses[data.month - 1];

    return '$diaSemana, ${data.day} de $mesExtenso de ${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = _formatarData(data);
    final corPrincipal = const Color(0xFF6ABAD5);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [corPrincipal.withOpacity(0.9), corPrincipal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Icon(
                      Icons.check_rounded,
                      size: 60,
                      color: corPrincipal,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tarefa agendada com sucesso!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Você receberá uma notificação próximo da data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    color: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tarefa: $descricao',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: corPrincipal,
                            ),
                          ),
                          Text(
                            'Motivo: $motivo',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.person, color: corPrincipal),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Paciente',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      paciente,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: corPrincipal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: corPrincipal),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Data da tarefa',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      '$dataFormatada, às $hora',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: corPrincipal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      // Navegação corrigida - volta para a tela inicial
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomeCuidadorScreen(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 5,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      'Voltar a Tela Inicial',
                      style: TextStyle(
                        fontSize: 16,
                        color: corPrincipal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder para a tela inicial
