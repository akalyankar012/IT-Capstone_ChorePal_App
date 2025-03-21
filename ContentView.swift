//
//  ContentView.swift
//  chorepal prototype
//
//  Created by rayyan khan on 3/10/25.
//

import SwiftUI

// Add Theme preference key
struct ThemePreferenceKey: PreferenceKey {
    static var defaultValue: ColorScheme = .light
    static func reduce(value: inout ColorScheme, nextValue: () -> ColorScheme) {
        value = nextValue()
    }
}

struct ContentView: View {
    @State private var selectedRole: UserRole?
    @StateObject private var choreModel = ChoreModel()
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var isImageAnimated = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background color
                Color(hex: "#a2cee3")
                    .opacity(colorScheme == .dark ? 0.05 : 0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // App Logo Image with error handling
                    Group {
                        if let uiImage = UIImage(named: "app_logo") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 180, height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                                .shadow(color: isDarkMode ? .white.opacity(0.1) : .gray.opacity(0.2), 
                                        radius: 10, x: 0, y: 5)
                                .scaleEffect(isImageAnimated ? 1.0 : 0.8)
                                .animation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0), 
                                         value: isImageAnimated)
                        } else {
                            Text("Loading Image...")
                                .frame(width: 180, height: 180)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 30))
                        }
                    }
                    .onAppear {
                        isImageAnimated = true
                    }
                    
                    Text("Welcome to")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#a2cee3"))
                    
                    Text("ChorePal!")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: "#a2cee3"))
                        .shadow(color: .white.opacity(0.5), radius: 2, x: 0, y: 2)
                        .scaleEffect(1.2)
                    
                    Text("I am a...")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.gray)
                        .padding(.top, 10)
                    
                    VStack(spacing: 20) {
                        RoleButton(role: .parent, isSelected: selectedRole == .parent) {
                            selectedRole = .parent
                        }
                        
                        RoleButton(role: .child, isSelected: selectedRole == .child) {
                            selectedRole = .child
                        }
                    }
                    .padding(.top, 10)
                    
                    if let role = selectedRole {
                        NavigationLink {
                            HomeView(userRole: role)
                                .environmentObject(choreModel)
                        } label: {
                            Text("Let's Go!")
                                .font(.system(.title2, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(hex: "#a2cee3"))
                                )
                                .padding(.horizontal, 40)
                                .padding(.top, 10)
                        }
                    }
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isDarkMode.toggle()
                        }
                    }) {
                        Image(systemName: isDarkMode ? "sun.max.fill" : "moon.fill")
                            .foregroundColor(isDarkMode ? .yellow : .primary)
                            .font(.system(size: 20))
                            .rotationEffect(.degrees(isDarkMode ? 0 : 180))
                            .scaleEffect(1.2)
                    }
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .animation(.easeInOut(duration: 0.3), value: isDarkMode)
    }
}

struct RoleButton: View {
    let role: UserRole
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: role == .parent ? "person.2.fill" : "person.fill")
                    .font(.system(size: 24))
                Text(role == .parent ? "Parent" : "Child")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
            }
            .foregroundColor(isSelected ? .white : Color(hex: "#a2cee3"))
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isSelected ? Color(hex: "#a2cee3") : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color(hex: "#a2cee3"), lineWidth: 2)
                    )
            )
            .padding(.horizontal, 40)
        }
    }
}

// Add this extension to handle press events
extension View {
    func pressEvents(onPress: @escaping () -> Void = {}, onRelease: @escaping () -> Void = {}) -> some View {
        self
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                if pressing {
                    onPress()
                } else {
                    onRelease()
                }
            }, perform: { })
    }
}

// Add Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    ContentView()
}
