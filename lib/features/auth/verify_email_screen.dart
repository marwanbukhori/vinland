import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Check status immediately
    isEmailVerified = authService.user?.emailVerified ?? false;

    if (!isEmailVerified) {
      // Send email on first load (optional, but good UX if coming from register)
      // _sendVerificationEmail(); 
      
      // Periodically check for verification
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.reloadUser();
    
    setState(() {
      isEmailVerified = authService.user?.emailVerified ?? false;
    });

    if (isEmailVerified) {
      timer?.cancel();
      // Wrapper will handle redirection automatically
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendVerificationEmail();

      setState(() => canResendEmail = false);
      await Future.delayed(const Duration(seconds: 5));
      setState(() => canResendEmail = true);
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification email sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isEmailVerified) {
       // Ideally wrapper handles this, but just in case
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authService.signOut(),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 80, color: Color(0xFFFF6B9D)),
            const SizedBox(height: 24),
            Text(
              'Verify your email address',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We have sent a verification link to:\n${authService.user?.email ?? "your email"}',
              style: const TextStyle(fontSize: 16, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please check your email and click the link to verify your account.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: canResendEmail ? sendVerificationEmail : () => sendVerificationEmail(),
              icon: const Icon(Icons.email),
              label: const Text('Resend Email'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => authService.signOut(),
              child: const Text('Cancel / Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
