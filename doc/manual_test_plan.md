# Engage360 Manual Test Plan

This document outlines the manual testing steps to verify the core features of the Engage360 application.

## 1. Authentication
**Goal**: Verify users can securely access the app.

- [ ] **Sign Up (New User)**
    - Navigate to "Sign Up".
    - Enter valid Name, Email, Password.
    - Select Role (Volunteer).
    - **Expected**: Account created, user redirected to Home/Activity List.
    - **Verify**: Firestore `users` collection contains the new document with correct `name` and `email`.

- [ ] **Login (Existing User)**
    - Enter valid credentials.
    - **Expected**: Successful login, redirected to Home.

- [ ] **Logout**
    - Go to Profile -> Settings/Logout.
    - **Expected**: Session cleared, redirected to Login screen.

## 2. Activities (Home)
**Goal**: Verify browsing and discovering activities.

- [ ] **View Activity List**
    - Scroll through the feed.
    - **Verify**: Activities show title, location, date, and image.
    - **Verify**: "Completed" or "Upcoming" status is visible if applicable.

- [ ] **Activity Details**
    - Tap on an activity card.
    - **Verify**: Detailed view opens with Description, Organization, Map/Location, and "Join" button.

## 3. Activity Lifecycle (The Core Flow)
**Goal**: Verify the entire volunteer journey for a single activity.

### Phase A: Registration
- [ ] **Join Activity**
    - Click "Join" on an upcoming activity.
    - **Expected**: Button changes to "Joined" or "Registered".
    - **Verify**: Points/Stats in Profile might update (if points are awarded for joining).
    - **Verify**: Firestore `registrations` collection has a new record.

### Phase B: Community Chat
- [ ] **Send Message**
    - Open "Community Chat" from Activity Details.
    - Type and send a message.
    - **Verify**: Message appears immediately.
    - **Verify**: Your **Name** is displayed correctly (not "Volunteer").

- [ ] **Receive Message**
    - (Optional) Have a second user send a message to the same activity.
    - **Verify**: Real-time update showing the other user's message.

### Phase C: Check-in (Attendance)
- [ ] **QR Check-in Flow**
    - **Organizer Mode** (if available) or Pre-set QR: Have a QR code ready containing the `activityId`.
    - **Volunteer**: Tap "Scan to Check In" (or equivalent button).
    - Scan the QR code.
    - **Expected**: Success message "Checked in!".
    - **Verify**: Profile Points increase (e.g., +50 points).
    - **Verify**: Registration status changes to `checked-in`.

### Phase D: Feedback
- [ ] **Submit Review**
    - (After activity is "Completed")
    - Go to Activity Details.
    - Rate (1-5 stars) and write a comment.
    - Tap "Submit".
    - **Verify**: Toast/Snackbar confirms submission.
    - **Verify**: Review appears in Firestore `reviews` subcollection.

## 4. Profile & Gamification
**Goal**: Verify user progress tracking.

- [ ] **View Profile**
    - Navigate to Profile tab.
    - **Verify**: Name, Email, and Total Points are correct.
    - **Verify**: "Joined Activities" list is accurate.

- [ ] **Leaderboard**
    - Navigate to Leaderboard tab.
    - **Verify**: Your user is listed with correct point tally.
    - **Verify**: List is sorted by points (Descending).

- [ ] **Certificates**
    - Navigate to Certificates section.
    - **Verify**: Certificates for completed/checked-in activities are listed.
    - **Verify**: Tapping one opens the certificate detail/image.

## 5. Rewards (Vouchers)
**Goal**: Verify point redemption system.

- [ ] **Browse Rewards**
    - Go to Rewards tab.
    - View available vouchers.

- [ ] **Redeem Voucher**
    - Select a voucher.
    - Ensure you have enough points.
    - Click "Redeem".
    - **Expected**: Success message, Points deducted from Profile.
    - **Verify**: Voucher moves to "My Vouchers" / "Redeemed" tab.

- [ ] **Validation (Insufficient Points)**
    - Try to redeem a voucher that costs more than your current balance.
    - **Expected**: Error message "Insufficient points".
