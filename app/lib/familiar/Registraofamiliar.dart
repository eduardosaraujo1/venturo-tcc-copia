import 'package:algumacoisa/cuidador/home_cuidador_screen.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// --- CONFIGURAÇÃO DA API ---
const String familiarCadastroApiUrl = '${Config.apiUrl}/api/familiar/cadastro';

class Registraofamiliar extends StatefulWidget {
  const Registraofamiliar({super.key});

  @override
  _RegistraofamiliarState createState() => _RegistraofamiliarState();
}

class _RegistraofamiliarState extends State<Registraofamiliar> {
  // --- Controllers para todos os campos de texto ---
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Variáveis para controle de visibilidade da senha
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Variáveis para Dropdown e Radio Button
  String? _selectedGender;
  int? _selectedDay;
  String? _selectedMonth;
  int? _selectedYear;

  // Mapa de meses para números
  final Map<String, String> _monthMap = {
    "Janeiro": "01",
    "Fevereiro": "02",
    "Março": "03",
    "Abril": "04",
    "Maio": "05",
    "Junho": "06",
    "Julho": "07",
    "Agosto": "08",
    "Setembro": "09",
    "Outubro": "10",
    "Novembro": "11",
    "Dezembro": "12",
  };

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- FUNÇÃO DE SUBMISSÃO DA API ---
  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('As senhas não coincidem.')));
      return;
    }

    if (_selectedDay == null ||
        _selectedMonth == null ||
        _selectedYear == null ||
        _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, preencha a data de nascimento e o gênero.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final monthNumber = _monthMap[_selectedMonth]!;
    final dayString = _selectedDay!.toString().padLeft(2, '0');
    final dataNascimento = '$_selectedYear-$monthNumber-$dayString';

    final data = {
      'nome': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'telefone': _phoneController.text.trim(),
      'endereco': _addressController.text.trim(),
      'data_nascimento': dataNascimento,
      'genero': _selectedGender,
      'senha': _passwordController.text,
    };

    try {
      final response = await http.post(
        Uri.parse(familiarCadastroApiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro realizado com sucesso!')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeCuidadorScreen()),
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['error'] ?? 'Erro desconhecido no cadastro.';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Erro ao enviar dados de cadastro: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Falha no cadastro: ${e.toString().replaceAll('Exception: ', '')}',
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

  Widget _buildTextField(
    String hint,
    TextEditingController controller,
    String? Function(String?) validator, {
    TextInputType type = TextInputType.text,
    bool isPassword = false,
    VoidCallback? onToggleVisibility,
    bool? obscureText,
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
      obscureText: obscureText ?? (isPassword ? _obscurePassword : false),
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
                icon: Icon(
                  obscureText ?? _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: Colors.black54,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
      ),
    );
  }

  // Método específico para campo de senha
  Widget _buildPasswordField(
    String hint,
    TextEditingController controller,
    String? Function(String?) validator, {
    bool isConfirmPassword = false,
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
      obscureText: isConfirmPassword
          ? _obscureConfirmPassword
          : _obscurePassword,
      keyboardType: TextInputType.visiblePassword,
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
        suffixIcon: IconButton(
          icon: Icon(
            isConfirmPassword
                ? (_obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility)
                : (_obscurePassword ? Icons.visibility_off : Icons.visibility),
            color: Colors.black54,
          ),
          onPressed: () {
            setState(() {
              if (isConfirmPassword) {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              } else {
                _obscurePassword = !_obscurePassword;
              }
            });
          },
        ),
      ),
    );
  }

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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              const Text(
                'Cadastrar Familiar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 106, 186, 213),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Nome Completo
              const Text(
                "Nome Completo *",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                "Digite seu nome",
                _nameController,
                (value) => value!.isEmpty ? 'O nome é obrigatório.' : null,
              ),
              const SizedBox(height: 20),

              // Email
              const Text(
                "Email *",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                "Digite seu email",
                _emailController,
                (value) {
                  if (value!.isEmpty || !value.contains('@')) {
                    return 'Insira um email válido.';
                  }
                  return null;
                },
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Data de Nascimento
              const Text(
                "Data de Nascimento *",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 400) {
                    return Column(
                      children: [
                        DropdownButtonFormField<int>(
                          decoration: _dropDownDecoration("Dia"),
                          initialValue: _selectedDay,
                          items: List.generate(31, (i) => i + 1)
                              .map(
                                (day) => DropdownMenuItem(
                                  value: day,
                                  child: Text(day.toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedDay = value),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: _dropDownDecoration("Mês"),
                          initialValue: _selectedMonth,
                          items: _monthMap.keys
                              .map(
                                (month) => DropdownMenuItem(
                                  value: month,
                                  child: Text(month),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedMonth = value),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          decoration: _dropDownDecoration("Ano"),
                          initialValue: _selectedYear,
                          items:
                              List.generate(100, (i) => DateTime.now().year - i)
                                  .map(
                                    (year) => DropdownMenuItem(
                                      value: year,
                                      child: Text(year.toString()),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) =>
                              setState(() => _selectedYear = value),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: _dropDownDecoration("Dia"),
                            initialValue: _selectedDay,
                            items: List.generate(31, (i) => i + 1)
                                .map(
                                  (day) => DropdownMenuItem(
                                    value: day,
                                    child: Text(day.toString()),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedDay = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: _dropDownDecoration("Mês"),
                            initialValue: _selectedMonth,
                            items: _monthMap.keys
                                .map(
                                  (month) => DropdownMenuItem(
                                    value: month,
                                    child: Text(month),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedMonth = value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: _dropDownDecoration("Ano"),
                            initialValue: _selectedYear,
                            items:
                                List.generate(
                                      100,
                                      (i) => DateTime.now().year - i,
                                    )
                                    .map(
                                      (year) => DropdownMenuItem(
                                        value: year,
                                        child: Text(year.toString()),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedYear = value),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 20),

              // Gênero
              const Text(
                "Gênero *",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: "F",
                        groupValue: _selectedGender,
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                        activeColor: const Color.fromARGB(255, 106, 186, 213),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text("Feminino"),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: "M",
                        groupValue: _selectedGender,
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                        activeColor: const Color.fromARGB(255, 106, 186, 213),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text("Masculino"),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: "O",
                        groupValue: _selectedGender,
                        onChanged: (value) =>
                            setState(() => _selectedGender = value),
                        activeColor: const Color.fromARGB(255, 106, 186, 213),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text("Outro"),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Telefone
              const Text(
                "Telefone",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                "Digite seu telefone",
                _phoneController,
                (value) => null,
                type: TextInputType.phone,
              ),

              const SizedBox(height: 20),

              // Endereço
              const Text(
                "Endereço",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              _buildTextField(
                "Digite seu endereço",
                _addressController,
                (value) => null,
              ),

              const SizedBox(height: 20),

              // Senha
              const Text(
                "Senha *",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                "Digite sua senha",
                _passwordController,
                (value) => value!.length < 6
                    ? 'A senha deve ter pelo menos 6 caracteres.'
                    : null,
                isConfirmPassword: false,
              ),

              const SizedBox(height: 20),

              // Confirme sua senha
              const Text(
                "Confirme sua senha *",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                "Repita sua senha",
                _confirmPasswordController,
                (value) => value!.isEmpty ? 'Confirme sua senha.' : null,
                isConfirmPassword: true,
              ),

              const SizedBox(height: 40),

              // Botão Cadastrar
              ElevatedButton(
                onPressed: _isLoading ? null : _submitRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 106, 186, 213),
                  foregroundColor: Colors.white,
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
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Cadastrar", style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
