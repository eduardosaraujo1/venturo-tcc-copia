import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TarefasFamiliar extends StatefulWidget {
  const TarefasFamiliar({super.key});

  @override
  State<TarefasFamiliar> createState() => _TarefasFamiliarState();
}

class _TarefasFamiliarState extends State<TarefasFamiliar> {
  List<dynamic> pacientesComTarefas = [];
  List<dynamic> pacientesFiltrados = [];
  bool isLoading = true;
  String errorMessage = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  Future<void> _carregarTarefas() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      print('🔄 Iniciando carregamento de tarefas...');

      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComTarefas'),
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
            print('Tem tarefas: ${data['data'][0]['tarefas'] != null}');
            if (data['data'][0]['tarefas'] != null) {
              print('Número de tarefas: ${data['data'][0]['tarefas'].length}');
              if (data['data'][0]['tarefas'].isNotEmpty) {
                print('Primeira tarefa: ${data['data'][0]['tarefas'][0]}');
              }
            }
          }

          setState(() {
            pacientesComTarefas = data['data'];
            pacientesFiltrados = List.from(pacientesComTarefas);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['error'] ?? 'Erro ao carregar tarefas';
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

  void _filtrarTarefas(String query) {
    setState(() {
      if (query.isEmpty) {
        pacientesFiltrados = List.from(pacientesComTarefas);
      } else {
        pacientesFiltrados = pacientesComTarefas.where((paciente) {
          final nome = paciente['nome']?.toString().toLowerCase() ?? '';
          final motivacao =
              paciente['tarefas']?.any(
                (tarefa) =>
                    tarefa['motivacao']?.toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false,
              ) ??
              false;
          final descricao =
              paciente['tarefas']?.any(
                (tarefa) =>
                    tarefa['descricao']?.toString().toLowerCase().contains(
                      query.toLowerCase(),
                    ) ??
                    false,
              ) ??
              false;
          final searchLower = query.toLowerCase();

          return nome.contains(searchLower) || motivacao || descricao;
        }).toList();
      }
    });
  }

  String _formatarData(String dataTarefa) {
    try {
      if (dataTarefa.isEmpty) return 'Data não informada';

      // Tenta parse como DateTime primeiro
      try {
        final dateTime = DateTime.parse(dataTarefa);
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } catch (e) {
        // Se não for uma data válida, retorna o valor original
        return dataTarefa;
      }
    } catch (e) {
      print('❌ Erro ao formatar data: $dataTarefa');
      return dataTarefa;
    }
  }

  Color _getTarefaColor(int index) {
    final colors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
    ];
    return colors[index % colors.length];
  }

  Widget _buildTarefaCard(dynamic tarefa, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (index > 0) Divider(height: 1, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTarefaColor(index),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.assignment,
                  color: Colors.blue[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tarefa['motivacao'] != null)
                      Text(
                        tarefa['motivacao']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    if (tarefa['descricao'] != null)
                      Text(
                        tarefa['descricao']!,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    const SizedBox(height: 4),
                    if (tarefa['data_tarefa'] != null)
                      Text(
                        'Data: ${_formatarData(tarefa['data_tarefa'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
            ],
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
        title: const Text('Tarefas dos Pacientes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarTarefas,
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
                hintText: 'Buscar paciente, motivação ou descrição...',
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
                          _filtrarTarefas('');
                        },
                      )
                    : null,
              ),
              onChanged: _filtrarTarefas,
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
                      Text('Carregando tarefas...'),
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
                        onPressed: _carregarTarefas,
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
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Nenhuma tarefa encontrada'
                            : 'Nenhuma tarefa encontrada para a busca',
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
                    final tarefas = paciente['tarefas'] as List<dynamic>? ?? [];

                    print(
                      '🎯 Renderizando paciente: ${paciente['nome']} com ${tarefas.length} tarefas',
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
                                  '${tarefas.length} tarefa(s)',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Lista de tarefas do paciente
                          if (tarefas.isNotEmpty)
                            ...tarefas.asMap().entries.map((entry) {
                              final tarefaIndex = entry.key;
                              final tarefa = entry.value;

                              print(
                                '📝 Renderizando tarefa: ${tarefa['motivacao']}',
                              );
                              return _buildTarefaCard(tarefa, tarefaIndex);
                            })
                          else
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Nenhuma tarefa atribuída',
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
