import 'package:algumacoisa/paciente/home_paciente.dart';
import '../config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Trocadesenha extends StatefulWidget {
  const Trocadesenha({super.key});

  @override
  _TrocadesenhaState createState() => _TrocadesenhaState();
}

class _TrocadesenhaState extends State<Trocadesenha> {
  bool _isOldPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmNewPasswordVisible = false;
  bool _isLoading = false;

  // Cores do tema
  static const Color corPrincipal = Color(0xFF6ABAD5);

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Função para alterar senha
  Future<void> _trocarSenha() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse('${Config.apiUrl}/api/pacientes/alterar-senha'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'senhaAtual': _oldPasswordController.text,
          'novaSenha': _newPasswordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (data['success']) {
          // Senha alterada com sucesso
          _mostrarMensagemSucesso('Senha alterada com sucesso!');
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePaciente()),
              (route) => false,
            );
          });
        } else {
          // Erro ao alterar senha
          _mostrarMensagemErro(data['message'] ?? 'Erro ao alterar senha');
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _mostrarMensagemErro('Erro de conexão. Tente novamente.');
      }
    }
  }

  void _mostrarMensagemSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _mostrarMensagemErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Função para validar email
  String? _validarEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }

    // Expressão regular para validar email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Digite um email válido';
    }

    return null;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
        title: const Text(
          'Alterar Senha',
          style: TextStyle(color: corPrincipal, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Título
                const Text(
                  "Alterar Senha",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: corPrincipal,
                  ),
                ),

                const SizedBox(height: 10),

                // Subtítulo
                const Text(
                  "Digite seu email e senha atual para criar uma nova senha",
                  style: TextStyle(fontSize: 16, color: Colors.blueGrey),
                ),

                const SizedBox(height: 40),

                // Campo Email
                const Text(
                  'Email',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  validator: _validarEmail,
                  decoration: InputDecoration(
                    hintText: 'Digite seu email',
                    filled: true,
                    fillColor: corPrincipal.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.email, color: corPrincipal),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Campo Senha Antiga
                const Text(
                  'Senha Atual',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: !_isOldPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Senha atual é obrigatória';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Digite sua senha atual',
                    filled: true,
                    fillColor: corPrincipal.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(Icons.lock, color: corPrincipal),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isOldPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: corPrincipal,
                      ),
                      onPressed: () {
                        setState(() {
                          _isOldPasswordVisible = !_isOldPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Campo Nova Senha
                const Text(
                  'Nova Senha',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nova senha é obrigatória';
                    }
                    if (value.length < 6) {
                      return 'Senha deve ter pelo menos 6 caracteres';
                    }
                    // Verificar se a nova senha é diferente da atual
                    if (value == _oldPasswordController.text) {
                      return 'A nova senha deve ser diferente da senha atual';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Digite sua nova senha',
                    filled: true,
                    fillColor: corPrincipal.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: corPrincipal,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isNewPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: corPrincipal,
                      ),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Campo Confirmar Nova Senha
                const Text(
                  'Confirmar Nova Senha',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmNewPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirmação de senha é obrigatória';
                    }
                    if (value != _newPasswordController.text) {
                      return 'As senhas não coincidem';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Confirme sua nova senha',
                    filled: true,
                    fillColor: corPrincipal.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.lock_reset,
                      color: corPrincipal,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmNewPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: corPrincipal,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmNewPasswordVisible =
                              !_isConfirmNewPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Dicas de senha
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sua nova senha deve conter:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text('Pelo menos 6 caracteres'),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text('Letras e números'),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text('Diferente da senha anterior'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Botão Trocar Senha
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _trocarSenha,
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
                            'Alterar Senha',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
