import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// =======================
// 1. MODELOS DE DADOS
// =======================
class Consulta {
  final int id;
  final String tipoConsulta;
  final String especialidade;
  final String medicoNome;
  final String crmMedico;
  final String horaConsulta;
  final String localConsulta;
  final String enderecoConsulta;
  final String status;

  Consulta({
    required this.id,
    required this.tipoConsulta,
    required this.especialidade,
    required this.medicoNome,
    required this.crmMedico,
    required this.horaConsulta,
    required this.localConsulta,
    required this.enderecoConsulta,
    required this.status,
  });

  factory Consulta.fromJson(Map<String, dynamic> json) {
    return Consulta(
      id: json['id'] ?? 0,
      tipoConsulta: json['tipo_consulta'] ?? 'N/A',
      especialidade: json['especialidade'] ?? 'N/A',
      medicoNome: json['medico_nome'] ?? 'N/A',
      crmMedico: json['crm_medico'] ?? 'N/A',
      horaConsulta: json['hora_consulta'] ?? 'N/A',
      localConsulta: json['local_consulta'] ?? 'N/A',
      enderecoConsulta: json['endereco_consulta'] ?? 'N/A',
      status: json['status'] ?? 'pendente',
    );
  }
}

class Paciente {
  final int id;
  final String nome;
  final String? tipoSanguineo;
  final String? comorbidade;
  final int? idade;
  final List<Consulta> consultas;

  Paciente({
    required this.id,
    required this.nome,
    this.tipoSanguineo,
    this.comorbidade,
    this.idade,
    this.consultas = const [],
  });

  factory Paciente.fromJson(Map<String, dynamic> json) {
    final consultasJson = json['consultas'] as List? ?? [];
    return Paciente(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      nome: json['nome']?.toString() ?? 'Nome não informado',
      tipoSanguineo: json['tipo_sanguineo']?.toString(),
      comorbidade: json['comorbidade']?.toString(),
      idade: json['idade'] is int
          ? json['idade']
          : int.tryParse(json['idade'].toString()),
      consultas: consultasJson.map((c) => Consulta.fromJson(c)).toList(),
    );
  }
}

// =======================
// 2. TELA PRINCIPAL
// =======================
class ConsultasScreen extends StatefulWidget {
  const ConsultasScreen({super.key});

  @override
  _ConsultasScreenState createState() => _ConsultasScreenState();
}

class _ConsultasScreenState extends State<ConsultasScreen> {
  late Future<List<Paciente>> _pacientesFuture;
  List<Paciente> _allPacientes = [];
  List<Paciente> _filteredPacientes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pacientesFuture = _fetchPacientes();
    _searchController.addListener(_filterPacientes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =======================
  // 3. FUNÇÃO DE BUSCA DA API
  // =======================
  Future<List<Paciente>> _fetchPacientes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 Iniciando busca de pacientes...');
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComConsulta'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        List<Paciente> pacientesList = [];

        if (responseData is List) {
          pacientesList = responseData
              .map<Paciente>((json) => Paciente.fromJson(json))
              .toList();
        } else if (responseData is Map && responseData['data'] is List) {
          pacientesList = (responseData['data'] as List)
              .map<Paciente>((json) => Paciente.fromJson(json))
              .toList();
        } else if (responseData is Map && responseData['pacientes'] is List) {
          pacientesList = (responseData['pacientes'] as List)
              .map<Paciente>((json) => Paciente.fromJson(json))
              .toList();
        } else {
          throw Exception('Formato de resposta não reconhecido');
        }

        setState(() {
          _allPacientes = pacientesList;
          _filteredPacientes = pacientesList;
          _isLoading = false;
        });

        print('✅ ${pacientesList.length} pacientes carregados com sucesso');
        return pacientesList;
      } else {
        throw Exception(
          'Falha ao carregar pacientes. Código: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Erro ao buscar pacientes: $e');
      setState(() {
        _error = 'Erro: $e';
        _isLoading = false;
      });
      return [];
    }
  }

  // =======================
  // 4. FUNÇÃO PARA ATUALIZAR STATUS DA CONSULTA
  // =======================
  Future<void> _atualizarStatusConsulta(String id, String status) async {
    try {
      final response = await http.put(
        Uri.parse('${Config.apiUrl}/api/consulta/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );

      if (response.statusCode == 200) {
        _refreshData(); // Recarrega os dados
        _mostrarSucessoSnackbar('Status atualizado com sucesso!');
      } else {
        throw Exception('Falha ao atualizar status');
      }
    } catch (error) {
      _mostrarErroSnackbar('Erro ao atualizar status');
    }
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

  // =======================
  // 5. FUNÇÃO DE FILTRAGEM
  // =======================
  void _filterPacientes() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPacientes = _allPacientes;
      } else {
        _filteredPacientes = _allPacientes.where((paciente) {
          return paciente.nome.toLowerCase().contains(query) ||
              (paciente.tipoSanguineo?.toLowerCase().contains(query) ??
                  false) ||
              (paciente.comorbidade?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  // =======================
  // 6. CARD DO PACIENTE COM CONSULTAS
  // =======================
  Widget _buildPacienteCard(Paciente paciente) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do Paciente
            Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 106, 186, 213),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      paciente.nome.isNotEmpty
                          ? paciente.nome[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
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
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow(
                        '',
                        'Idade: ${paciente.idade ?? "N/A"} anos',
                      ),
                      _buildInfoRow(
                        '',
                        'Tipo Sanguíneo: ${paciente.tipoSanguineo ?? "N/A"}',
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Comorbidade
            if (paciente.comorbidade != null &&
                paciente.comorbidade!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Comorbidade: ${paciente.comorbidade}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Seção de Consultas
            _buildConsultasSection(paciente.consultas),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // =======================
  // 7. SEÇÃO DE CONSULTAS
  // =======================
  Widget _buildConsultasSection(List<Consulta> consultas) {
    if (consultas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Text(
              'Nenhuma consulta agendada',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título da seção de consultas
        Row(
          children: [
            const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
            const SizedBox(width: 6),
            Text(
              'Consultas (${consultas.length})',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Lista de consultas
        ...consultas.map((consulta) => _buildConsultaCard(consulta)),
      ],
    );
  }

  // =======================
  // 8. CARD DA CONSULTA COM BOTÃO DE STATUS
  // =======================
  Widget _buildConsultaCard(Consulta consulta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(consulta.status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(consulta.status).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Linha superior: Tipo e Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '🩺 ${consulta.tipoConsulta}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(consulta.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatarStatus(consulta.status),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                    onPressed: () => _mostrarDialogoStatusConsulta(consulta),
                    tooltip: 'Alterar status',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Médico
          Text(
            ' Dr. ${consulta.medicoNome} (CRM: ${consulta.crmMedico})',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),

          // Local e Horário
          Row(
            children: [
              const Icon(Icons.location_on, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  consulta.localConsulta,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.access_time, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                _formatarDataHora(consulta.horaConsulta),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),

          // Especialidade
          if (consulta.especialidade.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                ' ${consulta.especialidade}',
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ),
        ],
      ),
    );
  }

  // =======================
  // 9. FUNÇÕES AUXILIARES
  // =======================
  String _formatarDataHora(String dataHora) {
    try {
      final dateTime = DateTime.parse(dataHora);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dataHora;
    }
  }

  String _formatarStatus(String status) {
    switch (status) {
      case 'pendente':
        return 'Pendente';
      case 'feita':
        return 'Realizada';
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

  // =======================
  // 10. DIÁLOGO PARA ALTERAR STATUS
  // =======================
  void _mostrarDialogoStatusConsulta(Consulta consulta) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Alterar Status da Consulta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Paciente: ${_encontrarNomePaciente(consulta.id)}'),
              Text('Médico: Dr. ${consulta.medicoNome}'),
              Text('Data: ${_formatarDataHora(consulta.horaConsulta)}'),
            ],
          ),
          actions: [
            _buildBotaoStatus('pendente', 'Pendente', consulta),
            _buildBotaoStatus('feita', 'Realizada', consulta),
            _buildBotaoStatus('atrasada', 'Atrasada', consulta),
            _buildBotaoStatus('cancelada', 'Cancelada', consulta),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBotaoStatus(String status, String label, Consulta consulta) {
    return TextButton(
      onPressed: () {
        Navigator.of(context).pop();
        _atualizarStatusConsulta(consulta.id.toString(), status);
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
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  String _encontrarNomePaciente(int consultaId) {
    for (final paciente in _allPacientes) {
      for (final consulta in paciente.consultas) {
        if (consulta.id == consultaId) {
          return paciente.nome;
        }
      }
    }
    return 'Paciente não encontrado';
  }

  // =======================
  // 11. WIDGET DE ERRO
  // =======================
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Erro desconhecido',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 106, 186, 213),
            ),
            child: const Text(
              'Tentar Novamente',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    setState(() {
      _pacientesFuture = _fetchPacientes();
    });
  }

  // =======================
  // 12. CONSTRUÇÃO DA TELA
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pacientes e Consultas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.blue),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Campo de Busca
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, tipo sanguíneo ou comorbidade...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 20.0,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Indicador de Carregamento
            if (_isLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ],

            // Contador de resultados
            if (_filteredPacientes.isNotEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_filteredPacientes.length} paciente(s) encontrado(s)',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),

            // Lista Dinâmica de Pacientes
            Expanded(
              child: FutureBuilder<List<Paciente>>(
                future: _pacientesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return _buildErrorWidget();
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum paciente encontrado',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return RefreshIndicator(
                      onRefresh: () async {
                        _refreshData();
                        await Future.delayed(const Duration(seconds: 1));
                      },
                      child: ListView.builder(
                        itemCount: _filteredPacientes.length,
                        itemBuilder: (context, index) {
                          return _buildPacienteCard(_filteredPacientes[index]);
                        },
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
