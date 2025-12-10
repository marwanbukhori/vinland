import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/firestore_service.dart';
import 'activity_detail_screen.dart';

class AllActivitiesScreen extends StatefulWidget {
  final String? creatorId;
  const AllActivitiesScreen({super.key, this.creatorId});

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = <String>[
    'All',
    'Community',
    'Education',
    'Healthcare',
    'Environment',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(widget.creatorId != null ? 'Your Activities' : 'All Activities'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: <Widget>[
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getActivities(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading activities'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<Map<String, dynamic>> activities =
                    snapshot.data ?? <Map<String, dynamic>>[];

                // Filter
                activities = activities.where((activity) {
                  final String title =
                      (activity['title'] as String? ?? '').toLowerCase();
                  final String category =
                      (activity['category'] as String? ?? 'Other');
                  final bool matchesSearch =
                      title.contains(_searchQuery.toLowerCase());
                  final bool matchesCategory = _selectedCategory == 'All' ||
                      category.toLowerCase() == _selectedCategory.toLowerCase();
                  
                  bool matchesCreator = true;
                  if (widget.creatorId != null) {
                    matchesCreator = (activity['createdBy'] == widget.creatorId);
                  }

                  return matchesSearch && matchesCategory && matchesCreator;
                }).toList();

                if (activities.isEmpty) {
                  return const Center(child: Text('No activities found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: activities.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _MinimalistActivityCard(activity: activities[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFFAFAFA),
      child: Column(
        children: <Widget>[
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Icon(Icons.search, color: Colors.grey[400], size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search activities',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final bool isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF6B9D) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFFF6B9D) : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
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
              }).toList(),
            ),
          ),
        ],
      ),
    );
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
