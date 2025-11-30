import 'package:flutter/material.dart';
import 'notificacao_confirmacao_screen.dart';

class ConfirmarAgendamentoScreen extends StatelessWidget {
  final String paciente;
  final String data;
  final String hora;
  final String especialidade;
  final String medicoNome;
  final String endereco; // NOVO PARÂMETRO

  const ConfirmarAgendamentoScreen({
    super.key,
    required this.paciente,
    required this.data,
    required this.hora,
    required this.especialidade,
    required this.medicoNome,
    required this.endereco, // NOVO PARÂMETRO
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: const Color.fromARGB(255, 106, 186, 213)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Confirmação de agendamento',
          style: TextStyle(color: const Color.fromARGB(255, 106, 186, 213), fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cadastro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6ABAD5),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Você cadastrou uma consulta para',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              paciente,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6ABAD5),
              ),
            ),
            SizedBox(height: 8),
            Text(
              '$data, às $hora',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Especialidade: $especialidade',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Médico: $medicoNome',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8), // ESPAÇAMENTO ADICIONADO
            Text( // WIDGET ADICIONADO PARA EXIBIR O ENDEREÇO
              'Endereço: $endereco',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Alterar data ou horário',
                style: TextStyle(color: const Color.fromARGB(255, 106, 186, 213), fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Motivo da consulta',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6ABAD5),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'O que você está sentindo ou precisa? Por exemplo:\n"Estou muito ansioso e com dificuldade para dormir"',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
              ),
            ),
            Spacer(),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificacaoConfirmacaoScreen(
                        paciente: paciente,
                        data: data,
                        hora: hora,
                        especialidade: especialidade,
                        medicoNome: medicoNome,
                        endereco: endereco,
                        // ADICIONE TAMBÉM O ENDEREÇO AQUI SE PRECISAR NA PRÓXIMA TELA
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6ABAD5),
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  'Confirmar agendamento',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}