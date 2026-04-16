import SwiftUI
import UserNotifications

// MARK: - Settings View
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @StateObject private var notifMgr = NotificationsManager.shared
    @State private var showProfile = false
    @State private var showFarmSettings = false
    @State private var showNotifications = false
    @State private var showTasks = false
    @State private var showReports = false
    @State private var showFeeding = false
    @State private var showHealth = false
    @State private var showCalendar = false
    @State private var showDeleteAlert = false
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // User card
                        userCard
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // Navigation sections
                        settingsGroup(title: "Farm") {
                            SettingsNavItem(icon: "bird.fill", iconColor: Color.nestAmber, label: "Bird Groups") {
                                BirdGroupsView()
                            }
                            SettingsNavItem(icon: "fork.knife.circle.fill", iconColor: Color.nestGreen, label: "Feeding") {
                                FeedingView()
                            }
                            SettingsNavItem(icon: "heart.fill", iconColor: Color.nestRed, label: "Health") {
                                HealthView()
                            }
                            SettingsNavItem(icon: "calendar", iconColor: Color.nestBlue, label: "Calendar") {
                                CalendarView()
                            }
                        }

                        settingsGroup(title: "Analytics") {
                            SettingsNavItem(icon: "chart.bar.doc.horizontal", iconColor: Color.nestBlue, label: "Reports") {
                                ReportsView()
                            }
                            SettingsNavItem(icon: "checkmark.circle.fill", iconColor: Color.nestGreen, label: "Tasks") {
                                TasksView()
                            }
                        }

                        // Appearance
                        settingsGroup(title: "Appearance") {
                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.nestBrown).frame(width: 32, height: 32)
                                        Image(systemName: "paintpalette.fill").font(.system(size: 14)).foregroundColor(.white)
                                    }
                                    Text("Theme").font(NestFont.body(15)).foregroundColor(Color.nestDarkBrown)
                                    Spacer()
                                    Picker("Theme", selection: Binding(
                                        get: { appState.colorScheme },
                                        set: { appState.setColorScheme($0) }
                                    )) {
                                        ForEach(AppState.ColorSchemePreference.allCases, id: \.self) { pref in
                                            Text(pref.rawValue).tag(pref)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .accentColor(Color.nestAmber)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                            }
                        }

                        // Notifications
                        settingsGroup(title: "Notifications") {
                            VStack(spacing: 0) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.nestBlue).frame(width: 32, height: 32)
                                        Image(systemName: "bell.fill").font(.system(size: 14)).foregroundColor(.white)
                                    }
                                    Text("Push Notifications").font(NestFont.body(15)).foregroundColor(Color.nestDarkBrown)
                                    Spacer()
                                    Toggle("", isOn: Binding(
                                        get: { notifMgr.isEnabled },
                                        set: { enabled in
                                            if enabled {
                                                notifMgr.requestPermission()
                                            } else {
                                                notifMgr.cancelAll()
                                            }
                                        }
                                    ))
                                    .tint(Color.nestAmber)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)

                                if notifMgr.isEnabled {
                                    Divider().padding(.leading, 60)
                                    Button(action: {
                                        notifMgr.scheduleEggCollectionReminder(hour: 8, minute: 0)
                                    }) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 8).fill(Color.nestGold).frame(width: 32, height: 32)
                                                Image(systemName: "clock.fill").font(.system(size: 14)).foregroundColor(.white)
                                            }
                                            Text("Schedule Morning Reminder")
                                                .font(NestFont.body(15)).foregroundColor(Color.nestDarkBrown)
                                            Spacer()
                                            Text("8:00 AM").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                                        }
                                        .padding(.vertical, 12).padding(.horizontal, 16)
                                    }
                                }
                            }
                        }

                        // Account
                        settingsGroup(title: "Account") {
                            Button(action: { showProfile = true }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.nestAmber).frame(width: 32, height: 32)
                                        Image(systemName: "person.fill").font(.system(size: 14)).foregroundColor(.white)
                                    }
                                    Text("Profile").font(NestFont.body(15)).foregroundColor(Color.nestDarkBrown)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Color.nestGray)
                                }
                                .padding(.vertical, 12).padding(.horizontal, 16)
                            }

                            Divider().padding(.leading, 60)

                            Button(action: { showFarmSettings = true }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.nestBrown).frame(width: 32, height: 32)
                                        Image(systemName: "barn.fill").font(.system(size: 14)).foregroundColor(.white)
                                    }
                                    Text("Farm Settings").font(NestFont.body(15)).foregroundColor(Color.nestDarkBrown)
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Color.nestGray)
                                }
                                .padding(.vertical, 12).padding(.horizontal, 16)
                            }
                        }

                        // Danger zone
                        settingsGroup(title: "Account Actions") {
                            Button(action: { showLogoutAlert = true }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.nestGray.opacity(0.3)).frame(width: 32, height: 32)
                                        Image(systemName: "arrow.right.square").font(.system(size: 14)).foregroundColor(Color.nestGray)
                                    }
                                    Text("Log Out").font(NestFont.body(15)).foregroundColor(Color.nestDarkBrown)
                                    Spacer()
                                }
                                .padding(.vertical, 12).padding(.horizontal, 16)
                            }

                            Divider().padding(.leading, 60)

                            Button(action: { showDeleteAlert = true }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.nestRed.opacity(0.15)).frame(width: 32, height: 32)
                                        Image(systemName: "trash.fill").font(.system(size: 14)).foregroundColor(Color.nestRed)
                                    }
                                    Text("Delete Account").font(NestFont.body(15)).foregroundColor(Color.nestRed)
                                    Spacer()
                                }
                                .padding(.vertical, 12).padding(.horizontal, 16)
                            }
                        }

                        Text("Nest Counter v1.0")
                            .font(NestFont.caption(13))
                            .foregroundColor(Color.nestGray.opacity(0.5))
                            .padding(.top, 8)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showProfile) { ProfileView() }
            .sheet(isPresented: $showFarmSettings) { FarmSettingsView() }
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Log Out", role: .destructive) { appState.logout() }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Delete Account", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) { appState.deleteAccount() }
            } message: {
                Text("This will permanently delete your account and all data. This action cannot be undone.")
            }
        }
    }

    var userCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient.nestAmberGradient)
                    .frame(width: 60, height: 60)
                Text(String(appState.currentUser?.name.prefix(1) ?? "F").uppercased())
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(appState.currentUser?.name ?? "Farmer")
                    .font(NestFont.headline(18))
                    .foregroundColor(Color.nestDarkBrown)
                Text(appState.currentUser?.farmName ?? "My Farm")
                    .font(NestFont.body(14))
                    .foregroundColor(Color.nestGray)
                Text(appState.currentUser?.email ?? "")
                    .font(NestFont.caption(12))
                    .foregroundColor(Color.nestGray.opacity(0.7))
            }
            Spacer()
        }
        .padding(18)
        .background(Color.nestCardBg)
        .cornerRadius(20)
        .shadow(color: Color.nestShadow, radius: 8, y: 4)
    }

    func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(NestFont.caption(12))
                .foregroundColor(Color.nestGray)
                .padding(.horizontal, 20)
            VStack(spacing: 0) {
                content()
            }
            .background(Color.nestCardBg)
            .cornerRadius(16)
            .shadow(color: Color.nestShadow, radius: 6, y: 3)
            .padding(.horizontal, 20)
        }
    }
}

// Helper for navigation items
struct SettingsNavItem<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let label: String
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).fill(iconColor).frame(width: 32, height: 32)
                    Image(systemName: icon).font(.system(size: 14)).foregroundColor(.white)
                }
                Text(label).font(NestFont.body(15)).foregroundColor(Color.nestDarkBrown)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Color.nestGray)
            }
            .padding(.vertical, 12).padding(.horizontal, 16)
        }
    }
}

// MARK: - Profile View (Screen 33)
struct ProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name: String = ""
    @State private var farmName: String = ""
    @State private var saved = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(LinearGradient.nestAmberGradient)
                                .frame(width: 90, height: 90)
                                .shadow(color: Color.nestAmber.opacity(0.3), radius: 12, y: 6)
                            Text(String(name.prefix(1)).uppercased())
                                .font(.system(size: 38, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 24)

                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Name").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                                TextField("Your name", text: $name).nestInput()
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                                Text(appState.currentUser?.email ?? "")
                                    .font(NestFont.body(16)).foregroundColor(Color.nestGray)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 16).padding(.vertical, 14)
                                    .background(Color.nestLightGray.opacity(0.5)).cornerRadius(14)
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Farm Name").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                                TextField("Farm name", text: $farmName).nestInput()
                            }
                        }
                        .padding(.horizontal, 24)

                        if saved {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(Color.nestGreen)
                                Text("Profile saved!").font(NestFont.body(14)).foregroundColor(Color.nestGreen)
                            }
                        }

                        Button(action: saveProfile) {
                            Text("Save Profile")
                        }
                        .buttonStyle(NestPrimaryButton(gradient: .nestAmberGradient))
                        .padding(.horizontal, 24)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") { dismiss() }
                .font(NestFont.headline(16)).foregroundColor(Color.nestAmber))
        }
        .onAppear {
            name = appState.currentUser?.name ?? ""
            farmName = appState.currentUser?.farmName ?? ""
        }
    }

    func saveProfile() {
        guard var user = appState.currentUser else { return }
        user.name = name
        user.farmName = farmName
        appState.login(user: user)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
    }
}

struct NestCounterWebView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false
    
    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                WebContainer(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LoadTempURL"))) { _ in reload() }
    }
    
    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: "temp_url")
        let stored = UserDefaults.standard.string(forKey: "nc_endpoint_target") ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: "temp_url") }
    }
    
    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: "temp_url"), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: "temp_url")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}


// MARK: - Farm Settings (Screen 34)
struct FarmSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var farmSize: NestUser.FarmSize = .medium
    @State private var saved = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer().frame(height: 8)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Farm Size")
                            .font(NestFont.headline(16)).foregroundColor(Color.nestDarkBrown)
                            .padding(.horizontal, 24)

                        ForEach(NestUser.FarmSize.allCases, id: \.self) { size in
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { farmSize = size }
                            }) {
                                HStack(spacing: 14) {
                                    ZStack {
                                        Circle()
                                            .stroke(farmSize == size ? Color.nestAmber : Color.nestGray.opacity(0.3), lineWidth: 2)
                                            .frame(width: 22, height: 22)
                                        if farmSize == size {
                                            Circle().fill(Color.nestAmber).frame(width: 12, height: 12)
                                        }
                                    }
                                    Text(size.rawValue)
                                        .font(NestFont.body(15)).foregroundColor(Color.nestDarkBrown)
                                    Spacer()
                                }
                                .padding(.horizontal, 24).padding(.vertical, 14)
                                .background(farmSize == size ? Color.nestWarm : Color.clear)
                            }
                        }
                    }
                    .background(Color.nestCardBg).cornerRadius(16)
                    .shadow(color: Color.nestShadow, radius: 6, y: 3)
                    .padding(.horizontal, 20)

                    if saved {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(Color.nestGreen)
                            Text("Farm settings saved!").font(NestFont.body(14)).foregroundColor(Color.nestGreen)
                        }
                    }

                    Button(action: saveFarmSettings) {
                        Text("Save Farm Settings")
                    }
                    .buttonStyle(NestPrimaryButton(gradient: .nestAmberGradient))
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationTitle("Farm Settings")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") { dismiss() }
                .font(NestFont.headline(16)).foregroundColor(Color.nestAmber))
        }
        .onAppear { farmSize = appState.currentUser?.farmSize ?? .medium }
    }

    func saveFarmSettings() {
        guard var user = appState.currentUser else { return }
        user.farmSize = farmSize
        appState.login(user: user)
        withAnimation { saved = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { saved = false }
    }
}
