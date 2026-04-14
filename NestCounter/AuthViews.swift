import SwiftUI

// MARK: - Welcome Screen
struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var eggFloat: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(hex: "#FDF6E3"), Color(hex: "#F5E6C8"), Color(hex: "#EDD5A0")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Decorative elements
                VStack {
                    HStack {
                        ForEach(0..<5, id: \.self) { i in
                            Text("🥚")
                                .font(.system(size: 20 + CGFloat(i * 4)))
                                .opacity(0.12 + Double(i) * 0.05)
                                .offset(y: eggFloat ? -8 : 8)
                                .animation(
                                    .easeInOut(duration: 1.8 + Double(i) * 0.3)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.2),
                                    value: eggFloat
                                )
                        }
                    }
                    .padding(.top, 60)
                    Spacer()
                }

                VStack(spacing: 0) {
                    Spacer()

                    // Hero
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient.nestGoldGradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: Color.nestGold.opacity(0.4), radius: 20, y: 8)

                            VStack(spacing: -4) {
                                Text("🥚")
                                    .font(.system(size: 36))
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        VStack(spacing: 8) {
                            Text("Nest Counter")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(Color.nestDarkBrown)
                            Text("Smart egg tracking for your farm")
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundColor(Color.nestBrown)
                        }
                    }

                    Spacer()

                    // Buttons
                    VStack(spacing: 14) {
                        // Demo button - prominent
                        Button(action: {
                            AuthViewModel().loginDemo(appState: appState)
                        }) {
                            HStack(spacing: 10) {
                                Text("🚀")
                                Text("Try Demo Account")
                                    .font(NestFont.headline(17))
                            }
                            .foregroundColor(.nestDarkBrown)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#F4C842"), Color(hex: "#FFE08A")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: Color.nestGold.opacity(0.5), radius: 10, y: 4)
                        }

                        Button(action: { showLogin = true }) {
                            Text("Log In")
                        }
                        .buttonStyle(NestPrimaryButton(gradient: .nestAmberGradient))

                        Button(action: { showRegister = true }) {
                            Text("Create Account")
                        }
                        .buttonStyle(NestSecondaryButton())
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 50)
                }
            }
            .onAppear { eggFloat = true }
            .sheet(isPresented: $showLogin) {
                LoginView()
            }
            .sheet(isPresented: $showRegister) {
                RegisterView()
            }
        }
    }
}

// MARK: - Login View
struct LoginView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = AuthViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.nestAmberGradient)
                                    .frame(width: 72, height: 72)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Text("Welcome back")
                                .font(NestFont.display(28))
                                .foregroundColor(Color.nestDarkBrown)
                            Text("Sign in to your farm account")
                                .font(NestFont.body(15))
                                .foregroundColor(Color.nestGray)
                        }
                        .padding(.top, 24)

                        // Demo quick login
                        Button(action: { vm.loginDemo(appState: appState) }) {
                            HStack(spacing: 10) {
                                Text("🚀")
                                Text("Quick Demo Login")
                                    .font(NestFont.headline(15))
                            }
                            .foregroundColor(Color.nestDarkBrown)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Color(hex: "#FFF5CC"))
                            .cornerRadius(14)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.nestGold, lineWidth: 1.5))
                        }
                        .padding(.horizontal, 24)

                        // Form
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                TextField("your@email.com", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .nestInput()
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                HStack {
                                    if showPassword {
                                        TextField("Password", text: $password)
                                    } else {
                                        SecureField("Password", text: $password)
                                    }
                                    Button(action: { showPassword.toggle() }) {
                                        Image(systemName: showPassword ? "eye.slash" : "eye")
                                            .foregroundColor(Color.nestGray)
                                    }
                                }
                                .nestInput()
                            }

                            if !vm.errorMessage.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text(vm.errorMessage)
                                }
                                .font(NestFont.caption(13))
                                .foregroundColor(.nestRed)
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Login btn
                        VStack(spacing: 14) {
                            if vm.isLoading {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(Color.nestAmber)
                            } else {
                                Button(action: {
                                    vm.login(appState: appState, email: email, password: password)
                                }) {
                                    Text("Log In")
                                }
                                .buttonStyle(NestPrimaryButton(gradient: .nestAmberGradient))
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarItems(leading: Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.nestDarkBrown)
            })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Register View
struct RegisterView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var vm = AuthViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.nestGreenGradient)
                                    .frame(width: 72, height: 72)
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Text("Create Account")
                                .font(NestFont.display(28))
                                .foregroundColor(Color.nestDarkBrown)
                            Text("Start tracking your farm today")
                                .font(NestFont.body(15))
                                .foregroundColor(Color.nestGray)
                        }
                        .padding(.top, 24)

                        // Form
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Name")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                TextField("Your name", text: $vm.nameField)
                                    .nestInput()
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                TextField("your@email.com", text: $vm.emailField)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .nestInput()
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                SecureField("Min. 6 characters", text: $vm.passwordField)
                                    .nestInput()
                            }

                            if !vm.errorMessage.isEmpty {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text(vm.errorMessage)
                                }
                                .font(NestFont.caption(13))
                                .foregroundColor(.nestRed)
                                .padding(.horizontal, 4)
                            }
                        }
                        .padding(.horizontal, 24)

                        VStack(spacing: 14) {
                            if vm.isLoading {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(Color.nestGreen)
                            } else {
                                Button(action: {
                                    vm.register(appState: appState)
                                }) {
                                    Text("Create Account")
                                }
                                .buttonStyle(NestPrimaryButton(gradient: .nestGreenGradient))
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarItems(leading: Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.nestDarkBrown)
            })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
