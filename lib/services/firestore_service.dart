import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get stream of activities
  Stream<List<Map<String, dynamic>>> getActivities() {
    return _db.collection('activities').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // Get single activity
  Future<Map<String, dynamic>?> getActivity(String id) async {
    DocumentSnapshot doc = await _db.collection('activities').doc(id).get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }
    return null;
  }

  // Add activity (Organization only)
  Future<void> addActivity(Map<String, dynamic> activityData) async {
    await _db.collection('activities').add(activityData);
  }

  // Join activity (Volunteer)
  Future<void> joinActivity(String userId, String activityId) async {
    // Add to user's joined activities
    await _db.collection('users').doc(userId).update({
      'joinedActivities': FieldValue.arrayUnion([activityId])
    });

    // Add to activity's participants and increment count
    await _db.collection('activities').doc(activityId).update({
      'participants': FieldValue.arrayUnion([userId]),
      'participantsCount': FieldValue.increment(1),
    });

    // Create a registration record
    await _db.collection('registrations').add({
      'userId': userId,
      'activityId': activityId,
      'status': 'registered', // registered, checked-in, completed
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- Chat ---
  Stream<List<Map<String, dynamic>>> getActivityMessages(String activityId) {
    return _db
        .collection('activities')
        .doc(activityId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Future<void> sendMessage(String activityId, String userId, String userName, String message) async {
    await _db.collection('activities').doc(activityId).collection('messages').add({
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- Feedback ---
  Future<void> addReview(String activityId, String userId, double rating, String comment) async {
    await _db.collection('activities').doc(activityId).collection('reviews').add({
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getActivityReviews(String activityId) {
    return _db
        .collection('activities')
        .doc(activityId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- Attendance / Check-in ---
  Stream<List<Map<String, dynamic>>> getActivityParticipants(String activityId) {
    return _db
        .collection('registrations')
        .where('activityId', isEqualTo: activityId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> participants = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id; // Registration ID
        
        // Fetch user details
        DocumentSnapshot userDoc = await _db.collection('users').doc(data['userId']).get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          data['userName'] = userData['name'] ?? 'Unknown';
          data['userEmail'] = userData['email'] ?? '';
        }
        participants.add(data);
      }
      return participants;
    });
  }

  Future<void> checkInUser(String registrationId) async {
    // Get registration to find userId
    final doc = await _db.collection('registrations').doc(registrationId).get();
    if (!doc.exists) return;
    
    final userId = doc.data()?['userId'];
    if (userId == null) return;

    await _db.runTransaction((transaction) async {
      final regRef = _db.collection('registrations').doc(registrationId);
      final userRef = _db.collection('users').doc(userId);

      transaction.update(regRef, {
        'status': 'checked-in',
        'checkInTime': FieldValue.serverTimestamp(),
      });

      // Award points (e.g., 50 points for checking in)
      transaction.update(userRef, {
        'points': FieldValue.increment(50),
      });
    });
  }

  Future<void> deleteActivity(String activityId) async {
    await _db.collection('activities').doc(activityId).delete();
  }

  Future<void> checkInUserByActivity(String userId, String activityId) async {
    final snapshot = await _db
        .collection('registrations')
        .where('userId', isEqualTo: userId)
        .where('activityId', isEqualTo: activityId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      if (data['status'] == 'checked-in') {
         return; // Already checked in
      }
      await checkInUser(snapshot.docs.first.id);
    } else {
      // Not registered, join first
      await joinActivity(userId, activityId);
      
      // Query again to get the new registration
      final newSnapshot = await _db
        .collection('registrations')
        .where('userId', isEqualTo: userId)
        .where('activityId', isEqualTo: activityId)
        .limit(1)
        .get();
      
      if (newSnapshot.docs.isNotEmpty) {
         await checkInUser(newSnapshot.docs.first.id);
      }
    }
  }

  Stream<Map<String, dynamic>?> getUserRegistrationStream(String userId, String activityId) {
    return _db
        .collection('registrations')
        .where('userId', isEqualTo: userId)
        .where('activityId', isEqualTo: activityId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return data;
      }
      return null;
    });
  }

  Future<List<Map<String, dynamic>>> getActiveRegistrationsForUser(String userId) async {
     // Get all registrations for user
     final snapshot = await _db.collection('registrations')
        .where('userId', isEqualTo: userId)
        .get();
        
     List<Map<String, dynamic>> results = [];
     for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'checked-in') continue;
        
        final activityId = data['activityId'];
        final activityDoc = await _db.collection('activities').doc(activityId).get();
        if (!activityDoc.exists) continue;
        
        // Check if activity is today (optional, but good for "Active")
        // For now, return all pending
        data['id'] = doc.id;
        data['activityTitle'] = activityDoc.data()?['title'] ?? 'Unknown Activity';
        results.add(data);
     }
     return results;
  }

  // --- Leaderboard ---
  Stream<List<Map<String, dynamic>>> getLeaderboard() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .orderBy('points', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
  // 251685
  // --- Vouchers / Rewards ---
  Stream<List<Map<String, dynamic>>> getVouchers() {
    return _db.collection('vouchers').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> createVoucher(Map<String, dynamic> voucherData) async {
    await _db.collection('vouchers').add(voucherData);
  }

  Future<void> deleteVoucher(String voucherId) async {
    await _db.collection('vouchers').doc(voucherId).delete();
  }

  Future<void> redeemVoucher(String userId, String voucherId, int cost) async {
    final DocumentReference userRef = _db.collection('users').doc(userId);
    // final DocumentReference voucherRef = _db.collection('vouchers').doc(voucherId);

    await _db.runTransaction((transaction) async {
      DocumentSnapshot userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) {
        throw Exception("User does not exist!");
      }

      int currentPoints = (userSnapshot.data() as Map<String, dynamic>)['points'] ?? 0;
      if (currentPoints < cost) {
        throw Exception("Insufficient points!");
      }

      // Deduct points
      transaction.update(userRef, {'points': currentPoints - cost});

      // Add to redeemed vouchers subcollection
      DocumentReference redeemedRef = userRef.collection('redeemedVouchers').doc();
      transaction.set(redeemedRef, {
        'voucherId': voucherId,
        'redeemedAt': FieldValue.serverTimestamp(),
        'status': 'active', // active, used, expired
      });
    });
  }

  Stream<List<Map<String, dynamic>>> getUserVouchers(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('redeemedVouchers')
        .orderBy('redeemedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> vouchers = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        
        // Fetch details from the main vouchers collection
        DocumentSnapshot voucherDoc = await _db.collection('vouchers').doc(data['voucherId']).get();
        if (voucherDoc.exists) {
          Map<String, dynamic> voucherData = voucherDoc.data() as Map<String, dynamic>;
          data['title'] = voucherData['title'];
          data['description'] = voucherData['description'];
          data['imageUrl'] = voucherData['imageUrl'];
        }
        vouchers.add(data);
      }
      return vouchers;
    });
  }
}
