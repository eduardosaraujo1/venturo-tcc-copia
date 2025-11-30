import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MedicamentosFamiliar extends StatefulWidget {
  const MedicamentosFamiliar({super.key});

  @override
  State<MedicamentosFamiliar> createState() => _MedicamentosFamiliarState();
}

class _MedicamentosFamiliarState extends State<MedicamentosFamiliar> {
  List<dynamic> pacientesComMedicamentos = [];
  List<dynamic> pacientesFiltrados = [];
  bool isLoading = true;
  String errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarMedicamentos();
  }

  Future<void> _carregarMedicamentos() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      print('🔄 Iniciando carregamento de medicamentos...');

      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComMedicamentos'),
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
            print(
              'Tem medicamentos: ${data['data'][0]['medicamentos'] != null}',
            );
            if (data['data'][0]['medicamentos'] != null) {
              print(
                'Número de medicamentos: ${data['data'][0]['medicamentos'].length}',
              );
              if (data['data'][0]['medicamentos'].isNotEmpty) {
                print(
                  'Primeiro medicamento: ${data['data'][0]['medicamentos'][0]}',
                );
              }
            }
          }

          setState(() {
            pacientesComMedicamentos = data['data'];
            pacientesFiltrados = List.from(pacientesComMedicamentos);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['error'] ?? 'Erro ao carregar medicamentos';
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

  void _filtrarMedicamentos(String query) {
    setState(() {
      if (query.isEmpty) {
        pacientesFiltrados = List.from(pacientesComMedicamentos);
      } else {
        pacientesFiltrados = pacientesComMedicamentos.where((paciente) {
          final nome = paciente['nome']?.toString().toLowerCase() ?? '';
          final medicamento =
              paciente['medicamentos']?.any(
                (med) =>
                    med['medicamento_nome']?.toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false,
              ) ??
              false;
          final searchLower = query.toLowerCase();

          return nome.contains(searchLower) || medicamento;
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

  String _formatarHorario(String dataHora) {
    try {
      final dateTime = DateTime.parse(dataHora);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      print('❌ Erro ao formatar horário: $dataHora');
      return dataHora;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'administrado':
        return Colors.green;
      case 'pendente':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'administrado':
        return Icons.check_circle;
      case 'pendente':
        return Icons.access_time;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getMedicationColor(int index) {
    final colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
    ];
    return colors[index % colors.length];
  }

  Widget _buildMedicamentoCard(dynamic medicamento, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (index > 0) Divider(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getMedicationColor(index),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: Colors.blue[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicamento['medicamento_nome']?.toString() ??
                          'Medicamento não informado',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Dosagem: ${medicamento['dosagem'] ?? 'Não informada'}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(medicamento['status']),
                        color: _getStatusColor(medicamento['status']),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (medicamento['status']?.toString().toUpperCase() ??
                            'PENDENTE'),
                        style: TextStyle(
                          color: _getStatusColor(medicamento['status']),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatarHorario(medicamento['data_hora'] ?? ''),
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (medicamento['data_hora'] != null)
            Text(
              'Próxima dose: ${_formatarDataHora(medicamento['data_hora'])}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
        title: const Text('Medicamentos'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarMedicamentos,
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
                hintText: 'Buscar paciente ou medicamento...',
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
                          _filtrarMedicamentos('');
                        },
                      )
                    : null,
              ),
              onChanged: _filtrarMedicamentos,
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
                      Text('Carregando medicamentos...'),
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
                        onPressed: _carregarMedicamentos,
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
                        Icons.medication_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Nenhum medicamento agendado'
                            : 'Nenhum medicamento encontrado para a busca',
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
                    final medicamentos =
                        paciente['medicamentos'] as List<dynamic>? ?? [];

                    print(
                      '🎯 Renderizando paciente: ${paciente['nome']} com ${medicamentos.length} medicamentos',
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
                                  '${medicamentos.length} medicamento(s)',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Lista de medicamentos do paciente
                          if (medicamentos.isNotEmpty)
                            ...medicamentos.asMap().entries.map((entry) {
                              final medIndex = entry.key;
                              final medicamento = entry.value;

                              print(
                                '💊 Renderizando medicamento: ${medicamento['medicamento_nome']}',
                              );
                              return _buildMedicamentoCard(
                                medicamento,
                                medIndex,
                              );
                            })
                          else
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Nenhum medicamento agendado',
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
