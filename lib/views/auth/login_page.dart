// imports remain unchanged
import 'dart:ui';
import 'package:flutter/material.dart';
import 'register_page.dart';
import '../../services/auth_service.dart';
import '../hotel/dashboard.dart';
import '../supplier/create_shop_page.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool isLoading = false;
  bool _hovering = false;
  double _beforeOffset = -100;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1BFD9C);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/background.jpg', fit: BoxFit.cover),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: 350,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Login',
                        style: GoogleFonts.italianno(
                          fontSize: 52,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black87,
                              offset: Offset(3, 3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildInputField(emailController, 'Email'),
                      const SizedBox(height: 15),
                      _buildInputField(
                        passwordController,
                        'Password',
                        isPassword: true,
                      ),
                      const SizedBox(height: 10),
                      _buildRememberMeCheckbox(),
                      const SizedBox(height: 20),
                      _buildNeonButton(
                        text: 'Login',
                        isLoading: isLoading,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                        child: const Text(
                          "Don't have an account? Register",
                          style: TextStyle(
                            color: Color.fromARGB(200, 255, 255, 255),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        'Frogot your password',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() {
      isLoading = true;
    });

    final response = await authService.loginUser(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    setState(() {
      isLoading = false;
    });

    if (response['success'] == true) {
      String role = response['role'];
      if (role == 'hotel') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HotelDashboard(hotelId: 'yourHotelIdHere'),
          ),
        );
      } else if (role == 'supplier') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CreateShopPage()),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['error'] ?? 'Login failed')),
      );
    }
  }

  Widget _buildNeonButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    const green = Color(0xFF1BFD9C);

    return MouseRegion(
      onEnter: (_) => setState(() {
        _hovering = true;
        _beforeOffset = 300;
      }),
      onExit: (_) => setState(() {
        _hovering = false;
        _beforeOffset = -100;
      }),
      child: GestureDetector(
        onTap: isLoading ? null : onPressed,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: green, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: green.withOpacity(_hovering ? 0.2 : 0.1),
                    blurRadius: 9,
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    color: green.withOpacity(_hovering ? 0.6 : 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 0),
                  ),
                ],
                gradient: const LinearGradient(
                  colors: [
                    Color.fromRGBO(27, 253, 156, 0.1),
                    Colors.transparent,
                    Colors.transparent,
                    Color.fromRGBO(27, 253, 156, 0.1),
                  ],
                  stops: [0.01, 0.4, 0.6, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      text,
                      style: TextStyle(
                        color: _hovering
                            ? const Color(0xFF82FFC9)
                            : const Color.fromARGB(255, 27, 253, 156),
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              top: 0,
              bottom: 0,
              left: _beforeOffset,
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      green.withOpacity(0.1),
                      green.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hint, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? _obscurePassword : false,
      style: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white70,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _buildRememberMeCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _rememberMe,
          onChanged: (value) {
            setState(() {
              _rememberMe = value ?? false;
            });
          },
          checkColor: Colors.black,
          activeColor: const Color(0xFF1BFD9C),
        ),
        const Text(
          'Remember password',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
      ],
    );
  }
}
