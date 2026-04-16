import SwiftUI

// MARK: - Main App Tab View
struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView()
                    .tag(0)
                EggRecordsView()
                    .tag(1)
                PhotoCounterView()
                    .tag(2)
                ProductionStatsView()
                    .tag(3)
                SettingsView()
                    .tag(4)
            }
            .accentColor(Color.nestAmber)

            // Custom Tab Bar
            NestTabBar(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

struct UnavailableView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                Image("nest_ii_img")
                    .resizable().scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .ignoresSafeArea()
                    .blur(radius: 4)
                    .opacity(0.7)
                
                Image("nest_aa_img")
                    .resizable()
                    .frame(width: 250, height: 220)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Custom Tab Bar
struct NestTabBar: View {
    @Binding var selectedTab: Int

    let items: [(icon: String, label: String)] = [
        ("house.fill", "Home"),
        ("list.clipboard.fill", "Records"),
        ("camera.fill", "Camera"),
        ("chart.bar.fill", "Stats"),
        ("gearshape.fill", "Settings")
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items.indices, id: \.self) { i in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = i
                    }
                }) {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == i {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.nestGold.opacity(0.18))
                                    .frame(width: 46, height: 34)
                            }
                            if i == 2 {
                                // Camera tab special style
                                ZStack {
                                    Circle()
                                        .fill(selectedTab == 2 ? LinearGradient.nestAmberGradient : LinearGradient(colors: [Color.nestGray.opacity(0.3), Color.nestGray.opacity(0.2)], startPoint: .top, endPoint: .bottom))
                                        .frame(width: 50, height: 50)
                                        .shadow(color: selectedTab == 2 ? Color.nestGold.opacity(0.4) : .clear, radius: 8, y: 4)
                                        .offset(y: -8)
                                    Image(systemName: items[i].icon)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .offset(y: -8)
                                }
                            } else {
                                Image(systemName: items[i].icon)
                                    .font(.system(size: selectedTab == i ? 20 : 18, weight: selectedTab == i ? .bold : .medium))
                                    .foregroundColor(selectedTab == i ? Color.nestAmber : Color.nestGray)
                                    .scaleEffect(selectedTab == i ? 1.1 : 1.0)
                            }
                        }
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: selectedTab)

                        if i != 2 {
                            Text(items[i].label)
                                .font(.system(size: 10, weight: selectedTab == i ? .semibold : .medium, design: .rounded))
                                .foregroundColor(selectedTab == i ? Color.nestAmber : Color.nestGray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                }
                .buttonStyle(NestIconButton())
            }
        }
        .padding(.bottom, 24)
        .background(
            Color.nestCardBg
                .shadow(color: Color.nestShadow, radius: 12, y: -4)
        )
    }
}

// MARK: - Dashboard View
struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataVM: DataViewModel
    @State private var appeared = false
    @State private var showAlerts = false

    var stats: ProductionStats { dataVM.productionStats }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header
                        dashboardHeader
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // Today's summary card
                        todaySummaryCard
                            .padding(.horizontal, 20)

                        // Alerts banner
                        if !dataVM.alerts.isEmpty {
                            alertsBanner
                                .padding(.horizontal, 20)
                        }

                        // Quick stats row
                        quickStatsRow
                            .padding(.horizontal, 20)

                        // Bird groups
                        birdGroupsSection
                            .padding(.horizontal, 20)

                        // Recent records
                        recentRecordsSection
                            .padding(.horizontal, 20)

                        Spacer(minLength: 100)
                    }
                    .padding(.top, 4)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) { appeared = true }
        }
        .sheet(isPresented: $showAlerts) {
            AlertsView()
        }
    }

    var dashboardHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(NestFont.body(14))
                    .foregroundColor(Color.nestGray)
                Text(appState.currentUser?.farmName ?? "My Farm")
                    .font(NestFont.display(24))
                    .foregroundColor(Color.nestDarkBrown)
            }
            Spacer()
            Button(action: { showAlerts = true }) {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(Color.nestWarm)
                        .frame(width: 44, height: 44)
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.nestAmber)
                    if !dataVM.alerts.isEmpty {
                        Circle()
                            .fill(Color.nestRed)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Text("\(dataVM.alerts.count)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 4, y: -4)
                    }
                }
            }
        }
    }

    var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning 🌅"
        case 12..<17: return "Good afternoon ☀️"
        default: return "Good evening 🌙"
        }
    }

    var todaySummaryCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(LinearGradient.nestAmberGradient)
                .shadow(color: Color.nestAmber.opacity(0.4), radius: 16, y: 8)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Eggs")
                        .font(NestFont.caption(13))
                        .foregroundColor(.white.opacity(0.85))

                    Text("\(stats.todayTotal)")
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(NestFont.caption(13))
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
                .padding(.leading, 24)

                Spacer()

                VStack(alignment: .trailing, spacing: 12) {
                    Text("🥚")
                        .font(.system(size: 56))
                    Text("Score: \(stats.productivityScore)%")
                        .font(NestFont.caption(13))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                .padding(.trailing, 20)
                .padding(.vertical, 20)
            }
        }
        .frame(height: 140)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    var alertsBanner: some View {
        Button(action: { showAlerts = true }) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(Color.nestAmber)
                Text("\(dataVM.alerts.count) alert\(dataVM.alerts.count > 1 ? "s" : "") need attention")
                    .font(NestFont.caption(14))
                    .foregroundColor(Color.nestDarkBrown)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.nestGray)
            }
            .padding(14)
            .background(Color(hex: "#FFF5E0"))
            .cornerRadius(14)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.nestGold.opacity(0.4), lineWidth: 1))
        }
    }

    var quickStatsRow: some View {
        HStack(spacing: 12) {
            StatMiniCard(
                title: "This Week",
                value: "\(stats.weekTotal)",
                icon: "calendar.badge.clock",
                color: Color.nestBlue
            )
            StatMiniCard(
                title: "Avg/Day",
                value: String(format: "%.1f", stats.avgPerDay),
                icon: "chart.bar",
                color: Color.nestGreen
            )
            StatMiniCard(
                title: "Best Day",
                value: "\(stats.bestDay)",
                icon: "star.fill",
                color: Color.nestGold
            )
        }
    }

    var birdGroupsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bird Groups")
                    .font(NestFont.headline(18))
                    .foregroundColor(Color.nestDarkBrown)
                Spacer()
                NavigationLink(destination: BirdGroupsView()) {
                    Text("See All")
                        .font(NestFont.caption(14))
                        .foregroundColor(Color.nestAmber)
                }
            }

            if dataVM.birdGroups.isEmpty {
                Text("No bird groups yet. Add one!")
                    .font(NestFont.body(14))
                    .foregroundColor(Color.nestGray)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.nestLightGray)
                    .cornerRadius(14)
            } else {
                ForEach(dataVM.birdGroups.prefix(3)) { group in
                    BirdGroupRowCard(group: group)
                }
            }
        }
    }

    var recentRecordsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Records")
                    .font(NestFont.headline(18))
                    .foregroundColor(Color.nestDarkBrown)
                Spacer()
                NavigationLink(destination: EggRecordsView()) {
                    Text("See All")
                        .font(NestFont.caption(14))
                        .foregroundColor(Color.nestAmber)
                }
            }

            if dataVM.eggRecords.isEmpty {
                Text("No records yet.")
                    .font(NestFont.body(14))
                    .foregroundColor(Color.nestGray)
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .background(Color.nestLightGray)
                    .cornerRadius(14)
            } else {
                ForEach(dataVM.eggRecords.prefix(5)) { record in
                    EggRecordRowView(record: record)
                }
            }
        }
    }
}

// MARK: - Stat Mini Card
struct StatMiniCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .monospaced))
                .foregroundColor(Color.nestDarkBrown)
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Color.nestGray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.nestCardBg)
        .cornerRadius(16)
        .shadow(color: Color.nestShadow, radius: 6, y: 3)
    }
}

// MARK: - Bird Group Row Card
struct BirdGroupRowCard: View {
    let group: BirdGroup
    @EnvironmentObject var dataVM: DataViewModel

    var todayEggs: Int {
        let cal = Calendar.current
        return dataVM.eggRecords
            .filter { $0.birdGroupId == group.id && cal.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.count }
    }

    var body: some View {
        HStack(spacing: 14) {
            Text(group.birdType.icon)
                .font(.system(size: 28))
                .frame(width: 48, height: 48)
                .background(Color(hex: group.color).opacity(0.15))
                .cornerRadius(14)

            VStack(alignment: .leading, spacing: 3) {
                Text(group.name)
                    .font(NestFont.headline(15))
                    .foregroundColor(Color.nestDarkBrown)
                Text("\(group.count) \(group.birdType.rawValue)s")
                    .font(NestFont.body(13))
                    .foregroundColor(Color.nestGray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(todayEggs)")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.nestAmber)
                Text("today")
                    .font(NestFont.caption(11))
                    .foregroundColor(Color.nestGray)
            }
        }
        .padding(14)
        .background(Color.nestCardBg)
        .cornerRadius(16)
        .shadow(color: Color.nestShadow, radius: 6, y: 3)
    }
}

// MARK: - Egg Record Row
struct EggRecordRowView: View {
    let record: EggRecord

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(record.photoCount ? Color.nestAmber.opacity(0.15) : Color.nestGreen.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: record.photoCount ? "camera.fill" : "pencil")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(record.photoCount ? Color.nestAmber : Color.nestGreen)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(record.birdGroupName)
                    .font(NestFont.headline(14))
                    .foregroundColor(Color.nestDarkBrown)
                Text(record.dateFormatted)
                    .font(NestFont.body(12))
                    .foregroundColor(Color.nestGray)
            }

            Spacer()

            Text("\(record.count) 🥚")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color.nestDarkBrown)
        }
        .padding(12)
        .background(Color.nestCardBg)
        .cornerRadius(14)
        .shadow(color: Color.nestShadow, radius: 4, y: 2)
    }
}

// MARK: - Alerts View
struct AlertsView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        if dataVM.alerts.isEmpty {
                            VStack(spacing: 16) {
                                Text("✅")
                                    .font(.system(size: 52))
                                Text("No alerts!")
                                    .font(NestFont.headline(20))
                                    .foregroundColor(Color.nestDarkBrown)
                                Text("Your farm is running smoothly.")
                                    .font(NestFont.body(15))
                                    .foregroundColor(Color.nestGray)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)
                        } else {
                            ForEach(dataVM.alerts) { alert in
                                AlertCardView(alert: alert) {
                                    dataVM.dismissAlert(alert)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing: Button("Done") { dismiss() }
                .font(NestFont.headline(16))
                .foregroundColor(Color.nestAmber)
            )
        }
    }
}

struct AlertCardView: View {
    let alert: FarmAlert
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: alert.type.icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(alert.type.color)
                .frame(width: 44, height: 44)
                .background(alert.type.color.opacity(0.12))
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(NestFont.headline(14))
                    .foregroundColor(Color.nestDarkBrown)
                Text(alert.message)
                    .font(NestFont.body(13))
                    .foregroundColor(Color.nestGray)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.nestGray)
                    .padding(6)
                    .background(Color.nestLightGray)
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color.nestCardBg)
        .cornerRadius(16)
        .shadow(color: Color.nestShadow, radius: 6, y: 3)
    }
}
