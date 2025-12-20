import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // This variable holds the error from Firebase
  String? _oldPasswordError;

  Future<void> _handleChangePassword() async {
    // Reset the old password error before validating again
    setState(() => _oldPasswordError = null);

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null && user.email != null) {
          // 1. Re-authenticate
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _oldPassController.text.trim(),
          );

          await user.reauthenticateWithCredential(credential);

          // 2. Update password
          await user.updatePassword(_newPassController.text.trim());

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Successful!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          setState(() {
            _oldPasswordError = "Incorrect old password. Please try again.";
          });
          // Force the form to rebuild and show the red error text immediately
          _formKey.currentState!.validate();
        } else {
          _showError(e.message ?? "An error occurred");
        }
      } catch (e) {
        _showError(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Change Password", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        // Set autovalidateMode to interactively check errors while typing
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // OLD PASSWORD
            _buildPasswordField(
              label: "Old Password",
              controller: _oldPassController,
              obscure: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
              validator: (value) {
                if (value == null || value.isEmpty) return "Please enter your old password";
                return _oldPasswordError; // Returns the Firebase error if present
              },
            ),
            const SizedBox(height: 20),

            // NEW PASSWORD
            _buildPasswordField(
              label: "New Password",
              controller: _newPassController,
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              validator: (value) {
                if (value == null || value.isEmpty) return "Please enter a new password";
                if (value.length < 6) return "Password must be at least 6 characters";
                return null;
              },
            ),
            const SizedBox(height: 20),

            // CONFIRM PASSWORD
            _buildPasswordField(
              label: "Confirm Password",
              controller: _confirmPassController,
              obscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (value) {
                if (value == null || value.isEmpty) return "Please confirm your password";
                // CRITICAL: Compare with the new password controller text
                if (value != _newPassController.text) {
                  return "Passwords do not match. Please check again.";
                }
                return null;
              },
            ),
            const SizedBox(height: 40),

            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF25278)))
                : ElevatedButton(
              onPressed: _handleChangePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF25278),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Update Password", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          // Clear Firebase error when user starts typing in Old Password field again
          onChanged: (val) {
            if (label == "Old Password" && _oldPasswordError != null) {
              setState(() => _oldPasswordError = null);
            }
          },
          decoration: InputDecoration(
            hintText: "Enter $label",
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            errorStyle: const TextStyle(color: Colors.red),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
              onPressed: onToggle,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}