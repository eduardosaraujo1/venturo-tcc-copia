import 'package:algumacoisa/cuidador/confirmar_agendamento_screen.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

class SelecionarPacienteConsulta extends StatefulWidget {
  final String especialidade;
  final String medicoNome;
  final DateTime data;
  final String hora;
  final String endereco;

  const SelecionarPacienteConsulta({
    super.key,
    required this.especialidade,
    required this.medicoNome,
    required this.endereco, // NOVO PARÂMETRO
    required this.data,
    required this.hora,
  });

  @override
  State<SelecionarPacienteConsulta> createState() =>
      _SelecionarPacienteConsultaState();
}

class _SelecionarPacienteConsultaState
    extends State<SelecionarPacienteConsulta> {
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

    // CORREÇÃO: Use uma URL válida para seu ambiente
    const apiUrl = '${Config.apiUrl}/api/cuidador/SelecionarPacienteConsulta';

    try {
      final response = await http
          .get(Uri.parse(apiUrl), headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

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

  // CORREÇÃO: Método separado para navegação
  void _navigateToConfirmation(Patient patient) {
    // Adiciona um pequeno delay para garantir que a UI não trave
    Future.delayed(Duration.zero, () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmarAgendamentoScreen(
            paciente: patient.nome,
            data: "${widget.data.day}/${widget.data.month}/${widget.data.year}",
            hora: widget.hora,
            especialidade: widget.especialidade,
            medicoNome: widget.medicoNome,
            endereco: widget.endereco,
          ),
        ),
      );
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
                'Para qual paciente é\nessa Consulta?',
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
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Color.fromARGB(255, 106, 186, 213),
                      ),
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

  // CORREÇÃO: Método simplificado para construir o card
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
          onPressed: () => _navigateToConfirmation(
            patient,
          ), // CORREÇÃO: Usando método separado
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
          'Nova Consulta',
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
}
