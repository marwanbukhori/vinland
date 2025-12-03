import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../services/auth_service.dart';
import '../../services/certificate_service.dart';

/// Responsive certificate gallery screen.
class CertificatesScreen extends StatelessWidget {
  final bool isEmbedded;

  const CertificatesScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final Widget content = CertificatesView(isEmbedded: isEmbedded);
    if (isEmbedded) {
      return content;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificates'),
      ),
      body: content,
    );
  }
}

class CertificatesView extends StatefulWidget {
  final bool isEmbedded;

  const CertificatesView({super.key, required this.isEmbedded});

  @override
  State<CertificatesView> createState() => _CertificatesViewState();
}

class _CertificatesViewState extends State<CertificatesView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final CertificateService certificateService = CertificateService();
    final String? userId = authService.user?.uid;

    if (userId == null) {
      return const Center(child: Text('Please sign in to view certificates.'));
    }

    return SafeArea(
      top: true,
      bottom: !widget.isEmbedded,
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
        builder: (BuildContext context,
            AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to fetch your certificates.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No records found.'));
          }
          final Map<String, dynamic> data = snapshot.data!.data() ?? <String, dynamic>{};
          final String userName = (data['name'] as String?) ?? 'Volunteer';
          // Reverse to show newest first (assuming appended)
          final List<String> joinedActivities = List<String>.from(
            data['joinedActivities'] ?? <String>[],
          ).reversed.toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Certificates',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Celebrate your impact and share your achievements.',
                        style: TextStyle(
                          color: Color(0xFF9698A9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSummaryCard(context, joinedActivities.length),
                      const SizedBox(height: 24),
                      // Search/Filter
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search certificates...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (joinedActivities.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final String activityId = joinedActivities[index];
                        return _CertificateCard(
                          activityId: activityId,
                          userName: userName,
                          certificateService: certificateService,
                          searchQuery: _searchQuery,
                        );
                      },
                      childCount: joinedActivities.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, int totalCertificates) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B9D), Color(0xFFFF9AC4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B9D).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Certificates Earned',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalCertificates',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const <Widget>[
        Icon(Icons.card_membership_outlined, size: 80, color: Color(0xFFC2C2C2)),
        SizedBox(height: 16),
        Text(
          'No certificates yet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text(
          'Complete an activity to unlock your first certificate.',
          style: TextStyle(color: Color(0xFF8B8B8B)),
        ),
      ],
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final String activityId;
  final String userName;
  final CertificateService certificateService;
  final String searchQuery;

  const _CertificateCard({
    required this.activityId,
    required this.userName,
    required this.certificateService,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('activities').doc(activityId).get(),
      builder: (BuildContext context,
          AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final Map<String, dynamic>? activity = snapshot.data!.data();
        if (activity == null) {
          return const SizedBox.shrink();
        }
        final String title = (activity['title'] as String?) ?? 'Activity';
        final String posterUrl = (activity['posterUrl'] as String?) ?? '';

        // Filter logic
        if (searchQuery.isNotEmpty && !title.toLowerCase().contains(searchQuery.toLowerCase())) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: posterUrl.isEmpty
                      ? Container(
                          color: const Color(0xFFFFEEF2),
                          child: const Icon(
                            Icons.image_outlined,
                            color: Color(0xFFFFB6C1),
                            size: 32,
                          ),
                        )
                      : Image.network(
                          posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFFFEEF2),
                            child: const Icon(
                              Icons.broken_image_outlined,
                              color: Color(0xFFFFB6C1),
                              size: 32,
                            ),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F1F1F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(
                        width: double.infinity,
                        height: 36,
                        child: ElevatedButton(
                          onPressed: () => _handleGenerate(context, title),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Icon(Icons.download_rounded, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleGenerate(BuildContext context, String activityTitle) async {
    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => const Center(child: CircularProgressIndicator()),
      );
      final File certificateFile = await certificateService.generateCertificate(
        userName: userName,
        activityTitle: activityTitle,
        completionDate: DateTime.now(),
      );
      if (!context.mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Certificate saved to ${certificateFile.path}'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => Share.shareXFiles(<XFile>[XFile(certificateFile.path)]),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate certificate: $error')),
      );
    }
  }
}
