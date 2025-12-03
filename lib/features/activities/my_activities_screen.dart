import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/firestore_service.dart';
import 'activity_detail_screen.dart';

class MyActivitiesView extends StatefulWidget {
  final String? userId;

  const MyActivitiesView({super.key, required this.userId});

  @override
  State<MyActivitiesView> createState() => _MyActivitiesViewState();
}

class _MyActivitiesViewState extends State<MyActivitiesView> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Community', 'Education', 'Healthcare', 'Environment', 'Other'];

  @override
  Widget build(BuildContext context) {
    if (widget.userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to view your activities.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('My Activities'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Category Filter
            SizedBox(
              height: 60,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF6B9D) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF6B9D) : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF666666),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Activities List
            Expanded(
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('users').doc(widget.userId).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('No data found.'));
                  }

                  final userData = snapshot.data!.data() ?? {};
                  final List<String> joinedActivities = List<String>.from(userData['joinedActivities'] ?? []);

                  if (joinedActivities.isEmpty) {
                    return const Center(child: Text('You haven\'t joined any activities yet.'));
                  }

                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firestoreService.getActivities(),
                    builder: (context, activitiesSnapshot) {
                      if (!activitiesSnapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allActivities = activitiesSnapshot.data!;
                      final myActivities = allActivities.where((activity) {
                        final activityId = activity['id'] as String?;
                        final category = activity['category'] as String? ?? 'Other';
                        final matchesCategory = _selectedCategory == 'All' || category == _selectedCategory;
                        return activityId != null && joinedActivities.contains(activityId) && matchesCategory;
                      }).toList();

                      // Sort by nearest date
                      myActivities.sort((a, b) {
                        final dateA = _getDateString(a['startDate']);
                        final dateB = _getDateString(b['startDate']);
                        return dateA.compareTo(dateB);
                      });

                      if (myActivities.isEmpty) {
                        return const Center(child: Text('No activities found for this category.'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: myActivities.length,
                        itemBuilder: (context, index) {
                          return _MinimalistActivityCard(activity: myActivities[index]);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getDateString(dynamic date) {
    if (date is Timestamp) {
      return date.toDate().toIso8601String();
    } else if (date is String) {
      return date;
    }
    return '';
  }
}

class _MinimalistActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _MinimalistActivityCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final String posterUrl = (activity['posterUrl'] as String?) ?? '';
    final String title = (activity['title'] as String?) ?? 'Untitled';
    final String location = (activity['location'] as String?) ?? 'Unknown';
    final int participants = (activity['participantsCount'] as int?) ?? 0;
    final int maxParticipants = (activity['maxParticipants'] as int?) ?? 0;

    String dateDisplay = 'TBA';
    if (activity['startDate'] is Timestamp) {
      dateDisplay = DateFormat('MMM d, y').format((activity['startDate'] as Timestamp).toDate());
    } else if (activity['startDate'] is String && (activity['startDate'] as String).isNotEmpty) {
      try {
        dateDisplay = DateFormat('MMM d, y').format(DateTime.parse(activity['startDate']));
      } catch (_) {}
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ActivityDetailScreen(activity: activity)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 80,
                height: 80,
                child: posterUrl.isEmpty
                    ? Container(
                        color: const Color(0xFFF5F5F5),
                        child: Icon(Icons.image_outlined, color: Colors.grey[400], size: 28),
                      )
                    : Image.network(
                        posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF5F5F5),
                          child: Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 28),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        dateDisplay,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people_outline, size: 13, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        maxParticipants > 0 ? '$participants / $maxParticipants' : '$participants',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
