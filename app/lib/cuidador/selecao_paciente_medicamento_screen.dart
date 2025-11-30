import 'package:flutter/material.dart';
import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'confirmar_agendamento_medicamento_screen.dart';

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

class SelecionarPacienteMedicamento extends StatefulWidget {
  final DateTime selectedDate;
  final String selectedTime;
  final DateTime selectedDateTime;
  final bool isRecurring; // Adicione este parâmetro

  const SelecionarPacienteMedicamento({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedDateTime,
    required this.isRecurring, // Adicione este parâmetro
  });

  @override
  State<SelecionarPacienteMedicamento> createState() =>
      _SelecionarPacienteMedicamentoState();
}

class _SelecionarPacienteMedicamentoState
    extends State<SelecionarPacienteMedicamento> {
  List<Patient> _patients = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPatients();

    // Debug: verifique se os parâmetros estão chegando
    print('Data selecionada: ${widget.selectedDate}');
    print('Hora selecionada: ${widget.selectedTime}');
    print('DateTime completo: ${widget.selectedDateTime}');
  }

  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // URL da API - ajuste conforme necessário
    const apiUrl =
        '${Config.apiUrl}/api/cuidador/SelecionarPacienteMedicamento';

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
          // Se a API não estiver disponível, use dados mock para teste
          _useMockData();
        }
      } else {
        // Se houver erro na API, use dados mock para teste
        _useMockData();
      }
    } catch (e) {
      // Em caso de erro de conexão, use dados mock
      _useMockData();
    }
  }

  void _useMockData() {
    final mockPatients = [
      Patient(
        id: '1',
        nome: 'João Silva',
        idade: '65',
        imagePath: 'assets/images/default_avatar.png',
      ),
      Patient(
        id: '2',
        nome: 'Maria Santos',
        idade: '72',
        imagePath: 'assets/images/default_avatar.png',
      ),
      Patient(
        id: '3',
        nome: 'Pedro Oliveira',
        idade: '68',
        imagePath: 'assets/images/default_avatar.png',
      ),
    ];

    setState(() {
      _patients = mockPatients;
      _isLoading = false;
      _error = null;
    });
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
                'Para qual paciente é\nesse medicamento?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6ABAD5),
                ),
              ),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Color(0xFF6ABAD5)),
                      SizedBox(height: 16),
                      Text('Carregando pacientes...'),
                    ],
                  ),
                )
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

  Widget _buildErrorWidget() {
    return Column(
      children: [
        Icon(Icons.error_outline, color: Colors.red, size: 64),
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
            backgroundColor: const Color(0xFF6ABAD5),
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
        return _buildPatientCard(
          context,
          patient.nome,
          patient.idade,
          patient.imagePath,
        );
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
          'Novo Medicamento',
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
              colors: [Color(0xFFB3E5FC), Color(0xFF6ABAD5)],
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
    );
  }

  Widget _buildPatientCard(
    BuildContext context,
    String name,
    String age,
    String imagePath,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 4,
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFF6ABAD5).withOpacity(0.2),
          child: const Icon(Icons.person, color: Color(0xFF6ABAD5), size: 30),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          'Idade: $age',
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ConfirmarAgendamentoMedicamentoScreen(
                  patientName: name,
                  medicationName: 'Clonazepam',
                  dosage: '1 Mg',
                  date: widget.selectedDate,
                  time: widget.selectedTime,
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6ABAD5),
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
}
