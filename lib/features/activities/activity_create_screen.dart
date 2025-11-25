import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';

/// Modernized creator for volunteer activities.
class ActivityCreateScreen extends StatefulWidget {
  const ActivityCreateScreen({super.key});

  @override
  State<ActivityCreateScreen> createState() => _ActivityCreateScreenState();
}

class _ActivityCreateScreenState extends State<ActivityCreateScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final FirestoreService firestoreService = FirestoreService();
  final StorageService storageService = StorageService();
  final ImagePicker picker = ImagePicker();

  String title = '';
  String description = '';
  String location = '';
  File? selectedImage;
  bool isSubmitting = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (pickedFile == null) {
      return;
    }
    setState(() {
      selectedImage = File(pickedFile.path);
    });
  }

  Future<void> _handleSubmit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isSubmitting = true;
    });
    String? imageUrl;
    if (selectedImage != null) {
      imageUrl = await storageService.uploadImage(
        selectedImage!,
        'activities/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
    }
    await firestoreService.addActivity(<String, dynamic>{
      'title': title,
      'description': description,
      'location': location,
      'posterUrl': imageUrl ?? '',
      'createdAt': DateTime.now(),
    });
    setState(() {
      isSubmitting = false;
    });
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Activity'),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Design a memorable experience',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Tell volunteers what makes this activity special.',
                  style: TextStyle(color: Color(0xFF8E8E8E)),
                ),
                const SizedBox(height: 24),
                _buildPosterPicker(),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Activity Title',
                  hint: 'Beach cleanup with the community',
                  onChanged: (String value) => setState(() => title = value),
                  validator: (String? value) => value == null || value.isEmpty ? 'Title is required' : null,
                ),
                const SizedBox(height: 18),
                _buildTextField(
                  label: 'Location',
                  hint: 'Port Klang Waterfront',
                  onChanged: (String value) => setState(() => location = value),
                  validator: (String? value) => value == null || value.isEmpty ? 'Location is required' : null,
                ),
                const SizedBox(height: 18),
                _buildTextField(
                  label: 'Description',
                  hint: 'Share the story, roles, and impact your volunteers will make.',
                  maxLines: 4,
                  onChanged: (String value) => setState(() => description = value),
                  validator: (String? value) => value == null || value.isEmpty ? 'Description is required' : null,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : _handleSubmit,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Publish Activity'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPosterPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: selectedImage == null ? const EdgeInsets.all(32) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F4),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFFC7DA)),
        ),
        child: selectedImage == null
            ? Column(
                children: const <Widget>[
                  Icon(Icons.add_photo_alternate_rounded, size: 48, color: Color(0xFFFF7AA2)),
                  SizedBox(height: 12),
                  Text(
                    'Upload cover poster',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Min 1200x1200px, JPG or PNG',
                    style: TextStyle(color: Color(0xFF8E8E8E)),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.file(selectedImage!, fit: BoxFit.cover),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required ValueChanged<String> onChanged,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4C4C4C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
          ),
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
