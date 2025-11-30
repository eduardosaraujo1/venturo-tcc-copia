import 'package:algumacoisa/cuidador/home_cuidador_screen.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// =======================
// 1. MODELO DE REGISTRO DIÁRIO
// =======================
class RegistroDiario {
  final int id;
  final int pacienteId;
  final String pacienteNome;
  final int? pacienteIdade;
  final String? tipoSanguineo;
  final String? comorbidade;
  final String? atividadesRealizadas;
  final String? outrasAtividades;
  final String? observacoesGerais;
  final String? estadoGeral;
  final String? observacoesSentimentos;
  final double? temperatura;
  final double? glicemia;
  final String? pressaoArterial;
  final String? outrasObservacoes;
  final String dataRegistro;
  final String dataFormatada;

  RegistroDiario({
    required this.id,
    required this.pacienteId,
    required this.pacienteNome,
    this.pacienteIdade,
    this.tipoSanguineo,
    this.comorbidade,
    this.atividadesRealizadas,
    this.outrasAtividades,
    this.observacoesGerais,
    this.estadoGeral,
    this.observacoesSentimentos,
    this.temperatura,
    this.glicemia,
    this.pressaoArterial,
    this.outrasObservacoes,
    required this.dataRegistro,
    required this.dataFormatada,
  });

  factory RegistroDiario.fromJson(Map<String, dynamic> json) {
    return RegistroDiario(
      id: json['id'] ?? 0,
      pacienteId: json['paciente_id'] ?? 0,
      pacienteNome: json['paciente_nome'] ?? 'Nome não informado',
      pacienteIdade: json['paciente_idade'] is int
          ? json['paciente_idade']
          : int.tryParse(json['paciente_idade'].toString()),
      tipoSanguineo: json['tipo_sanguineo']?.toString(),
      comorbidade: json['comorbidade']?.toString(),
      atividadesRealizadas: json['atividades_realizadas']?.toString(),
      outrasAtividades: json['outras_atividades']?.toString(),
      observacoesGerais: json['observacoes_gerais']?.toString(),
      estadoGeral: json['estado_geral']?.toString(),
      observacoesSentimentos: json['observacoes_sentimentos']?.toString(),
      temperatura: json['temperatura'] is double
          ? json['temperatura']
          : double.tryParse(json['temperatura'].toString()),
      glicemia: json['glicemia'] is double
          ? json['glicemia']
          : double.tryParse(json['glicemia'].toString()),
      pressaoArterial: json['pressao_arterial']?.toString(),
      outrasObservacoes: json['outras_observacoes']?.toString(),
      dataRegistro: json['data_registro']?.toString() ?? '',
      dataFormatada: json['data_formatada']?.toString() ?? 'Data não informada',
    );
  }
}

// =======================
// 2. TELA PRINCIPAL DE REGISTROS DIÁRIOS
// =======================
class VisualizarRegistrosScreen extends StatefulWidget {
  const VisualizarRegistrosScreen({super.key});

  @override
  _VisualizarRegistrosScreenState createState() =>
      _VisualizarRegistrosScreenState();
}

class _VisualizarRegistrosScreenState extends State<VisualizarRegistrosScreen> {
  late Future<List<RegistroDiario>> _registrosFuture;
  List<RegistroDiario> _allRegistros = [];
  List<RegistroDiario> _filteredRegistros = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _registrosFuture = _fetchRegistros();
    _searchController.addListener(_filterRegistros);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // =======================
  // 3. FUNÇÃO DE BUSCA DA API
  // =======================
  Future<List<RegistroDiario>> _fetchRegistros() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔍 Iniciando busca de registros diários...');
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/registrosdiarios'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic responseData = jsonDecode(response.body);
        List<RegistroDiario> registrosList = [];

        if (responseData is List) {
          registrosList = responseData
              .map<RegistroDiario>((json) => RegistroDiario.fromJson(json))
              .toList();
        } else if (responseData is Map && responseData['data'] is List) {
          registrosList = (responseData['data'] as List)
              .map<RegistroDiario>((json) => RegistroDiario.fromJson(json))
              .toList();
        } else if (responseData is Map && responseData['registros'] is List) {
          registrosList = (responseData['registros'] as List)
              .map<RegistroDiario>((json) => RegistroDiario.fromJson(json))
              .toList();
        } else {
          throw Exception('Formato de resposta não reconhecido');
        }

        setState(() {
          _allRegistros = registrosList;
          _filteredRegistros = registrosList;
          _isLoading = false;
        });

        print('✅ ${registrosList.length} registros carregados com sucesso');
        return registrosList;
      } else {
        throw Exception(
          'Falha ao carregar registros. Código: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Erro ao buscar registros: $e');
      setState(() {
        _error = 'Erro: $e';
        _isLoading = false;
      });
      return [];
    }
  }

  // =======================
  // 4. FUNÇÃO DE FILTRAGEM
  // =======================
  void _filterRegistros() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRegistros = _allRegistros;
      } else {
        _filteredRegistros = _allRegistros.where((registro) {
          return registro.pacienteNome.toLowerCase().contains(query) ||
              (registro.tipoSanguineo?.toLowerCase().contains(query) ??
                  false) ||
              (registro.comorbidade?.toLowerCase().contains(query) ?? false) ||
              (registro.estadoGeral?.toLowerCase().contains(query) ?? false) ||
              (registro.atividadesRealizadas?.toLowerCase().contains(query) ??
                  false);
        }).toList();
      }
    });
  }

  // =======================
  // 5. CARD DO REGISTRO DIÁRIO
  // =======================
  Widget _buildRegistroCard(RegistroDiario registro) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do Registro
            Row(
              children: [
                // Avatar do Paciente
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 106, 186, 213),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      registro.pacienteNome.isNotEmpty
                          ? registro.pacienteNome[0].toUpperCase()
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
                        registro.pacienteNome,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildInfoRow('📅', 'Data: ${registro.dataFormatada}'),
                      if (registro.pacienteIdade != null)
                        _buildInfoRow(
                          '👤',
                          'Idade: ${registro.pacienteIdade} anos',
                        ),
                      if (registro.tipoSanguineo != null)
                        _buildInfoRow(
                          '🩸',
                          'Tipo Sanguíneo: ${registro.tipoSanguineo}',
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Comorbidade
            if (registro.comorbidade != null &&
                registro.comorbidade!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text('🏥', style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Comorbidade: ${registro.comorbidade}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Seção de Atividades
            _buildAtividadesSection(registro),

            // Seção de Estado Geral
            _buildEstadoGeralSection(registro),

            // Seção de Sinais Clínicos
            _buildSinaisClinicosSection(registro),

            // Seção de Observações
            _buildObservacoesSection(registro),
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
  // 6. SEÇÃO DE ATIVIDADES
  // =======================
  Widget _buildAtividadesSection(RegistroDiario registro) {
    if (registro.atividadesRealizadas == null &&
        registro.outrasAtividades == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.assignment, size: 16, color: Colors.blue),
            const SizedBox(width: 6),
            const Text(
              'Atividades Realizadas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (registro.atividadesRealizadas != null)
          _buildInfoItem('📋 Atividades:', registro.atividadesRealizadas!),

        if (registro.outrasAtividades != null)
          _buildInfoItem('➕ Outras Atividades:', registro.outrasAtividades!),

        if (registro.observacoesGerais != null)
          _buildInfoItem('📝 Observações Gerais:', registro.observacoesGerais!),
      ],
    );
  }

  // =======================
  // 7. SEÇÃO DE ESTADO GERAL
  // =======================
  Widget _buildEstadoGeralSection(RegistroDiario registro) {
    if (registro.estadoGeral == null &&
        registro.observacoesSentimentos == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.mood, size: 16, color: Colors.green),
            const SizedBox(width: 6),
            const Text(
              'Estado Geral',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (registro.estadoGeral != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getEstadoGeralColor(
                registro.estadoGeral!,
              ).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getEstadoGeralColor(
                  registro.estadoGeral!,
                ).withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getEstadoGeralEmoji(registro.estadoGeral!),
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 6),
                Text(
                  _formatarEstadoGeral(registro.estadoGeral!),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getEstadoGeralColor(registro.estadoGeral!),
                  ),
                ),
              ],
            ),
          ),

        if (registro.observacoesSentimentos != null)
          _buildInfoItem('💬 Observações:', registro.observacoesSentimentos!),
      ],
    );
  }

  // =======================
  // 8. SEÇÃO DE SINAIS CLÍNICOS
  // =======================
  Widget _buildSinaisClinicosSection(RegistroDiario registro) {
    if (registro.temperatura == null &&
        registro.glicemia == null &&
        registro.pressaoArterial == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.monitor_heart, size: 16, color: Colors.red),
            const SizedBox(width: 6),
            const Text(
              'Sinais Clínicos',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            if (registro.temperatura != null)
              _buildSinalClinicoItem(
                '🌡️',
                'Temperatura',
                '${registro.temperatura}°C',
              ),

            if (registro.glicemia != null)
              _buildSinalClinicoItem(
                '🩸',
                'Glicemia',
                '${registro.glicemia} mg/dL',
              ),

            if (registro.pressaoArterial != null)
              _buildSinalClinicoItem(
                '❤️',
                'Pressão',
                registro.pressaoArterial!,
              ),
          ],
        ),
      ],
    );
  }

  // =======================
  // 9. SEÇÃO DE OBSERVAÇÕES
  // =======================
  Widget _buildObservacoesSection(RegistroDiario registro) {
    if (registro.outrasObservacoes == null) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.note, size: 16, color: Colors.orange),
            const SizedBox(width: 6),
            const Text(
              'Observações Adicionais',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        _buildInfoItem('📋', registro.outrasObservacoes!),
      ],
    );
  }

  Widget _buildInfoItem(String prefixo, String texto) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(prefixo, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSinalClinicoItem(String emoji, String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            titulo,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D3B51),
            ),
          ),
        ],
      ),
    );
  }

  // =======================
  // 10. FUNÇÕES AUXILIARES
  // =======================
  String _formatarEstadoGeral(String estado) {
    switch (estado.toLowerCase()) {
      case 'muito bem':
        return 'Muito Bem';
      case 'bem':
        return 'Bem';
      case 'mal':
        return 'Mal';
      case 'muito mal':
        return 'Muito Mal';
      default:
        return estado;
    }
  }

  String _getEstadoGeralEmoji(String estado) {
    switch (estado.toLowerCase()) {
      case 'muito bem':
        return '😊';
      case 'bem':
        return '🙂';
      case 'mal':
        return '😕';
      case 'muito mal':
        return '😞';
      default:
        return '😐';
    }
  }

  Color _getEstadoGeralColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'muito bem':
        return Colors.green;
      case 'bem':
        return Colors.lightGreen;
      case 'mal':
        return Colors.orange;
      case 'muito mal':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
      _registrosFuture = _fetchRegistros();
    });
  }

  // =======================
  // 12. BOTÃO HOME
  // =======================
  void _irParaHome() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeCuidadorScreen()),
    );
  }

  // =======================
  // 13. CONSTRUÇÃO DA TELA
  // =======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeCuidadorScreen()),
            );
          },
        ),
        title: const Text(
          'Registros Diários',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          // Botão Home
          IconButton(
            icon: const Icon(Icons.home, color: Colors.blue),
            onPressed: _irParaHome,
            tooltip: 'Ir para Home',
          ),
          // Botão Atualizar
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
                hintText: 'Buscar por nome, tipo sanguíneo, comorbidade...',
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
            if (_filteredRegistros.isNotEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_filteredRegistros.length} registro(s) encontrado(s)',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),

            // Lista Dinâmica de Registros
            Expanded(
              child: FutureBuilder<List<RegistroDiario>>(
                future: _registrosFuture,
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
                            Icons.assignment_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Nenhum registro encontrado',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          Text(
                            'Os registros diários aparecerão aqui',
                            style: TextStyle(color: Colors.grey),
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
                        itemCount: _filteredRegistros.length,
                        itemBuilder: (context, index) {
                          return _buildRegistroCard(_filteredRegistros[index]);
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
