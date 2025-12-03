import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final AuthService authService = Provider.of<AuthService>(context);
    final String? currentUserId = authService.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.getLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading leaderboard'));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No participants yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final String name = user['name'] ?? 'Unknown';
              final int points = user['points'] ?? 0;
              final String userId = user['id'];
              final bool isMe = userId == currentUserId;

              // Top 3 Styling
              Color? rankColor;
              IconData? rankIcon;
              if (index == 0) {
                rankColor = const Color(0xFFFFD700); // Gold
                rankIcon = Icons.emoji_events;
              } else if (index == 1) {
                rankColor = const Color(0xFFC0C0C0); // Silver
                rankIcon = Icons.emoji_events;
              } else if (index == 2) {
                rankColor = const Color(0xFFCD7F32); // Bronze
                rankIcon = Icons.emoji_events;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isMe ? const Color(0xFFFFEEF2) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isMe ? Border.all(color: const Color(0xFFFF6B9D), width: 1.5) : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: rankIcon != null
                        ? Icon(rankIcon, color: rankColor, size: 32)
                        : Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A9A9A),
                            ),
                          ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isMe ? const Color(0xFFFF6B9D) : Colors.black87,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$points pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF555555),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
