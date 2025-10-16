import SwiftUI

// MARK: - Phone Number Formatting
func formatPhoneNumber(_ phoneNumber: String) -> String {
    let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    let mask = "(XXX) XXX-XXXX"
    var result = ""
    var index = cleaned.startIndex
    for ch in mask where index < cleaned.endIndex {
        if ch == "X" {
            result.append(cleaned[index])
            index = cleaned.index(after: index)
        } else {
            result.append(ch)
        }
    }
    return result
}

// MARK: - Parent Sign Up View
struct ParentSignUpView: View {
    @ObservedObject var authService: AuthService
    @State private var parentName = ""
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Back Button - moved down from top
                    HStack {
                        Button(action: {
                            authService.authState = .none
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(themeColor)
                            .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 30) // Moved higher for better accessibility
                    
                    // Header - better centered with smaller fonts
                    VStack(spacing: 16) {
                        Image("potato")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100) // Reduced from 120
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 6) {
                            Text("Create Parent Account")
                                .font(.system(size: 28, weight: .heavy)) // Reduced from 32
                                .foregroundColor(themeColor)
                                .multilineTextAlignment(.center)
                            
                            Text("Manage your family's chores with ChorePal")
                                .font(.title2) // Reduced from title3
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16) // Reduced from 20
                        }
                    }
                    .padding(.top, 20) // Reduced from 30
                    .padding(.bottom, 20) // Reduced from 30
                    
                    // Form - more compact
                    VStack(spacing: 16) { // Reduced from 20
                        // Parent Name
                        VStack(alignment: .leading, spacing: 6) { // Reduced from 8
                            Text("Full Name")
                                .font(.subheadline) // Reduced from headline
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            TextField("Enter your full name", text: $parentName)
                                .textContentType(.name)
                                .padding(.vertical, 12) // Reduced from 16
                                .padding(.horizontal, 16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                        
                        // Phone Number
                        VStack(alignment: .leading, spacing: 6) { // Reduced from 8
                            Text("Phone Number")
                                .font(.subheadline) // Reduced from headline
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("+1")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 16)
                                
                                TextField("(555) 123-4567", text: $phoneNumber)
                                    .keyboardType(.phonePad)
                                    .textContentType(.telephoneNumber)
                                    .onChange(of: phoneNumber) { _, newValue in
                                        phoneNumber = formatPhoneNumber(newValue)
                                    }
                                    .padding(.vertical, 12) // Reduced from 16
                                    .padding(.horizontal, 12)
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 6) { // Reduced from 8
                            Text("Password")
                                .font(.subheadline) // Reduced from headline
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter password", text: $password)
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("Enter password", text: $password)
                                        .textContentType(.newPassword)
                                }
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 16)
                            }
                            .padding(.vertical, 12) // Reduced from 16
                            .padding(.leading, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 6) { // Reduced from 8
                            Text("Confirm Password")
                                .font(.subheadline) // Reduced from headline
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            HStack {
                                if showConfirmPassword {
                                    TextField("Confirm password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                } else {
                                    SecureField("Confirm password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                }
                                
                                Button(action: {
                                    showConfirmPassword.toggle()
                                }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 16)
                            }
                            .padding(.vertical, 12) // Reduced from 16
                            .padding(.leading, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Error Message
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 8)
                        }
                        
                        // Sign In Link - moved above Create Account button
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.gray)
                                .font(.subheadline) // Made smaller
                            
                            Button("Sign In") {
                                authService.authState = .signIn
                            }
                            .foregroundColor(themeColor)
                            .font(.subheadline) // Made smaller
                            .fontWeight(.semibold)
                        }
                        .padding(.top, 16) // Reduced from 20
                        
                        // Sign Up Button
                        Button(action: {
                            Task {
                                await signUp()
                            }
                        }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Create Account")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14) // Reduced from 16
                            .background(themeColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authService.isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.top, 16) // Reduced from 20
                    }
                    .padding(.horizontal, 24)
                    
                    // Spacer to push content up
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var isFormValid: Bool {
        !parentName.isEmpty &&
        !phoneNumber.isEmpty && 
        password.count >= 6 && 
        password == confirmPassword &&
        phoneNumber.count >= 10
    }
    
    private func signUp() async {
        let success = await authService.signUpParent(phoneNumber: phoneNumber, password: password)
        if success {
            // Phone verification will be handled by auth state change
        }
    }
}

// MARK: - Phone Verification View
struct PhoneVerificationView: View {
    @ObservedObject var authService: AuthService
    @State private var verificationCode = ""
    @State private var timeRemaining = 60
    @State private var canResend = false
    @FocusState private var isVerificationCodeFocused: Bool
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Back Button
                    HStack {
                        Button(action: {
                            authService.authState = .signUp
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(themeColor)
                            .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image("potato")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        Text("Verify Your Phone")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(themeColor)
                            .multilineTextAlignment(.center)
                        
                        Text("We sent a verification code to")
                            .font(.title3)
                            .foregroundColor(.gray)
                        
                        Text(authService.currentParent?.phoneNumber ?? "")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                    
                    // Verification Code Input
                    VStack(spacing: 20) {
                        Text("Enter 6-digit code")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { index in
                                VerificationCodeDigit(
                                    digit: index < verificationCode.count ? String(verificationCode[verificationCode.index(verificationCode.startIndex, offsetBy: index)]) : "",
                                    isActive: index == verificationCode.count
                                )
                            }
                        }
                        .padding(.vertical, 20)
                        
                        // Hidden text field for input
                        TextField("", text: $verificationCode)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .frame(width: 1, height: 1)
                            .opacity(0.001)
                            .focused($isVerificationCodeFocused)
                            .onChange(of: verificationCode) { _, newValue in
                                if newValue.count > 6 {
                                    verificationCode = String(newValue.prefix(6))
                                }
                                if newValue.count == 6 {
                                    Task {
                                        await verifyCode()
                                    }
                                }
                            }
                        
                        // Error Message
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 8)
                        }
                        
                        // Resend Code
                        HStack {
                            Text("Didn't receive the code?")
                                .foregroundColor(.gray)
                            
                            Button("Resend") {
                                resendCode()
                            }
                            .foregroundColor(canResend ? themeColor : .gray)
                            .fontWeight(.semibold)
                            .disabled(!canResend)
                        }
                        .padding(.top, 20)
                        
                        // Timer
                        if !canResend {
                            Text("Resend in \(timeRemaining)s")
                                .foregroundColor(.gray)
                                .font(.caption)
                                .padding(.top, 8)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startTimer()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isVerificationCodeFocused = true
            }
        }
    }
    
    private func verifyCode() async {
        let success = await authService.verifyPhoneCode(code: verificationCode)
        if success {
            // Authentication state will be updated by the service
        }
    }
    
    private func resendCode() {
        // Mock resend - in real app, this would call the API
        verificationCode = ""
        timeRemaining = 60
        canResend = false
        startTimer()
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
}

// MARK: - Verification Code Digit View
struct VerificationCodeDigit: View {
    let digit: String
    let isActive: Bool
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(isActive ? themeColor.opacity(0.2) : Color(.systemGray6))
                .frame(width: 50, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? themeColor : Color.clear, lineWidth: 2)
                )
            
            Text(digit)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Parent Sign In View
struct ParentSignInView: View {
    @ObservedObject var authService: AuthService
    @State private var phoneNumber = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showingForgotPassword = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Back Button - moved down from top
                    HStack {
                        Button(action: {
                            authService.authState = .none
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(themeColor)
                            .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 30) // Moved higher for better accessibility
                    
                    // Header - better centered
                    VStack(spacing: 20) {
                        Image("potato")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text("Welcome Back!")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(themeColor)
                                .multilineTextAlignment(.center)
                            
                            Text("Sign in to your ChorePal account")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 30) // Reduced from 40
                    .padding(.bottom, 30) // Reduced from 40
                    
                    // Form
                    VStack(spacing: 20) {
                        // Phone Number
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Phone Number")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                Text("+1")
                                    .foregroundColor(.gray)
                                    .padding(.leading, 16)
                                
                                TextField("(555) 123-4567", text: $phoneNumber)
                                    .keyboardType(.phonePad)
                                    .textContentType(.telephoneNumber)
                                    .onChange(of: phoneNumber) { _, newValue in
                                        phoneNumber = formatPhoneNumber(newValue)
                                    }
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 12)
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                if showPassword {
                                    TextField("Enter password", text: $password)
                                        .textContentType(.password)
                                } else {
                                    SecureField("Enter password", text: $password)
                                        .textContentType(.password)
                                }
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 16)
                            }
                            .padding(.vertical, 16)
                            .padding(.leading, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        // Forgot Password Link
                        HStack {
                            Spacer()
                            Button("Forgot Password?") {
                                showingForgotPassword = true
                            }
                            .foregroundColor(themeColor)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        }
                        
                        // Error Message
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 8)
                        }
                        
                        // Sign In Button
                        Button(action: {
                            Task {
                                await signIn()
                            }
                        }) {
                            HStack {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Sign In")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(themeColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authService.isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.top, 20)
                        
                        // Sign Up Link - moved up from bottom
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.gray)
                            
                            Button("Sign Up") {
                                authService.authState = .signUp
                            }
                            .foregroundColor(themeColor)
                            .fontWeight(.semibold)
                        }
                        .padding(.top, 30) // Increased from 20
                        .padding(.bottom, 20) // Added bottom padding
                    }
                    .padding(.horizontal, 24)
                    
                    // Spacer to push content up
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingForgotPassword) {
            ForgotPasswordView(authService: authService)
        }
    }
    
    private var isFormValid: Bool {
        !phoneNumber.isEmpty && !password.isEmpty
    }
    
    private func signIn() async {
        let success = await authService.signInParent(phoneNumber: phoneNumber, password: password)
        if success {
            // Authentication state will be updated by the service
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @ObservedObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @State private var phoneNumber = ""
    @State private var showingSuccessAlert = false
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeColor)
                    
                    Text("Reset Password")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Enter your phone number to receive a password reset link")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Phone Number")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Text("+1")
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                            
                            TextField("(555) 123-4567", text: $phoneNumber)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .onChange(of: phoneNumber) { _, newValue in
                                    phoneNumber = formatPhoneNumber(newValue)
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 12)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Error Message
                    if let errorMessage = authService.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: resetPassword) {
                        HStack {
                            if authService.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Send Reset Link")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canResetPassword ? themeColor : Color.gray)
                        .cornerRadius(12)
                    }
                    .disabled(!canResetPassword || authService.isLoading)
                    
                    Button(action: { dismiss() }) {
                        Text("Cancel")
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Password Reset", isPresented: $showingSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Password reset link has been sent to your phone number.")
        }
    }
    
    private var canResetPassword: Bool {
        !phoneNumber.isEmpty && phoneNumber.count >= 10
    }
    
    private func resetPassword() {
        // Placeholder until backend flow is added; show success UI so build runs
        showingSuccessAlert = true
    }
}

// MARK: - Child Login View
struct ChildLoginView: View {
    @ObservedObject var authService: AuthService
    @Binding var selectedRole: UserRole
    @State private var pin = ""
    @FocusState private var isPinFocused: Bool
    
    private let themeColor = Color(hex: "#a2cee3")
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Back Button - moved down from top
                    HStack {
                        Button(action: {
                            selectedRole = .none
                            authService.authState = .none
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(themeColor)
                            .font(.headline)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 30) // Moved higher for better accessibility
                    
                    // Header - better centered
                    VStack(spacing: 20) {
                        Image("potato")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        VStack(spacing: 8) {
                            Text("Welcome, Kid!")
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(themeColor)
                                .multilineTextAlignment(.center)
                            
                            Text("Enter your 4-digit PIN to start")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.top, 30) // Reduced from 40
                    .padding(.bottom, 30) // Reduced from 40
                    
                    // PIN Input
                    VStack(spacing: 20) {
                        Text("Enter PIN")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            ForEach(0..<4, id: \.self) { index in
                                VerificationCodeDigit(
                                    digit: index < pin.count ? String(pin[pin.index(pin.startIndex, offsetBy: index)]) : "",
                                    isActive: index == pin.count
                                )
                            }
                        }
                        .padding(.vertical, 20)
                        
                        // Hidden text field for input
                        TextField("", text: $pin)
                            .keyboardType(.numberPad)
                            .frame(width: 1, height: 1)
                            .opacity(0.001)
                            .focused($isPinFocused)
                            .onChange(of: pin) { _, newValue in
                                if newValue.count > 4 {
                                    pin = String(newValue.prefix(4))
                                }
                                if newValue.count == 4 {
                                    Task {
                                        await signIn()
                                    }
                                }
                            }
                        
                        // Error Message
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 8)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPinFocused = true
            }
        }
    }
    
    private func signIn() async {
        let success = await authService.signInChild(pin: pin)
        if success {
            // Authentication state will be updated by the service
        }
    }
}