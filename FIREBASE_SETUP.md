# Firebase Setup Guide for ChorePal

## Prerequisites
- Xcode 15.0 or later
- iOS 18.2 or later
- Firebase account

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `ChorePal`
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add iOS App to Firebase

1. In Firebase Console, click the iOS icon (+ Add app)
2. Enter iOS bundle ID: `project1.chorepal-prototype`
3. Enter app nickname: `ChorePal`
4. Click "Register app"
5. Download `GoogleService-Info.plist`

## Step 3: Add Firebase Dependencies

1. Open `chorepal prototype.xcodeproj` in Xcode
2. Select the project in the navigator
3. Go to "Package Dependencies" tab
4. Click "+" to add package
5. Enter: `https://github.com/firebase/firebase-ios-sdk.git`
6. Select these products:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseFirestoreSwift`

## Step 4: Add Configuration File

1. Drag `GoogleService-Info.plist` into Xcode project
2. Make sure "Copy items if needed" is checked
3. Add to target: `chorepal prototype`

## Step 5: Enable Authentication

1. In Firebase Console, go to "Authentication"
2. Click "Get started"
3. Go to "Sign-in method" tab
4. **Enable "Email/Password" provider** (this is required for our app)
5. Optionally enable "Phone" provider for future features
6. Add test phone numbers if using phone authentication

## Step 6: Create Firestore Database

1. In Firebase Console, go to "Firestore Database"
2. Click "Create database"
3. Choose "Start in test mode" (we'll add security rules later)
4. Select location closest to your users
5. Click "Done"

## Step 7: Security Rules (Optional for now)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all users under any document
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

## Step 8: Test the Setup

1. Build and run the project
2. Check console for Firebase initialization messages
3. Test phone authentication flow

## Troubleshooting

### Common Issues:

1. **"Firebase not configured" error**
   - Make sure `GoogleService-Info.plist` is added to the project
   - Check that `FirebaseApp.configure()` is called in `App.swift`

2. **Authentication errors**
   - Verify **Email/Password authentication** is enabled in Firebase Console
   - Check that test phone numbers are added (for development)
   - If you get "malformed credential" error, ensure Email/Password is enabled

3. **Build errors**
   - Clean build folder (Cmd+Shift+K)
   - Delete derived data
   - Rebuild project

## Next Steps

After setup is complete:
1. Test authentication flow
2. Implement data models for Firestore
3. Add real-time synchronization
4. Implement offline persistence
5. Add security rules

## Support

If you encounter issues:
1. Check Firebase documentation
2. Review Xcode console for error messages
3. Verify all dependencies are properly linked 