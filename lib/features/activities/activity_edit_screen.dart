import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../services/storage_service.dart';

class ActivityEditScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const ActivityEditScreen({super.key, required this.activity});

  @override
  State<ActivityEditScreen> createState() => _ActivityEditScreenState();
}

class _ActivityEditScreenState extends State<ActivityEditScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final StorageService storageService = StorageService();
  final ImagePicker picker = ImagePicker();

  late String title;
  late String description;
  late String location;
  late String category;
  late DateTime startDate;
  late DateTime endDate;
  String? existingImageUrl;
  File? selectedImage;
  bool isSubmitting = false;

  final List<String> _categories = [
    'Community',
    'Education',
    'Healthcare',
    'Environment',
    'Fundraising',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with existing data
    title = widget.activity['title'] ?? '';
    description = widget.activity['description'] ?? '';
    location = widget.activity['location'] ?? '';
    category = widget.activity['category'] ?? 'Community';
    existingImageUrl = widget.activity['posterUrl'];

    if (!_categories.contains(category)) {
      category = 'Other';
    }

    try {
      if (widget.activity['startDate'] is Timestamp) {
        startDate = (widget.activity['startDate'] as Timestamp).toDate();
      } else {
        startDate = DateTime.parse(widget.activity['startDate']);
      }
    } catch (_) {
      startDate = DateTime.now();
    }

    try {
      if (widget.activity['endDate'] is Timestamp) {
        endDate = (widget.activity['endDate'] as Timestamp).toDate();
      } else {
        endDate = DateTime.parse(widget.activity['endDate']);
      }
    } catch (_) {
      endDate = DateTime.now().add(const Duration(hours: 3));
    }
  }

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

  Future<void> _pickDateTime(bool isStart) async {
    final DateTime initialDate = isStart ? startDate : endDate;
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6B9D),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1F1F1F),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFFF6B9D),
                onPrimary: Colors.white,
                onSurface: Color(0xFF1F1F1F),
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          final DateTime newDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStart) {
            startDate = newDateTime;
            if (endDate.isBefore(startDate)) {
              endDate = startDate.add(const Duration(hours: 3));
            }
          } else {
            endDate = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      isSubmitting = true;
    });

    try {
      String? imageUrl = existingImageUrl;
      if (selectedImage != null) {
        final bytes = await selectedImage!.readAsBytes();
        final base64String = base64Encode(bytes);
        imageUrl = 'data:image/jpeg;base64,$base64String';
      }

      await FirebaseFirestore.instance
          .collection('activities')
          .doc(widget.activity['id'])
          .update({
            'title': title,
            'description': description,
            'location': location,
            'category': category,
            'posterUrl': imageUrl ?? '',
            'startDate': startDate.toIso8601String(),
            'endDate': endDate.toIso8601String(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Activity updated successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFF6B9D)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Edit Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F1F1F),
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildPosterPicker(),
                const SizedBox(height: 24),
                _buildTextField(
                  label: 'Activity Title',
                  initialValue: title,
                  onChanged: (String value) => setState(() => title = value),
                  validator: (String? value) => value == null || value.isEmpty
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 18),
                _buildTextField(
                  label: 'Location',
                  initialValue: location,
                  onChanged: (String value) => setState(() => location = value),
                  validator: (String? value) => value == null || value.isEmpty
                      ? 'Location is required'
                      : null,
                ),
                const SizedBox(height: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4C4C4C),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: category,
                      items: _categories.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => category = val!),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimePicker(
                        label: 'Start Date',
                        selectedDate: startDate,
                        onTap: () => _pickDateTime(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDateTimePicker(
                        label: 'End Date',
                        selectedDate: endDate,
                        onTap: () => _pickDateTime(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _buildTextField(
                  label: 'Description',
                  initialValue: description,
                  maxLines: 4,
                  onChanged: (String value) =>
                      setState(() => description = value),
                  validator: (String? value) => value == null || value.isEmpty
                      ? 'Description is required'
                      : null,
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
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime selectedDate,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4C4C4C),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    DateFormat('MMM d, h:mm a').format(selectedDate),
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Color(0xFF666666),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPosterPicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFEEF2), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (selectedImage != null)
                  Image.file(selectedImage!, fit: BoxFit.cover)
                else if (existingImageUrl != null &&
                    existingImageUrl!.isNotEmpty)
                  Builder(
                    builder: (context) {
                      final cleanPosterUrl = existingImageUrl!
                          .trim()
                          .replaceAll(RegExp(r'\s+'), '');
                      if (cleanPosterUrl.startsWith('data:image')) {
                        try {
                          final commaIndex = cleanPosterUrl.indexOf(',');
                          if (commaIndex != -1) {
                            final base64Data = cleanPosterUrl.substring(
                              commaIndex + 1,
                            );
                            return Image.memory(
                              base64Decode(base64Data),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: const Color(0xFFFFEEF2),
                                    child: const Icon(
                                      Icons.broken_image_outlined,
                                      size: 40,
                                      color: Color(0xFFFFB6C1),
                                    ),
                                  ),
                            );
                          }
                        } catch (e) {
                          // Fall through to error container
                        }
                        return Container(
                          color: const Color(0xFFFFEEF2),
                          child: const Icon(
                            Icons.broken_image_outlined,
                            size: 40,
                            color: Color(0xFFFFB6C1),
                          ),
                        );
                      }
                      return Image.network(
                        existingImageUrl!,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                else
                  Container(
                    color: const Color(0xFFFFEEF2),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 40,
                      color: Color(0xFFFF6B9D),
                    ),
                  ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFFFF6B9D),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
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
          initialValue: initialValue,
          maxLines: maxLines,
          decoration: const InputDecoration(), // Uses theme defaults
          validator: validator,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
