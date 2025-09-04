import SwiftUI

// MARK: - Parent Sign Up View
struct ParentSignUpView: View {
    @ObservedObject var authService: AuthService
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
                    // Back Button
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
                    .padding(.top, 16)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image("potato")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                        
                        Text("Create Parent Account")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(themeColor)
                            .multilineTextAlignment(.center)
                        
                        Text("Join ChorePal to manage your family's chores")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                    
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
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 12)
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
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
                            .padding(.vertical, 16)
                            .padding(.leading, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        
                        // Confirm Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.headline)
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
                            .padding(.vertical, 16)
                            .padding(.leading, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        
                        // Error Message
                        if let errorMessage = authService.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 8)
                        }
                        
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
                            .padding(.vertical, 16)
                            .background(themeColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(authService.isLoading || !isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                        .padding(.top, 20)
                        
                        // Sign In Link
                        HStack {
                            Text("Already have an account?")
                                .foregroundColor(.gray)
                            
                            Button("Sign In") {
                                authService.authState = .signIn
                            }
                            .foregroundColor(themeColor)
                            .fontWeight(.semibold)
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private var isFormValid: Bool {
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
                            .onChange(of: verificationCode) { newValue in
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
            RoundedRectangle(cornerRadius: 16)
                .fill(isActive ? themeColor.opacity(0.2) : Color(.systemGray6))
                .frame(width: 50, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isActive ? themeColor : Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            
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
                    .padding(.top, 16)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image("potato")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        
                        Text("Welcome Back!")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(themeColor)
                            .multilineTextAlignment(.center)
                        
                        Text("Sign in to your ChorePal account")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                    
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
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 12)
                            }
                            .background(Color(.systemGray6))
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
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
                        
                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.gray)
                            
                            Button("Sign Up") {
                                authService.authState = .signUp
                            }
                            .foregroundColor(themeColor)
                            .fontWeight(.semibold)
                        }
                        .padding(.top, 20)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationBarHidden(true)
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
                    // Back Button
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
                    .padding(.top, 16)
                    
                    // Header
                    VStack(spacing: 16) {
                        Image("potato")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 6)
                        
                        Text("Welcome, Kid!")
                            .font(.system(size: 32, weight: .heavy))
                            .foregroundColor(themeColor)
                            .multilineTextAlignment(.center)
                        
                        Text("Enter your 4-digit PIN to start")
                            .font(.title3)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)
                    
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
                            .onChange(of: pin) { newValue in
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