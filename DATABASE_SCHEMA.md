# ChorePal Database Schema

## Overview
This document describes the Firestore database schema used by both iOS and Android versions of ChorePal.

## Firebase Project
- **Project ID**: `project1.chorepal-prototype`
- **Database**: Firestore
- **Authentication**: Firebase Auth (Email/Password for parents, PIN-based for children)

## Collections

### 1. `parents` Collection
Stores parent user accounts and family information.

```json
{
  "id": "parent_uid_from_firebase_auth",
  "email": "parent@example.com",
  "name": "John Doe",
  "children": ["child_id_1", "child_id_2"],
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### 2. `children` Collection
Stores child accounts with PIN-based authentication.

```json
{
  "id": "auto_generated_child_id",
  "name": "Emma Doe",
  "pin": "2357",
  "points": 150,
  "totalPointsEarned": 500,
  "parentId": "parent_uid_from_firebase_auth",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### 3. `chores` Collection
Stores chore definitions and assignments.

```json
{
  "id": "auto_generated_chore_id",
  "title": "Clean Room",
  "description": "Pick up toys and make bed",
  "points": 25,
  "difficulty": "easy",
  "category": "cleaning",
  "parentId": "parent_uid_from_firebase_auth",
  "assignedTo": ["child_id_1"],
  "isCompleted": false,
  "completedBy": null,
  "completedAt": null,
  "dueDate": "2024-01-15T00:00:00Z",
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

### 4. `rewards` Collection
Stores reward definitions and redemption status.

```json
{
  "id": "auto_generated_reward_id",
  "title": "Extra Screen Time",
  "description": "30 minutes of extra screen time",
  "pointsCost": 100,
  "parentId": "parent_uid_from_firebase_auth",
  "isAvailable": true,
  "redeemedBy": [],
  "createdAt": "2024-01-01T00:00:00Z",
  "updatedAt": "2024-01-01T00:00:00Z"
}
```

## Authentication Flow

### Parent Authentication
1. User enters email/password
2. Firebase Auth validates credentials
3. On success, load parent data from Firestore
4. Set `authState = .parent`

### Child Authentication
1. User enters PIN
2. Query `children` collection for matching PIN
3. If found, set `currentChild` and `authState = .child`
4. No Firebase Auth required for children

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Development rules - allow all operations
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

## Data Relationships

### Parent → Children
- One-to-many relationship
- Parent document contains array of child IDs
- Child documents reference parent via `parentId`

### Parent → Chores
- One-to-many relationship
- Chores reference parent via `parentId`
- Chores can be assigned to multiple children

### Parent → Rewards
- One-to-many relationship
- Rewards reference parent via `parentId`
- Rewards can be redeemed by multiple children

### Child → Chores
- Many-to-many relationship
- Child can have multiple assigned chores
- Chore can be assigned to multiple children

## Points System

### Point Calculation
- **Current Points**: Available for spending on rewards
- **Total Points Earned**: Lifetime points earned (never decreases)
- **Points Earned**: From completing chores
- **Points Spent**: On reward redemptions

### Point Updates
1. **Chore Completion**: Add points to child's current and total
2. **Reward Redemption**: Deduct points from child's current only
3. **Real-time Sync**: Changes reflect immediately across platforms

## Cross-Platform Considerations

### iOS (Swift)
```swift
struct Parent: Codable {
    let id: String
    let email: String
    let name: String
    let children: [String]
    let createdAt: Date
    let updatedAt: Date
}
```

### Android (Kotlin)
```kotlin
data class Parent(
    val id: String,
    val email: String,
    val name: String,
    val children: List<String>,
    val createdAt: Date,
    val updatedAt: Date
)
```

## Real-time Listeners

### Parent Dashboard
- Listen to `children` collection (parent's children)
- Listen to `chores` collection (parent's chores)
- Listen to `rewards` collection (parent's rewards)

### Child Dashboard
- Listen to assigned chores
- Listen to available rewards
- Listen to own child document (for points updates)

## Error Handling

### Common Errors
1. **Network Issues**: Implement retry logic and offline caching
2. **Permission Errors**: Verify security rules and authentication state
3. **Data Validation**: Validate data before writing to Firestore
4. **Concurrent Updates**: Use Firestore transactions for critical operations

## Performance Optimization

### Pagination
- Load chores and rewards in pages
- Implement infinite scrolling
- Cache frequently accessed data

### Caching
- Store user preferences locally
- Cache authentication state
- Implement offline support for basic operations

## Testing

### Test Data
Use the provided mock data files:
- `mock_database.json`
- `sample_database.json`

### Test Scenarios
1. Parent login/logout
2. Child PIN authentication
3. Chore assignment and completion
4. Reward creation and redemption
5. Points calculation and updates
6. Real-time data synchronization
