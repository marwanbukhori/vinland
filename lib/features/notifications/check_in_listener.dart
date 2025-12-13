import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/firestore_service.dart';

class CheckInListener extends StatefulWidget {
  final Widget child;

  const CheckInListener({super.key, required this.child});

  @override
  State<CheckInListener> createState() => _CheckInListenerState();
}

class _CheckInListenerState extends State<CheckInListener> {
  Set<String> _checkedInIds = {};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    if (user == null) {
      _checkedInIds.clear();
      _initialized = false;
      return widget.child;
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('registrations')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return widget.child;

        final docs = snapshot.data!.docs;
        final currentCheckedInIds = <String>{};
        
        for (var doc in docs) {
           final data = doc.data() as Map<String, dynamic>;
           if (data['status'] == 'checked-in') {
             currentCheckedInIds.add(doc.id);
             
             // Check if this is a NEW check-in
             if (_initialized && !_checkedInIds.contains(doc.id)) {
               // Notify!
               final activityTitle = data['activityTitle'] ?? 'Activity';
               final title = 'You are Checked In! ✅';
               final body = 'Welcome to $activityTitle. +50 Points earned.';
               
               NotificationService().showNotification(
                 id: doc.id.hashCode, 
                 title: title, 
                 body: body,
               );
               
               // Save to History
               FirestoreService().saveNotification(
                 userId: user.uid, 
                 title: title, 
                 body: body, 
                 type: 'check-in'
               );
             }
           }
        }

        _checkedInIds = currentCheckedInIds;
        _initialized = true;

        return widget.child;
      },
    );
  }
}
