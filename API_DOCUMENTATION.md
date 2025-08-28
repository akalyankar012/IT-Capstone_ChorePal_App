# ChorePal API Documentation

## Overview
This document describes the service layer APIs used by ChorePal for both iOS and Android implementations.

## Authentication Service

### Parent Authentication

#### Sign In Parent
```swift
// iOS
func signInParent(email: String, password: String) async -> Bool
```

```kotlin
// Android
suspend fun signInParent(email: String, password: String): Boolean
```

**Parameters:**
- `email`: Parent's email address
- `password`: Parent's password

**Returns:** `Bool` - Success status

**Firebase Operations:**
1. Firebase Auth sign-in with email/password
2. Load parent data from Firestore
3. Set authentication state to `.parent`

#### Sign Out
```swift
// iOS
func signOut()
```

```kotlin
// Android
fun signOut()
```

**Firebase Operations:**
1. Sign out from Firebase Auth
2. Clear local authentication state
3. Clean up real-time listeners

### Child Authentication

#### Sign In Child
```swift
// iOS
func signInChild(pin: String) async -> Bool
```

```kotlin
// Android
suspend fun signInChild(pin: String): Boolean
```

**Parameters:**
- `pin`: Child's 4-digit PIN

**Returns:** `Bool` - Success status

**Firebase Operations:**
1. Query `children` collection for matching PIN
2. Load child data if found
3. Set authentication state to `.child`

## Child Management Service

### Add Child
```swift
// iOS
func addChild(name: String, pin: String) async -> Bool
```

```kotlin
// Android
suspend fun addChild(name: String, pin: String): Boolean
```

**Parameters:**
- `name`: Child's name
- `pin`: 4-digit PIN for child authentication

**Returns:** `Bool` - Success status

**Firebase Operations:**
1. Create new child document in Firestore
2. Add child ID to parent's children array
3. Update parent document

### Remove Child
```swift
// iOS
func removeChild(childId: String) async -> Bool
```

```kotlin
// Android
suspend fun removeChild(childId: String): Boolean
```

**Parameters:**
- `childId`: ID of child to remove

**Returns:** `Bool` - Success status

**Firebase Operations:**
1. Delete child document from Firestore
2. Remove child ID from parent's children array
3. Update parent document

### Load Children
```swift
// iOS
func loadChildrenForParent() async -> [Child]
```

```kotlin
// Android
suspend fun loadChildrenForParent(): List<Child>
```

**Returns:** Array/List of Child objects

**Firebase Operations:**
1. Query `children` collection where `parentId` matches current parent
2. Parse child documents into Child objects

## Points Management Service

### Award Points
```swift
// iOS
func awardPointsToChild(childId: String, points: Int) async -> Bool
```

```kotlin
// Android
suspend fun awardPointsToChild(childId: String, points: Int): Boolean
```

**Parameters:**
- `childId`: ID of child receiving points
- `points`: Number of points to award

**Returns:** `Bool` - Success status

**Firebase Operations:**
1. Update child's `points` field (add to current)
2. Update child's `totalPointsEarned` field (add to total)
3. Update `updatedAt` timestamp

### Deduct Points
```swift
// iOS
func deductPointsFromChild(childId: String, points: Int) async -> Bool
```

```kotlin
// Android
suspend fun deductPointsFromChild(childId: String, points: Int): Boolean
```

**Parameters:**
- `childId`: ID of child losing points
- `points`: Number of points to deduct

**Returns:** `Bool` - Success status

**Firebase Operations:**
1. Update child's `points` field (subtract from current only)
2. Update `updatedAt` timestamp

### Get Total Family Points
```swift
// iOS
func totalFamilyPoints() -> Int
```

```kotlin
// Android
fun totalFamilyPoints(): Int
```

**Returns:** `Int` - Total points across all children

## Chore Service

### Create Chore
```swift
// iOS
func createChore(title: String, description: String, points: Int, assignedTo: [String]) async -> Bool
```

```kotlin
// Android
suspend fun createChore(title: String, description: String, points: Int, assignedTo: List<String>): Boolean
```

**Parameters:**
- `title`: Chore title
- `description`: Chore description
- `points`: Points awarded for completion
- `assignedTo`: Array of child IDs

**Returns:** `Bool` - Success status

**Firebase Operations:**
1. Create new chore document in Firestore
2. Set `parentId` to current parent
3. Set `isCompleted` to false

### Complete Chore
```swift
// iOS
func completeChore(choreId: String, completedBy: String) async -> Bool
```

```kotlin
// Android
suspend fun completeChore(choreId: String, completedBy: String): Boolean
```

**Parameters:**
- `choreId`: ID of chore to complete
- `completedBy`: ID of child who completed the chore

**Returns:** `Bool` - Success status

**Firebase Operations:**
1. Update chore: set `isCompleted` to true
2. Set `completedBy` and `completedAt`
3. Award points to completing child
4. Update `updatedAt` timestamp

### Load Chores
```swift
// iOS
func loadChores() async -> [Chore]
```

```kotlin
// Android
suspend fun loadChores(): List<Chore>
```

**Returns:** Array/List of Chore objects

**Firebase Operations:**
1. Query `chores` collection where `parentId` matches current parent
2. Parse chore documents into Chore objects

### Load Assigned Chores
```swift
// iOS
func loadAssignedChores(for childId: String) async -> [Chore]
```

```kotlin
// Android
suspend fun loadAssignedChores(childId: String): List<Chore>
```

**Parameters:**
- `childId`: ID of child

**Returns:** Array/List of assigned Chore objects

**Firebase Operations:**
1. Query `chores` collection where `assignedTo` contains childId
2. Parse chore documents into Chore objects

## Reward Service

### Create Reward
```swift
// iOS
func createReward(title: String, description: String, pointsCost: Int) async -> Bool
```

```kotlin
// Android
suspend fun createReward(title: String, description: String, pointsCost: Int): Boolean
```

**Parameters:**
- `title`: Reward title
- `description`: Reward description
- `pointsCost`: Points required to redeem

**Returns:** `Bool` - Success status

**Firebase Operations:**
1. Create new reward document in Firestore
2. Set `parentId` to current parent
3. Set `isAvailable` to true

### Redeem Reward
```swift
// iOS
func redeemReward(rewardId: String, redeemedBy: String) async -> Bool
```

```kotlin
// Android
suspend fun redeemReward(rewardId: String, redeemedBy: String): Boolean
```

**Parameters:**
- `rewardId`: ID of reward to redeem
- `redeemedBy`: ID of child redeeming the reward

**Returns:** `Bool` - Success status

**Firebase Operations:**
1. Check if child has enough points
2. Deduct points from child
3. Add child ID to reward's `redeemedBy` array
4. Update `updatedAt` timestamp

### Load Rewards
```swift
// iOS
func loadRewards() async -> [Reward]
```

```kotlin
// Android
suspend fun loadRewards(): List<Reward>
```

**Returns:** Array/List of Reward objects

**Firebase Operations:**
1. Query `rewards` collection where `parentId` matches current parent
2. Parse reward documents into Reward objects

## Real-time Listeners

### Setup Listeners
```swift
// iOS
func setupRealTimeListeners()
```

```kotlin
// Android
fun setupRealTimeListeners()
```

**Firebase Operations:**
1. Set up Firestore snapshot listeners for relevant collections
2. Update local data when changes occur
3. Trigger UI updates via ObservableObject/ViewModel

### Cleanup Listeners
```swift
// iOS
func cleanupRealTimeListeners()
```

```kotlin
// Android
fun cleanupRealTimeListeners()
```

**Firebase Operations:**
1. Remove all active Firestore listeners
2. Clean up resources

## Error Handling

### Common Error Types
1. **Network Errors**: Connection issues, timeouts
2. **Authentication Errors**: Invalid credentials, expired tokens
3. **Permission Errors**: Insufficient Firestore permissions
4. **Validation Errors**: Invalid data format
5. **Concurrency Errors**: Simultaneous updates

### Error Response Format
```swift
// iOS
enum AuthError: Error {
    case networkError(String)
    case authenticationError(String)
    case permissionError(String)
    case validationError(String)
}
```

```kotlin
// Android
sealed class AuthError : Exception() {
    data class NetworkError(val message: String) : AuthError()
    data class AuthenticationError(val message: String) : AuthError()
    data class PermissionError(val message: String) : AuthError()
    data class ValidationError(val message: String) : AuthError()
}
```

## Data Models

### Parent Model
```swift
// iOS
struct Parent: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let children: [String]
    let createdAt: Date
    let updatedAt: Date
}
```

```kotlin
// Android
data class Parent(
    val id: String,
    val email: String,
    val name: String,
    val children: List<String>,
    val createdAt: Date,
    val updatedAt: Date
)
```

### Child Model
```swift
// iOS
struct Child: Codable, Identifiable {
    let id: String
    let name: String
    let pin: String
    let points: Int
    let totalPointsEarned: Int
    let parentId: String
    let createdAt: Date
    let updatedAt: Date
}
```

```kotlin
// Android
data class Child(
    val id: String,
    val name: String,
    val pin: String,
    val points: Int,
    val totalPointsEarned: Int,
    val parentId: String,
    val createdAt: Date,
    val updatedAt: Date
)
```

### Chore Model
```swift
// iOS
struct Chore: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let points: Int
    let difficulty: String
    let category: String
    let parentId: String
    let assignedTo: [String]
    let isCompleted: Bool
    let completedBy: String?
    let completedAt: Date?
    let dueDate: Date?
    let createdAt: Date
    let updatedAt: Date
}
```

```kotlin
// Android
data class Chore(
    val id: String,
    val title: String,
    val description: String,
    val points: Int,
    val difficulty: String,
    val category: String,
    val parentId: String,
    val assignedTo: List<String>,
    val isCompleted: Boolean,
    val completedBy: String?,
    val completedAt: Date?,
    val dueDate: Date?,
    val createdAt: Date,
    val updatedAt: Date
)
```

### Reward Model
```swift
// iOS
struct Reward: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let pointsCost: Int
    let parentId: String
    let isAvailable: Bool
    let redeemedBy: [String]
    let createdAt: Date
    let updatedAt: Date
}
```

```kotlin
// Android
data class Reward(
    val id: String,
    val title: String,
    val description: String,
    val pointsCost: Int,
    val parentId: String,
    val isAvailable: Boolean,
    val redeemedBy: List<String>,
    val createdAt: Date,
    val updatedAt: Date
)
```

## Testing

### Mock Data
Use the provided mock data for testing:
- `mock_database.json`: Complete mock database
- `sample_database.json`: Sample data for testing

### Test Scenarios
1. **Authentication Tests**
   - Parent login with valid/invalid credentials
   - Child login with valid/invalid PIN
   - Sign out functionality

2. **Data Management Tests**
   - CRUD operations for all entities
   - Real-time data synchronization
   - Error handling scenarios

3. **Points System Tests**
   - Point awarding and deduction
   - Reward redemption
   - Total points calculation

4. **Cross-Platform Tests**
   - Data consistency between iOS and Android
   - Real-time updates across platforms
   - Authentication state synchronization
