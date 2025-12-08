import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import 'voucher_create_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = Provider.of<AuthService>(context);
    final String? userId = authService.user?.uid;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userId != null
          ? FirebaseFirestore.instance.collection('users').doc(userId).snapshots()
          : null,
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data();
        final int userPoints = userData?['points'] ?? 0;
        final String role = userData?['role'] ?? 'volunteer';
        final bool isAdmin = role == 'organization';

        if (isAdmin) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Reward Management'),
              centerTitle: true,
            ),
            body: _buildAdminVoucherList(),
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VoucherCreateScreen()),
                );
              },
              backgroundColor: const Color(0xFFFF6B9D),
              child: const Icon(Icons.add),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Rewards Marketplace'),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF6B9D),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF6B9D),
              tabs: const [
                Tab(text: 'Available Rewards'),
                Tab(text: 'My Rewards'),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Color(0xFFFF6B9D), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '$userPoints',
                      style: const TextStyle(
                        color: Color(0xFFFF6B9D),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildAvailableRewards(userId, userPoints),
              _buildMyRewards(userId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminVoucherList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getVouchers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No vouchers created yet.'));
        }

        final vouchers = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            final voucher = vouchers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: voucher['imageUrl'] != null && voucher['imageUrl'].isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          voucher['imageUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.card_giftcard),
                        ),
                      )
                    : const Icon(Icons.card_giftcard, color: Color(0xFFFF6B9D)),
                title: Text(voucher['title'] ?? 'Reward'),
                subtitle: Text('${voucher['cost']} pts'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Voucher'),
                        content: const Text('Are you sure you want to delete this voucher?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    
                    if (confirm == true) {
                      await _firestoreService.deleteVoucher(voucher['id']);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Voucher deleted')),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAvailableRewards(String? userId, int userPoints) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getVouchers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No rewards available yet.'));
        }

        final vouchers = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            final voucher = vouchers[index];
            final int cost = voucher['cost'] ?? 0;
            final bool canAfford = userPoints >= cost;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  if (voucher['imageUrl'] != null && voucher['imageUrl'].isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        voucher['imageUrl'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Icon(Icons.card_giftcard, size: 50, color: Colors.grey),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                voucher['title'] ?? 'Reward',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$cost pts',
                                style: const TextStyle(
                                  color: Color(0xFFF57C00),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          voucher['description'] ?? '',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: canAfford
                                ? () => _redeemVoucher(userId, voucher['id'], cost)
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B9D),
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              canAfford ? 'Redeem' : 'Not enough points',
                              style: TextStyle(color: canAfford ? Colors.white : Colors.grey[600]),
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
      },
    );
  }

  Widget _buildMyRewards(String? userId) {
    if (userId == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.getUserVouchers(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('You haven\'t redeemed any rewards yet.'));
        }

        final vouchers = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vouchers.length,
          itemBuilder: (context, index) {
            final voucher = vouchers[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEF2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.card_giftcard, color: Color(0xFFFF6B9D)),
                ),
                title: Text(
                  voucher['title'] ?? 'Reward',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(voucher['description'] ?? ''),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _redeemVoucher(String? userId, String voucherId, int cost) async {
    if (userId == null) return;
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Redemption'),
        content: Text('Are you sure you want to spend $cost points?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.redeemVoucher(userId, voucherId, cost);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reward redeemed successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
