import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'scan_screen.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../community/community_chat_screen.dart';
import '../../services/notification_service.dart';

class ActivityDetailScreen extends StatefulWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 5.0;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final FirestoreService firestoreService = FirestoreService();
    final User? user = authService.user;

    final String posterUrl = (widget.activity['posterUrl'] as String?) ?? '';
    final String title =
        (widget.activity['title'] as String?) ?? 'Untitled Activity';
    final String location =
        (widget.activity['location'] as String?) ?? 'No location';
    final String description =
        (widget.activity['description'] as String?) ??
        'No description provided.';
    final String activityId = (widget.activity['id'] as String?) ?? '';
    final String organization =
        (widget.activity['organization'] as String?) ?? 'Community Organizer';
    final String category =
        (widget.activity['category'] as String?) ?? 'General';

    // Safe Date Parsing
    String startDateStr = '';
    String endDateStr = '';

    if (widget.activity['startDate'] != null) {
      if (widget.activity['startDate'] is Timestamp) {
        startDateStr = (widget.activity['startDate'] as Timestamp)
            .toDate()
            .toIso8601String();
      } else {
        startDateStr = widget.activity['startDate'].toString();
      }
    }

    if (widget.activity['endDate'] != null) {
      if (widget.activity['endDate'] is Timestamp) {
        endDateStr = (widget.activity['endDate'] as Timestamp)
            .toDate()
            .toIso8601String();
      } else {
        endDateStr = widget.activity['endDate'].toString();
      }
    }

    // Determine Status
    bool isCompleted = false;
    String durationStr = 'TBA';

    if (endDateStr.isNotEmpty) {
      try {
        final DateTime end = DateTime.parse(endDateStr);
        if (DateTime.now().isAfter(end)) {
          isCompleted = true;
        }

        if (startDateStr.isNotEmpty) {
          final DateTime start = DateTime.parse(startDateStr);
          final diff = end.difference(start);
          if (diff.inHours > 0) {
            durationStr = '${diff.inHours} hrs';
          } else {
            durationStr = '${diff.inMinutes} mins';
          }
        }
      } catch (_) {}
    }

    final int participantsCount =
        (widget.activity['participantsCount'] as int?) ?? 0;
    final int maxParticipants =
        (widget.activity['maxParticipants'] as int?) ?? 50;
    final int openSpots = maxParticipants - participantsCount;
    final String spotsStr = openSpots > 0 ? '$openSpots spots' : 'Full';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _buildHeroSection(context, posterUrl),
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildInfoCard(
                            context: context,
                            title: title,
                            location: location,
                            organization: organization,
                            description: description,
                            category: category,
                            isCompleted: isCompleted,
                            duration: durationStr,
                            spots: spotsStr,
                            activityId: activityId,
                            user: user,
                            firestoreService: firestoreService,
                          ),
                        ),
                      ),
                      if (isCompleted && user != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          child: _buildFeedbackSection(
                            context,
                            firestoreService,
                            activityId,
                            user,
                          ),
                        ),
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _JoinBottomBar(
              firestoreService: firestoreService,
              user: user,
              activityId: activityId,
              isCompleted: isCompleted,
              startDate: startDateStr,

              onShowAttendance: () =>
                  _showAttendanceDialog(context, firestoreService, activityId),
              onShowQR: () => _showActivityQRDialog(context, activityId, title),
              onScanQR: () => _showScanCheckInDialog(
                context,
                firestoreService,
                user?.uid,
                activityId,
              ),
              onShowTicket: () => _showUserTicketDialog(
                context,
                user?.uid ?? '',
                user?.displayName ?? 'Volunteer',
              ),
              onScanTicket: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRScannerScreen(),
                  ),
                );
                if (result != null && result is String && context.mounted) {
                  // Check in the scanned user for this activity
                  try {
                    await firestoreService.checkInUserByActivity(
                      result,
                      activityId,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Checked in user: $result')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, String posterUrl) {
    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Builder(
              builder: (context) {
                final cleanPosterUrl = posterUrl.trim().replaceAll(
                  RegExp(r'\s+'),
                  '',
                );

                if (cleanPosterUrl.isEmpty) {
                  return Container(
                    color: const Color(0xFFFFEEF2),
                    child: const Icon(
                      Icons.image_outlined,
                      size: 72,
                      color: Color(0xFFFFB6C1),
                    ),
                  );
                }

                if (cleanPosterUrl.startsWith('data:image')) {
                  try {
                    // Extract the base64 part safely
                    final commaIndex = cleanPosterUrl.indexOf(',');
                    if (commaIndex != -1) {
                      final base64Data = cleanPosterUrl.substring(
                        commaIndex + 1,
                      );
                      return Image.memory(
                        base64Decode(base64Data),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFFFEEF2),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              size: 72,
                              color: Color(0xFFFFB6C1),
                            ),
                          );
                        },
                      );
                    }
                  } catch (e) {
                    return Container(
                      color: const Color(0xFFFFEEF2),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 72,
                        color: Color(0xFFFFB6C1),
                      ),
                    );
                  }
                }

                return Image.network(
                  cleanPosterUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFFFEEF2),
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 72,
                        color: Color(0xFFFFB6C1),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                  Colors.black.withOpacity(0.2),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  _buildCircleButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildCircleButton(
                    icon: Icons.share_rounded,
                    onTap: () {
                      final title = widget.activity['title'] ?? 'Activity';
                      final location =
                          widget.activity['location'] ?? 'Unknown Location';
                      Share.share(
                        'Check out this activity: $title\n\nLocation: $location\n\nDownload Engage360 to join me!',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1A1A1A), size: 20),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String location,
    required String organization,
    required String description,
    required String category,
    required bool isCompleted,
    required String duration,
    required String spots,
    required String activityId,
    required User? user,
    required FirestoreService firestoreService,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (user != null &&
              widget.activity['createdBy'] == user.uid &&
              widget.activity['activityCode'] != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFB74D)),
              ),
              child: Column(
                children: [
                  const Text(
                    'ADMIN ACCESS CODE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF57C00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.activity['activityCode'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Color(0xFFE65100),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Share this code for manual check-in',
                    style: TextStyle(fontSize: 12, color: Color(0xFFE65100)),
                  ),
                ],
              ),
            ),
          // Header: Category & Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFFF6B9D),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Spacer(),
              if (user != null)
                StreamBuilder<Map<String, dynamic>?>(
                  stream: firestoreService.getUserRegistrationStream(
                    user.uid,
                    activityId,
                  ),
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    final bool isRegistered =
                        data != null; // If doc exists, they are registered
                    final bool isCheckedIn =
                        data != null && data['status'] == 'checked-in';

                    if (isCheckedIn) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CHECKED IN',
                          style: TextStyle(
                            color: Color(0xFF27AE60),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      );
                    } else if (isRegistered) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'REGISTERED',
                          style: TextStyle(
                            color: Color(0xFFFF9800),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      );
                    } else if (isCompleted) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'COMPLETED',
                          style: TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                )
              else if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Organization
          Row(
            children: <Widget>[
              const Icon(
                Icons.apartment_rounded,
                color: Color(0xFFFF6B9D),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                organization,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Info Grid (Replaces Pills for cleaner look)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(Icons.access_time_rounded, duration, 'Duration'),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildInfoItem(
                  Icons.people_outline_rounded,
                  spots,
                  'Availability',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFFF6B9D),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  location,
                  style: const TextStyle(
                    color: Color(0xFF333333),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Community Chat Button
          GestureDetector(
            onTap: () {
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please sign in to join the chat'),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CommunityChatScreen(
                    activityId: activityId,
                    activityTitle: title,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFFF6B9D).withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B9D).withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFFFF6B9D),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Join Community Chat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFFFF6B9D),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Description
          const Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF666666),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1A1A1A)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF999999)),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(
    BuildContext context,
    FirestoreService firestoreService,
    String activityId,
    User? user,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reviews',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('Rate your experience'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1.0;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        index < _rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        size: 32,
                        color: const Color(0xFFFFC107),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _reviewController,
                decoration: InputDecoration(
                  hintText: 'Write a review...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (user != null && _reviewController.text.isNotEmpty) {
                      await firestoreService.addReview(
                        activityId,
                        user.uid,
                        _rating,
                        _reviewController.text,
                      );
                      _reviewController.clear();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Review submitted!')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showActivityQRDialog(
    BuildContext context,
    String activityId,
    String title,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Activity QR Code', textAlign: TextAlign.center),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.grey, size: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: activityId,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ask volunteers to scan this code to check in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showScanCheckInDialog(
    BuildContext context,
    FirestoreService firestoreService,
    String? userId,
    String activityId,
  ) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Scan to Check In', textAlign: TextAlign.center),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.grey, size: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: InkWell(
                onTap: () async {
                  // Open Scanner
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QRScannerScreen()),
                  );

                  if (result != null && result is String) {
                    codeController.text = result;
                    // Auto submit
                    if (context.mounted) {
                      _handleCheckInSubmit(
                        context,
                        firestoreService,
                        userId,
                        activityId,
                        result,
                      );
                    }
                  }
                },
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Tap to Scan',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ), // Close Container
            const SizedBox(height: 16),
            const Text(
              'Or enter Activity ID manually:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: 'Activity ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _handleCheckInSubmit(
              context,
              firestoreService,
              userId,
              activityId,
              codeController.text.trim(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDialog(
    BuildContext context,
    FirestoreService firestoreService,
    String activityId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Attendance'),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.grey, size: 20),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestoreService.getActivityParticipants(activityId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No participants yet.');
              }
              final participants = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final p = participants[index];
                  final bool isCheckedIn = p['status'] == 'checked-in';
                  return ListTile(
                    title: Text(p['userName'] ?? 'Unknown'),
                    subtitle: Text(p['userEmail'] ?? ''),
                    trailing: isCheckedIn
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
                            onPressed: () async {
                              await firestoreService.checkInUser(p['id']);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B9D),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            child: const Text(
                              'Check In',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCheckInSubmit(
    BuildContext context,
    FirestoreService firestoreService,
    String? userId,
    String activityId,
    String code,
  ) async {
    final String? activityCode = widget.activity['activityCode'];

    if (code.isEmpty || userId == null) {
      return;
    }

    // Validate Code
    // Allow matching activityId OR activityCode
    if (code != activityId && code != activityCode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Code. Please try again.')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await firestoreService.checkInUserByActivity(userId, activityId);

      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        Navigator.pop(context); // Pop check-in dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked in successfully! +50 Points'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Pop loading
        // Don't pop check-in dialog, let them retry
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showUserTicketDialog(
    BuildContext context,
    String userId,
    String userName,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Ticket', textAlign: TextAlign.center),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.grey, size: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: userId, // User ID is the ticket data for now
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Show this code to the organizer to check in.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinBottomBar extends StatelessWidget {
  final FirestoreService firestoreService;
  final User? user;
  final String activityId;
  final bool isCompleted;
  final VoidCallback onShowQR;
  final VoidCallback onScanQR;
  final VoidCallback onShowAttendance;
  final VoidCallback onShowTicket;
  final VoidCallback onScanTicket;
  final String startDate;

  const _JoinBottomBar({
    required this.firestoreService,
    required this.user,
    required this.activityId,
    required this.isCompleted,
    required this.onShowAttendance,
    required this.onShowQR,
    required this.onScanQR,
    required this.onShowTicket,
    required this.onScanTicket,
    required this.startDate,
  });

  // Helper to access showUserTicketDialog which is in the parent state...
  // Since this is a stateless widget, we should pass the callback or move logic.
  // Ideally, passes a callback for 'onShowTicket'.
  // I will cheat slightly by finding the parent state or just duplicating the show dialog logic?
  // No, clean way: I will add 'onMyTicket' callback.
  // But I can't easily change the constructor signature without changing the call site.
  // The call site is in the same file.
  // I will just add the method to the class _ActivityDetailScreenState and pass another callback.
  // Wait, I am editing the class _JoinBottomBar below.
  // I'll update the constructor signature in a separate chunk.

  // Wait, I cannot change constructor in this chunk easily because I need to match the previous chunk.
  // I will scroll up and fix the call site in _ActivityDetailScreenState build method first?
  // Actually, I can use the context to find the User name?
  // Let's modify the signature in the next chunk.

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: user == null
                  ? null
                  : FirebaseFirestore.instance
                        .collection('users')
                        .doc(user!.uid)
                        .snapshots(),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                    snapshot,
                  ) {
                    if (activityId.isEmpty) {
                      return _buildButton(
                        context,
                        enabled: false,
                        label: 'Unavailable',
                      );
                    }
                    if (user == null) {
                      return _buildButton(
                        context,
                        enabled: false,
                        label: 'Sign in to join',
                      );
                    }
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 56,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final Map<String, dynamic>? data = snapshot.data?.data();
                    if (data == null) {
                      return _buildButton(
                        context,
                        enabled: false,
                        label: 'User data unavailable',
                      );
                    }
                    final String role =
                        (data['role'] as String?) ?? 'volunteer';
                    final List<String> joinedActivities = List<String>.from(
                      data['joinedActivities'] ?? <String>[],
                    );
                    final bool isOrganizer = role == 'organization';
                    final bool isJoined = joinedActivities.contains(activityId);

                    if (isOrganizer) {
                      return Row(
                        children: [
                          Expanded(
                            child: _buildButton(
                              context,
                              enabled: true,
                              label: 'QR',
                              onPressed: onShowQR,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildButton(
                              context,
                              enabled: true,
                              label: 'Scan',
                              onPressed: onScanTicket,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildButton(
                              context,
                              enabled: true,
                              label: 'List',
                              onPressed: onShowAttendance,
                            ),
                          ),
                        ],
                      );
                    }

                    if (isJoined) {
                      return StreamBuilder<Map<String, dynamic>?>(
                        stream: firestoreService.getUserRegistrationStream(
                          user!.uid,
                          activityId,
                        ),
                        builder: (context, regSnapshot) {
                          final regData = regSnapshot.data;
                          final isCheckedIn =
                              regData != null &&
                              regData['status'] == 'checked-in';

                          if (isCheckedIn) {
                            return _buildButton(
                              context,
                              enabled: false,
                              label: 'Checked In',
                              backgroundColor: const Color(0xFF27AE60),
                              textColor: Colors.white,
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: _buildButton(
                                  context,
                                  enabled: true,
                                  label: 'My Ticket',
                                  onPressed: onShowTicket,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildButton(
                                  context,
                                  enabled: true,
                                  label: 'Scan Event',
                                  onPressed: onScanQR,
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    }

                    if (isCompleted) {
                      return _buildButton(
                        context,
                        enabled: false,
                        label: 'Activity Completed',
                      );
                    }

                    return _buildButton(
                      context,
                      enabled: true,
                      label: 'Join Activity',
                      onPressed: () async {
                        if (user == null) {
                          return;
                        }
                        await firestoreService.joinActivity(
                          user!.uid,
                          activityId,
                        );

                        // Schedule Reminder (1 hour before)
                        if (startDate.isNotEmpty) {
                          try {
                            final start = DateTime.parse(startDate);
                            final reminderTime = start.subtract(
                              const Duration(hours: 1),
                            );
                            if (reminderTime.isAfter(DateTime.now())) {
                              await NotificationService().scheduleNotification(
                                id: activityId.hashCode,
                                title: 'Activity Reminder ⏰',
                                body: 'Your activity starts in 1 hour!',
                                scheduledTime: reminderTime,
                              );
                            }
                          } catch (e) {
                            debugPrint('Error scheduling notification: $e');
                          }
                        }

                        if (!context.mounted) {
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Joined successfully! Reminder set.'),
                          ),
                        );
                      },
                    );
                  },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required bool enabled,
    required String label,
    VoidCallback? onPressed,
    Color? backgroundColor,
    Color? textColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? const Color(0xFFFF6B9D),
          disabledBackgroundColor:
              backgroundColor?.withOpacity(0.5) ?? const Color(0xFFF0F0F0),
          disabledForegroundColor: textColor ?? const Color(0xFFAAAAAA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
