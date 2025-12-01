import 'package:flutter/material.dart';

import 'sinais_clinicos_screen.dart';

class SentimentosPacienteScreen extends StatefulWidget {
  final dynamic paciente;

  const SentimentosPacienteScreen({super.key, required this.paciente});

  @override
  _SentimentosPacienteScreenState createState() =>
      _SentimentosPacienteScreenState();
}

class _SentimentosPacienteScreenState extends State<SentimentosPacienteScreen> {
  String? _selectedSentiment;
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Função para obter a inicial do nome do paciente
  String _getInitial(String nome) {
    if (nome.isEmpty) return '?';
    return nome[0].toUpperCase();
  }

  // Função para gerar uma cor baseada no nome (para consistência)
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

  bool _alreadySaved = false;

  Future<void> _salvarSentimentos() async {
    if (_isLoading || _alreadySaved) return;

    setState(() {
      _isLoading = true;
    });

    try {
      print("FUNCIONALIDADE REMOVIDA");
      // final Map<String, dynamic> requestBody = {
      //   'paciente_id': widget.paciente.id,
      //   'estado_geral': _selectedSentiment,
      //   'observacoes_sentimentos': _searchController.text,
      // };

      // final response = await http.post(
      //   Uri.parse('${Config.apiUrl}/api/registrosdiarios/sentimentos'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: json.encode(requestBody),
      // );

      // if (response.statusCode == 201) {
      //   final Map<String, dynamic> data = json.decode(response.body);

      //   if (data['success'] == true) {
      _alreadySaved = true; // ✅ ADICIONE ESTA LINHA - marca como já salvo
      _navegarParaSinaisClinicos();
      //   } else {
      //     _mostrarErro(data['message'] ?? 'Erro ao salvar sentimentos');
      //   }
      // } else {
      //   _mostrarErro('Erro na conexão: ${response.statusCode}');
      // }
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
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  void _navegarParaSinaisClinicos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SinaisClinicosScreen(paciente: widget.paciente),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: LinearProgressIndicator(
          value: 0.55,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF62A7D2)),
        ),
        centerTitle: false,
        // No AppBar actions, deixe o botão desabilitado ou remova:
        actions: [
          TextButton(
            onPressed: null, // Desabilitado
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
                  // Avatar com a inicial do nome do paciente
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: _getAvatarColor(widget.paciente.nome),
                    child: Text(
                      _getInitial(widget.paciente.nome),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.paciente.nome,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.paciente.idade ?? 'Idade não informada',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Estado geral desse paciente hoje:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar sentimentos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildSentimentButton('Muito bem', const Color(0xFF81C784)),
                const SizedBox(width: 10),
                _buildSentimentButton('Bem', const Color(0xFF4FC3F7)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSentimentButton('Mal', const Color(0xFFFFB74D)),
                const SizedBox(width: 10),
                _buildSentimentButton('Muito mal', const Color(0xFFE57373)),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _selectedSentiment == null || _isLoading
                    ? null
                    : _salvarSentimentos,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF62A7D2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 50,
                    vertical: 15,
                  ),
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
                    : const Text('Próximo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentButton(String text, Color color) {
    bool isSelected = _selectedSentiment == text;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedSentiment = text;
          });
        },
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16.0),
            border: isSelected
                ? Border.all(color: Colors.black, width: 3.0)
                : Border.all(color: Colors.transparent, width: 0),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
