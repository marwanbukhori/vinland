import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../rewards/rewards_screen.dart';
import '../activities/admin_dashboard.dart';
import 'edit_profile_screen.dart';
import '../certificates/certificates_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool isEmbedded;

  const ProfileScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final Widget content = ProfileView(isEmbedded: isEmbedded);
    if (isEmbedded) {
      return content;
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF1A1A1A)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: content,
    );
  }
}

class ProfileView extends StatefulWidget {
  final bool isEmbedded;

  const ProfileView({super.key, required this.isEmbedded});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final String? userId = authService.user?.uid;
    if (userId == null) {
      return const Center(child: Text('Please sign in to view your profile.'));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Unable to load profile.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Profile not found.'));
        }

        final Map<String, dynamic> data = snapshot.data!.data() ?? <String, dynamic>{};
        final String name = (data['name'] as String?) ?? 'Volunteer';
        final String email = (data['email'] as String?) ?? 'No Email';
        final String role = (data['role'] as String?) ?? 'volunteer';
        final int points = (data['points'] as int?) ?? 0;
        final List<String> joinedActivities = List<String>.from(
          data['joinedActivities'] ?? <String>[],
        );
        final bool isOrganizer = role == 'organization';

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: <Widget>[
                    _buildHeroCard(context, name, email, role),
                    const SizedBox(height: 20),
                    
                    // Stats Row
                    if (isOrganizer)
                      _buildOrganizerStats(context, userId)
                    else
                      _buildUserStats(context, points, joinedActivities.length),
                    
                    const SizedBox(height: 20),
                    
                    // Action Buttons
                    if (!isOrganizer) _buildUserActionButtons(context),
                    // if (isOrganizer) _buildOrganizerActionButtons(context),
                    
                    const SizedBox(height: 28),
                    
                    // Section Header
                    // _buildSectionHeader(
                    //   isOrganizer ? 'My Organized Activities' : 'My Activities',
                    //   'Sorted by nearest date'
                    // ),
                    // const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            
            // Activity List
            // FutureBuilder<List<Map<String, dynamic>>>(
            //   future: _fetchAndSortActivities(joinedActivities, isOrganizer, userId),
            //   builder: (context, activitySnapshot) {
            //     if (activitySnapshot.connectionState == ConnectionState.waiting) {
            //       return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
            //     }
                
            //     final activities = activitySnapshot.data ?? [];

            //     if (activities.isEmpty) {
            //       return SliverToBoxAdapter(
            //         child: Padding(
            //           padding: const EdgeInsets.only(bottom: 120),
            //           child: _buildEmptyJourney(isOrganizer),
            //         ),
            //       );
            //     }

            //     return SliverPadding(
            //       padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            //       sliver: SliverList(
            //         delegate: SliverChildBuilderDelegate(
            //           (BuildContext context, int index) {
            //             final activity = activities[index];
            //             return Padding(
            //               padding: const EdgeInsets.only(bottom: 16),
            //               child: _ActivityTile(activity: activity),
            //             );
            //           },
            //           childCount: activities.length,
            //         ),
            //       ),
            //     );
            //   },
            // ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context, authService),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B9D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAndSortActivities(List<String> ids, bool isOrganizer, String userId) async {
    if (isOrganizer) {
      // Fetch activities created by this org
      final snapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('organizationId', isEqualTo: userId)
          .get();
      final activities = snapshot.docs.map((d) => d.data()).toList();
      _sortActivities(activities);
      return activities;
    } else {
      if (ids.isEmpty) return [];
      final List<Map<String, dynamic>> activities = [];
      // Batch fetch limited to 10 usually, but for now loop is safer for small numbers
      for (String id in ids) {
        final doc = await FirebaseFirestore.instance.collection('activities').doc(id).get();
        if (doc.exists && doc.data() != null) {
          activities.add(doc.data()!);
        }
      }
      _sortActivities(activities);
      return activities;
    }
  }

  void _sortActivities(List<Map<String, dynamic>> activities) {
    activities.sort((a, b) {
      final String dateA = (a['startDate'] as String?) ?? '';
      final String dateB = (b['startDate'] as String?) ?? '';
      if (dateA.isEmpty) return 1;
      if (dateB.isEmpty) return -1;
      return dateA.compareTo(dateB);
    });
  }

  Widget _buildHeroCard(BuildContext context, String name, String email, String role) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFFFFEEF2),
                child: Text(
                  name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFFF6B9D),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFFF6B9D),
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats(BuildContext context, int points, int activities) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _StatCard(
            title: 'Points',
            value: points.toString(),
            icon: Icons.stars_rounded,
            color: const Color(0xFFFF6B9D),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Activities',
            value: activities.toString(),
            icon: Icons.volunteer_activism,
            color: const Color(0xFF8A8DFF),
          ),
        ),
      ],
    );
  }

  Widget _buildOrganizerStats(BuildContext context, String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('activities').where('organizationId', isEqualTo: userId).snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }
        return Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                title: 'Organized',
                value: count.toString(),
                icon: Icons.event_available_rounded,
                color: const Color(0xFFFF6B9D),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                title: 'Rating',
                value: '4.8', // Mock
                icon: Icons.star_rounded,
                color: const Color(0xFFFFC107),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Leaderboard',
            icon: Icons.leaderboard_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            label: 'Certificates',
            icon: Icons.workspace_premium_rounded,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CertificatesScreen()),
              );
            },
          ),
        ),
      ],
    );
  }


  // Widget _buildOrganizerActionButtons(BuildContext context) {
  //   return SizedBox(
  //     width: double.infinity,
  //     child: _ActionButton(
  //       label: 'Go to Dashboard',
  //       icon: Icons.dashboard_rounded,
  //       onTap: () {
  //         // Assuming ActivityListScreen handles navigation, but we can push directly
  //         // Or switch tab. For now, pushing Dashboard is fine.
  //         Navigator.push(
  //           context,
  //           MaterialPageRoute(builder: (context) => const AdminDashboard()),
  //         );
  //       },
  //     ),
  //   );
  // }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyJourney(bool isOrganizer) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.event_busy_rounded, size: 60, color: Color(0xFFD0D0D0)),
        const SizedBox(height: 16),
        Text(
          'No activities found',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF666666)),
        ),
        const SizedBox(height: 8),
        Text(
          isOrganizer ? 'Create your first activity!' : 'Join an activity to see it here!',
          style: const TextStyle(color: Color(0xFF999999)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _handleLogout(BuildContext context, AuthService authService) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B9D)),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await authService.signOut();
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  title,
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEEEEEE)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFFF6B9D)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final String title = (activity['title'] as String?) ?? 'Untitled';
    final String location = (activity['location'] as String?) ?? 'Unknown location';
    final String startDateStr = (activity['startDate'] as String?) ?? '';
    
    String status = 'Upcoming';
    Color statusColor = Colors.blue;
    if (startDateStr.isNotEmpty) {
      try {
        final DateTime start = DateTime.parse(startDateStr);
        final DateTime end = DateTime.parse((activity['endDate'] as String?) ?? startDateStr);
        final DateTime now = DateTime.now();
        if (now.isAfter(end)) {
          status = 'Completed';
          statusColor = const Color(0xFF1BA975);
        } else if (now.isAfter(start)) {
          status = 'In Progress';
          statusColor = Colors.orange;
        }
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_note_rounded, color: Color(0xFFFF6B9D)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    const Icon(Icons.place_outlined, size: 14, color: Color(0xFF888888)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
