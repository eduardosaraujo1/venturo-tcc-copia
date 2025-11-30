import 'package:flutter/material.dart';
import '../config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SentimentosScreen extends StatefulWidget {
  const SentimentosScreen({super.key});

  @override
  State<SentimentosScreen> createState() => _SentimentosScreenState();
}

class _SentimentosScreenState extends State<SentimentosScreen> {
  List<dynamic> sentimentos = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _carregarSentimentos();
  }

  Future<void> _carregarSentimentos() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/cuidador/ExibirPacientes'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          sentimentos = data['data'] ?? [];
          isLoading = false;
          hasError = false;
        });
      } else {
        throw Exception('Falha ao carregar sentimentos');
      }
    } catch (error) {
      print('Erro: $error');
      setState(() {
        isLoading = false;
        hasError = true;
      });
      _mostrarErroSnackbar('Erro ao carregar sentimentos');
    }
  }

  void _mostrarErroSnackbar(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  String _formatarData(String data) {
    try {
      final dateTime = DateTime.parse(data);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return data;
    }
  }

  IconData _getSentimentoIcon(String sentimento) {
    switch (sentimento.toLowerCase()) {
      case 'feliz':
      case 'alegre':
      case 'contente':
        return Icons.sentiment_very_satisfied;
      case 'triste':
      case 'deprimido':
      case 'melancólico':
        return Icons.sentiment_very_dissatisfied;
      case 'neutro':
      case 'normal':
        return Icons.sentiment_neutral;
      case 'ansioso':
      case 'nervoso':
        return Icons.sentiment_very_dissatisfied;
      case 'calmo':
      case 'relaxado':
        return Icons.sentiment_satisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getSentimentoColor(String sentimento) {
    switch (sentimento.toLowerCase()) {
      case 'feliz':
      case 'alegre':
      case 'contente':
        return Colors.green;
      case 'triste':
      case 'deprimido':
      case 'melancólico':
        return Colors.blue;
      case 'ansioso':
      case 'nervoso':
        return Colors.orange;
      case 'calmo':
      case 'relaxado':
        return Colors.teal;
      case 'neutro':
      case 'normal':
        return Colors.grey;
      default:
        return Colors.purple;
    }
  }

  String _getInicial(String nome) {
    if (nome.isEmpty) return '?';
    return nome[0].toUpperCase();
  }

  Color _getAvatarColor(String letra) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.amber,
    ];

    if (letra.isEmpty || letra == '?') return Colors.grey;
    final index = letra.codeUnitAt(0) % colors.length;
    return colors[index];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Sentimentos registrados'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _carregarSentimentos,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            if (isLoading)
              Expanded(child: Center(child: CircularProgressIndicator()))
            else if (hasError)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Erro ao carregar sentimentos',
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarSentimentos,
                        child: Text('Tentar novamente'),
                      ),
                    ],
                  ),
                ),
              )
            else if (sentimentos.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sentiment_neutral,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum sentimento registrado',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Os sentimentos dos pacientes aparecerão aqui',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _carregarSentimentos,
                  child: ListView.builder(
                    itemCount: sentimentos.length,
                    itemBuilder: (context, index) {
                      final sentimento = sentimentos[index];
                      final nome = sentimento['nome'] ?? 'Nome não informado';
                      final sentimentoTipo =
                          sentimento['sentimento'] ?? 'Neutro';
                      final descricao = sentimento['descricao'];
                      final dataRegistro =
                          sentimento['data_registro'] ??
                          sentimento['created_at'];
                      final idade = sentimento['idade'];
                      final comorbidade = sentimento['comorbidade'];

                      final inicial = _getInicial(nome);
                      final avatarColor = _getAvatarColor(inicial);
                      final icon = _getSentimentoIcon(sentimentoTipo);
                      final iconColor = _getSentimentoColor(sentimentoTipo);

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: avatarColor,
                                    radius: 25,
                                    child: Text(
                                      inicial,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        icon,
                                        color: iconColor,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nome,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (idade != null)
                                      Text(
                                        '$idade anos',
                                        style: TextStyle(
                                          color: const Color.fromARGB(
                                            255,
                                            0,
                                            0,
                                            0,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    if (comorbidade != null)
                                      Text(
                                        comorbidade,
                                        style: TextStyle(
                                          color: const Color.fromARGB(
                                            255,
                                            0,
                                            0,
                                            0,
                                          ),
                                          fontSize: 12,
                                        ),
                                      ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Não Registrado: ',
                                      style: TextStyle(
                                        color: iconColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (descricao != null &&
                                        descricao.isNotEmpty)
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(height: 4),
                                          Text(
                                            descricao,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          _formatarData(dataRegistro),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
