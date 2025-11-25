import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final Function? toggleView;
  const RegisterScreen({super.key, this.toggleView});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String name = '';
  String role = 'volunteer'; // Default role
  String error = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Us! ✨'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.person, color: Color(0xFFFF6B9D)),
            label: const Text('Sign In', style: TextStyle(color: Color(0xFFFF6B9D))),
            onPressed: () {
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  size: 60,
                  color: Color(0xFFFF6B9D),
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                  onChanged: (val) {
                    setState(() => name = val);
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                  onChanged: (val) {
                    setState(() => email = val);
                  },
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  decoration: const InputDecoration(
                    hintText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (val) => val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                  onChanged: (val) {
                    setState(() => password = val);
                  },
                ),
                const SizedBox(height: 20.0),
                DropdownButtonFormField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  initialValue: role,
                  items: ['volunteer', 'organization'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => role = val as String),
                ),
                const SizedBox(height: 30.0),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        setState(() => _isLoading = true);

                        dynamic result = await authService.registerWithEmailAndPassword(
                          email,
                          password,
                          name,
                          role
                        );

                        if (result == null) {
                          setState(() {
                            error = 'Registration failed. Please try again.';
                            _isLoading = false;
                          });
                        } else {
                          // Success! Show message and navigate
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Welcome, $name! 🎉'),
                                backgroundColor: const Color(0xFFFF6B9D),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            // The Wrapper will automatically navigate to home
                            // because authService.user is now set
                            Navigator.pop(context);
                          }
                        }
                      }
                    },
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Register'),
                  ),
                ),
                const SizedBox(height: 12.0),
                Text(
                  error,
                  style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 14.0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
