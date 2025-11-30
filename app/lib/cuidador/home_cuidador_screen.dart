import 'package:flutter/material.dart';
import '../config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:algumacoisa/cuidador/agenda_cuidador.dart';
import 'package:algumacoisa/cuidador/selecionar_paciente_screen.dart';
import 'consultas_screen.dart';
import 'medicamentos_screen.dart';
import 'emergencias_screen.dart';
import 'tarefas_screen.dart';
import 'pacientes_screen.dart';
import 'meu_perfil_screen.dart';
import 'conversas_screen.dart';
import 'agendar_consultas_screen.dart';
import 'agendar_medicamento_screen.dart';
import 'agendar_tarefa_screen.dart'
    hide
        AgendarConsultasScreen,
        PacientesScreen,
        ConversasScreen,
        MeuPerfilScreen;
import 'notifications_screen.dart';

// Constante de cor primária e espaçamento para FABs
const Color _primaryColor = Color.fromARGB(255, 106, 186, 213);

// --- Modelo de Dados ---
class CuidadorPerfil {
  final String nome;

  CuidadorPerfil({required this.nome});

  factory CuidadorPerfil.fromJson(Map<String, dynamic> json) {
    return CuidadorPerfil(nome: json['nome'] ?? 'Nome Desconhecido');
  }
}

class HomeCuidadorScreen extends StatefulWidget {
  const HomeCuidadorScreen({super.key});

  @override
  _HomeCuidadorScreenState createState() => _HomeCuidadorScreenState();
}

class _HomeCuidadorScreenState extends State<HomeCuidadorScreen> {
  bool _showOptions = false;
  String _caregiverName = 'Cuidador(a)';
  bool _isLoading = true;
  bool _hasError = false;

  final String apiUrl = '${Config.apiUrl}/api/cuidador/perfil';

  @override
  void initState() {
    super.initState();
    _fetchCaregiverProfile();
  }

  Future<void> _fetchCaregiverProfile() async {
    try {
      final response = await http
          .get(Uri.parse(apiUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final profile = CuidadorPerfil.fromJson(jsonResponse);
        final firstName = profile.nome.split(' ').first;
        setState(() {
          _caregiverName = firstName;
          _isLoading = false;
        });
      } else {
        _handleFetchError(
          'Falha ao carregar perfil: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      _handleFetchError('Erro de conexão ou timeout: $e');
    }
  }

  void _handleFetchError(String message) {
    if (mounted) {
      setState(() {
        _caregiverName = 'Usuário';
        _isLoading = false;
        _hasError = true;
      });
      debugPrint(message);
    }
  }

  String _getInitialLetter() {
    if (_caregiverName.isEmpty || _caregiverName == 'Usuário') {
      return 'U';
    }
    return _caregiverName[0].toUpperCase();
  }

  void _toggleOptions() {
    setState(() {
      _showOptions = !_showOptions;
    });
  }

  // Método para fechar o menu quando tocar fora
  void _closeOptions() {
    if (_showOptions) {
      setState(() {
        _showOptions = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String welcomeMessage;
    if (_isLoading) {
      welcomeMessage = 'Carregando...';
    } else {
      welcomeMessage = 'Bem-vindo, $_caregiverName';
    }

    return GestureDetector(
      onTap: _closeOptions,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 100,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _primaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 40, left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MeuPerfilScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 24,
                          child: Text(
                            _getInitialLetter(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          welcomeMessage,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            // Corpo principal com padding extra na parte inferior
            Padding(
              padding: const EdgeInsets.only(
                bottom: 160.0,
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: ListView(
                children: <Widget>[
                  _buildInfoCard(
                    context: context,
                    icon: Icons.access_time,
                    title: 'Consultas Hoje',
                    subtitle: 'Clique para vizualizar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConsultasScreen(),
                        ),
                      );
                    },
                  ),
                  _buildInfoCard(
                    context: context,
                    icon: Icons.medical_services_outlined,
                    title: 'Medicamentos a administrar',
                    subtitle: 'Clique para vizualizar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MedicamentosScreen(),
                        ),
                      );
                    },
                  ),
                  _buildInfoCard(
                    context: context,
                    icon: Icons.warning_amber_outlined,
                    title: 'Emergências recentes',
                    subtitle: 'Clique para vizualizar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EmergenciasScreen(),
                        ),
                      );
                    },
                  ),
                  _buildInfoCard(
                    context: context,
                    icon: Icons.task_alt,
                    title: 'Tarefas Pendentes',
                    subtitle: 'Clique para vizualizar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TarefasScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- Menu Flutuante Aprimorado ---
            if (_showOptions) // Só renderiza quando visível
              Positioned(
                bottom: 80,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Botão de Anotações
                    _buildEnhancedFloatingButton(
                      icon: Icons.note_add_rounded,
                      label: 'Registros Diários',
                      isVisible: _showOptions,
                      offset: 4,
                      onPressed: () {
                        _toggleOptions();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SelecionarPacienteScreen(),
                          ),
                        );
                      },
                    ),

                    // Botão de Tarefas
                    _buildEnhancedFloatingButton(
                      icon: Icons.task_rounded,
                      label: 'Tarefas',
                      isVisible: _showOptions,
                      offset: 3,
                      onPressed: () {
                        _toggleOptions();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AgendarTarefaScreen(),
                          ),
                        );
                      },
                    ),

                    // Botão de Medicamentos
                    _buildEnhancedFloatingButton(
                      icon: Icons.medication_liquid_rounded,
                      label: 'Medicamentos',
                      isVisible: _showOptions,
                      offset: 2,
                      onPressed: () {
                        _toggleOptions();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const AgendarMedicamentoScreen(),
                          ),
                        );
                      },
                    ),

                    // Botão de Consultas
                    _buildEnhancedFloatingButton(
                      icon: Icons.calendar_month_rounded,
                      label: 'Consultas',
                      isVisible: _showOptions,
                      offset: 1,
                      onPressed: () {
                        _toggleOptions();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AgendarConsultaScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _toggleOptions,
          backgroundColor: _primaryColor,
          elevation: 8,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _showOptions ? Icons.close_rounded : Icons.add_rounded,
              key: ValueKey(_showOptions),
              size: 28,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _buildBottomAppBar(),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: _primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedFloatingButton({
    required IconData icon,
    required String label,
    required bool isVisible,
    required int offset,
    required VoidCallback onPressed,
  }) {
    // Gera um HeroTag único baseado no ícone e offset
    final String uniqueHeroTag = 'fab_${icon.codePoint}_$offset';

    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (offset * 100)),
      curve: Curves.easeOutBack,
      height: isVisible ? 48 : 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: Duration(milliseconds: 150 + (offset * 50)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                heroTag: uniqueHeroTag, // HeroTag único para evitar conflitos
                onPressed: onPressed,
                backgroundColor: _primaryColor,
                elevation: 4,
                child: Icon(icon, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.home_rounded, color: _primaryColor),
            iconSize: 28,
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: Colors.grey,
            ),
            iconSize: 28,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversasScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 48), // Espaço para o FAB central
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: Colors.grey),
            iconSize: 28,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PacientesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, color: Colors.grey),
            iconSize: 28,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AgendaCuidador()),
              );
            },
          ),
        ],
      ),
    );
  }
}
