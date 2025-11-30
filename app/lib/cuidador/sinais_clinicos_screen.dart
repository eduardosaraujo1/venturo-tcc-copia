import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'confirmacao_registro.dart';
import 'selecionar_paciente_screen.dart';

class SinaisClinicosScreen extends StatefulWidget {
  final Paciente paciente;

  const SinaisClinicosScreen({super.key, required this.paciente});

  @override
  _SinaisClinicosScreenState createState() => _SinaisClinicosScreenState();
}

class _SinaisClinicosScreenState extends State<SinaisClinicosScreen> {
  final TextEditingController _temperaturaController = TextEditingController();
  final TextEditingController _glicemiaController = TextEditingController();
  final TextEditingController _pressaoController = TextEditingController();
  final TextEditingController _outrasObservacoesController =
      TextEditingController();
  bool _isLoading = false;
  bool _alreadySaved = false; // ✅ ADICIONE ESTA FLAG

  @override
  void dispose() {
    _temperaturaController.dispose();
    _glicemiaController.dispose();
    _pressaoController.dispose();
    _outrasObservacoesController.dispose();
    super.dispose();
  }

  // Função para obter a inicial do nome do paciente
  String _getInitial(String nome) {
    if (nome.isEmpty) return '?';
    return nome[0].toUpperCase();
  }

  // Função para gerar uma cor baseada no nome
  Color _getAvatarColor(String nome) {
    final colors = [
      const Color(0xFF62A7D2),
      const Color(0xFF6ABAD5),
      const Color(0xFF1D3B51),
      const Color(0xFF4CAF50),
      const Color(0xFF9C27B0),
      const Color(0xFFFF9800),
      const Color(0xFF795548),
    ];
    final index = nome.hashCode % colors.length;
    return colors[index];
  }

  Future<void> _salvarSinaisClinicos() async {
    // ✅ VERIFICA: Se já está salvando OU se já salvou antes
    if (_isLoading || _alreadySaved) return;

    // Validações básicas
    if (_temperaturaController.text.isEmpty &&
        _glicemiaController.text.isEmpty &&
        _pressaoController.text.isEmpty) {
      _mostrarErro('Preencha pelo menos um sinal clínico');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> requestBody = {
        'paciente_id': widget.paciente.id,
        'temperatura': _temperaturaController.text.isNotEmpty
            ? double.tryParse(_temperaturaController.text.replaceAll(',', '.'))
            : null,
        'glicemia': _glicemiaController.text.isNotEmpty
            ? double.tryParse(_glicemiaController.text.replaceAll(',', '.'))
            : null,
        'pressao_arterial': _pressaoController.text.isNotEmpty
            ? _pressaoController.text
            : null,
        'outras_observacoes': _outrasObservacoesController.text.isNotEmpty
            ? _outrasObservacoesController.text
            : null,
      };

      // Remove campos nulos
      requestBody.removeWhere((key, value) => value == null);

      final response = await http.post(
        Uri.parse('${Config.apiUrl}/api/registrosdiarios/sinais-clinicos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          _alreadySaved = true; // ✅ MARCA COMO JÁ SALVO
          _navegarParaConfirmacao();
        } else {
          _mostrarErro(data['message'] ?? 'Erro ao salvar sinais clínicos');
        }
      } else {
        _mostrarErro('Erro na conexão: ${response.statusCode}');
      }
    } catch (e) {
      _mostrarErro('Erro: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _navegarParaConfirmacao() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => ConfirmacaoScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: LinearProgressIndicator(
          value: 0.80,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF62A7D2)),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: null, // ✅ DESABILITADO
            child: Text('Próximo', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: _getAvatarColor(widget.paciente.nome),
                    child: Text(
                      _getInitial(widget.paciente.nome),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.paciente.nome,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.paciente.idade ?? 'Idade não informada',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Sinais clínicos observados:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D3B51),
              ),
            ),
            SizedBox(height: 10),
            _buildInputField(
              controller: _temperaturaController,
              hintText: 'Temperatura corporal (C°)',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              icon: Icons.thermostat,
            ),
            SizedBox(height: 10),
            _buildInputField(
              controller: _glicemiaController,
              hintText: 'Glicemia (mg/dL)',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              icon: Icons.monitor_heart,
            ),
            SizedBox(height: 10),
            _buildInputField(
              controller: _pressaoController,
              hintText: 'Pressão (ex: 120/80)',
              keyboardType: TextInputType.text,
              icon: Icons.favorite,
            ),
            SizedBox(height: 20),
            Text(
              'Outras Observações detalhadas:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D3B51),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _outrasObservacoesController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Descreva outras observações...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _salvarSinaisClinicos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF62A7D2),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text('Próximo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    IconData? icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
    );
  }
}
