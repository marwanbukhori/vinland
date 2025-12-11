# Engage360 - System Sequence Diagrams

These diagrams illustrate the interaction between actors (Volunteers, Organizations) and the System (App + Firebase Backend).

## 1. Authentication & Verification
This flow covers Registration, Email Verification, and Login.

```mermaid
sequenceDiagram
    participant U as User (Volunteer/Org)
    participant A as Auth Service
    participant F as Firebase Auth
    participant D as Firestore (DB)

    U->>A: Register (Email, Pass, Name, Role)
    A->>F: createUserWithEmailAndPassword()
    F-->>A: UserCredential (uid)
    A->>D: Create User Document (uid, role, etc)
    A->>F: user.sendVerificationEmail()
    A-->>U: Show "Verify Email" Screen

    Note over U: User checks email & clicks link

    U->>A: Login (Email, Pass)
    A->>F: signInWithEmailAndPassword()
    F-->>A: User Object
    A->>F: Check emailVerified
    alt Verification False
        A-->>U: Redirect to VerifyEmailScreen
    else Verification True
        A->>D: Get User Role
        D-->>A: Role (Volunteer/Org)
        alt Role == Organization
            A-->>U: Redirect to Admin Dashboard
        else Role == Volunteer
            A-->>U: Redirect to Activity List
        end
    end
```

## 2. Activity Lifecycle (Create -> Join -> Check-in)
This flow shows how an activity is created, joined, and how users check in to earn points.

```mermaid
sequenceDiagram
    participant Org as Organization
    participant Vol as Volunteer
    participant Sys as System
    participant DB as Firestore

    %% Creation
    Org->>Sys: Create Activity (Title, Loc, Dates)
    Sys->>DB: addActivity(data)
    DB-->>Sys: Activity ID
    Sys-->>Org: Success Message

    %% Joining
    Vol->>Sys: View Activity Details
    Sys->>DB: getActivity(id)
    DB-->>Sys: Activity Data
    Vol->>Sys: Click "Join"
    Sys->>DB: addRegistration(uid, activityId, status='registered')
    Sys->>DB: Update Activity (participants array)
    Sys-->>Vol: Show "Registered" Status

    %% Check-in
    Vol->>Sys: Click "Scan QR" / Enter Code
    Sys->>Sys: Validate Input/QR
    Sys->>DB: Query Registration(uid, activityId)
    DB-->>Sys: Registration Doc
    
    alt Status == Checked-in
        Sys-->>Vol: Error "Already Checked In"
    else Status == Registered
        Sys->>DB: Transaction Start
        DB->>DB: Update Registration (status='checked-in')
        DB->>DB: Update User (points+=50, lifetimePoints+=50)
        Sys-->>Vol: Success "Checked In (+50 Pts)"
    end
```

## 3. Rewards & Redemption
This flow shows how vouchers are created and redeemed.

```mermaid
sequenceDiagram
    participant Org as Organization
    participant Vol as Volunteer
    participant Sys as System
    participant DB as Firestore

    %% Create Voucher
    Org->>Sys: Create Voucher (Title, Cost)
    Sys->>DB: createVoucher(data)
    DB-->>Org: Success

    %% Redeem Voucher
    Vol->>Sys: View Rewards
    Sys->>DB: getVouchers()
    DB-->>Sys: List of Vouchers
    Vol->>Sys: Click "Redeem" (Cost: X)
    
    Sys->>DB: Transaction Start
    DB->>DB: Get User Points
    alt User Points < Cost
        DB-->>Sys: Error "Insufficient Points"
        Sys-->>Vol: Error Message
    else User Points >= Cost
        DB->>DB: Update User (points -= Cost)
        Note right of DB: lifetimePoints is NOT deducted
        DB->>DB: Add to User/redeemedVouchers
        Sys-->>Vol: Success "Reward Redeemed"
        Sys->>Vol: Show in "My Rewards"
    end
```
