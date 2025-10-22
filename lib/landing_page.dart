import 'package:flutter/material.dart';
import 'dart:math';
import 'home_screen.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _buttonController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<Offset> _buttonSlideAnimation;
  late Animation<double> _pulseAnimation;
  List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    // Controller for text animations
    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Controller for button slide animation
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Controller for button pulse effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    // Controller for particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // Initialize particles
    _particles = List.generate(50, (_) => Particle());

    // Fade animation for title
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    // Fade animation for subtitle (delayed)
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    // Slide animation for button
    _buttonSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutCubic),
    );

    // Pulse animation for button
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _textController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _buttonController.forward();
    });

    // Update particles on animation tick
    _particleController.addListener(() {
      setState(() {
        for (var particle in _particles) {
          particle.update();
        }
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _buttonController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Particle animation layer
          CustomPaint(
            painter: ParticlePainter(particles: _particles),
            child: Container(),
          ),
          // Background image with fallback gradient
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.deepPurple.shade300, Colors.deepPurple.shade700],
                ),
              ),
            ),
          ),
          // Gradient overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          // Main content at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0, left: 16.0, right: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FadeTransition(
                    opacity: _titleFadeAnimation,
                    child: const Text(
                      'Remote Directory',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black45,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _subtitleFadeAnimation,
                    child: const Text(
                      'Explore and manage your directory with ease',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SlideTransition(
                    position: _buttonSlideAnimation,
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.withOpacity(0.7),
                              Colors.deepPurple.withOpacity(0.9),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const HomeScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                            textStyle: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Get Started'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Particle class to define particle properties
class Particle {
  Offset position;
  Offset velocity;
  double radius;
  double opacity;
  Color color;

  Particle()
      : position = Offset.zero,
        velocity = Offset(
          Random().nextDouble() * 4 - 2, // Random x velocity (-2 to 2)
          Random().nextDouble() * 4 - 2, // Random y velocity (-2 to 2)
        ),
        radius = Random().nextDouble() * 5 + 2, // Random radius (2 to 7)
        opacity = Random().nextDouble() * 0.5 + 0.3, // Random opacity (0.3 to 0.8)
        color = Colors.white.withOpacity(Random().nextDouble() * 0.5 + 0.3);

  void update() {
    position += velocity;
    // Wrap particles around the screen
    if (position.dx < 0) position = Offset(position.dx + 1000, position.dy);
    if (position.dx > 1000) position = Offset(position.dx - 1000, position.dy);
    if (position.dy < 0) position = Offset(position.dx, position.dy + 1000);
    if (position.dy > 1000) position = Offset(position.dx, position.dy - 1000);
  }
}

// Custom painter to draw particles
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(particle.position, particle.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}