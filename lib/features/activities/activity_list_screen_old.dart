import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'activity_detail_screen.dart';
import 'activity_create_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ActivitiesHomeView(),
    const Center(child: Text('Search')), // Placeholder
    const Center(child: Text('Profile')), // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final String? userId = authService.user?.uid;

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: EngageBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 0) {
            setState(() => _currentIndex = 0);
          } else if (index == 1) {
            // Navigate to Search or Explore
             setState(() => _currentIndex = 1);
          } else if (index == 2) {
             // Navigate to Profile
             Navigator.pushNamed(context, '/profile');
          }
        },
      ),
      floatingActionButton: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userId != null
            ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots()
            : null,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.exists) {
            final role = snapshot.data!.data()?['role'];
            if (role == 'organization') {
              return FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ActivityCreateScreen()),
                  );
                },
                backgroundColor: const Color(0xFFFF6B9D),
                child: const Icon(Icons.add),
              );
            }
          }
          return const SizedBox.shrink();
        },
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
  String _selectedStatus = 'All';
  bool _showStatusFilter = false;

  late Stream<List<Map<String, dynamic>>> _activitiesStream;

  final List<String> _categories = ['All', 'Community', 'Education', 'Healthcare', 'Environment', 'Other'];
  final List<String> _activityStatuses = ['All', 'Upcoming', 'In Progress', 'Completed', 'Canceled'];

  @override
  void initState() {
    super.initState();
    _activitiesStream = _firestoreService.getActivities();
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final String? userId = authService.user?.uid;

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Hello,',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: userId != null
                            ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots()
                            : null,
                        builder: (context, snapshot) {
                          String name = 'Volunteer';
                          if (snapshot.hasData && snapshot.data!.exists) {
                            name = snapshot.data!.data()?['name'] ?? 'Volunteer';
                          }
                          return Text(
                            name,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: NetworkImage('https://i.pravatar.cc/150?img=12'), // Placeholder
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search activities...',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showStatusFilter = !_showStatusFilter;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _showStatusFilter ? const Color(0xFFFF6B9D) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: _showStatusFilter ? Colors.white : const Color(0xFFFF6B9D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status Filter (Collapsible)
          if (_showStatusFilter)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _activityStatuses.map((status) {
                      final bool isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedStatus = status),
                          selectedColor: const Color(0xFFFF6B9D),
                          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

          // Categories
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
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
                      margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFF6B9D) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected ? const Color(0xFFFF6B9D).withOpacity(0.3) : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF666666),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Popular Activities Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Popular Now',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF6B9D),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Popular Activities List
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _activitiesStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  // Sort by participants count
                  final activities = List<Map<String, dynamic>>.from(snapshot.data!);
                  activities.sort((a, b) {
                    final int countA = (a['participantsCount'] as int?) ?? 0;
                    final int countB = (b['participantsCount'] as int?) ?? 0;
                    return countB.compareTo(countA);
                  });
                  final popular = activities.take(5).toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    scrollDirection: Axis.horizontal,
                    itemCount: popular.length,
                    itemBuilder: (context, index) {
                      return PopularActivityCard(activity: popular[index]);
                    },
                  );
                },
              ),
            ),
          ),

          // Upcoming Activities Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: const Text(
                'Upcoming Activities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ),
          ),

          // Upcoming Activities List
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _activitiesStream,
            builder: (BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              if (snapshot.hasError) {
                return const SliverToBoxAdapter(child: Center(child: Text('Something went wrong. Please try again.')));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
              }

              List<Map<String, dynamic>> activities = snapshot.data ?? <Map<String, dynamic>>[];

              // Filter logic
              List<Map<String, dynamic>> filteredActivities = activities.where((activity) {
                final String title = (activity['title'] as String? ?? '').toLowerCase();
                final String category = (activity['category'] as String? ?? 'Other');
                
                // Handle startDate which might be Timestamp or String
                String startDateStr = '';
                if (activity['startDate'] is Timestamp) {
                  startDateStr = (activity['startDate'] as Timestamp).toDate().toIso8601String();
                } else if (activity['startDate'] is String) {
                  startDateStr = activity['startDate'] as String;
                }

                // Handle endDate which might be Timestamp or String
                String endDateStr = '';
                if (activity['endDate'] is Timestamp) {
                  endDateStr = (activity['endDate'] as Timestamp).toDate().toIso8601String();
                } else if (activity['endDate'] is String) {
                  endDateStr = activity['endDate'] as String;
                }
                
                // Status Logic
                String status = 'Upcoming'; // Default
                if (startDateStr.isNotEmpty && endDateStr.isNotEmpty) {
                  try {
                    final DateTime start = DateTime.parse(startDateStr);
                    final DateTime end = DateTime.parse(endDateStr);
                    final DateTime now = DateTime.now();
                    if (now.isBefore(start)) {
                      status = 'Upcoming';
                    } else if (now.isAfter(end)) {
                      status = 'Completed';
                    } else {
                      status = 'In Progress';
                    }
                  } catch (e) {
                    // Fallback if date parsing fails
                  }
                }

                final bool matchesSearch = title.contains(_searchQuery.toLowerCase());
                final bool matchesCategory = _selectedCategory == 'All' ||
                    category.toLowerCase() == _selectedCategory.toLowerCase();
                final bool matchesStatus = _selectedStatus == 'All' || status == _selectedStatus;

                return matchesSearch && matchesCategory && matchesStatus;
              }).toList();

              // Sort filtered activities by date (nearest first)
              filteredActivities.sort((a, b) {
                String dateAStr = '';
                if (a['startDate'] is Timestamp) {
                  dateAStr = (a['startDate'] as Timestamp).toDate().toIso8601String();
                } else if (a['startDate'] is String) {
                  dateAStr = a['startDate'] as String;
                }

                String dateBStr = '';
                if (b['startDate'] is Timestamp) {
                  dateBStr = (b['startDate'] as Timestamp).toDate().toIso8601String();
                } else if (b['startDate'] is String) {
                  dateBStr = b['startDate'] as String;
                }

                return dateAStr.compareTo(dateBStr);
              });

              if (filteredActivities.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text('No activities found matching your criteria.')),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      return MonthlyActivityCard(activity: filteredActivities[index]);
                    },
                    childCount: filteredActivities.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PopularActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const PopularActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final String posterUrl = (activity['posterUrl'] as String?) ?? '';
    final String title = (activity['title'] as String?) ?? 'Untitled';
    final String location = (activity['location'] as String?) ?? 'Unknown';
    final int participants = (activity['participantsCount'] as int?) ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ActivityDetailScreen(activity: activity)),
        );
      },
      child: Container(
        width: 260,
        height: 280,
        margin: const EdgeInsets.only(right: 20, bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SizedBox(
                height: 156,
                width: double.infinity,
                child: posterUrl.isEmpty
                    ? Container(
                        color: const Color(0xFFFFEEF2),
                        child: const Icon(Icons.image, color: Color(0xFFFFB6C1), size: 40),
                      )
                    : Image.network(
                        posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFFFEEF2),
                          child: const Icon(Icons.broken_image, color: Color(0xFFFFB6C1), size: 40),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D2D2D),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: <Widget>[
                            const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFFFF6B9D)),
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
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 14, color: Color(0xFFFF6B9D)),
                            const SizedBox(width: 4),
                            Text(
                              '$participants joined',
                              style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MonthlyActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const MonthlyActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final String posterUrl = (activity['posterUrl'] as String?) ?? '';
    final String title = (activity['title'] as String?) ?? 'Untitled';
    
    // Handle date display
    String dateDisplay = 'Upcoming';
    if (activity['startDate'] is Timestamp) {
      dateDisplay = DateFormat('MMM d, y').format((activity['startDate'] as Timestamp).toDate());
    } else if (activity['startDate'] is String) {
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 80,
                height: 80,
                child: posterUrl.isEmpty
                    ? Container(
                        color: const Color(0xFFFFEEF2),
                        child: const Icon(Icons.image, color: Color(0xFFFFB6C1)),
                      )
                    : Image.network(
                        posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFFFEEF2),
                          child: const Icon(Icons.broken_image, color: Color(0xFFFFB6C1)),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFFFF6B9D)),
                      const SizedBox(width: 6),
                      Text(
                        dateDisplay,
                        style: const TextStyle(
                          color: Color(0xFF888888),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFFF6B9D)),
            ),
          ],
        ),
      ),
    );
  }
}

class EngageBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const EngageBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.explore_rounded, 'Explore'),
              _buildNavItem(1, Icons.search_rounded, 'Search'),
              _buildNavItem(2, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFEEF2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF6B9D) : Colors.grey[400],
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFFF6B9D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
