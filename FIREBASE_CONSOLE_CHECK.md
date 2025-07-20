# Firebase Console Settings Checklist

## 🔧 **Quick Fix for "Malformed Credential" Error**

### **Step 1: Enable Email/Password Authentication**

1. **Open Firebase Console:** https://console.firebase.google.com/
2. **Select your project:** `chorepal-ios-app`
3. **Go to:** Authentication → Sign-in method
4. **Find "Email/Password"** in the list
5. **Click "Enable"** if it's disabled
6. **Save changes**

### **Step 2: Verify Settings**

✅ **Email/Password** should be **ENABLED**  
✅ **Project ID** should be: `chorepal-ios-app`  
✅ **Bundle ID** should be: `project1.chorepal-prototype`  

### **Step 3: Test Again**

After enabling Email/Password authentication:
1. **Run the app** in Xcode
2. **Try signing in** with:
   - Phone: `1234567899`
   - Password: `password1234`
3. **Should work now!** 🎉

### **Common Issues:**

❌ **"Email/Password not enabled"** → Enable it in Firebase Console  
❌ **"Project ID mismatch"** → Check GoogleService-Info.plist  
❌ **"Bundle ID mismatch"** → Check Xcode project settings  

### **Still Having Issues?**

If the error persists after enabling Email/Password:
1. **Clean build** (Cmd+Shift+K in Xcode)
2. **Delete app** from simulator
3. **Rebuild and run**
4. **Try creating a new account** instead of signing in 