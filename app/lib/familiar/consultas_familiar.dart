import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ConsultasFamiliar extends StatefulWidget {
  const ConsultasFamiliar({super.key});

  @override
  State<ConsultasFamiliar> createState() => _ConsultasFamiliarState();
}

class _ConsultasFamiliarState extends State<ConsultasFamiliar> {
  List<dynamic> pacientesComConsultas = [];
  List<dynamic> pacientesFiltrados = [];
  bool isLoading = true;
  String errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarConsultas();
  }

  Future<void> _carregarConsultas() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      print('🔄 Iniciando carregamento de consultas...');

      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComConsulta'),
      );

      print('📡 Status da resposta: ${response.statusCode}');
      print('📦 Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('✅ API retornou success: ${data['success']}');
        print('📊 Total de pacientes: ${data['data']?.length}');

        if (data['success'] == true) {
          // Debug: Verificar estrutura dos dados
          if (data['data'] != null && data['data'].isNotEmpty) {
            print('🔍 Estrutura do primeiro paciente:');
            print('Nome: ${data['data'][0]['nome']}');
            print('Tem consultas: ${data['data'][0]['consultas'] != null}');
            if (data['data'][0]['consultas'] != null) {
              print(
                'Número de consultas: ${data['data'][0]['consultas'].length}',
              );
              if (data['data'][0]['consultas'].isNotEmpty) {
                print('Primeira consulta: ${data['data'][0]['consultas'][0]}');
              }
            }
          }

          setState(() {
            pacientesComConsultas = data['data'];
            pacientesFiltrados = List.from(pacientesComConsultas);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['error'] ?? 'Erro ao carregar consultas';
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
      print('❌ Erro no carregamento: $e');
      setState(() {
        errorMessage = 'Erro: $e';
        isLoading = false;
      });
    }
  }

  void _filtrarConsultas(String query) {
    setState(() {
      if (query.isEmpty) {
        pacientesFiltrados = List.from(pacientesComConsultas);
      } else {
        pacientesFiltrados = pacientesComConsultas.where((paciente) {
          final nome = paciente['nome']?.toString().toLowerCase() ?? '';
          final especialidade =
              paciente['consultas']?.any(
                (consulta) =>
                    consulta['especialidade']
                        ?.toString()
                        .toLowerCase()
                        .contains(query.toLowerCase()) ??
                    false,
              ) ??
              false;
          final medico =
              paciente['consultas']?.any(
                (consulta) =>
                    consulta['medico_nome']?.toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false,
              ) ??
              false;
          final searchLower = query.toLowerCase();

          return nome.contains(searchLower) || especialidade || medico;
        }).toList();
      }
    });
  }

  String _formatarDataHora(String dataHora) {
    try {
      final dateTime = DateTime.parse(dataHora);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} às ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('❌ Erro ao formatar data: $dataHora');
      return dataHora;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmada':
        return Colors.green;
      case 'pendente':
        return Colors.orange;
      case 'cancelada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getTipoConsulta(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'presencial':
        return '👥 Presencial';
      case 'telemedicina':
        return '📱 Telemedicina';
      case 'domiciliar':
        return '🏠 Domiciliar';
      default:
        return tipo ?? 'Não especificado';
    }
  }

  Widget _buildConsultaCard(dynamic consulta) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(consulta['status']),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  (consulta['status']?.toString().toUpperCase() ?? 'PENDENTE'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getTipoConsulta(consulta['tipo_consulta']),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            consulta['especialidade']?.toString() ??
                'Especialidade não informada',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            'Dr. ${consulta['medico_nome'] ?? 'Médico não informado'}',
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          if (consulta['crm_medico'] != null)
            Text(
              'CRM: ${consulta['crm_medico']}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          const SizedBox(height: 4),
          Text(
            consulta['local_consulta'] ??
                consulta['endereco_consulta'] ??
                'Local não informado',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            _formatarDataHora(consulta['hora_consulta'] ?? ''),
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Consultas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarConsultas,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de pesquisa
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar paciente, especialidade ou médico...',
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filtrarConsultas('');
                        },
                      )
                    : null,
              ),
              onChanged: _filtrarConsultas,
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Carregando consultas...'),
                    ],
                  ),
                ),
              )
            else if (errorMessage.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarConsultas,
                        child: Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else if (pacientesFiltrados.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Nenhuma consulta agendada'
                            : 'Nenhuma consulta encontrada para a busca',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: pacientesFiltrados.length,
                  itemBuilder: (context, index) {
                    final paciente = pacientesFiltrados[index];
                    final consultas =
                        paciente['consultas'] as List<dynamic>? ?? [];

                    print(
                      '🎯 Renderizando paciente: ${paciente['nome']} com ${consultas.length} consultas',
                    );

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cabeçalho do paciente
                          ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.blue[100],
                              child: Text(
                                paciente['nome']
                                        ?.toString()
                                        .substring(0, 1)
                                        .toUpperCase() ??
                                    '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            title: Text(
                              paciente['nome']?.toString() ??
                                  'Paciente não identificado',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (paciente['idade'] != null)
                                  Text('Idade: ${paciente['idade']} anos'),
                                if (paciente['tipo_sanguineo'] != null)
                                  Text(
                                    'Tipo Sanguíneo: ${paciente['tipo_sanguineo']}',
                                  ),
                                Text(
                                  '${consultas.length} consulta(s)',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Lista de consultas do paciente
                          if (consultas.isNotEmpty)
                            ...consultas.map((consulta) {
                              print(
                                '📅 Renderizando consulta: ${consulta['especialidade']}',
                              );
                              return _buildConsultaCard(consulta);
                            })
                          else
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Nenhuma consulta agendada',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
