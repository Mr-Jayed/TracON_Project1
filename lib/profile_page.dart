import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final user = Supabase.instance.client.auth.currentUser;
  final _nameController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current metadata
    _nameController.text = user?.userMetadata?['full_name'] ?? "Unknown Commander";
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);
    try {
      // Update metadata in Supabase Auth
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          data: {'full_name': _nameController.text.trim()},
        ),
      );

      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("COMMANDER DATA UPDATED"),
            backgroundColor: Colors.tealAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("COMMANDER PROFILE",
            style: TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (mounted) Navigator.pushReplacementNamed(context, '/');
              },
            )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.tealAccent.withOpacity(0.5), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white10,
                      child: Icon(Icons.person_rounded, size: 50, color: Colors.tealAccent),
                    ),
                  ),
                  if (_isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.tealAccent, shape: BoxShape.circle),
                        child: const Icon(Icons.edit, size: 15, color: Colors.black),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Identity Field
            _buildInfoField(
              label: "IDENTITY (FULL NAME)",
              controller: _nameController,
              isEditable: _isEditing,
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 25),

            // Email Field (Read Only)
            _buildInfoField(
              label: "COMMUNICATION CHANNEL (EMAIL)",
              controller: TextEditingController(text: user?.email),
              isEditable: false,
              icon: Icons.alternate_email,
            ),
            const SizedBox(height: 25),

            // Device ID (Read Only)
            _buildInfoField(
              label: "LINKED HARDWARE",
              controller: TextEditingController(text: "CAR_001_ESP32"),
              isEditable: false,
              icon: Icons.memory,
            ),

            const SizedBox(height: 50),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isEditing ? Colors.tealAccent : Colors.white.withOpacity(0.05),
                  foregroundColor: _isEditing ? Colors.black : Colors.tealAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.tealAccent, width: 0.5),
                  ),
                ),
                onPressed: _isLoading
                    ? null
                    : () {
                  if (_isEditing) {
                    _updateProfile();
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                child: _isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : Text(
                  _isEditing ? "SAVE CONFIGURATION" : "MODIFY PROFILE",
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ),
            ),

            if (_isEditing)
              TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text("CANCEL", style: TextStyle(color: Colors.white24, fontSize: 10)),
              ),

            // Go to Dashboard Button (Only if not editing)
            if (!_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("ACCESS DASHBOARD", style: TextStyle(color: Colors.white, fontSize: 11)),
                      SizedBox(width: 5),
                      Icon(Icons.arrow_forward, size: 14, color: Colors.tealAccent),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField({
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          enabled: isEditable,
          style: TextStyle(color: isEditable ? Colors.white : Colors.white70),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: isEditable ? Colors.tealAccent : Colors.white24),
            filled: true,
            fillColor: isEditable ? Colors.white.withOpacity(0.05) : Colors.transparent,
            disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.tealAccent),
            ),
          ),
        ),
      ],
    );
  }
}