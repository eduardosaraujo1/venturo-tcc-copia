import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class EditarPerfilPaciente extends StatefulWidget {
  final Map<String, dynamic> perfilData;

  const EditarPerfilPaciente({super.key, required this.perfilData});

  @override
  State<EditarPerfilPaciente> createState() => _EditarPerfilPacienteState();
}

class _EditarPerfilPacienteState extends State<EditarPerfilPaciente> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _tipoSanguineoController;
  late TextEditingController _idadeController;
  late TextEditingController _pesoController;
  late TextEditingController _comorbidadeController;

  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';

  // Cores do tema
  static const Color corPrincipal = Color.fromARGB(255, 106, 186, 213);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nomeController = TextEditingController(
      text: widget.perfilData['nome'] ?? '',
    );
    _tipoSanguineoController = TextEditingController(
      text: widget.perfilData['tipo_sanguineo'] ?? '',
    );
    _idadeController = TextEditingController(
      text: widget.perfilData['idade']?.toString() ?? '',
    );
    _pesoController = TextEditingController(
      text: widget.perfilData['peso']?.toString() ?? '',
    );
    _comorbidadeController = TextEditingController(
      text: widget.perfilData['comorbidade'] ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _tipoSanguineoController.dispose();
    _idadeController.dispose();
    _pesoController.dispose();
    _comorbidadeController.dispose();
    super.dispose();
  }

  Future<void> _atualizarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _successMessage = '';
    });

    try {
      final Map<String, dynamic> dadosAtualizacao = {
        'nome': _nomeController.text.trim(),
        'tipo_sanguineo': _tipoSanguineoController.text.trim().isEmpty
            ? null
            : _tipoSanguineoController.text.trim(),
        'idade': _idadeController.text.trim().isEmpty
            ? null
            : int.tryParse(_idadeController.text.trim()),
        'peso': _pesoController.text.trim().isEmpty
            ? null
            : double.tryParse(_pesoController.text.trim()),
        'comorbidade': _comorbidadeController.text.trim().isEmpty
            ? null
            : _comorbidadeController.text.trim(),
      };

      // Remove campos nulos
      dadosAtualizacao.removeWhere((key, value) => value == null);

      final response = await http.put(
        Uri.parse('${Config.apiUrl}/api/paciente/atualizar-perfil'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dadosAtualizacao),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          setState(() {
            _successMessage =
                responseData['message'] ?? 'Perfil atualizado com sucesso!';
          });

          // Aguarda um pouco para mostrar a mensagem de sucesso antes de voltar
          await Future.delayed(const Duration(seconds: 2));

          // Retorna para a tela anterior com os dados atualizados
          if (mounted) {
            Navigator.pop(context, dadosAtualizacao);
          }
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Erro ao atualizar perfil';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Erro no servidor: ${response.statusCode}';
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Erro de conexão: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editar Perfil'),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Mensagens de erro/sucesso
              _buildMessageWidgets(),

              // Campo Nome
              _buildFormField(
                controller: _nomeController,
                label: 'Nome Completo *',
                hintText: 'Digite seu nome completo',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Campo Tipo Sanguíneo
              _buildFormField(
                controller: _tipoSanguineoController,
                label: 'Tipo Sanguíneo',
                hintText: 'Ex: A+, O-, etc.',
                validator: _validateTipoSanguineo,
              ),

              const SizedBox(height: 16),

              // Campo Idade
              _buildFormField(
                controller: _idadeController,
                label: 'Idade',
                hintText: 'Digite sua idade',
                keyboardType: TextInputType.number,
                validator: _validateIdade,
              ),

              const SizedBox(height: 16),

              // Campo Peso
              _buildFormField(
                controller: _pesoController,
                label: 'Peso (kg)',
                hintText: 'Digite seu peso em kg',
                keyboardType: TextInputType.number,
                validator: _validatePeso,
              ),

              const SizedBox(height: 16),

              // Campo Comorbidade
              _buildFormField(
                controller: _comorbidadeController,
                label: 'Comorbidades',
                hintText: 'Digite suas comorbidades (separadas por vírgula)',
                maxLines: 3,
                validator: (value) => null, // Campo opcional
              ),

              const SizedBox(height: 30),

              // Botão Salvar
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageWidgets() {
    return Column(
      children: [
        if (_errorMessage.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red),
            ),
            child: Text(
              _errorMessage,
              style: const TextStyle(color: Colors.red),
            ),
          ),

        if (_successMessage.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Text(
              _successMessage,
              style: const TextStyle(color: Colors.green),
            ),
          ),
      ],
    );
  }

  String? _validateTipoSanguineo(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final tipoSanguineo = value.trim().toUpperCase();
      final regex = RegExp(r'^(A|B|AB|O)[+-]$');
      if (!regex.hasMatch(tipoSanguineo)) {
        return 'Tipo sanguíneo inválido. Use formato: A+, B-, O+, etc.';
      }
    }
    return null;
  }

  String? _validateIdade(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final idade = int.tryParse(value.trim());
      if (idade == null || idade < 0 || idade > 150) {
        return 'Idade deve ser um número válido (0-150)';
      }
    }
    return null;
  }

  String? _validatePeso(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final peso = double.tryParse(value.trim());
      if (peso == null || peso <= 0 || peso > 500) {
        return 'Peso deve ser um número válido (0-500 kg)';
      }
    }
    return null;
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _atualizarPerfil,
        style: ElevatedButton.styleFrom(
          backgroundColor: corPrincipal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Salvar Alterações', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
