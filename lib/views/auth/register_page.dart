import 'dart:ui';
import 'package:flutter/material.dart';
import 'login_page.dart';
import '../../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService authService = AuthService();
  String selectedRole = 'hotel';

  bool isLoading = false;
  bool _hovering = false;
  double _beforeOffset = -100;

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
                  width: 370,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Register',
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
                        const SizedBox(height: 20),
                        _buildInputField(usernameController, 'Username'),
                        const SizedBox(height: 15),
                        _buildInputField(emailController, 'Email'),
                        const SizedBox(height: 15),
                        _buildInputField(
                          passwordController,
                          'Password',
                          isPassword: true,
                        ),
                        const SizedBox(height: 20),
                        _buildRoleDropdown(),
                        const SizedBox(height: 25),
                        _buildNeonButton(
                          text: 'Register',
                          isLoading: isLoading,
                          onPressed: _handleRegister,
                        ),
                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Already have an account? Login",
                            style: TextStyle(
                              color: Color.fromARGB(200, 255, 255, 255),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    setState(() => isLoading = true);

    final response = await authService.registerUser(
      username: usernameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      role: selectedRole,
    );

    setState(() => isLoading = false);

    if (response == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response)));
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
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        dropdownColor: const Color.fromARGB(200, 0, 0, 0),
        style: const TextStyle(color: Colors.white, fontSize: 16),
        value: selectedRole,
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: 'Select Role',
          labelStyle: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
        ),
        onChanged: (value) {
          setState(() {
            selectedRole = value!;
          });
        },
        items: const [
          DropdownMenuItem(value: 'hotel', child: Text('Hotel')),
          DropdownMenuItem(value: 'supplier', child: Text('Supplier')),
        ],
      ),
    );
  }
}
