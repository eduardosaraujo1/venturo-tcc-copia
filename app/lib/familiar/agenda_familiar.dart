import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'detalhes_agenda.dart';

class AgendaFamiliar extends StatefulWidget {
  const AgendaFamiliar({super.key});

  @override
  State<AgendaFamiliar> createState() => _AgendaFamiliarState();
}

class _AgendaFamiliarState extends State<AgendaFamiliar> {
  List<dynamic> pacientesComAgenda = [];
  bool isLoading = true;
  String errorMessage = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _carregarAgenda();
  }

  Future<void> _carregarAgenda() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      print('🔄 Iniciando carregamento da agenda...');

      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/PacienteComAgendaCompleta'),
      );

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('✅ API retornou success: ${data['success']}');
        print('📊 Total de pacientes: ${data['data']?.length}');

        if (data['success'] == true) {
          setState(() {
            pacientesComAgenda = data['data'];
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = data['error'] ?? 'Erro ao carregar agenda';
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

  void _navigateToPreviousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _navigateToNextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
  }

  String _getMonthName(DateTime date) {
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
    return months[date.month - 1];
  }

  // Função corrigida para obter a semana atual
  List<DateTime> _getCurrentWeek() {
    final now = _selectedDate;
    // Encontra o primeiro dia da semana (domingo)
    final firstDayOfWeek = now.subtract(Duration(days: now.weekday % 7));

    List<DateTime> week = [];
    for (int i = 0; i < 7; i++) {
      week.add(firstDayOfWeek.add(Duration(days: i)));
    }
    return week;
  }

  List<Map<String, dynamic>> _getEventosDoDia(DateTime date) {
    final eventos = [];

    for (var paciente in pacientesComAgenda) {
      // Consultas
      if (paciente['consultas'] != null) {
        for (var consulta in paciente['consultas']) {
          if (consulta['hora_consulta'] != null) {
            try {
              final dataConsulta = DateTime.parse(consulta['hora_consulta']);
              if (_isSameDay(dataConsulta, date)) {
                eventos.add({
                  'tipo': 'consulta',
                  'titulo': 'Consulta - ${consulta['especialidade']}',
                  'subtitulo': 'Dr. ${consulta['medico_nome']}',
                  'hora':
                      '${dataConsulta.hour.toString().padLeft(2, '0')}:${dataConsulta.minute.toString().padLeft(2, '0')}',
                  'paciente': paciente['nome'],
                  'status': consulta['status'],
                  'dados': consulta,
                  'pacienteCompleto': paciente,
                });
              }
            } catch (e) {
              print(
                '❌ Erro ao parse data da consulta: ${consulta['hora_consulta']}',
              );
            }
          }
        }
      }

      // Medicamentos
      if (paciente['medicamentos'] != null) {
        for (var medicamento in paciente['medicamentos']) {
          if (medicamento['data_hora'] != null) {
            try {
              final dataMedicamento = DateTime.parse(medicamento['data_hora']);
              if (_isSameDay(dataMedicamento, date)) {
                eventos.add({
                  'tipo': 'medicamento',
                  'titulo': 'Medicamento - ${medicamento['medicamento_nome']}',
                  'subtitulo': 'Dosagem: ${medicamento['dosagem']}',
                  'hora':
                      '${dataMedicamento.hour.toString().padLeft(2, '0')}:${dataMedicamento.minute.toString().padLeft(2, '0')}',
                  'paciente': paciente['nome'],
                  'status': medicamento['status'],
                  'dados': medicamento,
                  'pacienteCompleto': paciente,
                });
              }
            } catch (e) {
              print(
                '❌ Erro ao parse data do medicamento: ${medicamento['data_hora']}',
              );
            }
          }
        }
      }

      // Tarefas
      if (paciente['tarefas'] != null) {
        for (var tarefa in paciente['tarefas']) {
          if (tarefa['data_tarefa'] != null) {
            try {
              final dataTarefa = DateTime.parse(tarefa['data_tarefa']);
              if (_isSameDay(dataTarefa, date)) {
                eventos.add({
                  'tipo': 'tarefa',
                  'titulo': 'Tarefa - ${tarefa['motivacao']}',
                  'subtitulo': tarefa['descricao'] ?? 'Sem descrição',
                  'hora': '09:00', // Horário padrão para tarefas
                  'paciente': paciente['nome'],
                  'status': 'pendente',
                  'dados': tarefa,
                  'pacienteCompleto': paciente,
                });
              }
            } catch (e) {
              print('❌ Erro ao parse data da tarefa: ${tarefa['data_tarefa']}');
            }
          }
        }
      }
    }

    // Ordenar por hora
    eventos.sort((a, b) => a['hora'].compareTo(b['hora']));
    return List<Map<String, dynamic>>.from(eventos);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Color _getEventColor(String tipo) {
    switch (tipo) {
      case 'consulta':
        return const Color.fromARGB(255, 106, 186, 213);
      case 'medicamento':
        return Colors.green;
      case 'tarefa':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventIcon(String tipo) {
    switch (tipo) {
      case 'consulta':
        return Icons.medical_services;
      case 'medicamento':
        return Icons.medication;
      case 'tarefa':
        return Icons.assignment;
      default:
        return Icons.event;
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentWeek = _getCurrentWeek();
    final eventosDoDia = _getEventosDoDia(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Agenda',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarAgenda,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando agenda...'),
                ],
              ),
            )
          : errorMessage.isNotEmpty
          ? Center(
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
                    onPressed: _carregarAgenda,
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho do mês
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_getMonthName(_selectedDate)} ${_selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _navigateToPreviousMonth,
                          icon: const Icon(Icons.arrow_back_ios),
                        ),
                        IconButton(
                          onPressed: _navigateToNextMonth,
                          icon: const Icon(Icons.arrow_forward_ios),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dias da semana - CORRIGIDO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: currentWeek.asMap().entries.map((entry) {
                        final index = entry.key;
                        final date = entry.value;
                        final isSelected = _isSameDay(date, _selectedDate);
                        final dayNames = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

                        return _buildDayOfWeek(
                          dayNames[index],
                          date.day,
                          isSelected,
                          onTap: () => _selectDate(date),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Cabeçalho de eventos
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Eventos do Dia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Lista de eventos
                    if (eventosDoDia.isEmpty)
                      const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Nenhum evento para este dia',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: eventosDoDia.map((evento) {
                          return _buildEventCard(context, evento);
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDayOfWeek(
    String day,
    int date,
    bool isSelected, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 60,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade100 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 106, 186, 213)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? const Color.fromARGB(255, 106, 186, 213)
                    : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected
                    ? const Color.fromARGB(255, 106, 186, 213)
                    : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, dynamic> evento) {
    final color = _getEventColor(evento['tipo']);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetalhesAgenda()),
        );
      },
      child: Card(
        color: color.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color, width: 2),
        ),
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(_getEventIcon(evento['tipo']), color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evento['titulo'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      evento['subtitulo'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16),
                        const SizedBox(width: 4),
                        Text(evento['hora'], style: TextStyle(color: color)),
                        const SizedBox(width: 16),
                        const Icon(Icons.person, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          evento['paciente'],
                          style: TextStyle(color: color),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
