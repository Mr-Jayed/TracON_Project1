import 'package:flutter/material.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.tealAccent.withOpacity(0.3)),
                          ),
                          child: Icon(
                            Icons.sensors,
                            color: Colors.tealAccent,
                            size: screenHeight * 0.06,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          'TRACKON\nSYSTEMS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.1,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Universal remote telemetry and vehicle command terminal.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: screenWidth * 0.04,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 60),

                        _buildButton(
                          context,
                          'SIGN IN',
                          Colors.tealAccent,
                          Colors.black,
                              () => Navigator.pushNamed(context, '/login'),
                        ),

                        const SizedBox(height: 15),

                        _buildButton(
                          context,
                          'REGISTER AS NEW USER',
                          Colors.white.withOpacity(0.05),
                          Colors.tealAccent,
                              () => Navigator.pushNamed(context, '/signup'),
                          hasBorder: true,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            }
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, Color bgColor, Color textColor, VoidCallback onPressed, {bool hasBorder = false}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: hasBorder ? const BorderSide(color: Colors.tealAccent, width: 0.5) : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
    );
  }
}