import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Displays the details of a selected activity and allows eligible users to join.
class ActivityDetailScreen extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailScreen({super.key, required this.activity});

  /// Builds the activity detail UI with join controls.
  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final FirestoreService firestoreService = FirestoreService();
    final User? user = authService.user;
    final String posterUrl = (activity['posterUrl'] as String?) ?? '';
    final String activityId = (activity['id'] as String?) ?? '';
    final String title = (activity['title'] as String?) ?? 'Untitled Activity';
    final String location = (activity['location'] as String?) ?? 'No location';
    final String description = (activity['description'] as String?) ?? 'No description provided.';

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  posterUrl.isNotEmpty
                      ? Image.network(
                          posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: const Color(0xFFFFEEF2),
                            child: const Icon(Icons.image_not_supported_outlined,
                                color: Color(0xFFFFB6C1), size: 60),
                          ),
                        )
                      : Container(
                          color: const Color(0xFFFFEEF2),
                          child: const Icon(Icons.volunteer_activism,
                              color: Color(0xFFFFB6C1), size: 80),
                        ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black45,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'VOLUNTEER ACTIVITY',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(color: Colors.white70),
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
            leading: Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFFF3D71)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(location),
                  const SizedBox(height: 24),
                  _buildHighlights(context),
                  const SizedBox(height: 28),
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F1F1F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5C5C5C),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildImpactCard(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 56,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final Map<String, dynamic>? userData = snapshot.data?.data();
              if (userData == null) {
                return const SizedBox(
                  height: 64,
                  child: Center(child: Text('User data unavailable')),
                );
              }
              final String role = (userData['role'] as String?) ?? 'volunteer';
              final List<String> joinedActivities = List<String>.from(
                userData['joinedActivities'] ?? <String>[],
              );
              final bool isJoined = activityId.isNotEmpty && joinedActivities.contains(activityId);
              final bool isOrganizer = role == 'organization';

              return Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (isOrganizer || isJoined || activityId.isEmpty)
                          ? null
                          : () async {
                              if (user == null) {
                                return;
                              }
                              await firestoreService.joinActivity(user.uid, activityId);
                              if (!context.mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Joined successfully! 🎉'),
                                ),
                              );
                            },
                      icon: Icon(isJoined ? Icons.check_circle : Icons.favorite_outline),
                      label: Text(
                        isOrganizer
                            ? 'Organizers Cannot Join'
                            : isJoined
                                ? 'Joined'
                                : 'Join Activity',
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String location) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEEF2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.location_on_outlined, color: Color(0xFFFF3D71)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location',
                style: TextStyle(
                  color: Color(0xFF8E8E8E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                location,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHighlights(BuildContext context) {
    final List<Map<String, String>> highlights = [
      {
        'title': 'Impact Hours',
        'value': '4h',
      },
      {
        'title': 'Volunteers',
        'value': '25 slots',
      },
      {
        'title': 'Difficulty',
        'value': 'Easy',
      },
    ];
    return Row(
      children: highlights
          .map(
            (Map<String, String> item) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: item == highlights.last ? 0 : 12),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      item['value'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['title'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF8E8E8E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildImpactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Why this matters',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Support local organizations and help create meaningful change for the community.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
