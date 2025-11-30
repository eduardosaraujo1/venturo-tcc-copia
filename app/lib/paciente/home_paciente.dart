import 'package:algumacoisa/paciente/notificacoes_screen.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:algumacoisa/paciente/agenda_paciente.dart';
import 'package:algumacoisa/paciente/emergencia_paciente.dart';
import 'package:algumacoisa/paciente/mensagems_paciente.dart';
import 'package:algumacoisa/paciente/perfil_paciente.dart';
import 'package:algumacoisa/paciente/sentimentos_paciente.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePaciente extends StatefulWidget {
  const HomePaciente({super.key});

  @override
  _HomePacienteState createState() => _HomePacienteState();
}

class _HomePacienteState extends State<HomePaciente> {
  int _selectedIndex = 2;
  Map<String, dynamic> _pacienteData = {};
  List<dynamic> _consultas = [];
  List<dynamic> _medicamentos = [];
  List<dynamic> _tarefas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosPaciente();
    _carregarAtribuicoes();
  }

  // Função para obter cor baseada no status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'feita':
        return Colors.green;
      case 'atrasada':
        return Colors.red;
      case 'pendente':
        return Colors.orange;
      case 'cancelada':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Função para obter ícone baseado no status
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'feita':
        return Icons.check_circle;
      case 'atrasada':
        return Icons.warning;
      case 'pendente':
        return Icons.access_time;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  // Função para obter texto do status
  String _getStatusText(String status) {
    switch (status) {
      case 'feita':
        return 'Concluída';
      case 'atrasada':
        return 'Atrasada';
      case 'pendente':
        return 'Pendente';
      case 'cancelada':
        return 'Cancelada';
      default:
        return 'Desconhecido';
    }
  }

  // Função para marcar como feito
  Future<void> _marcarComoFeito(String tipo, String id) async {
    try {
      String endpoint = '';

      switch (tipo) {
        case 'consulta':
          endpoint = '${Config.apiUrl}/api/consulta/$id/status';
          break;
        case 'medicamento':
          endpoint = '${Config.apiUrl}/api/medicamento/$id/status';
          break;
        case 'tarefa':
          endpoint = '${Config.apiUrl}/api/tarefa/$id/status';
          break;
      }

      final response = await http.put(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': 'feita'}),
      );

      if (response.statusCode == 200) {
        print('✅ $tipo marcado como feito');
        // Recarregar os dados
        _carregarAtribuicoes();

        // Mostrar snackbar de confirmação
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$tipo marcado como concluído!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Erro ao atualizar status');
      }
    } catch (error) {
      print('❌ Erro ao marcar como feito: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao marcar como concluído: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _carregarDadosPaciente() async {
    try {
      print('🔍 Iniciando requisição para a API...');
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/paciente/perfil'),
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Dados recebidos da API: $data');

        setState(() {
          _pacienteData = data;
        });
      } else {
        print('❌ Erro na API - Status: ${response.statusCode}');
        _usarDadosPadrao();
      }
    } catch (error) {
      print('💥 Erro na requisição: $error');
      _usarDadosPadrao();
    }
  }

  Future<void> _carregarAtribuicoes() async {
    try {
      print('📋 Carregando atribuições do paciente...');

      // Carregar consultas
      final consultasResponse = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComConsulta'),
      );
      if (consultasResponse.statusCode == 200) {
        final consultasData = json.decode(consultasResponse.body);
        setState(() {
          _consultas = consultasData['data'] ?? [];
        });
        print('✅ Consultas carregadas: ${_consultas.length}');
      }

      // Carregar medicamentos
      final medicamentosResponse = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComMedicamentos'),
      );
      if (medicamentosResponse.statusCode == 200) {
        final medicamentosData = json.decode(medicamentosResponse.body);
        setState(() {
          _medicamentos = medicamentosData['data'] ?? [];
        });
        print('✅ Medicamentos carregados: ${_medicamentos.length}');
      }

      // Carregar tarefas
      final tarefasResponse = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComTarefas'),
      );
      if (tarefasResponse.statusCode == 200) {
        final tarefasData = json.decode(tarefasResponse.body);
        setState(() {
          _tarefas = tarefasData['data'] ?? [];
        });
        print('✅ Tarefas carregadas: ${_tarefas.length}');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (error) {
      print('💥 Erro ao carregar atribuições: $error');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _usarDadosPadrao() {
    print('🔄 Usando dados padrão...');
    setState(() {
      _pacienteData = {'nome': 'Paulo', 'foto_url': 'assets/Paulosikera.jpg'};
    });
  }

  // Função para obter a letra inicial do nome
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

  // Função para formatar data/hora
  String _formatarDataHora(String dataHora) {
    try {
      DateTime dateTime = DateTime.parse(dataHora);
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dataHora;
    }
  }

  // Função para obter consultas de hoje
  List<dynamic> _getConsultasDeHoje() {
    final hoje = DateTime.now();
    return _consultas.expand((paciente) => paciente['consultas'] ?? []).where((
      consulta,
    ) {
      if (consulta['hora_consulta'] == null) return false;
      try {
        final dataConsulta = DateTime.parse(consulta['hora_consulta']);
        return dataConsulta.year == hoje.year &&
            dataConsulta.month == hoje.month &&
            dataConsulta.day == hoje.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  // Função para obter medicamentos de hoje
  List<dynamic> _getMedicamentosDeHoje() {
    final hoje = DateTime.now();
    return _medicamentos
        .expand((paciente) => paciente['medicamentos'] ?? [])
        .where((medicamento) {
          if (medicamento['data_hora'] == null) return false;
          try {
            final dataMedicamento = DateTime.parse(medicamento['data_hora']);
            return dataMedicamento.year == hoje.year &&
                dataMedicamento.month == hoje.month &&
                dataMedicamento.day == hoje.day;
          } catch (e) {
            return false;
          }
        })
        .toList();
  }

  // Função para obter tarefas de hoje
  List<dynamic> _getTarefasDeHoje() {
    final hoje = DateTime.now();
    return _tarefas.expand((paciente) => paciente['tarefas'] ?? []).where((
      tarefa,
    ) {
      if (tarefa['data_tarefa'] == null) return false;
      try {
        final dataTarefa = DateTime.parse(tarefa['data_tarefa']);
        return dataTarefa.year == hoje.year &&
            dataTarefa.month == hoje.month &&
            dataTarefa.day == hoje.day;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AgendaPaciente()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ConversasPaciente()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SentimentosPaciente()),
        );
        break;
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tem certeza de que deseja enviar um alerta de emergência?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmergenciaPaciente(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'SIM, PRECISO DE AJUDA',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'CANCELAR',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final consultasDeHoje = _getConsultasDeHoje();
    final medicamentosDeHoje = _getMedicamentosDeHoje();
    final tarefasDeHoje = _getTarefasDeHoje();
    final nomeCompleto = _pacienteData['nome'] ?? 'Paciente';
    final inicial = _getInicial(nomeCompleto);
    final avatarColor = _getAvatarColor(inicial);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(avatarColor, inicial),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final padding = isSmallScreen
              ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0)
              : EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.1,
                  vertical: 20.0,
                );

          return SingleChildScrollView(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildInfoCard(
                    context: context,
                    icon: Icons.warning_amber_outlined,
                    title: 'Emergência',
                    subtitle: 'Clique para pedir ajuda',
                    iconColor: Colors.red,
                    onTap: _showEmergencyDialog,
                    isSmallScreen: isSmallScreen,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Hoje:',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Exibir tarefas de hoje
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (tarefasDeHoje.isEmpty &&
                      medicamentosDeHoje.isEmpty &&
                      consultasDeHoje.isEmpty)
                    _buildInfoCard(
                      context: context,
                      icon: Icons.check_circle_outline,
                      title: 'Nenhuma atividade para hoje',
                      subtitle: 'Aproveite para descansar!',
                      iconColor: Colors.green,
                      onTap: () {},
                      isSmallScreen: isSmallScreen,
                    )
                  else
                    _buildAtividadesList(
                      tarefasDeHoje: tarefasDeHoje,
                      medicamentosDeHoje: medicamentosDeHoje,
                      consultasDeHoje: consultasDeHoje,
                      isSmallScreen: isSmallScreen,
                    ),

                  SizedBox(height: isSmallScreen ? 100 : 120),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildAtividadesList({
    required List<dynamic> tarefasDeHoje,
    required List<dynamic> medicamentosDeHoje,
    required List<dynamic> consultasDeHoje,
    required bool isSmallScreen,
  }) {
    final todasAtividades = [
      ...tarefasDeHoje.map((t) => _AtividadeItem(t, 'tarefa')),
      ...medicamentosDeHoje.map((m) => _AtividadeItem(m, 'medicamento')),
      ...consultasDeHoje.map((c) => _AtividadeItem(c, 'consulta')),
    ];

    // Ordenar por horário se disponível
    todasAtividades.sort((a, b) {
      final horaA = _extrairHora(a.item);
      final horaB = _extrairHora(b.item);
      return horaA.compareTo(horaB);
    });

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: todasAtividades.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: isSmallScreen ? 8 : 12),
      itemBuilder: (context, index) {
        final atividade = todasAtividades[index];
        return _buildInfoCardComStatus(
          context: context,
          icon: _getIconPorTipo(atividade.tipo),
          title: _getTituloPorTipo(atividade.item, atividade.tipo),
          subtitle: _getSubtituloPorTipo(atividade.item, atividade.tipo),
          iconColor: const Color.fromARGB(255, 106, 186, 213),
          status: atividade.item['status'] ?? 'pendente',
          tipo: atividade.tipo,
          id: atividade.item['id'].toString(),
          onTap: () {},
          isSmallScreen: isSmallScreen,
        );
      },
    );
  }

  DateTime _extrairHora(Map<String, dynamic> item) {
    try {
      final dataHora =
          item['data_hora'] ?? item['hora_consulta'] ?? item['data_tarefa'];
      if (dataHora != null) {
        return DateTime.parse(dataHora);
      }
    } catch (e) {
      print('Erro ao extrair hora: $e');
    }
    return DateTime.now();
  }

  IconData _getIconPorTipo(String tipo) {
    switch (tipo) {
      case 'tarefa':
        return Icons.task_alt;
      case 'medicamento':
        return Icons.medical_services_outlined;
      case 'consulta':
        return Icons.person_pin_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getTituloPorTipo(Map<String, dynamic> item, String tipo) {
    switch (tipo) {
      case 'tarefa':
        return item['motivacao'] ?? 'Tarefa';
      case 'medicamento':
        return item['medicamento_nome'] ?? 'Medicamento';
      case 'consulta':
        return item['especialidade'] ?? 'Consulta';
      default:
        return 'Atividade';
    }
  }

  String _getSubtituloPorTipo(Map<String, dynamic> item, String tipo) {
    switch (tipo) {
      case 'tarefa':
        return item['descricao'] ?? 'Descrição não disponível';
      case 'medicamento':
        return '${item['dosagem'] ?? 'Dosagem não informada'} - ${_formatarDataHora(item['data_hora'] ?? '')}';
      case 'consulta':
        return '${item['medico_nome'] ?? 'Médico'} - ${_formatarDataHora(item['hora_consulta'] ?? '')}';
      default:
        return 'Detalhes não disponíveis';
    }
  }

  PreferredSizeWidget _buildAppBar(Color avatarColor, String inicial) {
    return AppBar(
      toolbarHeight: 100,
      backgroundColor: const Color.fromARGB(0, 25, 190, 25),
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 106, 186, 213),
                  Color.fromARGB(255, 106, 186, 213),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                top: isSmallScreen ? 40 : 50,
                left: isSmallScreen ? 16 : 24,
                right: isSmallScreen ? 16 : 24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PerfilPaciente(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        // Avatar com inicial do nome
                        CircleAvatar(
                          backgroundColor: avatarColor,
                          radius: isSmallScreen ? 24 : 28,
                          child: Text(
                            inicial,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Bem-vindo, ${_pacienteData['nome'] ?? 'Paciente'}.',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: isSmallScreen ? 24 : 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Notificacoes()),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool isSmallScreen,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: isSmallScreen
              ? const EdgeInsets.all(16.0)
              : const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: isSmallScreen ? 40 : 48, color: iconColor),
              SizedBox(width: isSmallScreen ? 16 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 16 : 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCardComStatus({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required String status,
    required String tipo,
    required String id,
    required bool isSmallScreen,
    VoidCallback? onTap,
  }) {
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusText = _getStatusText(status);
    final podeMarcarComoFeito = status != 'feita' && status != 'cancelada';

    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: isSmallScreen
              ? const EdgeInsets.all(16.0)
              : const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: isSmallScreen ? 40 : 48, color: iconColor),
              SizedBox(width: isSmallScreen ? 16 : 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 16 : 18,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Badge de status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusIcon,
                            size: isSmallScreen ? 14 : 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Botão para marcar como feito
              if (podeMarcarComoFeito)
                IconButton(
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: isSmallScreen ? 24 : 28,
                  ),
                  onPressed: () => _marcarComoFeito(tipo, id),
                  tooltip: 'Marcar como concluído',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return BottomAppBar(
          padding: isSmallScreen
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(horizontal: constraints.maxWidth * 0.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildBottomNavItem(
                icon: Icons.calendar_today_outlined,
                index: 0,
                isSmallScreen: isSmallScreen,
              ),
              _buildBottomNavItem(
                icon: Icons.mail_outline,
                index: 1,
                isSmallScreen: isSmallScreen,
              ),
              _buildBottomNavItem(
                icon: Icons.home,
                index: 2,
                isSmallScreen: isSmallScreen,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required int index,
    required bool isSmallScreen,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: _selectedIndex == index
            ? const Color.fromARGB(255, 106, 186, 213)
            : Colors.grey,
        size: isSmallScreen ? 24 : 28,
      ),
      onPressed: () => _onItemTapped(index),
    );
  }
}

class _AtividadeItem {
  final Map<String, dynamic> item;
  final String tipo;

  _AtividadeItem(this.item, this.tipo);
}
