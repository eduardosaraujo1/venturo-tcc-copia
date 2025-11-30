import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'register_step2_screen.dart';
import 'package:algumacoisa/paciente/home_paciente.dart';
import 'package:algumacoisa/cuidador/home_cuidador_screen.dart';
import 'package:algumacoisa/familiar/home_familiar.dart';
import 'create_password_screen.dart';

// URLs das APIs
const String loginCuidadorUrl = '${Config.apiUrl}/api/cuidador/login';
const String loginFamiliarUrl = '${Config.apiUrl}/api/familiar/login';
const String loginPacienteUrl =
    '${Config.apiUrl}/api/paciente/login'; // Se tiver

class LoginUnificadoScreen extends StatefulWidget {
  const LoginUnificadoScreen({super.key});

  @override
  State<LoginUnificadoScreen> createState() => _LoginUnificadoScreenState();
}

class _LoginUnificadoScreenState extends State<LoginUnificadoScreen> {
  final TextEditingController _identificadorController =
      TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool obscurePassword = true;
  bool _isLoading = false;

  // Cores do tema
  static const Color corPrincipal = Color(0xFF6ABAD5);
  static const Color corFundo = Colors.white;

  @override
  void dispose() {
    _identificadorController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // --- FUNÇÃO DE LOGIN QUE VERIFICA HIERARQUIA ---
  Future<void> _fazerLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String identificador = _identificadorController.text.trim();
    final String senha = _senhaController.text;

    try {
      Map<String, dynamic>? userData;
      String? userType;

      // Tenta login como CUIDADOR primeiro (maior hierarquia)
      userData = await _tentarLogin(loginCuidadorUrl, identificador, senha);
      if (userData != null) {
        userType = 'cuidador';
      }

      // Se não for cuidador, tenta como FAMILIAR
      if (userData == null) {
        userData = await _tentarLogin(loginFamiliarUrl, identificador, senha);
        if (userData != null) {
          userType = 'familiar';
        }
      }

      // Se não for familiar, tenta como PACIENTE (se tiver endpoint)
      if (userData == null && loginPacienteUrl.isNotEmpty) {
        userData = await _tentarLogin(loginPacienteUrl, identificador, senha);
        if (userData != null) {
          userType = 'paciente';
        }
      }

      if (mounted) {
        if (userData != null && userType != null) {
          // Login bem-sucedido - redireciona conforme o tipo
          _redirecionarPorTipo(userType, userData);
        } else {
          // Todas as tentativas falharam
          _mostrarSnackBar(
            'Credenciais inválidas para todos os tipos de usuário',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        print('Erro de conexão: $e');
        _mostrarSnackBar('Erro de conexão. Verifique o servidor.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- TENTA LOGIN EM UM ENDPOINT ESPECÍFICO ---
  Future<Map<String, dynamic>?> _tentarLogin(
    String url,
    String identificador,
    String senha,
  ) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'identificador': identificador, 'senha': senha}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Erro no login $url: $e');
    }
    return null;
  }

  // --- REDIRECIONA CONFORME O TIPO DE USUÁRIO ---
  void _redirecionarPorTipo(String userType, Map<String, dynamic> userData) {
    switch (userType) {
      case 'cuidador':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeCuidadorScreen(), // Sem parâmetros
          ),
        );
        break;

      case 'familiar':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeFamiliar(), // Sem parâmetros
          ),
        );
        break;

      case 'paciente':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePaciente(), // Sem parâmetros
          ),
        );
        break;
    }

    _mostrarSnackBar('Bem-vindo!', isError: false);
  }

  void _mostrarSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: corFundo,
      appBar: AppBar(
        backgroundColor: corFundo,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Título
                const Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: corPrincipal,
                  ),
                ),

                const SizedBox(height: 10),

                // Logo
                Image.asset('assets/image-removebg-preview.png', height: 100),

                const SizedBox(height: 10),

                // Subtítulo
                const Text(
                  "Bem-Vindo!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Digite seus dados de acesso",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 30),

                // Campo de Email/Telefone
                TextFormField(
                  controller: _identificadorController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email ou Telefone é obrigatório';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Email ou Telefone",
                    hintText: "seu@email.com ou (00) 90000-0000",
                    filled: true,
                    fillColor: corPrincipal.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.person, color: corPrincipal),
                  ),
                ),

                const SizedBox(height: 20),

                // Campo de Senha
                TextFormField(
                  controller: _senhaController,
                  obscureText: obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Senha é obrigatória';
                    }
                    if (value.length < 3) {
                      return 'Senha muito curta';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: "Senha",
                    filled: true,
                    fillColor: corPrincipal.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock, color: corPrincipal),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: corPrincipal,
                      ),
                      onPressed: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Esqueceu senha
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreatePasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Esqueceu sua senha?",
                      style: TextStyle(color: Color(0xFF6ABAD5)),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Botão Login
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _fazerLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: corPrincipal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                            "Entrar",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                // Divisor
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "ou",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ],
                ),

                const SizedBox(height: 30),

                // Botão Cadastrar
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterStep2Screen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: corPrincipal),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      "Criar Nova Conta",
                      style: TextStyle(
                        color: corPrincipal,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
