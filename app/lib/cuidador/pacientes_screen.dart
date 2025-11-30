import 'package:algumacoisa/paciente/acesso_paciente.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:algumacoisa/familiar/Registraofamiliar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PacientesScreen extends StatefulWidget {
  const PacientesScreen({super.key});

  @override
  State<PacientesScreen> createState() => _PacientesScreenState();
}

class _PacientesScreenState extends State<PacientesScreen> {
  List<dynamic> pacientes = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarPacientes();
  }

  Future<void> _carregarPacientes() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/ExibirPacientes'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse['success'] == true) {
          setState(() {
            pacientes = decodedResponse['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage =
                'Erro na resposta da API: ${decodedResponse['error']}';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Erro ao carregar pacientes: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro de conexão: $e';
        isLoading = false;
      });
    }
  }

  // Função para obter a letra inicial do nome do paciente
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pacientes'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegistraPacienteScreen(),
                ),
              ).then((_) => _carregarPacientes());
            },
            child: Text('Adicionar', style: TextStyle(color: Colors.lightBlue)),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Registraofamiliar()),
              );
            },
            child: Text(
              'Adicionar Familiar',
              style: TextStyle(color: Colors.lightBlue),
            ),
          ),
        ],
      ),
      body: Padding(padding: const EdgeInsets.all(16.0), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _carregarPacientes,
              child: Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (pacientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Nenhum paciente cadastrado'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RegistraPacienteScreen(),
                  ),
                ).then((_) => _carregarPacientes());
              },
              child: Text('Cadastrar Primeiro Paciente'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarPacientes,
      child: ListView.builder(
        itemCount: pacientes.length,
        itemBuilder: (context, index) {
          final paciente = pacientes[index];
          return _buildPatientCard(context, paciente: paciente);
        },
      ),
    );
  }

  Widget _buildPatientCard(BuildContext context, {required dynamic paciente}) {
    final inicial = _getInicial(paciente['nome'] ?? '');
    final avatarColor = _getAvatarColor(inicial);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: avatarColor,
              radius: 30,
              child: Text(
                inicial,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paciente['nome'] ?? 'Nome não informado',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    paciente['idade'] ?? 'Idade não informada',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    paciente['comorbidade'] ?? 'Nenhuma comorbidade',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
