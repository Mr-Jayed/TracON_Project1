import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  String? _errorMessage;
  bool _loading = false;

  final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  final RegExp _passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*#?&])[A-Za-z\d@$!%*#?&]{8,}$');

  Future<void> _signUp() async {
    setState(() { _errorMessage = null; _loading = true; });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'All fields are required for initialization.';
        _loading = false;
      });
      return;
    }


    if (!_emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Invalid Communication ID (Email format).';
        _loading = false;
      });
      return;
    }


    if (!_passwordRegex.hasMatch(password)) {
      setState(() {
        _errorMessage = 'Access Code must have 8+ chars, 1 letter, 1 number & 1 symbol.';
        _loading = false;
      });
      return;
    }


    if (password != confirm) {
      setState(() {
        _errorMessage = 'Access Codes do not match.';
        _loading = false;
      });
      return;
    }

    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration Successful. Please Login.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white24, size: 20),
                onPressed: () => Navigator.pushNamed(context, '/'),
              ),
              const SizedBox(height: 25),
              const Text("NEW COMMANDER", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              const Text("INITIALIZE TRACKON PROTOCOL", style: TextStyle(color: Colors.tealAccent, fontSize: 10, letterSpacing: 1)),

              const SizedBox(height: 40),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
                ),

              _buildField(_nameController, "FULL NAME", Icons.person_outline, false, screenWidth),
              const SizedBox(height: 20),
              _buildField(_emailController, "EMAIL ADDRESS", Icons.email_outlined, false, screenWidth),
              const SizedBox(height: 20),
              _buildField(_passwordController, "ACCESS CODE", Icons.lock_outline, true, screenWidth),
              const SizedBox(height: 20),
              _buildField(_confirmController, "CONFIRM ACCESS CODE", Icons.shield_outlined, true, screenWidth),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('INITIALIZE ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: RichText(
                    text: const TextSpan(
                      text: "ALREADY AUTHORIZED? ",
                      style: TextStyle(color: Colors.white24, fontSize: 11, letterSpacing: 1),
                      children: [
                        TextSpan(
                          text: "SIGN IN",
                          style: TextStyle(color: Colors.tealAccent, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, bool obscure, double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white24, size: 18),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1))
            ),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.tealAccent)
            ),
          ),
        ),
      ],
    );
  }
}