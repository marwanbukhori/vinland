import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../profile/profile_screen.dart';
import '../certificates/certificates_screen.dart';
import '../rewards/rewards_screen.dart';
import 'activity_detail_screen.dart';
import 'activity_create_screen.dart';
import 'all_activities_screen.dart';
import 'my_activities_screen.dart';
import 'admin_dashboard.dart';
import '../ranking/ranking_screen.dart';
import 'scan_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final String? userId = authService.user?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userId != null
          ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots()
          : null,
      builder: (context, snapshot) {
        final String role = snapshot.data?.data()?['role'] ?? 'volunteer';
        final bool isOrganization = role == 'organization';

        final List<Widget> screens;
        if (isOrganization) {
           screens = [
             const AdminDashboard(),
             const RewardsScreen(),
             const ProfileScreen(),
           ];
        } else {
           screens = [
             const ActivitiesHomeView(),
             MyActivitiesView(userId: userId),
             const RewardsScreen(),
             const ProfileScreen(),
           ];
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex < screens.length ? _currentIndex : 0,
            children: screens,
          ),
          bottomNavigationBar: _buildBottomNav(isOrganization),
          floatingActionButton: isOrganization && _currentIndex == 0 // Dashboard is 0 for Admin
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ActivityCreateScreen()),
                    );
                  },
                  backgroundColor: const Color(0xFFFF6B9D),
                  heroTag: 'admin_create_activity_fab',
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }

  Widget _buildBottomNav(bool isOrganization) {
    List<Widget> navItems;

    if (isOrganization) {
      navItems = [
        _buildNavItem(0, Icons.dashboard_rounded, 'Dashboard'),
        _buildNavItem(1, Icons.card_giftcard_rounded, 'Rewards'),
        _buildNavItem(2, Icons.person_rounded, 'Profile'),
      ];
    } else {
      navItems = [
        _buildNavItem(0, Icons.explore_rounded, 'Explore'),
        _buildNavItem(1, Icons.event_note_rounded, 'My Events'),
        _buildNavItem(2, Icons.card_giftcard_rounded, 'Rewards'),
        _buildNavItem(3, Icons.person_rounded, 'Profile'),
      ];
    }

    return Container(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEEF2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF6B9D) : Colors.grey[400],
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFFF6B9D),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class ActivitiesHomeView extends StatefulWidget {
  const ActivitiesHomeView({super.key});

  @override
  State<ActivitiesHomeView> createState() => _ActivitiesHomeViewState();
}

class _ActivitiesHomeViewState extends State<ActivitiesHomeView> {
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  final List<String> _categories = ['All', 'Community', 'Education', 'Healthcare', 'Environment', 'Other'];

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final String? userId = authService.user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Light grey background
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            _buildHeader(userId),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    _buildSearchBar(),
                    
                    // Categories
                    _buildCategories(),
                    
                    // Popular/Featured Section
                    _buildSectionHeader('Popular Events', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllActivitiesScreen()),
                      );
                    }),
                    _buildPopularEvents(),
                    
                    // All Activities Section
                    _buildSectionHeader('Upcoming Events', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllActivitiesScreen()),
                      );
                    }),
                    _buildUpcomingEvents(),
                    
                    const SizedBox(height: 80), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String? userId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: userId != null ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots() : null,
      builder: (context, snapshot) {
        final String userName = snapshot.data?.get('name') ?? 'Volunteer';
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back,',
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hi, $userName',
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Notification
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Notifications',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 20, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            const Icon(Icons.notifications_none_rounded, size: 64, color: Color(0xFFE0E0E0)),
                            const SizedBox(height: 16),
                            const Text(
                              'No new notifications',
                              style: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'We\'ll let you know when there are updates.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 14),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded, size: 24, color: Color(0xFF1A1A1A)),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B9D),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search events...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: const Color(0xFFFF6B9D), size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showQRScannerDialog(context),
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Icon(Icons.qr_code_scanner_rounded, color: const Color(0xFFFF6B9D), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B9D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF6B9D) : const Color(0xFFFF6B9D).withOpacity(0.1), // Pink tint for unselected
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFFF6B9D),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              children: const [
                Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888888),
                  ),
                ),
                Icon(Icons.arrow_right_rounded, size: 18, color: Color(0xFF888888)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularEvents() {
    return SizedBox(
      height: 260,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getActivities(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final activities = snapshot.data!;
          // Filter logic
          final filtered = activities.where((a) {
             final matchesSearch = (a['title'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
             final matchesCategory = _selectedCategory == 'All' || (a['category'] as String? ?? '') == _selectedCategory;
             return matchesSearch && matchesCategory;
          }).toList();

          if (filtered.isEmpty) return const Center(child: Text('No events found'));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              return _PopularEventCard(activity: filtered[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getActivities(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        
        final activities = snapshot.data!;
        // Filter logic (same as above)
        final filtered = activities.where((a) {
             final matchesSearch = (a['title'] as String? ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
             final matchesCategory = _selectedCategory == 'All' || (a['category'] as String? ?? '') == _selectedCategory;
             return matchesSearch && matchesCategory;
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _UpcomingEventCard(activity: filtered[index]);
          },
        );
      },
    );
  }

  void _showQRScannerDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan QR Code'),
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
                       _handleScanSubmit(context, result);
                     }
                  }
                },
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white, size: 48),
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
            ),
            const SizedBox(height: 16),
            const Text('Or enter code manually:'),
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
              if (code.isNotEmpty) {
                Navigator.pop(context);
                // Fetch activity and navigate
                final activity = await _firestoreService.getActivity(code);
                if (activity != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ActivityDetailScreen(activity: activity)),
                  );
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Activity not found')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B9D),
            ),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScanSubmit(BuildContext context, String code) async {
     if (code.isNotEmpty) {
        Navigator.pop(context); // Close dialog
        // Fetch activity and navigate
        try {
          final activity = await _firestoreService.getActivity(code);
          if (activity != null && context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ActivityDetailScreen(activity: activity)),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Activity not found')),
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
  }

}

class _PopularEventCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _PopularEventCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final String posterUrl = (activity['posterUrl'] as String?) ?? '';
    final String title = (activity['title'] as String?) ?? 'Untitled';
    final String location = (activity['location'] as String?) ?? 'Unknown';
    final int participants = (activity['participantsCount'] as int?) ?? 0;

    // Date & Status Logic
    DateTime? startDate;
    DateTime? endDate;
    String status = 'Upcoming';
    Color statusColor = const Color(0xFF2196F3); // Blue
    Color statusBg = const Color(0xFFE3F2FD);

    if (activity['startDate'] != null) {
       if (activity['startDate'] is Timestamp) {
         startDate = (activity['startDate'] as Timestamp).toDate();
       } else {
         startDate = DateTime.tryParse(activity['startDate'].toString());
       }
    }
    if (activity['endDate'] != null) {
       if (activity['endDate'] is Timestamp) {
         endDate = (activity['endDate'] as Timestamp).toDate();
       } else {
         endDate = DateTime.tryParse(activity['endDate'].toString());
       }
    }

    if (startDate != null) {
      final now = DateTime.now();
      if (endDate != null && now.isAfter(endDate!)) {
        status = 'Completed';
        statusColor = const Color(0xFF4CAF50); // Green
        statusBg = const Color(0xFFE8F5E9);
      } else if (now.isAfter(startDate!) && (endDate == null || now.isBefore(endDate!))) {
        status = 'In Progress';
        statusColor = const Color(0xFFFF9800); // Orange
        statusBg = const Color(0xFFFFF3E0);
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ActivityDetailScreen(activity: activity)),
        );
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 16, bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Padding(
              padding: const EdgeInsets.all(10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 140,
                      width: double.infinity,
                      child: posterUrl.isNotEmpty
                          ? Image.network(
                              posterUrl, 
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey));
                              },
                            )
                          : Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 16, color: Color(0xFFFF6B9D)),
                      const SizedBox(width: 4),
                      Text(
                        '$participants Going',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _UpcomingEventCard({required this.activity});

  @override
  Widget build(BuildContext context) {
    final String posterUrl = (activity['posterUrl'] as String?) ?? '';
    final String title = (activity['title'] as String?) ?? 'Untitled';
    final String location = (activity['location'] as String?) ?? 'Unknown';
    
    // Date formatting
    String month = 'TBA';
    String day = '--';
    String time = '';
    
    if (activity['startDate'] != null) {
       try {
         DateTime date;
         if (activity['startDate'] is Timestamp) {
           date = (activity['startDate'] as Timestamp).toDate();
         } else {
           date = DateTime.parse(activity['startDate']);
         }
         month = DateFormat('MMM').format(date).toUpperCase();
         day = DateFormat('d').format(date);
         time = DateFormat('h:mm a').format(date);
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 90,
                height: 90,
                child: posterUrl.isNotEmpty
                    ? Image.network(
                        posterUrl, 
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey));
                        },
                      )
                    : Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (time.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFFFF6B9D)),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            // Date Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B9D),
                    ),
                  ),
                  Text(
                    month,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF6B9D),
                    ),
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
