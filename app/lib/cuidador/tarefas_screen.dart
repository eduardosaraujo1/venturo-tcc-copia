import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TarefasScreen extends StatefulWidget {
  const TarefasScreen({super.key});

  @override
  State<TarefasScreen> createState() => _TarefasScreenState();
}

class _TarefasScreenState extends State<TarefasScreen> {
  List<dynamic> pacientes = [];
  List<dynamic> pacientesFiltrados = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _carregarTarefas();
  }

  Future<void> _carregarTarefas() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComTarefas'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          pacientes = data['data'];
          pacientesFiltrados = pacientes;
          isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar tarefas');
      }
    } catch (error) {
      print('Erro: $error');
      setState(() {
        isLoading = false;
      });
      _mostrarErroSnackbar('Erro ao carregar tarefas');
    }
  }

  // Função para atualizar status da tarefa
  Future<void> _atualizarStatusTarefa(String id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.apiUrl}/api/tarefa/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        _carregarTarefas(); // Recarrega os dados
        _mostrarSucessoSnackbar('Status atualizado com sucesso!');
      } else {
        throw Exception('Falha ao atualizar status');
      }
    } catch (error) {
      _mostrarErroSnackbar('Erro ao atualizar status');
    }
  }

  void _filtrarPacientes(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        pacientesFiltrados = pacientes;
      } else {
        pacientesFiltrados = pacientes.where((paciente) {
          final nome = paciente['nome'].toString().toLowerCase();
          final tarefas = paciente['tarefas'] ?? [];
          final hasTarefaComTexto = tarefas.any((tarefa) {
            final motivacao =
                tarefa['motivacao']?.toString().toLowerCase() ?? '';
            final descricao =
                tarefa['descricao']?.toString().toLowerCase() ?? '';
            return motivacao.contains(query.toLowerCase()) ||
                descricao.contains(query.toLowerCase());
          });
          return nome.contains(query.toLowerCase()) || hasTarefaComTexto;
        }).toList();
      }
    });
  }

  void _mostrarErroSnackbar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  void _mostrarSucessoSnackbar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.green),
    );
  }

  String _formatarData(String data) {
    try {
      final dateTime = DateTime.parse(data);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return data;
    }
  }

  String _formatarStatus(String status) {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'feita':
        return 'Concluída';
      case 'atrasada':
        return 'Atrasada';
      case 'cancelada':
        return 'Cancelada';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orange;
      case 'feita':
        return Colors.green;
      case 'atrasada':
        return Colors.red;
      case 'cancelada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getInicial(String nome) {
    if (nome.isEmpty) return '?';
    return nome[0].toUpperCase();
  }

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

    if (letra.isEmpty || letra == '?')
      return const Color.fromARGB(255, 0, 0, 0);
    final index = letra.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  // Diálogo para escolher status
  void _mostrarDialogoStatusTarefa(dynamic tarefa) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Alterar Status'),
          content: Text('Tarefa: ${tarefa['motivacao'] ?? 'Tarefa'}'),
          actions: [
            _buildBotaoStatus('pendente', 'Pendente', tarefa),
            _buildBotaoStatus('feita', 'Concluída', tarefa),
            _buildBotaoStatus('atrasada', 'Atrasada', tarefa),
            _buildBotaoStatus('cancelada', 'Cancelada', tarefa),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBotaoStatus(String status, String label, dynamic tarefa) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
        _atualizarStatusTarefa(tarefa['id'].toString(), status);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Tarefas'),
        centerTitle: true,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _carregarTarefas),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              onChanged: _filtrarPacientes,
              decoration: InputDecoration(
                hintText: 'Buscar pacientes ou tarefas...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            SizedBox(height: 16),
            if (isLoading)
              Expanded(child: Center(child: CircularProgressIndicator()))
            else if (pacientesFiltrados.isEmpty && searchQuery.isNotEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum paciente encontrado para "$searchQuery"',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
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
                      Icon(Icons.task, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum paciente com tarefas encontrado',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _carregarTarefas,
                  child: ListView(
                    children: pacientesFiltrados.map<Widget>((paciente) {
                      final tarefas = paciente['tarefas'] ?? [];

                      if (tarefas.isEmpty) return SizedBox.shrink();

                      final inicial = _getInicial(paciente['nome'] ?? '');
                      final avatarColor = _getAvatarColor(inicial);

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cabeçalho do paciente
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: avatarColor,
                                    radius: 25,
                                    child: Text(
                                      inicial,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Nome do paciente
                                        Text(
                                          paciente['nome'] ??
                                              'Nome não informado',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        // Idade
                                        if (paciente['idade'] != null)
                                          Text(
                                            '${paciente['idade']} anos',
                                            style: TextStyle(
                                              color: Colors.grey[700],
                                              fontSize: 14,
                                            ),
                                          ),
                                        // Comorbidade
                                        if (paciente['comorbidade'] != null)
                                          Text(
                                            paciente['comorbidade'] ?? '',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        // Contador de tarefas
                                        Text(
                                          '${tarefas.length} tarefa${tarefas.length > 1 ? 's' : ''}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              // Lista de tarefas
                              ...tarefas.map<Widget>((tarefa) {
                                final status = tarefa['status'] ?? 'pendente';
                                return Card(
                                  margin: EdgeInsets.only(bottom: 8),
                                  elevation: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        // Ícone da tarefa
                                        Icon(
                                          Icons.task,
                                          color: _getStatusColor(status),
                                        ),
                                        SizedBox(width: 12),
                                        // Informações da tarefa
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Motivação
                                              if (tarefa['motivacao'] != null)
                                                Text(
                                                  tarefa['motivacao'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              // Descrição
                                              if (tarefa['descricao'] != null)
                                                SizedBox(height: 4),
                                              if (tarefa['descricao'] != null)
                                                Text(
                                                  tarefa['descricao'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              // Data
                                              if (tarefa['data_tarefa'] != null)
                                                SizedBox(height: 4),
                                              if (tarefa['data_tarefa'] != null)
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      _formatarData(
                                                        tarefa['data_tarefa'],
                                                      ),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Status e botão editar
                                        Column(
                                          children: [
                                            // Status
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                  status,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: _getStatusColor(
                                                    status,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                _formatarStatus(status),
                                                style: TextStyle(
                                                  color: _getStatusColor(
                                                    status,
                                                  ),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            // Botão editar
                                            IconButton(
                                              icon: Icon(Icons.edit, size: 16),
                                              onPressed: () =>
                                                  _mostrarDialogoStatusTarefa(
                                                    tarefa,
                                                  ),
                                              tooltip: 'Alterar status',
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
