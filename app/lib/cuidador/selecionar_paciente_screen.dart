import 'package:algumacoisa/cuidador/registros_diarios_screen.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SelecionarPacienteScreen extends StatefulWidget {
  const SelecionarPacienteScreen({super.key});

  @override
  State<SelecionarPacienteScreen> createState() =>
      _SelecionarPacienteScreenState();
}

class _SelecionarPacienteScreenState extends State<SelecionarPacienteScreen> {
  List<Paciente> pacientes = [];
  List<Paciente> pacientesFiltrados = [];
  bool isLoading = true;
  String errorMessage = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarPacientes();
    _searchController.addListener(_filtrarPacientes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _carregarPacientes() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/ExibirPacientes'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            pacientes = (data['data'] as List)
                .map((item) => Paciente.fromJson(item))
                .toList();
            pacientesFiltrados = List.from(pacientes);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Erro ao carregar pacientes';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Erro na conexão: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro: $e';
        isLoading = false;
      });
    }
  }

  void _filtrarPacientes() {
    final query = _searchController.text.toLowerCase();

    if (query.isEmpty) {
      setState(() {
        pacientesFiltrados = List.from(pacientes);
      });
    } else {
      setState(() {
        pacientesFiltrados = pacientes
            .where((paciente) => paciente.nome.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  // Função para obter a inicial do nome do paciente
  String _getInitial(String nome) {
    if (nome.isEmpty) return '?';
    return nome[0].toUpperCase();
  }

  // Função para gerar uma cor baseada no nome (para consistência)
  Color _getAvatarColor(String nome) {
    final colors = [
      const Color(0xFF62A7D2),
      const Color(0xFF6ABAD5),
      const Color(0xFF1D3B51),
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF795548),
    ];
    final index = nome.hashCode % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Registros Diarios',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pra qual paciente é esse relatório?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D3B51),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar pacientes',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
            _buildPatientList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientList() {
    if (isLoading) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (errorMessage.isNotEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Erro: $errorMessage'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _carregarPacientes,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (pacientesFiltrados.isEmpty) {
      return const Expanded(
        child: Center(child: Text('Nenhum paciente encontrado')),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: pacientesFiltrados.length,
        itemBuilder: (context, index) {
          final paciente = pacientesFiltrados[index];
          return _buildPatientCard(context, paciente);
        },
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, Paciente paciente) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Avatar com a inicial do nome
            CircleAvatar(
              radius: 30,
              backgroundColor: _getAvatarColor(paciente.nome),
              child: Text(
                _getInitial(paciente.nome),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paciente.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    paciente.idade ?? 'Idade não informada',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        RegistrosDiariosScreen(paciente: paciente),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF62A7D2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Selecionar'),
            ),
          ],
        ),
      ),
    );
  }
}

class Paciente {
  final int? id;
  final String nome;
  final String? idade;
  final String peso;
  final String tipoSanguineo;
  final String comorbidade;
  final int? cuidadorId;
  final String? email;
  final String? dataRegistro;
  final String? imagePath;

  Paciente({
    this.id,
    required this.nome,
    this.idade,
    required this.peso,
    required this.tipoSanguineo,
    required this.comorbidade,
    this.cuidadorId,
    this.email,
    this.dataRegistro,
    this.imagePath,
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    return Paciente(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      nome: json['nome']?.toString() ?? 'Nome não informado',
      idade: json['idade']?.toString(),
      peso: json['peso']?.toString() ?? 'Peso não informado',
      tipoSanguineo: json['tipo_sanguineo']?.toString() ?? 'Não informado',
      comorbidade: json['comorbidade']?.toString() ?? 'Nenhuma',
      cuidadorId: json['cuidador_id'] != null
          ? int.tryParse(json['cuidador_id'].toString())
          : null,
      email: json['email']?.toString(),
      dataRegistro: json['data_registro']?.toString(),
      imagePath: json['imagePath']?.toString(),
    );
  }
}
