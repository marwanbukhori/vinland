import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'activity_create_screen.dart';
import 'activity_edit_screen.dart';
import 'activity_detail_screen.dart';
import 'all_activities_screen.dart';
import 'scan_screen.dart';
import '../rewards/rewards_screen.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Organization Dashboard',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF1A1A1A)),
            onPressed: () {},
          ),
          // IconButton(
          //   icon: const Icon(Icons.logout_rounded, color: Color(0xFFC62828)),
          //   onPressed: () async {
          //     await AuthService().signOut();
          //   },
          // ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            _buildStatsGrid(),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Create Activity',
                    Icons.add_circle_outline_rounded,
                    const Color(0xFFFF6B9D),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ActivityCreateScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Manage Vouchers',
                    Icons.card_giftcard_rounded,
                    const Color(0xFF6B9DFF),
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RewardsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context,
                    'Scan Attendee',
                    Icons.qr_code_scanner_rounded,
                    const Color(0xFF4CAF50),
                    () async {
                       // Generic Scan
                       final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => QRScannerScreen()),
                        );
                        if (result != null && result is String && context.mounted) {
                           final firestore = FirestoreService();
                           // Check pending registrations
                           try {
                             final pending = await firestore.getActiveRegistrationsForUser(result);
                             if (context.mounted) {
                               if (pending.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No pending check-ins found for this user.')),
                                  );
                               } else if (pending.length == 1) {
                                  // Auto confirm
                                  final reg = pending.first;
                                  final bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Confirm Check-in'),
                                      content: Text('Check in user to ${reg['activityTitle']}?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Check In')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && context.mounted) {
                                     await firestore.checkInUser(reg['id']);
                                     ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Checked in successfully!')),
                                     );
                                  }
                               } else {
                                 // Pick one
                                 showDialog(
                                   context: context,
                                   builder: (context) => AlertDialog(
                                     title: const Text('Select Activity'),
                                     content: SizedBox(
                                       width: double.maxFinite,
                                       child: ListView.builder(
                                         shrinkWrap: true,
                                         itemCount: pending.length,
                                         itemBuilder: (context, index) {
                                           final reg = pending[index];
                                           return ListTile(
                                             title: Text(reg['activityTitle']),
                                             onTap: () async {
                                               Navigator.pop(context);
                                               await firestore.checkInUser(reg['id']);
                                               if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Checked in successfully!')),
                                                  );
                                               }
                                             },
                                           );
                                         },
                                       ),
                                     ),
                                   ),
                                 );
                               }
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
                  ),
                ),
                const SizedBox(width: 16),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 24),

            // Recent Activities
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Your Activities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AllActivitiesScreen(creatorId: user.uid)),
                      );
                    }
                  },
                  child: const Text('See All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRecentActivities(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Please log in'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activities')
          .where('createdBy', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        int totalActivities = 0;
        int totalParticipants = 0;
        int activeNow = 0;
        int totalHours = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalActivities = docs.length;
          final now = DateTime.now();
          
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final int parts = (data['participantsCount'] as int? ?? 0);
            totalParticipants += parts;
            
            // Calc Active
            DateTime? start;
            DateTime? end;
            if (data['startDate'] is Timestamp) start = (data['startDate'] as Timestamp).toDate();
            if (data['endDate'] is Timestamp) end = (data['endDate'] as Timestamp).toDate();
            
            if (start != null && end != null) {
               if (now.isAfter(start) && now.isBefore(end)) {
                 activeNow++;
               }
               // Calc Hours (Potential hours served by all participants)
               final hours = end.difference(start).inHours;
               if (hours > 0) {
                 totalHours += hours * parts;
               }
            }
          }
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard('Total Activities', '$totalActivities', Icons.event_note_rounded, const Color(0xFFFFE5EE), const Color(0xFFFF6B9D)),
            _buildStatCard('Total Volunteers', '$totalParticipants', Icons.people_outline_rounded, const Color(0xFFE5EEFF), const Color(0xFF6B9DFF)),
            _buildStatCard('Est. Hours Served', '$totalHours', Icons.access_time_rounded, const Color(0xFFE5FFEA), const Color(0xFF4CAF50)),
            // _buildStatCard('Avg. Rating', 'N/A', Icons.star_outline_rounded, const Color(0xFFFFF8E5), const Color(0xFFFFC107)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activities')
          .where('createdBy', isEqualTo: user.uid)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index].data() as Map<String, dynamic>;
            activity['id'] = activities[index].id;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: activity['posterUrl'] != null && (activity['posterUrl'] as String).isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(activity['posterUrl']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: activity['posterUrl'] == null || (activity['posterUrl'] as String).isEmpty
                      ? const Icon(Icons.event, color: Colors.grey)
                      : null,
                ),
                title: Text(
                  activity['title'] ?? 'Untitled',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${activity['participantsCount'] ?? 0} Participants',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF666666)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ActivityEditScreen(activity: activity)),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Activity?'),
                            content: const Text('This cannot be undone.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await FirestoreService().deleteActivity(activity['id']);
                        }
                      },
                    ),
                  ],
                ),
                onTap: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ActivityDetailScreen(activity: activity)),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
