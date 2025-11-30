import 'package:flutter/material.dart';
import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// Importa o modelo de dados e a tela de edição
import 'caregiver_model.dart';
import 'editar_perfil_screen.dart'; // Nome do arquivo de edição padronizado

// CaregiverModel removido daqui e movido para 'caregiver_model.dart'

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  CaregiverModel? _caregiverData;
  // ... (restante da classe _PerfilScreenState sem alterações) ...
  bool _isLoading = true;
  String _errorMessage = '';

  // Cores do tema
  static const Color corPrincipal = Color.fromARGB(255, 106, 186, 213);

  @override
  void initState() {
    super.initState();
    _loadCaregiverData();
  }

  Future<void> _loadCaregiverData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      const String urlApi = '${Config.apiUrl}/api/cuidador/perfil';

      final response = await http.get(Uri.parse(urlApi));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final realData = CaregiverModel.fromJson(data);

        setState(() {
          _caregiverData = realData;
          _isLoading = false;
        });
      } else if (response.statusCode == 404) {
        throw Exception('Perfil não encontrado (código 404).');
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
    if (_caregiverData == null || _caregiverData!.nome.isEmpty) {
      return 'U';
    }
    return _caregiverData!.nome[0].toUpperCase();
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
        title: const Text('Perfil'),
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
                onPressed: _loadCaregiverData,
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final caregiver = _caregiverData!;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Avatar circular com letra inicial - estilo MeuPerfilScreen
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
          // Nome do cuidador
          Text(
            caregiver.nome,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          // Itens do perfil no estilo MeuPerfilScreen
          _buildProfileItem(
            icon: Icons.person_outline,
            label: 'Nome Completo',
            value: caregiver.nome,
          ),
          _buildProfileItem(
            icon: Icons.phone_outlined,
            label: 'Número',
            value: caregiver.numero,
          ),
          _buildProfileItem(
            icon: Icons.cake_outlined,
            label: 'Data de Nascimento',
            value: caregiver.dataNascimento,
          ),
          _buildProfileItem(
            icon: Icons.location_on_outlined,
            label: 'Endereço',
            value: caregiver.endereco,
          ),
          _buildProfileItem(
            icon: Icons.fitness_center_outlined,
            label: 'Informações Físicas',
            value: caregiver.infoFisicas,
          ),

          const SizedBox(height: 30),

          // Botão de editar
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditPerfilScreen(caregiverData: _caregiverData!),
                ),
              ).then((value) {
                // Recarregar dados se o perfil foi atualizado
                if (value == true) {
                  _loadCaregiverData();
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

  // Widget para construir os itens do perfil no estilo MeuPerfilScreen
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
