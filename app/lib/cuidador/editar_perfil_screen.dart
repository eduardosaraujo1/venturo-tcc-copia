import 'package:flutter/material.dart';
import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// Importa o modelo de dados
import 'caregiver_model.dart';

// CaregiverModel removido daqui e movido para 'caregiver_model.dart'

class EditPerfilScreen extends StatefulWidget {
  final CaregiverModel caregiverData;

  const EditPerfilScreen({super.key, required this.caregiverData});

  @override
  State<EditPerfilScreen> createState() => _EditPerfilScreenState();
}

class _EditPerfilScreenState extends State<EditPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  // ... (restante da classe _EditPerfilScreenState sem alterações) ...
  late TextEditingController _numeroController;
  late TextEditingController _dataNascimentoController;
  late TextEditingController _enderecoController;
  late TextEditingController _infoFisicasController;

  bool _isLoading = false;
  static const Color corPrincipal = Color.fromARGB(255, 106, 186, 213);

  @override
  void initState() {
    super.initState();
    // Inicializar controllers com dados atuais
    _nomeController = TextEditingController(text: widget.caregiverData.nome);
    _numeroController = TextEditingController(
      text: widget.caregiverData.numero,
    );
    _dataNascimentoController = TextEditingController(
      text: widget.caregiverData.dataNascimento,
    );
    _enderecoController = TextEditingController(
      text: widget.caregiverData.endereco,
    );
    _infoFisicasController = TextEditingController(
      text: widget.caregiverData.infoFisicas,
    );
  }

  Future<void> _salvarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const String urlApi = '${Config.apiUrl}/api/cuidador/atualizar-perfil';

      final response = await http.put(
        Uri.parse(urlApi),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nome': _nomeController.text,
          'numero': _numeroController.text,
          'data_nascimento': _dataNascimentoController.text,
          'endereco': _enderecoController.text,
          'info_fisicas': _infoFisicasController.text,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception(data['message'] ?? 'Erro ao atualizar perfil');
        }
      } else {
        throw Exception('Falha ao atualizar. Status: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selecionarData() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _dataNascimentoController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _numeroController.dispose();
    _dataNascimentoController.dispose();
    _enderecoController.dispose();
    _infoFisicasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (O restante do Widget build() é mantido) ...
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Editar Perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _salvarPerfil,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Avatar circular com letra inicial
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: corPrincipal,
                        child: Text(
                          _getInitialLetter(),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Campo Nome Completo
                      _buildEditableField(
                        icon: Icons.person_outline,
                        label: 'Nome Completo',
                        controller: _nomeController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite seu nome';
                          }
                          return null;
                        },
                      ),

                      // Campo Número de Telefone
                      _buildEditableField(
                        icon: Icons.phone_outlined,
                        label: 'Número de Telefone',
                        controller: _numeroController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite seu telefone';
                          }
                          return null;
                        },
                      ),

                      // Campo Data de Nascimento
                      _buildEditableField(
                        icon: Icons.cake_outlined,
                        label: 'Data de Nascimento',
                        controller: _dataNascimentoController,
                        readOnly: true,
                        onTap: _selecionarData,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, selecione sua data de nascimento';
                          }
                          return null;
                        },
                      ),

                      // Campo Endereço
                      _buildEditableField(
                        icon: Icons.location_on_outlined,
                        label: 'Endereço',
                        controller: _enderecoController,
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite seu endereço';
                          }
                          return null;
                        },
                      ),

                      // Campo Informações Físicas
                      _buildEditableField(
                        icon: Icons.fitness_center_outlined,
                        label: 'Informações Físicas',
                        controller: _infoFisicasController,
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite suas informações físicas';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 40),

                      // Botão Salvar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _salvarPerfil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corPrincipal,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Salvar Alterações',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Botão Cancelar
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: corPrincipal, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  readOnly: readOnly,
                  onTap: onTap,
                  validator: validator,
                  maxLines: maxLines,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    errorStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitialLetter() {
    if (_nomeController.text.isEmpty) {
      return 'U';
    }
    return _nomeController.text[0].toUpperCase();
  }
}
