import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// -----------------------------------------------------------------------------
// 1. Definição da tela de Confirmação (ConfirmationNotificationScreen)
// Esta é a tela que estava faltando e causava o erro de compilação.
// Ela é o destino após o agendamento bem-sucedido.
// -----------------------------------------------------------------------------

class ConfirmationNotificationScreen extends StatelessWidget {
  final String tipoConsulta;
  final String observacoes;
  final DateTime date;
  final String time;
  final String patientName;

  const ConfirmationNotificationScreen({
    super.key,
    this.tipoConsulta = 'Consulta Médica',
    this.observacoes = '',
    required this.date,
    required this.time,
    required this.patientName,
  });

  String _formatDate(DateTime date) {
    const dayNames = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    const monthNames = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    return '${dayNames[date.weekday - 1]}, ${date.day} de ${monthNames[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Agendamento Concluído'),
        backgroundColor: const Color(0xFF6ABAD5),
        automaticallyImplyLeading: false, // Remove o botão de voltar
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 32),
              const Text(
                'Agendamento Confirmado!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6ABAD5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'A consulta de "$tipoConsulta" para $patientName foi agendada com sucesso.',
                style: const TextStyle(fontSize: 18, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Data',
                        _formatDate(date),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.access_time, 'Horário', time),
                      const SizedBox(height: 12),
                      _buildInfoRow(Icons.person, 'Paciente', patientName),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  // Aqui você pode navegar para a tela principal ou lista de consultas
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6ABAD5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Voltar para a tela inicial',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6ABAD5), size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// 2. Tela de Confirmação e Edição (ConfirmarAgendamentoConsultaScreen)
// -----------------------------------------------------------------------------

class ConfirmarAgendamentoConsultaScreen extends StatefulWidget {
  final String patientName;
  final String tipoConsulta;
  final DateTime date;
  final String time;

  const ConfirmarAgendamentoConsultaScreen({
    super.key,
    required this.patientName,
    required this.tipoConsulta,
    required this.date,
    required this.time,
  });

  @override
  State<ConfirmarAgendamentoConsultaScreen> createState() =>
      _ConfirmarAgendamentoConsultaScreenState();
}

class _ConfirmarAgendamentoConsultaScreenState
    extends State<ConfirmarAgendamentoConsultaScreen> {
  late TextEditingController _tipoConsultaController;
  late TextEditingController _observacoesController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tipoConsultaController = TextEditingController(text: widget.tipoConsulta);
    _observacoesController = TextEditingController();
  }

  @override
  void dispose() {
    _tipoConsultaController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  String _getDayName(int weekday) {
    const dayNames = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    // weekday 1=Monday, 7=Sunday. Array is 0-indexed.
    return dayNames[weekday - 1];
  }

  String _getMonthName(int month) {
    const monthNames = [
      'janeiro',
      'fevereiro',
      'março',
      'abril',
      'maio',
      'junho',
      'julho',
      'agosto',
      'setembro',
      'outubro',
      'novembro',
      'dezembro',
    ];
    // month 1=January, 12=December. Array is 0-indexed.
    return monthNames[month - 1];
  }

  Future<void> _saveAppointmentToDatabase() async {
    if (_tipoConsultaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o tipo de consulta')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Mocked endpoint - Substitua com a sua URL real da API.
      const apiUrl = '${Config.apiUrl}/api/consultas';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          // O ideal é usar o ID do paciente, não o nome, mas usaremos o nome
          // conforme a estrutura atual do widget.
          'patient_name': widget.patientName,
          'tipo_consulta': _tipoConsultaController.text,
          'observacoes': _observacoesController.text,
          'date': widget.date.toIso8601String().substring(
            0,
            10,
          ), // Apenas a data
          'time': widget.time,
          'cuidador_id': 1, // Valor fixo para simulação
        }),
      );

      if (response.statusCode == 201) {
        // Sucesso: Navega para a tela de notificação de confirmação
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationNotificationScreen(
              tipoConsulta: _tipoConsultaController.text,
              observacoes: _observacoesController.text,
              date: widget.date,
              time: widget.time,
              patientName: widget.patientName,
            ),
          ),
        );
      } else {
        // Falha: Exibe erro do servidor
        String errorMessage =
            'Erro ao agendar consulta (Status: ${response.statusCode})';
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['error'] ?? errorMessage;
        } catch (_) {
          // Se o body não for JSON, usa a mensagem padrão
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Falha: Erro de rede/conexão
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de Rede: $e\nVerifique o servidor ')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_getDayName(widget.date.weekday)}, ${widget.date.day} de ${_getMonthName(widget.date.month)}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Confirmação de Consulta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6ABAD5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Você está agendando uma consulta para\n${widget.patientName}:',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$formattedDate, às ${widget.time}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              TextButton(
                onPressed: () {
                  // TODO: Implementar a navegação para a tela de seleção de data/horário
                  // Por enquanto, apenas exibe um SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Funcionalidade de Alterar Data/Horário ainda não implementada.',
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Alterar data ou horário',
                  style: TextStyle(
                    color: Color(0xFF6ABAD5),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              _buildEditableField('Tipo de Consulta', _tipoConsultaController),
              const SizedBox(height: 24),
              _buildObservacoesField(
                'Observações (opcional)',
                _observacoesController,
              ),
              const SizedBox(height: 64),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6ABAD5),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _saveAppointmentToDatabase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6ABAD5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Confirmar consulta',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80.0),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Agendar Consulta',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFB3E5FC), Color(0xFF6ABAD5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6ABAD5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            decoration: const InputDecoration(border: InputBorder.none),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildObservacoesField(
    String label,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6ABAD5),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(border: InputBorder.none),
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
      ],
    );
  }
}
