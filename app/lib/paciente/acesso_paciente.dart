import 'package:algumacoisa/cuidador/home_cuidador_screen.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// Importação ajustada, altere para o nome correto da sua tela de login

// --- CONFIGURAÇÃO DA API ---
const String _baseUrl =
    '${Config.apiUrl}/api/paciente/cadastrocompleto'; // Base para as rotas do paciente

class RegistraPacienteScreen extends StatefulWidget {
  const RegistraPacienteScreen({super.key});

  @override
  _RegistraPacienteScreenState createState() => _RegistraPacienteScreenState();
}

class _RegistraPacienteScreenState extends State<RegistraPacienteScreen> {
  // --- Controllers para os campos de texto ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(); // NOVO
  final TextEditingController _passwordController =
      TextEditingController(); // NOVO
  final TextEditingController _comorbidadeController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // NOVO: Para mostrar/esconder a senha

  // Variáveis para Dropdown
  String? _selectedBloodType;

  // Lista de Tipos Sanguíneos
  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose(); // DISPOSE NOVO
    _passwordController.dispose(); // DISPOSE NOVO
    _comorbidadeController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // --- FUNÇÃO DE SUBMISSÃO DA API ATUALIZADA ---
  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBloodType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione o Tipo Sanguíneo.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Coleta e envia dados
    final Map<String, dynamic> data = {
      'nome': _nameController.text.trim(),
      'email': _emailController.text.trim(), // CAMPO NOVO
      'senha': _passwordController.text, // CAMPO NOVO
      'idade': int.tryParse(_ageController.text.trim()),
      'peso': double.tryParse(
        _weightController.text.trim().replaceAll(',', '.'),
      ),
      'tipo_sanguineo': _selectedBloodType,
      'comorbidade': _comorbidadeController.text.trim().isEmpty
          ? 'Nenhuma/Não Informado'
          : _comorbidadeController.text.trim(),
    };

    try {
      // Endpoint de cadastro completo, agora incluindo dados de usuário (email/senha)
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Paciente cadastrado com sucesso! ✅')),
          );
          // Redireciona para a tela de Login após o cadastro
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeCuidadorScreen()),
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['error'] ?? 'Erro desconhecido no cadastro.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Erro ao enviar dados de cadastro do paciente: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Falha no cadastro: ${e.toString().replaceAll('Exception: ', '')} ❌',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Método auxiliar para campos de texto
  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    String? Function(String?) validator, {
    TextInputType type = TextInputType.text,
    bool isPassword = false,
  }) {
    final OutlineInputBorder borderStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
    );
    final OutlineInputBorder focusStyle = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: const BorderSide(
        color: Color.fromARGB(255, 106, 186, 213),
        width: 2,
      ),
    );

    return TextFormField(
      controller: controller,
      obscureText:
          isPassword &&
          !_isPasswordVisible, // Usado apenas para o campo de senha
      keyboardType: type,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 16.0,
        ),
        border: borderStyle,
        enabledBorder: borderStyle,
        focusedBorder: focusStyle,
        filled: true,

        suffixIcon: isPassword
            ? IconButton(
                // Botão de visibilidade de senha
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
      ),
    );
  }

  // Método auxiliar para dropdowns
  InputDecoration _dropDownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12.0,
        horizontal: 12.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(
          color: Color.fromARGB(255, 106, 186, 213),
          width: 2,
        ),
      ),
      filled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              const Text(
                'Cadastrar Paciente',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 106, 186, 213),
                ),
              ),
              const SizedBox(height: 40),

              // Nome Completo do Paciente (Obrigatório)
              const Text(
                "Nome Completo *",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(137, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                "Nome completo do paciente",
                _nameController,
                (value) => value!.isEmpty ? 'O nome é obrigatório.' : null,
              ),
              const SizedBox(height: 20),

              // --- NOVO: Email (Obrigatório) ---
              const Text(
                "Email *",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(137, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                "email@exemplo.com",
                _emailController,
                (value) {
                  if (value!.isEmpty) {
                    return 'O email é obrigatório.';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Insira um email válido.';
                  }
                  return null;
                },
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // --- NOVO: Senha (Obrigatório) ---
              const Text(
                "Senha *",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(137, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField("Digite sua senha", _passwordController, (value) {
                if (value!.isEmpty) {
                  return 'A senha é obrigatória.';
                }
                if (value.length < 6) {
                  return 'A senha deve ter pelo menos 6 caracteres.';
                }
                return null;
              }, isPassword: true), // Adicionado 'isPassword: true'
              const SizedBox(height: 20),

              // Idade
              const Text(
                "Idade (anos)",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(137, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField("Digite a idade", _ageController, (value) {
                if (value!.isNotEmpty && int.tryParse(value) == null) {
                  return 'A idade deve ser um número inteiro.';
                }
                return null;
              }, type: TextInputType.number),
              const SizedBox(height: 20),

              // Peso
              const Text(
                "Peso (Kg)",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(137, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField("Digite o peso em Kg", _weightController, (
                value,
              ) {
                if (value!.isNotEmpty) {
                  final cleanValue = value.replaceAll(',', '.');
                  if (double.tryParse(cleanValue) == null) {
                    return 'O peso deve ser um número (ex: 75.5).';
                  }
                }
                return null;
              }, type: TextInputType.number),
              const SizedBox(height: 20),

              // Tipo Sanguíneo (Dropdown)
              const Text(
                "Tipo Sanguíneo *",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(137, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: _dropDownDecoration("Selecione o tipo"),
                initialValue: _selectedBloodType,
                items: _bloodTypes
                    .map(
                      (type) =>
                          DropdownMenuItem(value: type, child: Text(type)),
                    )
                    .toList(),
                onChanged: (value) =>
                    setState(() => _selectedBloodType = value),
                validator: (value) =>
                    value == null ? 'O tipo sanguíneo é obrigatório.' : null,
              ),
              const SizedBox(height: 20),

              // Comorbidade
              const Text(
                "Comorbidade (Ex: Diabetes, Hipertensão)",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(137, 0, 0, 0),
                ),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                "Informe comorbidades ou deixe vazio",
                _comorbidadeController,
                (value) => null, // Campo opcional
                type: TextInputType.multiline,
              ),

              const SizedBox(height: 40),

              // Botão Cadastrar - APENAS A FONTE ALTERADA PARA BRANCO
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 106, 186, 213),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color.fromARGB(255, 0, 0, 0),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Cadastrar Paciente",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white, // FONTE ALTERADA PARA BRANCO
                        ),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
