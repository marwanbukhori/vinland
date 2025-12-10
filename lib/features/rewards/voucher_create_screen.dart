import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';

class VoucherCreateScreen extends StatefulWidget {
  const VoucherCreateScreen({super.key});

  @override
  State<VoucherCreateScreen> createState() => _VoucherCreateScreenState();
}

class _VoucherCreateScreenState extends State<VoucherCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();

  String title = '';
  String description = '';
  int cost = 0;
  String imageUrl = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Voucher'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Voucher Title',
                  hintText: 'e.g., \$10 Amazon Gift Card',
                ),
                validator: (val) => val!.isEmpty ? 'Please enter a title' : null,
                onChanged: (val) => title = val,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Details about the voucher...',
                ),
                maxLines: 3,
                validator: (val) => val!.isEmpty ? 'Please enter a description' : null,
                onChanged: (val) => description = val,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Cost (Points)',
                  hintText: 'e.g., 500',
                ),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Please enter cost' : null,
                onChanged: (val) => cost = int.tryParse(val) ?? 0,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Image URL (Optional)',
                  hintText: 'https://...',
                ),
                onChanged: (val) => imageUrl = val,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Voucher', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _firestoreService.createVoucher({
          'title': title,
          'description': description,
          'cost': cost,
          'imageUrl': imageUrl,
          'imageUrl': imageUrl,
          'createdBy': FirebaseAuth.instance.currentUser?.uid,
          'createdAt': DateTime.now().toIso8601String(),
        });
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voucher created successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
