# Engage360 - Data Flow Diagrams (DFD)

## Level 0 DFD (Context Diagram)
High-level overview of the system and its external entities.

```mermaid
graph LR
    Volunteer[Volunteer]
    Org[Organization/Admin]
    System(Engage360 System)

    Volunteer -- Registration Data, Login Creds --> System
    Volunteer -- Check-in Data, Reward Requests --> System
    
    Org -- Activity Details, Voucher Details --> System
    Org -- Login Creds --> System

    System -- Activity List, Points, Rewards --> Volunteer
    System -- Dashboard Stats, Participant List --> Org
```

## Level 1 DFD (System Breakdown)
Detailed breakdown of major processes and data stores.

```mermaid
graph TD
    %% Entities
    Vol[Volunteer]
    Org[Organization]

    %% Processes
    P1(1.0 Authentication)
    P2(2.0 Manage Activities)
    P3(3.0 Manage Participation)
    P4(4.0 Manage Rewards)

    %% Data Stores
    D1[(D1: Users)]
    D2[(D2: Activities)]
    D3[(D3: Registrations)]
    D4[(D4: Vouchers)]

    %% Connections
    
    %% Auth
    Vol -->|Credentials| P1
    Org -->|Credentials| P1
    P1 -->|Read/Write User Data| D1
    P1 -->|Token/Access| Vol
    P1 -->|Token/Access| Org

    %% Activities
    Org -->|Create/Edit Activity| P2
    P2 -->|Save Details| D2
    D2 -->|Activity List| P2
    P2 -->|View Activities| Vol
    
    %% Participation
    Vol -->|Join Request| P3
    Vol -->|QR/Check-in Code| P3
    P3 -->|Validate User| D1
    P3 -->|Read Activity| D2
    P3 -->|Create/Update Record| D3
    P3 -->|Update Points| D1
    
    %% Rewards
    Org -->|Create Voucher| P4
    P4 -->|Save Voucher| D4
    Vol -->|Redeem Request| P4
    P4 -->|Check Balance| D1
    P4 -->|Deduct Points| D1
    P4 -->|Read Voucher Cost| D4
```

### Data Dictionary
- **Users**: `uid`, `name`, `email`, `role`, `points`, `lifetimePoints`.
- **Activities**: `id`, `title`, `description`, `location`, `startDate`, `participants`.
- **Registrations**: `id`, `userId`, `activityId`, `status`, `timestamp`.
- **Vouchers**: `id`, `title`, `cost`, `imageUrl`, `createdBy`.
