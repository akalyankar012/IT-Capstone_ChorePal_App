# Firebase Console Settings Checklist

## 🔧 **Quick Fix for "Malformed Credential" Error**

### **Step 1: Enable Email/Password Authentication**

1. **Open Firebase Console:** https://console.firebase.google.com/
2. **Select your project:** `chorepal-ios-app`
3. **Go to:** Authentication → Sign-in method
4. **Find "Email/Password"** in the list
5. **Click "Enable"** if it's disabled
6. **Save changes**

### **Step 2: Create Firestore Database (CRITICAL!)**

1. **In Firebase Console, go to:** Firestore Database
2. **Click "Create database"**
3. **Choose "Start in test mode"** (for development)
4. **Select a location** (choose closest to you)
5. **Click "Done"**
6. **Wait for database to be created** (takes a few minutes)

### **Step 3: Verify Settings**

✅ **Email/Password** should be **ENABLED**  
✅ **Project ID** should be: `chorepal-ios-app`  
✅ **Bundle ID** should be: `project1.chorepal-prototype`  
✅ **Firestore Database** should be **CREATED**  

### **Step 4: Test Again**

After enabling Email/Password authentication AND creating the Firestore database:
1. **Run the app** in Xcode
2. **Try signing in** with:
   - Phone: `1234567899`
   - Password: `password1234`
3. **Create a child account** - this should now save to Firestore
4. **Try child login** with the PIN - this should now work! 🎉

## 🚨 **Important Notes:**

- **Firestore Database is REQUIRED** for child accounts and PINs to work
- Without it, child creation and login will fail silently
- The database setup takes 2-3 minutes to complete 