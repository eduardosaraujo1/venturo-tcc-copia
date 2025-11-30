import 'package:flutter/material.dart';
import 'home_cuidador_screen.dart';

class ConfirmacaoMedicamentos extends StatelessWidget {
  final String medicationName;
  final String dosage;
  final DateTime date;
  final String time;
  final String patientName;

  const ConfirmacaoMedicamentos({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.date,
    required this.time,
        required this.patientName,
  });

  String _getDayName(int day) {
    const dayNames = [
      'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'
    ];
    return dayNames[day - 1];
  }

  String _getMonthName(int month) {
    const monthNames = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho', 'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
    ];
    return monthNames[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = '${_getDayName(date.weekday)}, ${date.day} de ${_getMonthName(date.month)}';

    return Scaffold(
      body: Stack(
        children: [
          Container(
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
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color.fromARGB(255, 106, 186, 213),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 60,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Você agendou uma Medicação com sucesso!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Você receberá uma notificação ao chegar próximo da data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue.shade50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Colors.white,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow(
                            icon: Icons.local_pharmacy_outlined,
                            label: 'Remédio:',
                            value: medicationName,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            icon: Icons.straighten_outlined,
                            label: 'Dose:',
                            value: dosage,
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.calendar_today, color: const Color.fromARGB(255, 30, 212, 229)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Data do medicamento cadastrada',
                                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                    ),
                                    Text(
                                      '$formattedDate, às $time',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF6ABAD5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const HomeCuidadorScreen()),
                        (Route<dynamic> route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 5,
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Voltar à Tela Inicial',
                      style: TextStyle(fontSize: 16, color: Color(0xFF6ABAD5)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Removida a propriedade 'bottomNavigationBar'
      // Removida a propriedade 'floatingActionButtonLocation'
     
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF6ABAD5),),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}