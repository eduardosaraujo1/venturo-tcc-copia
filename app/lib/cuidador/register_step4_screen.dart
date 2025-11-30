import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:algumacoisa/cuidador/login_screen.dart';

// --- CONFIGURAÇÃO DA API ---
const String professionalDataApiUrl =
    '${Config.apiUrl}/api/cuidador/profissional';

class RegisterStep4Screen extends StatefulWidget {
  final int? cuidadorId;

  const RegisterStep4Screen({super.key, this.cuidadorId});

  @override
  State<RegisterStep4Screen> createState() => _RegisterStep4ScreenState();
}

class _RegisterStep4ScreenState extends State<RegisterStep4Screen> {
  // Controladores e Chave do Formulário
  final TextEditingController _registrationNumberController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Variáveis de Estado
  String? _selectedFormacao;
  bool _isAptoChecked = false; // Checkbox de aptidão
  bool _isLoading = false;

  @override
  void dispose() {
    _registrationNumberController.dispose();
    super.dispose();
  }

  // --- FUNÇÃO DE SUBMISSÃO SIMPLES VIA JSON ---
  Future<void> _submitProfessionalData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validações adicionais
    if (_selectedFormacao == null) {
      return _showError('Selecione sua formação profissional.');
    }
    if (!_isAptoChecked) {
      return _showError(
        'Você deve declarar que as informações são verdadeiras.',
      );
    }

    final String cuidadorId =
        widget.cuidadorId?.toString() ?? '1'; // Usando '1' como fallback

    setState(() => _isLoading = true);

    try {
      // 1. Prepara o corpo da requisição JSON
      final body = json.encode({
        'cuidador_id': cuidadorId,
        'formacao': _selectedFormacao!,
        'registro_profissional': _registrationNumberController.text.trim(),
        'declaracao_apto': _isAptoChecked,
      });

      // 2. Envia a requisição POST (JSON)
      final response = await http.post(
        Uri.parse(professionalDataApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Sucesso
        if (mounted) {
          _showSuccess(
            'Informações profissionais enviadas com sucesso! Aguarde a validação.',
          );
          // Navega para a tela de Login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginUnificadoScreen(),
            ),
          );
        }
      } else {
        // Falha no servidor
        final responseBody = json.decode(response.body);
        final errorMessage =
            responseBody['error'] ?? 'Erro no servidor: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Erro ao enviar dados profissionais: $e');
      if (mounted) {
        _showError('Falha no envio: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // Estilos de Decoração
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF6ABAD5).withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 20),
                const Text(
                  "Informações Profissionais",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6ABAD5),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Image.asset('assets/image-removebg-preview.png', height: 100),
                const SizedBox(height: 10),
                const Text(
                  "Complete seu perfil",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  // Texto foi ajustado para refletir a ausência de upload.
                  'Preencha as informações profissionais para que possamos validar sua atuação como cuidador.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),

                // Campo de Formação
                const Text(
                  'Formação *',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedFormacao,
                  validator: (value) =>
                      value == null ? 'Selecione uma formação.' : null,
                  items: ['Enfermagem', 'Fisioterapia', 'Cuidador de Idosos']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedFormacao = value;
                    });
                  },
                  decoration: _inputDecoration('Selecione Sua Formação'),
                ),

                const SizedBox(height: 20),

                // Campo de Número de Registro Profissional
                const Text(
                  'Número De Registro Profissional',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _registrationNumberController,
                  decoration: _inputDecoration('Coren (Se houver)'),
                ),
                const SizedBox(height: 20),

                // A seção de upload de arquivo foi removida.
                const SizedBox(height: 10),

                // Declaração de informações
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _isAptoChecked,
                      onChanged: (value) {
                        setState(() {
                          _isAptoChecked = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF6ABAD5),
                    ),
                    const Expanded(
                      child: Text(
                        'Declaro que as informações fornecidas são verdadeiras e que estou apto para exercer a função de cuidador.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Botão Enviar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitProfessionalData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6ABAD5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Enviar",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
