import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HistoricoDeRegistros extends StatefulWidget {
  const HistoricoDeRegistros({super.key});

  @override
  _HistoricoDeRegistrosState createState() => _HistoricoDeRegistrosState();
}

class _HistoricoDeRegistrosState extends State<HistoricoDeRegistros> {
  List<dynamic> _consultas = [];
  List<dynamic> _medicamentos = [];
  List<dynamic> _tarefas = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _carregarTodosRegistros();
  }

  // Função para converter Map<dynamic, dynamic> para Map<String, dynamic>
  Map<String, dynamic> _convertToStringKeyMap(
    Map<dynamic, dynamic> originalMap,
  ) {
    return originalMap.map((key, value) => MapEntry(key.toString(), value));
  }

  Future<void> _carregarTodosRegistros() async {
    try {
      print('🔍 Iniciando carregamento de registros...');

      // Carrega consultas, medicamentos e tarefas em paralelo
      final responses = await Future.wait([
        http.get(
          Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComConsulta'),
        ),
        http.get(
          Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComMedicamentos'),
        ),
        http.get(Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComTarefas')),
      ]);

      print('📊 Respostas recebidas: ${responses.length}');

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        print('🔧 Processando resposta $i - Status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          print('📦 Dados brutos da API $i: $decoded');

          // Verifica se a resposta tem a estrutura esperada
          if (decoded is Map &&
              decoded['success'] == true &&
              decoded['data'] is List) {
            final List data = decoded['data'];
            print('✅ Dados processados $i: ${data.length} pacientes');

            // Extrai todos os registros dos pacientes
            List<dynamic> registros = [];

            for (var paciente in data) {
              // Converte o paciente para Map<String, dynamic>
              final pacienteMap = _convertToStringKeyMap(
                paciente as Map<dynamic, dynamic>,
              );

              switch (i) {
                case 0: // Consultas
                  if (pacienteMap['consultas'] is List) {
                    for (var consulta in pacienteMap['consultas'] as List) {
                      // Converte a consulta para Map<String, dynamic>
                      final consultaMap = _convertToStringKeyMap(
                        consulta as Map<dynamic, dynamic>,
                      );
                      // Adiciona informações do paciente à consulta
                      registros.add({
                        ...consultaMap,
                        'paciente_nome': pacienteMap['nome'],
                        'paciente_id': pacienteMap['id'],
                      });
                    }
                  }
                  break;
                case 1: // Medicamentos
                  if (pacienteMap['medicamentos'] is List) {
                    for (var medicamento
                        in pacienteMap['medicamentos'] as List) {
                      final medicamentoMap = _convertToStringKeyMap(
                        medicamento as Map<dynamic, dynamic>,
                      );
                      registros.add({
                        ...medicamentoMap,
                        'paciente_nome': pacienteMap['nome'],
                        'paciente_id': pacienteMap['id'],
                      });
                    }
                  }
                  break;
                case 2: // Tarefas
                  if (pacienteMap['tarefas'] is List) {
                    for (var tarefa in pacienteMap['tarefas'] as List) {
                      final tarefaMap = _convertToStringKeyMap(
                        tarefa as Map<dynamic, dynamic>,
                      );
                      registros.add({
                        ...tarefaMap,
                        'paciente_nome': pacienteMap['nome'],
                        'paciente_id': pacienteMap['id'],
                      });
                    }
                  }
                  break;
              }
            }

            print('📋 Registros extraídos $i: ${registros.length}');

            switch (i) {
              case 0:
                setState(() => _consultas = registros);
                break;
              case 1:
                setState(() => _medicamentos = registros);
                break;
              case 2:
                setState(() => _tarefas = registros);
                break;
            }
          } else {
            print('❌ Estrutura inválida na resposta $i');
          }
        } else {
          print('❌ Erro HTTP $i: ${response.statusCode} - ${response.body}');
        }
      }

      setState(() => _isLoading = false);
      print('🎉 Carregamento concluído!');
      print('📋 Consultas: ${_consultas.length}');
      print('💊 Medicamentos: ${_medicamentos.length}');
      print('📝 Tarefas: ${_tarefas.length}');
    } catch (error) {
      print('💥 Erro ao carregar registros: $error');
      setState(() {
        _errorMessage = 'Erro ao carregar registros: $error';
        _isLoading = false;
      });
    }
  }

  String _formatarDataHora(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  String _formatarData(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'Data não informada';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildConsultaCard(dynamic consulta) {
    // Converte para Map<String, dynamic> antes de usar
    final consultaMap = _convertToStringKeyMap(
      consulta as Map<dynamic, dynamic>,
    );

    return _buildRecordCard(
      'Consulta - ${consultaMap['especialidade']}',
      _formatarDataHora(consultaMap['hora_consulta'] ?? ''),
      'Médico: ${consultaMap['medico_nome'] ?? 'Não informado'}\n'
          'Tipo: ${consultaMap['tipo_consulta'] ?? 'Não informado'}\n'
          'Local: ${consultaMap['local_consulta'] ?? 'Não informado'}\n'
          'Status: ${consultaMap['status'] ?? 'pendente'}\n'
          'Paciente: ${consultaMap['paciente_nome'] ?? 'Não informado'}',
      Icons.medical_services,
      Colors.blue,
    );
  }

  Widget _buildMedicamentoCard(dynamic medicamento) {
    final medicamentoMap = _convertToStringKeyMap(
      medicamento as Map<dynamic, dynamic>,
    );

    return _buildRecordCard(
      'Medicamento - ${medicamentoMap['medicamento_nome']}',
      _formatarDataHora(medicamentoMap['data_hora'] ?? ''),
      'Dosagem: ${medicamentoMap['dosagem'] ?? 'Não informada'}\n'
          'Status: ${medicamentoMap['status'] ?? 'pendente'}\n'
          'Paciente: ${medicamentoMap['paciente_nome'] ?? 'Não informado'}',
      Icons.medication,
      Colors.green,
    );
  }

  Widget _buildTarefaCard(dynamic tarefa) {
    final tarefaMap = _convertToStringKeyMap(tarefa as Map<dynamic, dynamic>);

    return _buildRecordCard(
      'Tarefa - ${tarefaMap['motivacao'] ?? 'Atividade'}',
      _formatarData(tarefaMap['data_tarefa']),
      'Descrição: ${tarefaMap['descricao'] ?? 'Sem descrição'}\n'
          'Paciente: ${tarefaMap['paciente_nome'] ?? 'Não informado'}',
      Icons.task,
      Colors.orange,
    );
  }

  Widget _buildRecordCard(
    String title,
    String date,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
                textAlign: TextAlign.right,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(fontSize: 16, height: 1.4)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                // Ação para verificar o registro
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 106, 186, 213),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Verificar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Histórico De Registros',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _carregarTodosRegistros,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _carregarTodosRegistros,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Resumo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        _consultas.length,
                        'Consultas',
                        Icons.medical_services,
                      ),
                      _buildSummaryItem(
                        _medicamentos.length,
                        'Medicamentos',
                        Icons.medication,
                      ),
                      _buildSummaryItem(_tarefas.length, 'Tarefas', Icons.task),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Todos os Registros',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 106, 186, 213),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _carregarTodosRegistros,
                      child: ListView(
                        children: [
                          // Consultas
                          if (_consultas.isNotEmpty) ...[
                            ..._consultas.map(
                              (consulta) => _buildConsultaCard(consulta),
                            ),
                          ] else
                            _buildEmptyState('Nenhuma consulta registrada'),

                          // Medicamentos
                          if (_medicamentos.isNotEmpty) ...[
                            ..._medicamentos.map(
                              (medicamento) =>
                                  _buildMedicamentoCard(medicamento),
                            ),
                          ] else
                            _buildEmptyState('Nenhum medicamento registrado'),

                          // Tarefas
                          if (_tarefas.isNotEmpty) ...[
                            ..._tarefas.map(
                              (tarefa) => _buildTarefaCard(tarefa),
                            ),
                          ] else
                            _buildEmptyState('Nenhuma tarefa registrada'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryItem(int count, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 106, 186, 213).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: const Color.fromARGB(255, 106, 186, 213),
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
