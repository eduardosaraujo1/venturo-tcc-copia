import 'package:algumacoisa/cuidador/tarefa1.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AgendarTarefaScreen extends StatefulWidget {
  const AgendarTarefaScreen({super.key});

  @override
  _AgendarTarefaScreenState createState() => _AgendarTarefaScreenState();
}

class _AgendarTarefaScreenState extends State<AgendarTarefaScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _horaPersonalizadaController =
      TextEditingController();

  bool _isLoading = false;
  bool _mostrarCampoHoraPersonalizada = false;

  Future<void> _salvarTarefa() async {
    if (_selectedTime == null) {
      _mostrarSnackBar('Selecione um horário');
      return;
    }

    if (_descricaoController.text.isEmpty || _motivoController.text.isEmpty) {
      _mostrarSnackBar('Preencha a descrição e motivo da tarefa');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        int.parse(_selectedTime!.split(':')[0]),
        int.parse(_selectedTime!.split(':')[1]),
      );

      final Map<String, dynamic> tarefaData = {
        'cuidador_id': 1, // ID do cuidador logado
        'paciente_id': 1,
        'descricao': _descricaoController.text,
        'motivacao': _motivoController.text,
        'data_tarefa': selectedDateTime.toIso8601String(),
      };

      print('Enviando dados da tarefa: $tarefaData');

      final response = await http.post(
        Uri.parse('${Config.apiUrl}/api/cuidador/PacienteTarefa'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(tarefaData),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('Tarefa agendada com sucesso: ${responseData['tarefa']}');

        // Navegar para seleção de paciente passando os dados da tarefa
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PatientTaskSelectionScreen(
              descricao: _descricaoController.text,
              motivo: _motivoController.text,
              data: _selectedDate,
              hora: _selectedTime!,
            ),
          ),
        );
      } else {
        final errorData = json.decode(response.body);
        print('Erro na resposta: ${errorData['error']}');
        _mostrarSnackBar('Erro: ${errorData['error']}');
      }
    } catch (e) {
      print('Erro ao conectar ou enviar dados: $e');
      _mostrarSnackBar('Erro de conexão. Verifique sua rede.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _validarEHoraPersonalizada() {
    final horaTexto = _horaPersonalizadaController.text.trim();

    // Validar formato HH:mm
    final regex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    if (!regex.hasMatch(horaTexto)) {
      _mostrarSnackBar('Formato de hora inválido. Use HH:mm (ex: 14:30)');
      return;
    }

    // Validar se a hora é válida
    final partes = horaTexto.split(':');
    final hora = int.parse(partes[0]);
    final minuto = int.parse(partes[1]);

    if (hora < 0 || hora > 23 || minuto < 0 || minuto > 59) {
      _mostrarSnackBar('Hora inválida. Use valores entre 00:00 e 23:59');
      return;
    }

    setState(() {
      _selectedTime = horaTexto;
      _mostrarCampoHoraPersonalizada = false;
      _horaPersonalizadaController.clear();
    });
  }

  void _mostrarSnackBar(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    const Color corPrincipal = Color(0xFF6ABAD5);
    final month = _selectedDate.month;
    final year = _selectedDate.year;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: corPrincipal),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Agenda para marcar tarefa',
          style: TextStyle(color: corPrincipal, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(height: 16),
              _buildTextField('Descrição da Tarefa', _descricaoController),
              SizedBox(height: 16),
              _buildTextField('Motivo da Tarefa', _motivoController),
              SizedBox(height: 24),
              _buildCalendar(month, year),
              SizedBox(height: 24),
              Text(
                'Adicione o Horário:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: corPrincipal,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              _buildTimeGrid(),

              // Botão para adicionar horário personalizado
              SizedBox(height: 16),
              if (!_mostrarCampoHoraPersonalizada)
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _mostrarCampoHoraPersonalizada = true;
                      _selectedTime = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: corPrincipal),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: corPrincipal, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Adicionar Horário Personalizado',
                        style: TextStyle(color: corPrincipal),
                      ),
                    ],
                  ),
                ),

              // Campo para horário personalizado
              if (_mostrarCampoHoraPersonalizada)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16),
                    Text(
                      'Digite o horário (HH:mm):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: corPrincipal,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _horaPersonalizadaController,
                            decoration: InputDecoration(
                              hintText: 'Ex: 14:30',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: corPrincipal),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            keyboardType: TextInputType.datetime,
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _validarEHoraPersonalizada,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corPrincipal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'OK',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _mostrarCampoHoraPersonalizada = false;
                              _horaPersonalizadaController.clear();
                            });
                          },
                          child: Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Formato: HH:mm (ex: 09:15, 14:30, 23:45)',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

              // Horário selecionado
              if (_selectedTime != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: corPrincipal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: corPrincipal.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, color: corPrincipal),
                        SizedBox(width: 8),
                        Text(
                          'Horário selecionado: $_selectedTime',
                          style: TextStyle(
                            color: corPrincipal,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 80),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: ElevatedButton(
                  onPressed:
                      (_selectedTime != null &&
                          _descricaoController.text.isNotEmpty &&
                          _motivoController.text.isNotEmpty &&
                          !_isLoading)
                      ? _salvarTarefa
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        (_selectedTime != null &&
                            _descricaoController.text.isNotEmpty &&
                            _motivoController.text.isNotEmpty &&
                            !_isLoading)
                        ? corPrincipal
                        : Colors.grey[400],
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'Próximo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    const Color corPrincipal = Color(0xFF6ABAD5);

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: corPrincipal),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: corPrincipal),
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: corPrincipal.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildCalendar(int month, int year) {
    const Color corPrincipal = Color(0xFF6ABAD5);
    final daysOfWeek = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];

    final firstDayOfMonth = DateTime(year, month, 1);
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final daysInMonthCount = lastDayOfMonth.day;
    final leadingEmptyDays = firstDayOfMonth.weekday % 7;

    final daysInMonth = [
      ...List.generate(leadingEmptyDays, (_) => ''),
      ...List.generate(daysInMonthCount, (index) => (index + 1).toString()),
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(year, month - 1, 1);
                  _selectedTime = null;
                  _mostrarCampoHoraPersonalizada = false;
                });
              },
            ),
            Text(
              '${_getMonthName(month)}\n$year',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: corPrincipal,
              ),
              textAlign: TextAlign.center,
            ),
            IconButton(
              icon: Icon(Icons.arrow_forward_ios, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime(year, month + 1, 1);
                  _selectedTime = null;
                  _mostrarCampoHoraPersonalizada = false;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: daysOfWeek.length,
          itemBuilder: (context, index) {
            return Center(
              child: Text(
                daysOfWeek[index],
                style: TextStyle(color: corPrincipal),
              ),
            );
          },
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemCount: daysInMonth.length,
          itemBuilder: (context, index) {
            final day = daysInMonth[index];
            final isCurrentMonthDay = day.isNotEmpty;
            final dayInt = isCurrentMonthDay ? int.parse(day) : -1;

            final isSelected =
                isCurrentMonthDay &&
                dayInt == _selectedDate.day &&
                month == _selectedDate.month &&
                year == _selectedDate.year;

            final DateTime currentDayDate = isCurrentMonthDay
                ? DateTime(year, month, dayInt)
                : DateTime.now().add(Duration(days: 9999));
            final bool isPastDate = currentDayDate.isBefore(
              DateTime.now().subtract(Duration(days: 1)),
            );

            return GestureDetector(
              onTap: isCurrentMonthDay && !isPastDate
                  ? () {
                      setState(() {
                        _selectedDate = DateTime(year, month, dayInt);
                        _selectedTime = null;
                        _mostrarCampoHoraPersonalizada = false;
                      });
                    }
                  : null,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? corPrincipal.withOpacity(0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(8),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isSelected
                          ? corPrincipal
                          : (isPastDate
                                ? Colors.grey.shade400
                                : (isCurrentMonthDay
                                      ? Colors.black
                                      : Colors.transparent)),
                      fontWeight: isSelected || isCurrentMonthDay
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimeGrid() {
    const Color corPrincipal = Color(0xFF6ABAD5);
    final times = [
      '8:00',
      '9:00',
      '11:00',
      '12:00',
      '14:00',
      '15:00',
      '17:00',
      '18:00',
      '19:00',
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: times.length,
      itemBuilder: (context, index) {
        final time = times[index];
        final isSelected =
            _selectedTime == time && !_mostrarCampoHoraPersonalizada;

        return OutlinedButton(
          onPressed: () {
            setState(() {
              _selectedTime = time;
              _mostrarCampoHoraPersonalizada = false;
            });
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected
                ? corPrincipal.withOpacity(0.1)
                : Colors.white,
            side: BorderSide(
              color: isSelected
                  ? Colors.transparent
                  : corPrincipal.withOpacity(0.4),
              width: 1.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            time,
            style: TextStyle(
              color: isSelected ? corPrincipal : corPrincipal.withOpacity(0.6),
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro",
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _motivoController.dispose();
    _horaPersonalizadaController.dispose();
    super.dispose();
  }
}
