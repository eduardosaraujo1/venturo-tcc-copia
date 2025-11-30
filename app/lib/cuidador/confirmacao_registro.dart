import 'package:flutter/material.dart';
import 'home_cuidador_screen.dart';
import 'listaregistros.dart';

class ConfirmacaoScreen extends StatelessWidget {
  const ConfirmacaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF62A7D2),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF62A7D2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Registro Adicionado com sucesso!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 20),
           
                SizedBox(height: 30),
                // BOTÃO PARA VER REGISTRO
                ElevatedButton(
                  onPressed: () {
                    // CORREÇÃO: Remove todas as telas anteriores e vai para registros
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => VisualizarRegistrosScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6ABAD5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    'Ver registro diario completo',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(height: 10),
                // BOTÃO PARA VOLTAR AO INÍCIO
                TextButton(
                  onPressed: () {
                    // CORREÇÃO: Remove todas as telas e volta para Home
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => HomeCuidadorScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Voltar ao Início',
                    style: TextStyle(
                      color: const Color(0xFF6ABAD5),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}