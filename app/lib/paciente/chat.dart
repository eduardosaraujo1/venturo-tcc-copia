import 'package:flutter/material.dart';
import 'chamada_screen.dart';
import 'video_chamada_screen.dart';

class ChatScreen extends StatelessWidget {
  final String chatName;
  final String imagePath;

  const ChatScreen({super.key, required this.chatName, required this.imagePath});

  // Função para obter a inicial do nome
  String _getInicial(String nome) {
    if (nome.isEmpty) return '?';
    // Remove " (Familiar)" se existir e pega a primeira letra
    final nomeLimpo = nome.replaceAll(RegExp(r'\s*\(Familiar\)'), '');
    return nomeLimpo.isNotEmpty ? nomeLimpo[0].toUpperCase() : '?';
  }

  // Função para gerar cor baseada no nome
  Color _getCorBaseadaNoNome(String nome) {
    final cores = [
      Color(0xFF6ABAD5), // Azul principal
      Color(0xFF4CAF50), // Verde
      Color(0xFF9C27B0), // Roxo
      Color(0xFFFF9800), // Laranja
      Color(0xFFF44336), // Vermelho
      Color(0xFF2196F3), // Azul
      Color(0xFF009688), // Teal
    ];
    
    if (nome.isEmpty) return cores[0];
    
    // Gera um índice baseado no código ASCII do primeiro caractere
    final codigo = nome.codeUnits.reduce((a, b) => a + b);
    return cores[codigo % cores.length];
  }

  @override
  Widget build(BuildContext context) {
    final inicial = _getInicial(chatName);
    final corAvatar = _getCorBaseadaNoNome(chatName);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: corAvatar,
              radius: 20,
              child: Text(
                inicial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chatName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('Online', style: TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ),
          ],
        ),
        actions: [
          // No ChatScreen, modifique os IconButtons:
IconButton(
  icon: Icon(Icons.videocam_outlined),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoChamadaScreen(nomeContato: chatName),
      ),
    );
  },
),
IconButton(
  icon: Icon(Icons.call_outlined),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChamadaScreen(nomeContato: chatName),
      ),
    );
  },
),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDateSeparator('HOJE'),
                  _buildMessageBubble(
                    context,
                    text: 'Olá, tudo bem?',
                    isSentByMe: true,
                    time: '09:25 AM',
                    inicial: _getInicial('Você'), // Inicial para suas mensagens
                    corAvatar: _getCorBaseadaNoNome('Você'),
                  ),
                  _buildMessageBubble(
                    context,
                    text: 'Oi, tudo sim, e vc',
                    isSentByMe: false,
                    time: '09:25 AM',
                    inicial: inicial, // Inicial da pessoa com quem está conversando
                    corAvatar: corAvatar,
                  ),
                ],
              ),
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          date,
          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, {
    required String text,
    required bool isSentByMe,
    required String time,
    required String inicial,
    required Color corAvatar,
  }) {
    final alignment = isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start;
    final color = isSentByMe ? Color(0xFFE3F2FD) : Colors.grey.shade200;
    final borderRadius = BorderRadius.only(
      topLeft: Radius.circular(12),
      topRight: Radius.circular(12),
      bottomLeft: isSentByMe ? Radius.circular(12) : Radius.circular(0),
      bottomRight: isSentByMe ? Radius.circular(0) : Radius.circular(12),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSentByMe)
            CircleAvatar(
              backgroundColor: corAvatar,
              radius: 16,
              child: Text(
                inicial,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: borderRadius,
            ),
            child: Text(text),
          ),
          SizedBox(width: 8),
          Text(time, style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file, color: const Color.fromARGB(255, 33, 177, 243)),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Digite sua mensagem',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF6ABAD5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}