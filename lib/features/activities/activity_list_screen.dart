import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../certificates/certificates_screen.dart';
import '../profile/profile_screen.dart';
import 'activity_create_screen.dart';
import 'activity_detail_screen.dart';

const List<String> _activityCategories = <String>[
  'Community',
  'Education',
  'Healthcare',
  'Environment',
  'Fundraising',
];

/// Main shell for the authenticated user experience with custom navigation.
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: EngageBottomNav(
        currentIndex: _currentIndex,
        onSelected: (int index) => setState(() => _currentIndex = index),
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

/// Rounded navigation inspired by the reference event application.
class EngageBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const EngageBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<_NavItemConfig> items = <_NavItemConfig>[
      const _NavItemConfig(
        icon: Icons.auto_awesome_mosaic_outlined,
        activeIcon: Icons.auto_awesome_mosaic,
        label: 'Discover',
      ),
      const _NavItemConfig(
        icon: Icons.workspace_premium_outlined,
        activeIcon: Icons.workspace_premium,
        label: 'Certificates',
      ),
      const _NavItemConfig(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: List<Widget>.generate(
              items.length,
              (int index) => _NavButton(
                config: items[index],
                isActive: currentIndex == index,
                onTap: () => onSelected(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemConfig {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemConfig({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavButton extends StatelessWidget {
  final _NavItemConfig config;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.config,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                isActive ? config.activeIcon : config.icon,
                color: isActive ? theme.colorScheme.primary : const Color(0xFF9A9A9A),
              ),
              const SizedBox(height: 4),
              Text(
                config.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? theme.colorScheme.primary : const Color(0xFF9A9A9A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Discover tab with hero header and curated lists inspired by the reference design.
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
              final List<Map<String, dynamic>> popularActivities =
                  activities.take(5).toList();
              final List<Map<String, dynamic>> monthActivities =
                  activities.length > 5 ? activities.skip(5).toList() : activities;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _buildHeader(context, name),
                          const SizedBox(height: 18),
                          _buildHighlightCard(context, joinedActivities.length, role),
                          const SizedBox(height: 24),
                          _buildSearchField(context),
                          const SizedBox(height: 18),
                          _buildCategories(),
                          const SizedBox(height: 28),
                          _buildSectionHeader(context, 'Popular Activities'),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 300,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(left: 24, right: 12),
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: popularActivities.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: PopularActivityCard(activity: popularActivities[index]),
                          );
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: _buildSectionHeader(context, 'This Month'),
                    ),
                  ),
                  if (monthActivities.isEmpty)
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
                            final Map<String, dynamic> activity = monthActivities[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: MonthlyActivityCard(activity: activity),
                            );
                          },
                          childCount: monthActivities.length,
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
                'Current Location',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF9A9A9A),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Hello, $name 👋',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Discover impactful activities around you.',
                style: TextStyle(color: Color(0xFF8C8C8C)),
              ),
            ],
          ),
        ),
        Container(
          height: 52,
          width: 52,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite, color: Color(0xFFFF6B9D)),
        ),
      ],
    );
  }

  Widget _buildHighlightCard(BuildContext context, int joinedCount, String role) {
    final bool isOrganizer = role == 'organization';
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            isOrganizer ? 'Organizer Dashboard' : 'Volunteer Journey',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            isOrganizer
                ? 'Create events that inspire the community.'
                : 'You have joined $joinedCount meaningful activities.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const <Widget>[
              _HighlightBadge(label: 'Impact'),
              _HighlightBadge(label: 'Community'),
              _HighlightBadge(label: 'Growth'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
      decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          hintText: 'Search activities...',
          border: InputBorder.none,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.tune_rounded, color: Color(0xFFFF6B9D)),
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 24),
        itemBuilder: (BuildContext context, int index) {
          final String label = _activityCategories[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFFF6B9D),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: _activityCategories.length,
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const Text(
          'View all',
          style: TextStyle(color: Color(0xFF9A9A9A)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const <Widget>[
        Icon(Icons.sentiment_dissatisfied, size: 72, color: Color(0xFFC8C8C8)),
        SizedBox(height: 16),
        Text(
          'No activities yet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          'Please check back later or create one if you are an organizer.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF8E8E8E)),
        ),
      ],
    );
  }
}

class _HighlightBadge extends StatelessWidget {
  final String label;

  const _HighlightBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Horizontal card representing highlighted activities.
class PopularActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const PopularActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final String posterUrl = (activity['posterUrl'] as String?) ?? '';
    final String title = (activity['title'] as String?) ?? 'Untitled';
    final String location = (activity['location'] as String?) ?? 'No location';
    final String category = (activity['category'] as String?) ?? 'Volunteer';
    final String summary = (activity['description'] as String?) ?? '';

    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      child: Container(
        width: 260,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  child: AspectRatio(
                aspectRatio: 16 / 10,
                    child: posterUrl.isEmpty
                        ? Container(
                            color: const Color(0xFFFFEEF2),
                        child: const Icon(Icons.image_not_supported, color: Color(0xFFFFB6C1), size: 48),
                          )
                        : Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFFFEEF2),
                          child: const Icon(Icons.broken_image_outlined, color: Color(0xFFFFB6C1), size: 48),
                        ),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEEF2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              category.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFFFF6B9D),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                        const SizedBox(width: 4),
                        const Icon(Icons.favorite_border, color: Color(0xFFFF6B9D), size: 16),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                    child: Text(
                        title,
                      style: const TextStyle(
                          fontSize: 15,
                        fontWeight: FontWeight.w600,
                          color: Color(0xFF1F1F1F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Flexible(
                      child: Text(
                        summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8E8E8E),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                children: <Widget>[
                        const Icon(Icons.location_pin, size: 14, color: Color(0xFFFF6B9D)),
                        const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                            location,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A4A4A),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ActivityDetailScreen(activity: activity),
      ),
    );
  }
}

/// Vertical card for activities scheduled this month.
class MonthlyActivityCard extends StatelessWidget {
  final Map<String, dynamic> activity;

  const MonthlyActivityCard({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final String posterUrl = (activity['posterUrl'] as String?) ?? '';
    final String title = (activity['title'] as String?) ?? 'Untitled';
    final String location = (activity['location'] as String?) ?? 'No location';
    final String summary = (activity['description'] as String?) ?? 'Tap to read more.';

    return GestureDetector(
      onTap: () => _navigateToDetail(context),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 90,
                height: 90,
                child: posterUrl.isEmpty
                    ? Container(
                        color: const Color(0xFFFFEEF2),
                        child: const Icon(Icons.image_not_supported, color: Color(0xFFFFB6C1)),
                      )
                    : Image.network(
                        posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFFFEEF2),
                          child: const Icon(Icons.broken_image_outlined, color: Color(0xFFFFB6C1)),
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF7C7C7C)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      const Icon(Icons.place_outlined, size: 18, color: Color(0xFFFF6B9D)),
                      const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                            color: Color(0xFF4A4A4A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFB0B0B0)),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ActivityDetailScreen(activity: activity),
      ),
    );
  }
}
