import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'notificacao_medicamento.dart';
import 'agendar_medicamento_screen.dart';

class ConfirmarAgendamentoMedicamentoScreen extends StatefulWidget {
  final String patientName;
  final String medicationName;
  final String dosage;
  final DateTime date;
  final String time;

  const ConfirmarAgendamentoMedicamentoScreen({
    super.key,
    required this.patientName,
    required this.medicationName,
    required this.dosage,
    required this.date,
    required this.time,
  });

  @override
  State<ConfirmarAgendamentoMedicamentoScreen> createState() =>
      _ConfirmarAgendamentoMedicamentoScreenState();
}

class _ConfirmarAgendamentoMedicamentoScreenState
    extends State<ConfirmarAgendamentoMedicamentoScreen> {
  late TextEditingController _medicationNameController;
  late TextEditingController _dosageController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _medicationNameController = TextEditingController(
      text: widget.medicationName,
    );
    _dosageController = TextEditingController(text: widget.dosage);
  }

  @override
  void dispose() {
    _medicationNameController.dispose();
    _dosageController.dispose();
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
    return monthNames[month - 1];
  }

  Future<void> _saveMedicationToDatabase() async {
    if (_medicationNameController.text.isEmpty ||
        _dosageController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/api/medicamentos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patient_name': widget.patientName,
          'medication_name': _medicationNameController.text,
          'dosage': _dosageController.text,
          'date': widget.date.toIso8601String(),
          'time': widget.time,
          'cuidador_id': 1, // ← ADICIONE O ID DO CUIDADOR AQUI
        }),
      );

      if (response.statusCode == 201) {
        // Navega para tela de confirmação
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmacaoMedicamentos(
              medicationName: _medicationNameController.text,
              dosage: _dosageController.text,
              date: widget.date,
              time: widget.time,
              patientName: widget.patientName,
            ),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Erro ao salvar medicamento');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
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
                'Confirmação de Agendamento',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6ABAD5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Você está agendando um medicamento para\n${widget.patientName}:',
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgendarMedicamentoScreen(),
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
              _buildEditableField(
                'Nome do Medicamento',
                _medicationNameController,
              ),
              const SizedBox(height: 24),
              _buildEditableField('Dosagem', _dosageController),
              const SizedBox(height: 64),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF6ABAD5),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: _saveMedicationToDatabase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6ABAD5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Confirmar agendamento',
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
          'Agendar',
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
}
