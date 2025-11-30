import 'package:algumacoisa/familiar/home_familiar.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificacoesFamiliar extends StatefulWidget {
  const NotificacoesFamiliar({super.key});

  @override
  State<NotificacoesFamiliar> createState() => _NotificacoesFamiliar();
}

class _NotificacoesFamiliar extends State<NotificacoesFamiliar> {
  List<dynamic> _pacientesComConsultas = [];
  List<dynamic> _pacientesComMedicamentos = [];
  List<dynamic> _pacientesComTarefas = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final responses = await Future.wait([
        http.get(
          Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComConsulta'),
        ),
        http.get(
          Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComMedicamentos'),
        ),
        http.get(Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComTarefas')),
      ]);

      for (int i = 0; i < responses.length; i++) {
        final response = responses[i];
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true) {
            setState(() {
              switch (i) {
                case 0:
                  _pacientesComConsultas = data['data'];
                  break;
                case 1:
                  _pacientesComMedicamentos = data['data'];
                  break;
                case 2:
                  _pacientesComTarefas = data['data'];
                  break;
              }
            });
          }
        } else {
          throw Exception('Erro ao carregar dados da API ${i + 1}');
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar notificações: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day} ${_getMonthName(date.month)}';
    } catch (e) {
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ',
    ];
    return months[month - 1];
  }

  String _calculateDaysLeft(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = date.difference(now);
      final days = difference.inDays;

      if (days == 0) return 'Hoje!';
      if (days == 1) return 'Falta 1 dia!';
      if (days > 1) return 'Faltam $days dias!';
      if (days == -1) return 'Há 1 dia';
      if (days < -1) return 'Há ${days.abs()} dias';

      return 'Data inválida';
    } catch (e) {
      return 'Data inválida';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendente':
        return Colors.orange;
      case 'concluído':
        return Colors.green;
      case 'cancelado':
        return Colors.red;
      case 'atrasado':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'consultas':
        return Icons.medical_services_outlined;
      case 'medicamentos':
        return Icons.medication_outlined;
      case 'tarefas':
        return Icons.task_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'consultas':
        return const Color(0xFF6ABAD5);
      case 'medicamentos':
        return const Color(0xFF4CAF50);
      case 'tarefas':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF6ABAD5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // AppBar personalizada
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Color(0xFF6ABAD5),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeFamiliar()),
                );
              },
            ),
            title: const Text(
              'Notificações',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            centerTitle: false,
          ),

          // Conteúdo principal
          SliverToBoxAdapter(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage.isNotEmpty
                ? _buildErrorState()
                : _buildContent(isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 300,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6ABAD5)),
            ),
            SizedBox(height: 16),
            Text(
              'Carregando notificações...',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6ABAD5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Tentar Novamente',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isTablet) {
    final hasConsultas = _pacientesComConsultas.isNotEmpty;
    final hasMedicamentos = _pacientesComMedicamentos.isNotEmpty;
    final hasTarefas = _pacientesComTarefas.isNotEmpty;

    if (!hasConsultas && !hasMedicamentos && !hasTarefas) {
      return _buildEmptyState();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 16,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasConsultas) ...[
            _buildSectionHeader('Consultas', 'consultas'),
            const SizedBox(height: 16),
            _buildConsultasSection(isTablet),
            const SizedBox(height: 24),
          ],

          if (hasMedicamentos) ...[
            _buildSectionHeader('Medicamentos', 'medicamentos'),
            const SizedBox(height: 16),
            _buildMedicamentosSection(isTablet),
            const SizedBox(height: 24),
          ],

          if (hasTarefas) ...[
            _buildSectionHeader('Tarefas', 'tarefas'),
            const SizedBox(height: 16),
            _buildTarefasSection(isTablet),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_rounded,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma notificação',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Você não tem notificações no momento',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String category) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getCategoryColor(category).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(category),
            color: _getCategoryColor(category),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildConsultasSection(bool isTablet) {
    return isTablet
        ? _buildGridCards('consultas')
        : Column(children: _buildConsultasCards());
  }

  Widget _buildMedicamentosSection(bool isTablet) {
    return isTablet
        ? _buildGridCards('medicamentos')
        : Column(children: _buildMedicamentosCards());
  }

  Widget _buildTarefasSection(bool isTablet) {
    return isTablet
        ? _buildGridCards('tarefas')
        : Column(children: _buildTarefasCards());
  }

  Widget _buildGridCards(String category) {
    List<Map<String, dynamic>> items = [];

    switch (category) {
      case 'consultas':
        for (var paciente in _pacientesComConsultas) {
          for (var consulta in paciente['consultas']) {
            items.add({
              'date': consulta['hora_consulta'],
              'title': 'Consulta: ${consulta['especialidade']}',
              'subtitle':
                  'Paciente: ${paciente['nome']} - ${consulta['medico_nome']}',
              'description':
                  consulta['local_consulta'] ??
                  consulta['endereco_consulta'] ??
                  '',
              'status': consulta['status'],
              'category': category,
            });
          }
        }
        break;
      case 'medicamentos':
        for (var paciente in _pacientesComMedicamentos) {
          for (var medicamento in paciente['medicamentos']) {
            items.add({
              'date': medicamento['data_hora'],
              'title': 'Medicação: ${medicamento['medicamento_nome']}',
              'subtitle':
                  'Paciente: ${paciente['nome']} - ${medicamento['dosagem']}',
              'description':
                  'Horário: ${DateTime.parse(medicamento['data_hora']).hour.toString().padLeft(2, '0')}:${DateTime.parse(medicamento['data_hora']).minute.toString().padLeft(2, '0')}',
              'status': medicamento['status'],
              'category': category,
            });
          }
        }
        break;
      case 'tarefas':
        for (var paciente in _pacientesComTarefas) {
          for (var tarefa in paciente['tarefas']) {
            items.add({
              'date': tarefa['data_tarefa'],
              'title': 'Tarefa: ${tarefa['motivacao']}',
              'subtitle': 'Paciente: ${paciente['nome']}',
              'description': tarefa['descricao'] ?? '',
              'status': tarefa['status'],
              'category': category,
            });
          }
        }
        break;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildNotificationCard(
          _formatDate(item['date']),
          item['title'],
          item['subtitle'],
          item['description'],
          _calculateDaysLeft(item['date']),
          _getStatusColor(item['status']),
          _getCategoryIcon(category),
          category,
        );
      },
    );
  }

  List<Widget> _buildConsultasCards() {
    List<Widget> cards = [];

    for (var paciente in _pacientesComConsultas) {
      for (var consulta in paciente['consultas']) {
        cards.add(
          _buildNotificationCard(
            _formatDate(consulta['hora_consulta']),
            'Consulta: ${consulta['especialidade']}',
            'Paciente: ${paciente['nome']} - ${consulta['medico_nome']}',
            consulta['local_consulta'] ?? consulta['endereco_consulta'] ?? '',
            _calculateDaysLeft(consulta['hora_consulta']),
            _getStatusColor(consulta['status']),
            Icons.medical_services_outlined,
            'consultas',
          ),
        );
        cards.add(const SizedBox(height: 12));
      }
    }

    return cards;
  }

  List<Widget> _buildMedicamentosCards() {
    List<Widget> cards = [];

    for (var paciente in _pacientesComMedicamentos) {
      for (var medicamento in paciente['medicamentos']) {
        cards.add(
          _buildNotificationCard(
            _formatDate(medicamento['data_hora']),
            'Medicação: ${medicamento['medicamento_nome']}',
            'Paciente: ${paciente['nome']} - ${medicamento['dosagem']}',
            'Horário: ${DateTime.parse(medicamento['data_hora']).hour.toString().padLeft(2, '0')}:${DateTime.parse(medicamento['data_hora']).minute.toString().padLeft(2, '0')}',
            _calculateDaysLeft(medicamento['data_hora']),
            _getStatusColor(medicamento['status']),
            Icons.medication_outlined,
            'medicamentos',
          ),
        );
        cards.add(const SizedBox(height: 12));
      }
    }

    return cards;
  }

  List<Widget> _buildTarefasCards() {
    List<Widget> cards = [];

    for (var paciente in _pacientesComTarefas) {
      for (var tarefa in paciente['tarefas']) {
        cards.add(
          _buildNotificationCard(
            _formatDate(tarefa['data_tarefa']),
            'Tarefa: ${tarefa['motivacao']}',
            'Paciente: ${paciente['nome']}',
            tarefa['descricao'] ?? '',
            _calculateDaysLeft(tarefa['data_tarefa']),
            _getStatusColor(tarefa['status']),
            Icons.task_outlined,
            'tarefas',
          ),
        );
        cards.add(const SizedBox(height: 12));
      }
    }

    return cards;
  }

  Widget _buildNotificationCard(
    String date,
    String title,
    String subtitle,
    String description,
    String status,
    Color statusColor,
    IconData icon,
    String category,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Data com gradiente
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCategoryColor(category),
                    _getCategoryColor(category).withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    date.split(' ')[0],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    date.split(' ')[1],
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 16),

            // Conteúdo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título com ícone
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          icon,
                          size: 16,
                          color: _getCategoryColor(category),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Subtítulo
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Descrição (se houver)
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
