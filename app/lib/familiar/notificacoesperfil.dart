import 'package:flutter/material.dart';

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  _NotificacoesScreenState createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  bool _notificacoesHabilitadas = true;
  bool _somHabilitado = true;
  bool _vibrarHabilitado = true;

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
        title: Text('Notificações'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            _buildToggleItem('Notificações', _notificacoesHabilitadas, (bool value) {
              setState(() {
                _notificacoesHabilitadas = value;
              });
            }),
            _buildToggleItem('Som', _somHabilitado, (bool value) {
              setState(() {
                _somHabilitado = value;
              });
            }),
            _buildToggleItem('Vibrar', _vibrarHabilitado, (bool value) {
              setState(() {
                _vibrarHabilitado = value;
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 16)),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xFF6ABAD5),
        ),
      ],
    );
  }
}