import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../certificates/certificates_screen.dart';
import '../profile/profile_screen.dart';
import 'activity_create_screen.dart';
import 'activity_detail_screen.dart';

/// Main shell for the post-authenticated experience with bottom navigation.
class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  int _currentIndex = 0;
  final FirestoreService firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final List<Widget> screens = <Widget>[
      ActivitiesHomeView(
        authService: authService,
        firestoreService: firestoreService,
      ),
      const CertificatesScreen(isEmbedded: true),
      const ProfileScreen(isEmbedded: true),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_mosaic_outlined),
            selectedIcon: Icon(Icons.auto_awesome_mosaic),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.workspace_premium_outlined),
            selectedIcon: Icon(Icons.workspace_premium),
            label: 'Certificates',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: _buildFloatingActionButton(authService),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget? _buildFloatingActionButton(AuthService authService) {
    if (_currentIndex != 0) {
      return null;
    }
    final String? userId = authService.user?.uid;
    if (userId == null) {
      return null;
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final Map<String, dynamic>? data = snapshot.data?.data();
        final String role = (data?['role'] as String?) ?? 'volunteer';
        if (role != 'organization') {
          return const SizedBox.shrink();
        }
        return FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const ActivityCreateScreen(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Create'),
        );
      },
    );
  }
}

/// Discover tab with hero header, stats, and curated activity cards.
class ActivitiesHomeView extends StatelessWidget {
  final AuthService authService;
  final FirestoreService firestoreService;

  const ActivitiesHomeView({
    super.key,
    required this.authService,
    required this.firestoreService,
  });

  @override
  Widget build(BuildContext context) {
    final String? userId = authService.user?.uid;
    return SafeArea(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: userId == null
            ? null
            : FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> userSnapshot) {
          final Map<String, dynamic>? userData = userSnapshot.data?.data();
          final String name = (userData?['name'] as String?) ?? 'Volunteer';
          final String role = (userData?['role'] as String?) ?? 'volunteer';
          final List<String> joinedActivities = List<String>.from(
            userData?['joinedActivities'] ?? <String>[],
          );

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestoreService.getActivities(),
            builder: (BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Something went wrong. Please try again.'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final List<Map<String, dynamic>> activities = snapshot.data ?? <Map<String, dynamic>>[];
              final List<String> categories = <String>[
                'Community',
                'Education',
                'Healthcare',
                'Environment',
                'Fundraising',
              ];

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildHeader(context, name),
                          const SizedBox(height: 16),
                          _buildHighlightCard(context, joinedActivities.length, role),
                          const SizedBox(height: 20),
                          _buildSearchField(context),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (BuildContext _, int index) {
                                final String label = categories[index];
                                return Chip(
                                  label: Text(label),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(width: 12),
                              itemCount: categories.length,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Upcoming Activities',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (activities.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (BuildContext context, int index) {
                            final Map<String, dynamic> activity = activities[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: ActivityCard(activity: activity),
                            );
                          },
                          childCount: activities.length,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Hello, $name',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Discover impactful activities near you',
                style: TextStyle(
                  color: Color(0xFF777777),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.favorite_rounded, color: Color(0xFFFF3D71)),
        ),
      ],
    );
  }

  Widget _buildHighlightCard(BuildContext context, int joinedCount, String role) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            role == 'organization' ? 'Organizer Dashboard' : 'Volunteer Journey',
            style: const TextStyle(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            role == 'organization'
                ? 'Create events that inspire communities'
                : 'You have joined $joinedCount activities',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return TextField(
      readOnly: true,
      decoration: InputDecoration(
        hintText: 'Search activities, causes...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.tune_rounded, color: Color(0xFFFF3D71)),
        ),
      ),
      onTap: () {},
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const <Widget>[
        Icon(Icons.search_off_rounded, size: 72, color: Color(0xFFB6B6B6)),
        SizedBox(height: 16),
        Text(
          'No activities available right now',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          'Please check back later or create one if you are an organizer.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF7A7A7A)),
        ),
      ],
    );
  }
}

/// High fidelity activity card inspired by the event-app reference.
class ActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const ActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final String posterUrl = (activity['posterUrl'] as String?) ?? '';
    final String title = (activity['title'] as String?) ?? 'Untitled Activity';
    final String location = (activity['location'] as String?) ?? 'No location';
    final String id = (activity['id'] as String?) ?? '';
    final String summary = (activity['description'] as String?) ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => ActivityDetailScreen(activity: activity),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              children: <Widget>[
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: posterUrl.isEmpty
                        ? Container(
                            color: const Color(0xFFFFEEF2),
                            child: const Icon(
                              Icons.image_outlined,
                              size: 64,
                              color: Color(0xFFFFB6C1),
                            ),
                          )
                        : Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFFFEEF2),
                              child: const Icon(
                                Icons.broken_image_outlined,
                                size: 64,
                                color: Color(0xFFFFB6C1),
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      id.isEmpty ? 'VOLUNTEER' : 'ID $id',
                      style: const TextStyle(
                        color: Color(0xFFFF3D71),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: Color(0xFFFF3D71)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF6D6D6D),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEEF2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFFFF3D71),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                        color: Color(0xFF444444),
                        fontWeight: FontWeight.w600,
                      ),
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
