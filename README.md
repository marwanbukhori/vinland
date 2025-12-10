# Engage360 - Volunteer Management Mobile App

A Flutter-based mobile application for managing volunteer activities, built with Firebase backend services. It connects organizations with volunteers, gamifies participation, and streamlines activity management.

## Features

### Implemented ✅

#### For Volunteers
- **Authentication**: Email/Password login and registration.
- **Activity Browsing**: View "Popular" and "Upcoming" activities with live status (Upcoming, In Progress, Completed).
- **Check-in System**: 
  - Scan QR Codes to check in.
  - Enter unique 6-digit Activity PIN manually.
  - Real-time status updates (Registered -> Checked In).
- **Gamification**: Earn points (+50) for checking in.
- **Rewards**: Redeem points for vouchers/rewards.
- **Community Chat**: Real-time group chat for each activity.
- **Profile**: View stats, points, and joined activities.

#### For Organizations (Admins)
- **Admin Dashboard**: 
  - View key metrics (Total Activities, Total Participants, Active Events).
  - Manage "Your Activities" (Create, Edit, Delete).
- **Activity Management**: 
  - Create activities with location, dates, and posters.
  - Generate unique 6-digit access codes for manual check-in.
  - Monitor participant counts.
- **Rewards Management**: Create and manage vouchers for volunteers.
- **Data Isolation**: Admins see only their own organization's data.

### Planned 🚧
- **Push Notifications**: Activity reminders via FCM.
- **Leaderboard**: Global ranking of top volunteers.
- **Advanced Analytics**: Deeper insights for organizations.

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - **Authentication**: User management (Volunteer/Organization roles).
  - **Cloud Firestore**: Real-time database for activities, users, chats, and registrations.
  - **Firebase Storage**: Image hosting (Posters, Avatars).
- **State Management**: Provider & StreamBuilder for real-time updates.

## Project Structure

```
lib/
├── features/
│   ├── auth/           # Login & Registration
│   ├── activities/     # Activity Listing, Details, Creation, Editing & Dashboard
│   ├── profile/        # User Profile & Stats
│   ├── community/      # Group Chat logic
│   ├── rewards/        # Voucher system
│   └── certificates/   # Certificate generation (WIP)
├── services/
│   ├── auth_service.dart      # Firebase Auth wrapper
│   ├── firestore_service.dart # Database logic
│   └── storage_service.dart   # File upload logic
└── main.dart           # Entry point & Routing
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.x+)
- Firebase CLI
- Valid Firebase Project

### Installation

1. **Clone the repository**
   ```bash
   git clone <repo_url>
   cd engage360
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   Use FlutterFire CLI to connect your project:
   ```bash
   flutterfire configure --project=<your-project-id>
   ```

4. **Deploy Security Rules**
   Ensure your Firestore rules allow self-check-in:
   ```bash
   firebase deploy --only firestore:rules
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Firestore Schema & Security

The app uses a robust Firestore schema with security rules enforcing:
- **Users**: Read-only for public (basic info), Write for owner.
- **Activities**: Public read, Org-only write.
- **Registrations**: User can create (join) and update (self check-in via app logic). Org can manage.
- **Vouchers**: Public read, Org-only write.

### Sample Rules
```javascript
match /registrations/{registrationId} {
  allow read, create: if request.auth != null;
  // Allow users to update their own check-in status
  allow update: if request.auth != null && (resource.data.userId == request.auth.uid || isOrg());
}
```

## Usage Guide

### Volunteer Flow
1. **Join**: Browse activities -> Click "Join". Status becomes "Registered".
2. **Check-in**: At event, click "Scan Event" or enter the 6-digit code provided by the organizer.
3. **Earn**: Status updates to "Checked In" (Green badge). Points are awarded immediately.
4. **Reward**: Go to Rewards tab -> Redeem vouchers using points.

### Organization Flow
1. **Dashboard**: See overview of active events.
2. **Create**: Tap '+' FAB -> Enter details -> Activity is live.
3. **Manage**: Click "See All" in Dashboard to edit existing activities.
4. **Verify**: Provide the 6-digit "Activity Code" (visible in Activity Details) to volunteers for manual check-in.

## License

This project is created for educational purposes. 

## Contact

For support, please contact the development team.
