import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

/// Displays the details of a selected activity with an event-app inspired layout.
class ActivityDetailScreen extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityDetailScreen({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final FirestoreService firestoreService = FirestoreService();
    final User? user = authService.user;
    final String posterUrl = (activity['posterUrl'] as String?) ?? '';
    final String title = (activity['title'] as String?) ?? 'Untitled Activity';
    final String location = (activity['location'] as String?) ?? 'No location';
    final String description = (activity['description'] as String?) ?? 'No description provided.';
    final String activityId = (activity['id'] as String?) ?? '';
    final String organization = (activity['organization'] as String?) ?? 'Community Organizer';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                        offset: const Offset(0, -30),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildInfoCard(
                            context: context,
                            title: title,
                            location: location,
                            organization: organization,
                            description: description,
                          ),
                        ),
                      ),
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
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 11,
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
                  Colors.black.withOpacity(0.05),
                  Colors.black.withOpacity(0.25),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 24,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                _buildCircleButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                _buildCircleButton(
                  icon: Icons.more_horiz,
                  onTap: () {},
                ),
              ],
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
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF424242)),
      ),
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required String title,
    required String location,
    required String organization,
    required String description,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 140),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 30,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'VOLUNTEER ACTIVITY',
              style: TextStyle(
                color: Color(0xFFFF6B9D),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(Icons.apartment_rounded, color: Color(0xFFFF6B9D)),
              const SizedBox(width: 6),
              Text(
                organization,
                style: const TextStyle(color: Color(0xFF777777)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.location_on_rounded, color: Color(0xFFFF6B9D)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Location',
                      style: TextStyle(color: Color(0xFF9A9A9A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: const <Widget>[
              _InfoPill(label: '3 hrs'),
              SizedBox(width: 12),
              _InfoPill(label: 'Open spots'),
              SizedBox(width: 12),
              _InfoPill(label: 'Community'),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'About Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
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
}

class _InfoPill extends StatelessWidget {
  final String label;

  const _InfoPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF505050),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _JoinBottomBar extends StatelessWidget {
  final FirestoreService firestoreService;
  final User? user;
  final String activityId;

  const _JoinBottomBar({
    required this.firestoreService,
    required this.user,
    required this.activityId,
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
                  return _buildButton(context, enabled: false, label: 'Organizers cannot join');
                }
                if (isJoined) {
                  return _buildButton(context, enabled: false, label: 'You already joined');
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
                      const SnackBar(
                        content: Text('Joined successfully! 🎉'),
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
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? const Color(0xFFFF6B9D) : const Color(0xFFF1F1F1),
          foregroundColor: enabled ? Colors.white : const Color(0xFF8C8C8C),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
