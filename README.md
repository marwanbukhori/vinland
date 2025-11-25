# Engage360 - Volunteer Management Mobile App

A Flutter-based mobile application for managing volunteer activities, built with Firebase backend services.

## Features

### Implemented ✅
- **Authentication**: Email/Password login and registration with role selection (Volunteer/Organization)
- **User Management**: User profiles stored in Firestore with points and activity tracking
- **Activity Management**:
  - Organizations can create volunteer activities with images
  - Volunteers can browse and join activities
  - Real-time activity updates
  - Activity posters using Firebase Storage
- **Gamification**: Points system for volunteer participation
- **Profile Screen**: View user stats, points, and joined activities
- **Certificate Generation**: Generate and share PDF certificates for completed activities
- **Firebase Integration**: Authentication, Firestore, and Storage

### Planned 🚧
- **Messaging**: Real-time chat between users
- **Push Notifications**: Activity reminders and updates via FCM
- **Leaderboard**: Top volunteers ranking
- **Activity Completion Tracking**: Mark activities as completed with automatic point awards

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Free Tier)
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Messaging (planned)
- **State Management**: Provider

## Project Structure

```
lib/
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── activities/
│   │   ├── activity_list_screen.dart
│   │   ├── activity_detail_screen.dart
│   │   └── activity_create_screen.dart
│   ├── profile/
│   ├── messaging/
│   ├── certificates/
│   └── rewards/
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── utils/
└── main.dart
```

## Setup Instructions

### Prerequisites
- Flutter SDK installed
- Firebase CLI installed
- Firebase project created

### Installation

1. **Clone the repository** (if applicable)
   ```bash
   cd /Users/muhdmarwan/2030/engage360
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   export PATH="$PATH":"$HOME/.pub-cache/bin"
   flutterfire configure --project=engage360-fd4fa --platforms=android
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Firebase Setup

### Firestore Collections

#### `users`
```json
{
  "name": "string",
  "email": "string",
  "role": "volunteer | organization",
  "phone": "string",
  "points": 0,
  "profilePhotoUrl": "string",
  "joinedActivities": [],
  "createdAt": "timestamp"
}
```

#### `activities`
```json
{
  "title": "string",
  "description": "string",
  "location": "string",
  "startDate": "timestamp",
  "organizationId": "string",
  "posterUrl": "string",
  "createdAt": "timestamp"
}
```

#### `registrations`
```json
{
  "userId": "string",
  "activityId": "string",
  "status": "registered | completed",
  "timestamp": "timestamp"
}
```

### Security Rules (To be configured in Firebase Console)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read all, but only update their own
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }

    // Activities
    match /activities/{activityId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null;
    }

    // Registrations
    match /registrations/{registrationId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Usage

### For Volunteers
1. Register with email/password and select "VOLUNTEER" role
2. Browse available activities
3. Tap on an activity to view details
4. Join activities to earn points

### For Organizations
1. Register with email/password and select "ORGANIZATION" role
2. Tap the "+" button to create new activities
3. Fill in activity details (title, description, location)
4. Submit to publish the activity

## Development

### Run in Debug Mode
```bash
flutter run
```

### Build APK (Android)
```bash
flutter build apk
```

### Analyze Code
```bash
flutter analyze
```

## Next Steps

1. **Enable Firestore in Firebase Console**
   - Go to Firebase Console → Firestore Database
   - Create database in production mode
   - Apply security rules

2. **Implement Messaging**
   - Create chat screens
   - Set up Firestore listeners for real-time messages

3. **Add Push Notifications**
   - Configure FCM
   - Implement notification service

4. **Certificate Generation**
   - Use `pdf` package to generate certificates
   - Upload to Firebase Storage

## License

This project is created for educational purposes.

## Contact

For questions or support, please contact the development team.
