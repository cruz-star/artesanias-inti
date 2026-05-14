import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'seller_dashboard.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    
    // Primero intentamos entrar con el token guardado
    bool isLoggedIn = await auth.tryAutoLogin();

    // Si no hay token o falló, hacemos un "Silent Login" con las credenciales maestras
    if (!isLoggedIn) {
      isLoggedIn = await auth.loginAsSeller('gusscruz23@gmail.com', 'inti2027');
    }

    if (mounted) {
      if (isLoggedIn) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        // Si incluso el silent login falla (ej: sin internet), permitimos ir al login manual o reintentar
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF2E9), // Terracotta background
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Image.asset('ic_launcher.png', width: 120, height: 120),
              ),
              const SizedBox(height: 32),
              const Text(
                'Artesanías Inti',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD35400),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 64),
              if (auth.isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Color(0xFFD35400)),
                    SizedBox(height: 16),
                    Text('Iniciando sistema...', style: TextStyle(color: Colors.brown)),
                  ],
                )
              else if (auth.isLoggedIn)
                const Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 40),
                    SizedBox(height: 16),
                    Text('¡Acceso concedido!', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      const Text(
                        'No se pudo conectar con el servidor',
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToNext(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD35400),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
