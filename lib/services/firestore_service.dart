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

    // Add to activity's participants (optional, if we track it there too)
    // await _db.collection('activities').doc(activityId).update({
    //   'participants': FieldValue.arrayUnion([userId])
    // });

    // Create a registration record
    await _db.collection('registrations').add({
      'userId': userId,
      'activityId': activityId,
      'status': 'registered', // registered, completed
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
