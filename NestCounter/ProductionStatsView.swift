import SwiftUI

// MARK: - Production Stats View (Screen 16)
struct ProductionStatsView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var selectedPeriod: StatsPeriod = .weekly

    enum StatsPeriod: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
    }

    var stats: ProductionStats { dataVM.productionStats }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Productivity Score Card
                        productivityScoreCard
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // Period Selector
                        Picker("Period", selection: $selectedPeriod) {
                            ForEach(StatsPeriod.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 20)
                        .tint(Color.nestAmber)

                        // Chart
                        switch selectedPeriod {
                        case .daily:
                            DailyProductionView()
                                .padding(.horizontal, 20)
                        case .weekly:
                            WeeklyProductionView()
                                .padding(.horizontal, 20)
                        case .monthly:
                            MonthlyProductionView()
                                .padding(.horizontal, 20)
                        }

                        // Summary stats
                        summaryGrid

                        // Feed Impact
                        NavigationLink(destination: FeedImpactView()) {
                            HStack(spacing: 14) {
                                Image(systemName: "fork.knife.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color.nestGreen)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Feed Impact Analysis")
                                        .font(NestFont.headline(15))
                                        .foregroundColor(Color.nestDarkBrown)
                                    Text("See how feeding affects production")
                                        .font(NestFont.body(13))
                                        .foregroundColor(Color.nestGray)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(Color.nestGray)
                            }
                            .padding(16)
                            .background(Color.nestCardBg)
                            .cornerRadius(16)
                            .shadow(color: Color.nestShadow, radius: 6, y: 3)
                        }
                        .padding(.horizontal, 20)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Production Stats")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    var productivityScoreCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: stats.productivityScore >= 80 ?
                        [Color(hex: "#4A8A2A"), Color(hex: "#6FAE4E")] :
                        [Color(hex: "#D4821A"), Color(hex: "#E8A020")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: (stats.productivityScore >= 80 ? Color.nestGreen : Color.nestAmber).opacity(0.4), radius: 16, y: 8)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Productivity Score")
                        .font(NestFont.caption(14))
                        .foregroundColor(.white.opacity(0.85))
                    Text("\(stats.productivityScore)")
                        .font(.system(size: 56, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        + Text("/100")
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    Text(stats.productivityScore >= 80 ? "Excellent! 🌟" : stats.productivityScore >= 60 ? "Good 👍" : "Needs attention ⚠️")
                        .font(NestFont.caption(13))
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                Spacer()
                // Circular progress
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 10)
                        .frame(width: 90, height: 90)
                    Circle()
                        .trim(from: 0, to: CGFloat(stats.productivityScore) / 100)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8, dampingFraction: 0.7), value: stats.productivityScore)
                    Text("\(stats.productivityScore)%")
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            .padding(24)
        }
        .frame(height: 150)
    }

    var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            SummaryStatCard(title: "Today", value: "\(stats.todayTotal)", unit: "eggs", icon: "sun.max.fill", color: Color.nestGold)
            SummaryStatCard(title: "This Week", value: "\(stats.weekTotal)", unit: "eggs", icon: "calendar", color: Color.nestBlue)
            SummaryStatCard(title: "This Month", value: "\(stats.monthTotal)", unit: "eggs", icon: "calendar.badge.clock", color: Color.nestGreen)
            SummaryStatCard(title: "Daily Avg", value: String(format: "%.1f", stats.avgPerDay), unit: "eggs/day", icon: "chart.bar", color: Color.nestAmber)
        }
        .padding(.horizontal, 20)
    }
}

struct SummaryStatCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
                Text(title)
                    .font(NestFont.caption(12))
                    .foregroundColor(Color.nestGray)
            }
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(Color.nestDarkBrown)
            Text(unit)
                .font(NestFont.caption(11))
                .foregroundColor(Color.nestGray)
        }
        .padding(16)
        .background(Color.nestCardBg)
        .cornerRadius(18)
        .shadow(color: Color.nestShadow, radius: 6, y: 3)
    }
}

// MARK: - Bar Chart Component
struct NestBarChart: View {
    let data: [(label: String, value: Int)]
    let color: Color
    var maxValue: Int {
        max(data.map { $0.value }.max() ?? 1, 1)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(data.indices, id: \.self) { i in
                    VStack(spacing: 4) {
                        Text("\(data[i].value)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.nestGray)
                            .opacity(data[i].value > 0 ? 1 : 0)

                        GeometryReader { geo in
                            VStack {
                                Spacer()
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [color.opacity(0.8), color],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(height: data[i].value > 0 ? max(4, geo.size.height * CGFloat(data[i].value) / CGFloat(maxValue)) : 4)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.05), value: data[i].value)
                            }
                        }

                        Text(data[i].label)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(Color.nestGray)
                            .lineLimit(1)
                    }
                }
            }
            .frame(height: 160)
        }
        .padding(16)
        .background(Color.nestCardBg)
        .cornerRadius(20)
        .shadow(color: Color.nestShadow, radius: 8, y: 4)
    }
}

// MARK: - Daily Production (Screen 17)
struct DailyProductionView: View {
    @EnvironmentObject var dataVM: DataViewModel

    var todayByGroup: [(label: String, value: Int)] {
        dataVM.birdGroups.map { group in
            let cal = Calendar.current
            let count = dataVM.eggRecords
                .filter { $0.birdGroupId == group.id && cal.isDateInToday($0.date) }
                .reduce(0) { $0 + $1.count }
            return (label: group.name, value: count)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today by Group")
                .font(NestFont.headline(16))
                .foregroundColor(Color.nestDarkBrown)
            if todayByGroup.isEmpty || todayByGroup.allSatisfy({ $0.value == 0 }) {
                Text("No data for today yet")
                    .font(NestFont.body(14))
                    .foregroundColor(Color.nestGray)
                    .frame(maxWidth: .infinity)
                    .padding(30)
                    .background(Color.nestCardBg)
                    .cornerRadius(20)
            } else {
                NestBarChart(data: todayByGroup, color: Color.nestAmber)
            }
        }
    }
}

// MARK: - Weekly Production (Screen 18)
struct WeeklyProductionView: View {
    @EnvironmentObject var dataVM: DataViewModel

    var weekData: [(label: String, value: Int)] {
        dataVM.productionStats.weeklyData.map { (label: $0.label, value: $0.count) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(NestFont.headline(16))
                .foregroundColor(Color.nestDarkBrown)
            NestBarChart(data: weekData, color: Color.nestAmber)
        }
    }
}

// MARK: - Monthly Production (Screen 19)
struct MonthlyProductionView: View {
    @EnvironmentObject var dataVM: DataViewModel

    var monthData: [(label: String, value: Int)] {
        dataVM.productionStats.monthlyData.map { (label: $0.label, value: $0.count) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 4 Weeks")
                .font(NestFont.headline(16))
                .foregroundColor(Color.nestDarkBrown)
            NestBarChart(data: monthData, color: Color.nestBlue)
        }
    }
}

// MARK: - Feed Impact (Screen 20)
struct FeedImpactView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var selectedGroupId: String = ""

    var body: some View {
        ZStack {
            Color.nestCream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Group picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select Bird Group")
                            .font(NestFont.headline(16))
                            .foregroundColor(Color.nestDarkBrown)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(dataVM.birdGroups) { group in
                                    Button(action: { selectedGroupId = group.id }) {
                                        HStack(spacing: 6) {
                                            Text(group.birdType.icon)
                                            Text(group.name).font(NestFont.caption(13))
                                        }
                                        .foregroundColor(selectedGroupId == group.id ? .white : Color.nestDarkBrown)
                                        .padding(.horizontal, 14).padding(.vertical, 10)
                                        .background(selectedGroupId == group.id ? AnyView(LinearGradient.nestGreenGradient) : AnyView(Color.nestLightGray))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    if !selectedGroupId.isEmpty {
                        let impact = dataVM.feedImpactForGroup(selectedGroupId)

                        // Feed chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Feed Amount (kg)")
                                .font(NestFont.headline(15))
                                .foregroundColor(Color.nestDarkBrown)
                            NestBarChart(
                                data: impact.map {
                                    let f = DateFormatter()
                                    f.dateFormat = "EE"
                                    return (label: f.string(from: $0.date), value: Int($0.feedKg * 10))
                                },
                                color: Color.nestGreen
                            )
                        }
                        .padding(.horizontal, 20)

                        // Eggs chart
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Egg Production")
                                .font(NestFont.headline(15))
                                .foregroundColor(Color.nestDarkBrown)
                            NestBarChart(
                                data: impact.map {
                                    let f = DateFormatter()
                                    f.dateFormat = "EE"
                                    return (label: f.string(from: $0.date), value: $0.eggs)
                                },
                                color: Color.nestAmber
                            )
                        }
                        .padding(.horizontal, 20)

                        // Correlation note
                        HStack(spacing: 12) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(Color.nestGold)
                                .font(.system(size: 20))
                            Text("Higher feed amounts typically correlate with better egg production. Maintain consistent feeding schedules for optimal results.")
                                .font(NestFont.body(13))
                                .foregroundColor(Color.nestDarkBrown)
                                .lineSpacing(3)
                        }
                        .padding(16)
                        .background(Color(hex: "#FFF5CC"))
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    } else {
                        Text("Select a group to see feed impact analysis")
                            .font(NestFont.body(15))
                            .foregroundColor(Color.nestGray)
                            .frame(maxWidth: .infinity)
                            .padding(40)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Feed Impact")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if selectedGroupId.isEmpty, let first = dataVM.birdGroups.first {
                selectedGroupId = first.id
            }
        }
    }
}
