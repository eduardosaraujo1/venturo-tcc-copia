import 'package:algumacoisa/cuidador/home_cuidador_screen.dart';
import 'package:flutter/material.dart';

class NotificacaoConfirmacaoScreen extends StatelessWidget {
  final String paciente;
  final String data;
  final String hora;
  final String especialidade;
  final String medicoNome;
  final String endereco; // NOVO PARÂMETRO

  const NotificacaoConfirmacaoScreen({
    super.key,
    required this.paciente,
    required this.data,
    required this.hora,
    required this.especialidade,
    required this.medicoNome,
    required this.endereco, // NOVO PARÂMETRO
  });

  // Método para formatar a data em um formato mais amigável
  String _formatarData(String data) {
    try {
      if (data.contains('/')) {
        final parts = data.split('/');
        if (parts.length == 3) {
          final dia = int.parse(parts[0]);
          final mes = int.parse(parts[1]);
          final ano = int.parse(parts[2]);
          
          final meses = [
            'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
            'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
          ];
          
          final diasSemana = [
            'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira',
            'Quinta-feira', 'Sexta-feira', 'Sábado'
          ];
          
          final dateTime = DateTime(ano, mes, dia);
          final diaSemana = diasSemana[dateTime.weekday - 1];
          final mesExtenso = meses[mes - 1];
          
          return '$diaSemana, $dia de $mesExtenso de $ano';
        }
      }
      return data;
    } catch (e) {
      return data;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataFormatada = _formatarData(data);
    final corPrincipal = const Color(0xFF6ABAD5);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notificação de confirmação',
          style: TextStyle(
            color: corPrincipal, 
            fontSize: isSmallScreen ? 16 : 18,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16.0 : 24.0, 
            vertical: 16.0
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).padding.vertical - 
                       kToolbarHeight,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    // Ícone de confirmação
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                      decoration: BoxDecoration(
                        color: corPrincipal.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check, 
                        size: isSmallScreen ? 50 : 60, 
                        color: corPrincipal
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    
                    // Título principal
                    Text(
                      'Consulta agendada com sucesso!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 22,
                        fontWeight: FontWeight.bold,
                        color: corPrincipal,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8.0 : 0.0
                      ),
                      child: Text(
                        'Você receberá uma notificação próximo à data da consulta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 24 : 32),
                    
                    // Cards de informações
                    _buildInfoCard(
                      context: context,
                      icon: Icons.person,
                      title: 'Paciente',
                      mainText: paciente,
                      subtitle: null,
                      isSmallScreen: isSmallScreen,
                      corPrincipal: corPrincipal,
                    ),
                    SizedBox(height: 12),
                    
                    _buildInfoCard(
                      context: context,
                      icon: Icons.medical_services,
                      title: 'Médico',
                      mainText: medicoNome,
                      subtitle: especialidade,
                      isSmallScreen: isSmallScreen,
                      corPrincipal: corPrincipal,
                    ),
                    SizedBox(height: 12),
                    
                    // NOVO CARD PARA O ENDEREÇO
                    _buildInfoCard(
                      context: context,
                      icon: Icons.location_on,
                      title: 'Endereço',
                      mainText: endereco,
                      subtitle: null,
                      isSmallScreen: isSmallScreen,
                      corPrincipal: corPrincipal,
                    ),
                    SizedBox(height: 12),
                    
                    _buildInfoCard(
                      context: context,
                      icon: Icons.calendar_today,
                      title: 'Data e Horário',
                      mainText: dataFormatada,
                      subtitle: 'Às $hora',
                      isSmallScreen: isSmallScreen,
                      corPrincipal: corPrincipal,
                    ),
                    
                    SizedBox(height: isSmallScreen ? 16 : 24),
                    
                    // Resumo da Consulta
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      decoration: BoxDecoration(
                        color: corPrincipal.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: corPrincipal.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Resumo da Consulta',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: corPrincipal,
                              fontSize: isSmallScreen ? 14 : 16,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          _buildSummaryRow(
                            'Paciente:',
                            paciente,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: 4),
                          _buildSummaryRow(
                            'Médico:',
                            medicoNome,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: 4),
                          _buildSummaryRow(
                            'Especialidade:',
                            especialidade,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: 4),
                          // NOVA LINHA PARA O ENDEREÇO
                          _buildSummaryRow(
                            'Endereço:',
                            endereco,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: 4),
                          _buildSummaryRow(
                            'Data:',
                            dataFormatada,
                            isSmallScreen: isSmallScreen,
                          ),
                          SizedBox(height: 4),
                          _buildSummaryRow(
                            'Horário:',
                            hora,
                            isSmallScreen: isSmallScreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Botões
                Padding(
                  padding: EdgeInsets.only(
                    top: isSmallScreen ? 16 : 20,
                    bottom: isSmallScreen ? 8 : 16,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => HomeCuidadorScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: corPrincipal,
                            padding: EdgeInsets.symmetric(
                              vertical: isSmallScreen ? 14 : 16,
                              horizontal: isSmallScreen ? 24 : 50,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Voltar à Tela Inicial',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 10),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Agendar outra consulta',
                          style: TextStyle(
                            color: corPrincipal,
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String mainText,
    required String? subtitle,
    required bool isSmallScreen,
    required Color corPrincipal,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: isSmallScreen ? 20 : 24,
              backgroundColor: corPrincipal.withOpacity(0.1),
              child: Icon(
                icon, 
                size: isSmallScreen ? 18 : 22, 
                color: corPrincipal
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isSmallScreen ? 11 : 12,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    mainText,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: corPrincipal,
                        fontSize: isSmallScreen ? 12 : 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {required bool isSmallScreen}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isSmallScreen ? 12 : 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 12 : 14,
            ),
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}