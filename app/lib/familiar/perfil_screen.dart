import 'package:flutter/material.dart';
import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'caregiver_model.dart';
import 'editar_perfil_familiar_screen.dart'; // Tela de edição específica para familiar

class PerfilFamiliar extends StatefulWidget {
  const PerfilFamiliar({super.key});

  @override
  State<PerfilFamiliar> createState() => _PerfilFamiliarState();
}

class _PerfilFamiliarState extends State<PerfilFamiliar> {
  CaregiverModel? _familiarData;
  bool _isLoading = true;
  String _errorMessage = '';

  // Cores do tema
  static const Color corPrincipal = Color.fromARGB(255, 106, 186, 213);

  @override
  void initState() {
    super.initState();
    _loadFamiliarData();
  }

  Future<void> _loadFamiliarData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      const String urlApi =
          '${Config.apiUrl}/api/familiar/perfil'; // ✅ Endpoint correto

      final response = await http.get(Uri.parse(urlApi));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final realData = CaregiverModel.fromJson(data);

        setState(() {
          _familiarData = realData;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        throw Exception('Perfil do familiar não encontrado (código 404).');
      } else {
        throw Exception(
          'Falha ao carregar dados. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro de conexão/servidor: $e';
        _isLoading = false;
      });
    }
  }

  // Função para obter a letra inicial do nome
  String _getInitialLetter() {
    if (_familiarData == null || _familiarData!.nome.isEmpty) {
      return 'F'; // F de Familiar
    }
    return _familiarData!.nome[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Perfil - Familiar'),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _loadFamiliarData,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final familiar = _familiarData!;

    return Padding(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 10),
          // Nome do familiar
          Text(
            familiar.nome,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          // Itens do perfil
          _buildProfileItem(
            icon: Icons.person_outline,
            label: 'Nome Completo',
            value: familiar.nome,
          ),
          _buildProfileItem(
            icon: Icons.phone_outlined,
            label: 'Telefone',
            value: familiar.numero,
          ),
          _buildProfileItem(
            icon: Icons.cake_outlined,
            label: 'Data de Nascimento',
            value: familiar.dataNascimento,
          ),
          _buildProfileItem(
            icon: Icons.location_on_outlined,
            label: 'Endereço',
            value: familiar.endereco,
          ),
          _buildProfileItem(
            icon: Icons.email_outlined,
            label: 'Email',
            value: familiar.infoFisicas, // Reutilizando este campo para email
          ),

          const SizedBox(height: 30),

          // Botão de editar
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditPerfilFamiliarScreen(familiarData: _familiarData!),
                ),
              ).then((value) {
                // Recarregar dados se o perfil foi atualizado
                if (value == true) {
                  _loadFamiliarData();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: corPrincipal,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Editar Perfil',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para construir os itens do perfil
  Widget _buildProfileItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return InkWell(
      onTap: () {
        // Pode adicionar ação de tap se necessário
      },
      child: Padding(
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
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
