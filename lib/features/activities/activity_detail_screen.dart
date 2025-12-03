import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../community/community_chat_screen.dart';

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
    final String title = (widget.activity['title'] as String?) ?? 'Untitled Activity';
    final String location = (widget.activity['location'] as String?) ?? 'No location';
    final String description = (widget.activity['description'] as String?) ?? 'No description provided.';
    final String activityId = (widget.activity['id'] as String?) ?? '';
    final String organization = (widget.activity['organization'] as String?) ?? 'Community Organizer';
    final String category = (widget.activity['category'] as String?) ?? 'General';
    
    // Safe Date Parsing
    String startDateStr = '';
    String endDateStr = '';
    
    if (widget.activity['startDate'] != null) {
      if (widget.activity['startDate'] is Timestamp) {
        startDateStr = (widget.activity['startDate'] as Timestamp).toDate().toIso8601String();
      } else {
        startDateStr = widget.activity['startDate'].toString();
      }
    }
    
    if (widget.activity['endDate'] != null) {
      if (widget.activity['endDate'] is Timestamp) {
        endDateStr = (widget.activity['endDate'] as Timestamp).toDate().toIso8601String();
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
    
    final int participantsCount = (widget.activity['participantsCount'] as int?) ?? 0;
    final int maxParticipants = (widget.activity['maxParticipants'] as int?) ?? 50;
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
                          ),
                        ),
                      ),
                      if (isCompleted && user != null)
                         Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                           child: _buildFeedbackSection(context, firestoreService, activityId, user),
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
              onShowAttendance: () => _showAttendanceDialog(context, firestoreService, activityId),
              onShowQR: () => _showActivityQRDialog(context, activityId, title),
              onScanQR: () => _showScanCheckInDialog(context, firestoreService, user?.uid, activityId),
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
            child: posterUrl.isEmpty
                ? Container(
                    color: const Color(0xFFFFEEF2),
                    child: const Icon(Icons.image_outlined, size: 72, color: Color(0xFFFFB6C1)),
                  )
                : Image.network(
                    posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFFFEEF2),
                      child: const Icon(Icons.broken_image_outlined, size: 72, color: Color(0xFFFFB6C1)),
                    ),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sharing not implemented yet')),
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

  Widget _buildCircleButton({required IconData icon, required VoidCallback onTap}) {
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
          // Header: Category & Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'COMPLETED',
                    style: TextStyle(
                      color: Color(0xFF27AE60),
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
              const Icon(Icons.apartment_rounded, color: Color(0xFFFF6B9D), size: 18),
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
                _buildInfoItem(Icons.people_outline_rounded, spots, 'Availability'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFFFF6B9D), size: 20),
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
                  const SnackBar(content: Text('Please sign in to join the chat')),
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
                border: Border.all(color: const Color(0xFFFF6B9D).withOpacity(0.3)),
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
                  Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFFF6B9D)),
                  SizedBox(width: 12),
                  Text(
                    'Join Community Chat',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFFF6B9D)),
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
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(BuildContext context, FirestoreService firestoreService, String activityId, User? user) {
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
                        index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
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
                      await firestoreService.addReview(activityId, user.uid, _rating, _reviewController.text);
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showActivityQRDialog(BuildContext context, String activityId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Activity QR Code', textAlign: TextAlign.center),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showScanCheckInDialog(BuildContext context, FirestoreService firestoreService, String? userId, String activityId) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Scan to Check In', textAlign: TextAlign.center),
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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'Scan Activity QR\n(Camera not available)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Or enter Activity ID manually:', style: TextStyle(fontWeight: FontWeight.bold)),
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
            onPressed: () async {
              final String code = codeController.text.trim();
              if (code.isNotEmpty && userId != null) {
                if (code != activityId) {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid QR Code for this activity')),
                  );
                  return;
                }
                Navigator.pop(context);
                try {
                  await firestoreService.checkInUserByActivity(userId, activityId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Checked in successfully! +50 Points')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Check In'),
          ),
        ],
      ),
    );
  }

  void _showAttendanceDialog(BuildContext context, FirestoreService firestoreService, String activityId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Attendance'),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('Check In', style: TextStyle(fontSize: 12)),
                          ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
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

  const _JoinBottomBar({
    required this.firestoreService,
    required this.user,
    required this.activityId,
    required this.isCompleted,
    required this.onShowAttendance,
    required this.onShowQR,
    required this.onScanQR,
  });

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
                  : FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                if (activityId.isEmpty) {
                  return _buildButton(context, enabled: false, label: 'Unavailable');
                }
                if (user == null) {
                  return _buildButton(context, enabled: false, label: 'Sign in to join');
                }
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 56,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final Map<String, dynamic>? data = snapshot.data?.data();
                if (data == null) {
                  return _buildButton(context, enabled: false, label: 'User data unavailable');
                }
                final String role = (data['role'] as String?) ?? 'volunteer';
                final List<String> joinedActivities = List<String>.from(
                  data['joinedActivities'] ?? <String>[],
                );
                final bool isOrganizer = role == 'organization';
                final bool isJoined = joinedActivities.contains(activityId);

                if (isOrganizer) {
                  return Row(
                    children: [
                      Expanded(child: _buildButton(context, enabled: true, label: 'Show QR', onPressed: onShowQR)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildButton(context, enabled: true, label: 'Attendance', onPressed: onShowAttendance)),
                    ],
                  );
                }
                if (isJoined) {
                  return Row(
                    children: [
                      Expanded(child: _buildButton(context, enabled: false, label: 'Joined')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildButton(context, enabled: true, label: 'Scan to Check In', onPressed: onScanQR)),
                    ],
                  );
                }
                if (isCompleted) {
                   return _buildButton(context, enabled: false, label: 'Activity Completed');
                }

                return _buildButton(
                  context,
                  enabled: true,
                  label: 'Join Activity',
                  onPressed: () async {
                    if (user == null) {
                      return;
                    }
                    await firestoreService.joinActivity(user!.uid, activityId);
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Joined successfully!')),
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

  Widget _buildButton(BuildContext context, {required bool enabled, required String label, VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B9D),
          disabledBackgroundColor: const Color(0xFFF0F0F0),
          disabledForegroundColor: const Color(0xFFAAAAAA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
