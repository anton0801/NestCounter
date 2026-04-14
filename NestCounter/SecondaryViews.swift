import SwiftUI

// MARK: - Feeding View (Screen 21)
struct FeedingView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                if dataVM.feedRecords.isEmpty {
                    EmptyStateView(icon: "fork.knife", title: "No Feed Records", message: "Start tracking feed to analyze production impact")
                } else {
                    List {
                        ForEach(dataVM.feedRecords) { record in
                            FeedRecordRow(record: record)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { i in
                                dataVM.deleteFeedRecord(dataVM.feedRecords[i])
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Feeding")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(Color.nestAmber)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddFeedRecordView()
            }
        }
    }
}

struct FeedRecordRow: View {
    let record: FeedRecord
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.nestGreen.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: "fork.knife").font(.system(size: 18, weight: .semibold)).foregroundColor(Color.nestGreen)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(record.birdGroupName).font(NestFont.headline(14)).foregroundColor(Color.nestDarkBrown)
                Text(record.feedType.rawValue).font(NestFont.body(12)).foregroundColor(Color.nestGray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(String(format: "%.1f kg", record.amountKg)).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(Color.nestGreen)
                Text(record.date.formatted(date: .abbreviated, time: .omitted)).font(NestFont.caption(11)).foregroundColor(Color.nestGray)
            }
        }
        .padding(12).background(Color.nestCardBg).cornerRadius(14).shadow(color: Color.nestShadow, radius: 4, y: 2)
    }
}

// MARK: - Add Feed Record (Screen 22)
struct AddFeedRecordView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedGroupId = ""
    @State private var feedType: FeedRecord.FeedType = .layer
    @State private var amount: Double = 2.0
    @State private var date = Date()
    @State private var notes = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        // Group
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bird Group").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            Picker("Bird Group", selection: $selectedGroupId) {
                                Text("Select group").tag("")
                                ForEach(dataVM.birdGroups) { g in Text(g.name).tag(g.id) }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .background(Color.nestLightGray).cornerRadius(14).accentColor(Color.nestAmber)
                        }

                        // Feed type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Feed Type").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(FeedRecord.FeedType.allCases, id: \.self) { type in
                                    Button(action: { feedType = type }) {
                                        Text(type.rawValue).font(NestFont.caption(13))
                                            .foregroundColor(feedType == type ? .white : Color.nestDarkBrown)
                                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                                            .background(feedType == type ? AnyView(LinearGradient.nestGreenGradient) : AnyView(Color.nestLightGray))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        // Amount
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Amount (kg)").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                                Spacer()
                                Text(String(format: "%.1f kg", amount)).font(.system(size: 16, weight: .bold, design: .monospaced)).foregroundColor(Color.nestGreen)
                            }
                            Slider(value: $amount, in: 0.1...20.0, step: 0.1)
                                .tint(Color.nestGreen)
                        }

                        // Date
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Date").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Color.nestLightGray).cornerRadius(14).accentColor(Color.nestAmber)
                        }

                        // Notes
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            TextField("Optional notes", text: $notes).nestInput()
                        }

                        Button(action: saveRecord) {
                            Text("Save Feed Record")
                        }
                        .buttonStyle(NestPrimaryButton(gradient: .nestGreenGradient))
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Add Feed Record")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() }.foregroundColor(Color.nestGray))
        }
        .onAppear { if let f = dataVM.birdGroups.first { selectedGroupId = f.id } }
    }

    func saveRecord() {
        guard !selectedGroupId.isEmpty else { return }
        let groupName = dataVM.birdGroups.first { $0.id == selectedGroupId }?.name ?? ""
        dataVM.addFeedRecord(FeedRecord(id: UUID().uuidString, birdGroupId: selectedGroupId, birdGroupName: groupName, feedType: feedType, amountKg: amount, date: date, notes: notes))
        dismiss()
    }
}

// MARK: - Health View (Screen 23)
struct HealthView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false
    @State private var showResolved = false

    var visibleRecords: [HealthRecord] {
        showResolved ? dataVM.healthRecords : dataVM.healthRecords.filter { !$0.resolved }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                VStack(spacing: 0) {
                    Toggle("Show Resolved", isOn: $showResolved)
                        .font(NestFont.body(14))
                        .tint(Color.nestGreen)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)

                    if visibleRecords.isEmpty {
                        EmptyStateView(icon: "heart.fill", title: showResolved ? "No Records" : "All Clear! ✅", message: showResolved ? "No health records yet" : "No active health issues")
                    } else {
                        List {
                            ForEach(visibleRecords) { record in
                                HealthRecordRow(record: record)
                                    .listRowBackground(Color.clear).listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { i in dataVM.deleteHealthRecord(visibleRecords[i]) }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle("Health")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(Color.nestAmber)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddHealthRecordView() }
        }
    }
}

struct HealthRecordRow: View {
    let record: HealthRecord
    @EnvironmentObject var dataVM: DataViewModel

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(record.resolved ? Color.nestGreen.opacity(0.12) : Color.nestRed.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: record.issue.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(record.resolved ? Color.nestGreen : Color.nestRed)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(record.issue.rawValue).font(NestFont.headline(14)).foregroundColor(Color.nestDarkBrown)
                Text(record.birdGroupName).font(NestFont.body(12)).foregroundColor(Color.nestGray)
                if !record.treatment.isEmpty {
                    Text("Treatment: \(record.treatment)").font(NestFont.caption(11)).foregroundColor(Color.nestBlue)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(record.resolved ? "Resolved" : "Active")
                    .font(NestFont.caption(11))
                    .foregroundColor(record.resolved ? Color.nestGreen : Color.nestRed)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background((record.resolved ? Color.nestGreen : Color.nestRed).opacity(0.1))
                    .cornerRadius(8)
                Button(action: { dataVM.toggleHealthResolved(record) }) {
                    Text(record.resolved ? "Reopen" : "Resolve")
                        .font(NestFont.caption(12))
                        .foregroundColor(record.resolved ? Color.nestAmber : Color.nestGreen)
                }
            }
        }
        .padding(12).background(Color.nestCardBg).cornerRadius(14).shadow(color: Color.nestShadow, radius: 4, y: 2)
    }
}

// MARK: - Add Health Record (Screen 24)
struct AddHealthRecordView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedGroupId = ""
    @State private var issue: HealthRecord.HealthIssue = .disease
    @State private var treatment = ""
    @State private var notes = ""
    @State private var date = Date()

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Bird Group").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            Picker("Bird Group", selection: $selectedGroupId) {
                                Text("Select group").tag("")
                                ForEach(dataVM.birdGroups) { g in Text(g.name).tag(g.id) }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .padding(.horizontal, 16).padding(.vertical, 14)
                            .background(Color.nestLightGray).cornerRadius(14).accentColor(Color.nestAmber)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Issue Type").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                ForEach(HealthRecord.HealthIssue.allCases, id: \.self) { iss in
                                    Button(action: { issue = iss }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: iss.icon).font(.system(size: 12))
                                            Text(iss.rawValue).font(NestFont.caption(12))
                                        }
                                        .foregroundColor(issue == iss ? .white : Color.nestDarkBrown)
                                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                                        .background(issue == iss ? AnyView(LinearGradient(colors: [Color.nestSoftRed, Color.nestRed], startPoint: .leading, endPoint: .trailing)) : AnyView(Color.nestLightGray))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Treatment").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            TextField("Treatment plan...", text: $treatment).nestInput()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Notes").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            TextField("Additional notes", text: $notes).nestInput()
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Date").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Color.nestLightGray).cornerRadius(14).accentColor(Color.nestAmber)
                        }

                        Button(action: saveRecord) {
                            Text("Save Health Record")
                        }
                        .buttonStyle(NestPrimaryButton(gradient: LinearGradient(colors: [Color.nestSoftRed, Color.nestRed], startPoint: .leading, endPoint: .trailing)))
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(20).padding(.top, 8)
                }
            }
            .navigationTitle("Add Health Record")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() }.foregroundColor(Color.nestGray))
        }
        .onAppear { if let f = dataVM.birdGroups.first { selectedGroupId = f.id } }
    }

    func saveRecord() {
        guard !selectedGroupId.isEmpty else { return }
        let groupName = dataVM.birdGroups.first { $0.id == selectedGroupId }?.name ?? ""
        dataVM.addHealthRecord(HealthRecord(id: UUID().uuidString, birdGroupId: selectedGroupId, birdGroupName: groupName, issue: issue, treatment: treatment, date: date, resolved: false, notes: notes))
        dismiss()
    }
}

// MARK: - Calendar View (Screen 25)
struct CalendarView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var currentMonth = Date()
    @State private var selectedDate: Date? = nil

    var selectedEggs: Int {
        guard let d = selectedDate else { return 0 }
        return dataVM.eggsForDate(d)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Month header
                        HStack {
                            Button(action: { changeMonth(-1) }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 28)).foregroundColor(Color.nestAmber)
                            }
                            Spacer()
                            Text(monthYearString(from: currentMonth))
                                .font(NestFont.display(20))
                                .foregroundColor(Color.nestDarkBrown)
                            Spacer()
                            Button(action: { changeMonth(1) }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 28)).foregroundColor(Color.nestAmber)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        // Day headers
                        HStack {
                            ForEach(["Mo","Tu","We","Th","Fr","Sa","Su"], id: \.self) { d in
                                Text(d).font(NestFont.caption(12)).foregroundColor(Color.nestGray).frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Calendar grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                            ForEach(calendarDays(), id: \.self) { date in
                                CalendarDayCell(
                                    date: date,
                                    isCurrentMonth: Calendar.current.isDate(date, equalTo: currentMonth, toGranularity: .month),
                                    isSelected: selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false,
                                    eggCount: dataVM.eggsForDate(date)
                                ) {
                                    selectedDate = date
                                }
                            }
                        }
                        .padding(.horizontal, 12)

                        // Selected day detail
                        if let selected = selectedDate {
                            VStack(spacing: 12) {
                                HStack {
                                    Text(selected.formatted(date: .complete, time: .omitted))
                                        .font(NestFont.headline(15))
                                        .foregroundColor(Color.nestDarkBrown)
                                    Spacer()
                                }
                                HStack {
                                    Text("Total Eggs:")
                                        .font(NestFont.body(15)).foregroundColor(Color.nestGray)
                                    Spacer()
                                    Text("\(selectedEggs) 🥚")
                                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.nestAmber)
                                }

                                let dayRecords = dataVM.eggRecords.filter {
                                    Calendar.current.isDate($0.date, inSameDayAs: selected)
                                }
                                ForEach(dayRecords) { r in
                                    HStack {
                                        Text(r.birdGroupName).font(NestFont.body(13)).foregroundColor(Color.nestDarkBrown)
                                        Spacer()
                                        Text("\(r.count) eggs").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                                    }
                                }
                            }
                            .padding(16).background(Color.nestCardBg).cornerRadius(16)
                            .shadow(color: Color.nestShadow, radius: 6, y: 3)
                            .padding(.horizontal, 20)
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    func changeMonth(_ delta: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: delta, to: currentMonth) ?? currentMonth
        }
    }

    func monthYearString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    func calendarDays() -> [Date] {
        let cal = Calendar.current
        let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: currentMonth))!
        var weekday = cal.component(.weekday, from: firstDay) - 2
        if weekday < 0 { weekday += 7 }
        let start = cal.date(byAdding: .day, value: -weekday, to: firstDay)!
        return (0..<42).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }
}

struct CalendarDayCell: View {
    let date: Date
    let isCurrentMonth: Bool
    let isSelected: Bool
    let eggCount: Int
    let action: () -> Void

    var isToday: Bool { Calendar.current.isDateInToday(date) }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 14, weight: isSelected || isToday ? .bold : .regular, design: .rounded))
                    .foregroundColor(
                        isSelected ? .white :
                        isToday ? Color.nestAmber :
                        isCurrentMonth ? Color.nestDarkBrown : Color.nestGray.opacity(0.4)
                    )
                if eggCount > 0 {
                    Circle()
                        .fill(isSelected ? Color.white : Color.nestGold)
                        .frame(width: 6, height: 6)
                } else {
                    Circle().fill(Color.clear).frame(width: 6, height: 6)
                }
            }
            .frame(width: 38, height: 42)
            .background(
                Group {
                    if isSelected {
                        AnyView(RoundedRectangle(cornerRadius: 12).fill(LinearGradient.nestAmberGradient))
                    } else if isToday {
                        AnyView(RoundedRectangle(cornerRadius: 12).stroke(Color.nestAmber, lineWidth: 2))
                    } else {
                        AnyView(Color.clear)
                    }
                }
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Reports View (Screen 27)
struct ReportsView: View {
    @EnvironmentObject var dataVM: DataViewModel

    var stats: ProductionStats { dataVM.productionStats }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Summary
                        reportCard(title: "Production Summary", icon: "chart.bar.doc.horizontal", color: Color.nestAmber) {
                            VStack(spacing: 12) {
                                reportRow("Today", "\(stats.todayTotal) eggs")
                                reportRow("This Week", "\(stats.weekTotal) eggs")
                                reportRow("This Month", "\(stats.monthTotal) eggs")
                                reportRow("Daily Average", String(format: "%.1f eggs", stats.avgPerDay))
                                reportRow("Best Day", "\(stats.bestDay) eggs")
                                reportRow("Productivity Score", "\(stats.productivityScore)/100")
                            }
                        }

                        reportCard(title: "Flock Overview", icon: "bird", color: Color.nestGreen) {
                            VStack(spacing: 12) {
                                reportRow("Total Groups", "\(dataVM.birdGroups.count)")
                                reportRow("Total Birds", "\(dataVM.birdGroups.reduce(0) { $0 + $1.count })")
                                reportRow("Egg Records", "\(dataVM.eggRecords.count)")
                                reportRow("Feed Records", "\(dataVM.feedRecords.count)")
                                reportRow("Active Health Issues", "\(dataVM.healthRecords.filter { !$0.resolved }.count)")
                            }
                        }

                        reportCard(title: "Group Breakdown", icon: "square.grid.2x2", color: Color.nestBlue) {
                            ForEach(dataVM.birdGroups) { group in
                                let cal = Calendar.current
                                let week = cal.date(byAdding: .day, value: -7, to: Date())!
                                let weekEggs = dataVM.eggRecords.filter {
                                    $0.birdGroupId == group.id && $0.date >= week
                                }.reduce(0) { $0 + $1.count }
                                HStack {
                                    Text(group.birdType.icon + " " + group.name)
                                        .font(NestFont.body(14)).foregroundColor(Color.nestDarkBrown)
                                    Spacer()
                                    Text("\(weekEggs) eggs/wk")
                                        .font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                                }
                            }
                        }

                        NavigationLink(destination: ActivityHistoryView()) {
                            HStack(spacing: 14) {
                                Image(systemName: "clock.arrow.circlepath").font(.system(size: 24)).foregroundColor(Color.nestBlue)
                                Text("Activity History").font(NestFont.headline(15)).foregroundColor(Color.nestDarkBrown)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(Color.nestGray)
                            }
                            .padding(16).background(Color.nestCardBg).cornerRadius(16).shadow(color: Color.nestShadow, radius: 6, y: 3)
                        }

                        NavigationLink(destination: ProductivityScoreView()) {
                            HStack(spacing: 14) {
                                Image(systemName: "star.fill").font(.system(size: 24)).foregroundColor(Color.nestGold)
                                Text("Productivity Score").font(NestFont.headline(15)).foregroundColor(Color.nestDarkBrown)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(Color.nestGray)
                            }
                            .padding(16).background(Color.nestCardBg).cornerRadius(16).shadow(color: Color.nestShadow, radius: 6, y: 3)
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    func reportCard<Content: View>(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 18, weight: .semibold)).foregroundColor(color)
                Text(title).font(NestFont.headline(16)).foregroundColor(Color.nestDarkBrown)
            }
            content()
        }
        .padding(18).background(Color.nestCardBg).cornerRadius(20).shadow(color: Color.nestShadow, radius: 8, y: 4)
    }

    func reportRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(NestFont.body(14)).foregroundColor(Color.nestGray)
            Spacer()
            Text(value).font(.system(size: 14, weight: .semibold, design: .monospaced)).foregroundColor(Color.nestDarkBrown)
        }
    }
}

// MARK: - Productivity Score View (Screen 28)
struct ProductivityScoreView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var animateScore = false

    var score: Int { dataVM.productionStats.productivityScore }

    var body: some View {
        ZStack {
            Color.nestCream.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Big circle score
                    ZStack {
                        Circle().stroke(Color.nestLightGray, lineWidth: 16).frame(width: 200, height: 200)
                        Circle()
                            .trim(from: 0, to: animateScore ? CGFloat(score) / 100 : 0)
                            .stroke(score >= 80 ? LinearGradient.nestGreenGradient : LinearGradient.nestAmberGradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animateScore)
                        VStack(spacing: 4) {
                            Text("\(score)")
                                .font(.system(size: 64, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.nestDarkBrown)
                            Text("/ 100")
                                .font(NestFont.body(16)).foregroundColor(Color.nestGray)
                        }
                    }
                    .padding(.top, 24)

                    Text(score >= 80 ? "Excellent Performance! 🌟" : score >= 60 ? "Good Performance 👍" : "Needs Improvement ⚠️")
                        .font(NestFont.headline(18)).foregroundColor(Color.nestDarkBrown)

                    // Score breakdown
                    VStack(spacing: 12) {
                        ScoreFactorRow(label: "Production Rate", value: min(100, score + 5), color: Color.nestAmber)
                        ScoreFactorRow(label: "Consistency", value: max(0, score - 10), color: Color.nestBlue)
                        ScoreFactorRow(label: "Health Status", value: dataVM.healthRecords.filter { !$0.resolved }.isEmpty ? 100 : 60, color: Color.nestGreen)
                        ScoreFactorRow(label: "Feed Compliance", value: dataVM.feedRecords.isEmpty ? 50 : 85, color: Color.nestBrown)
                    }
                    .padding(20).background(Color.nestCardBg).cornerRadius(20).shadow(color: Color.nestShadow, radius: 8, y: 4)
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle("Productivity Score")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { animateScore = true } }
    }
}

struct ScoreFactorRow: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(NestFont.body(14)).foregroundColor(Color.nestDarkBrown)
                Spacer()
                Text("\(value)%").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.nestLightGray).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100.0, height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: value)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Activity History (Screen 29)
struct ActivityHistoryView: View {
    @EnvironmentObject var dataVM: DataViewModel

    var allActivities: [(date: Date, icon: String, title: String, subtitle: String, color: Color)] {
        var activities: [(date: Date, icon: String, title: String, subtitle: String, color: Color)] = []
        for r in dataVM.eggRecords.prefix(20) {
            activities.append((r.date, "basket.fill", "Egg Collection", "\(r.count) eggs from \(r.birdGroupName)", Color.nestAmber))
        }
        for r in dataVM.feedRecords.prefix(10) {
            activities.append((r.date, "fork.knife", "Feeding", "\(String(format: "%.1f", r.amountKg))kg for \(r.birdGroupName)", Color.nestGreen))
        }
        for r in dataVM.healthRecords.prefix(10) {
            activities.append((r.date, r.issue.icon, "Health: \(r.issue.rawValue)", r.birdGroupName, Color.nestRed))
        }
        return activities.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Color.nestCream.ignoresSafeArea()
            if allActivities.isEmpty {
                EmptyStateView(icon: "clock", title: "No Activity", message: "Activity will appear as you use the app")
            } else {
                List {
                    ForEach(allActivities.indices, id: \.self) { i in
                        let act = allActivities[i]
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(act.color.opacity(0.15)).frame(width: 40, height: 40)
                                Image(systemName: act.icon).font(.system(size: 16)).foregroundColor(act.color)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(act.title).font(NestFont.headline(13)).foregroundColor(Color.nestDarkBrown)
                                Text(act.subtitle).font(NestFont.body(12)).foregroundColor(Color.nestGray)
                            }
                            Spacer()
                            Text(act.date.formatted(date: .abbreviated, time: .omitted))
                                .font(NestFont.caption(11)).foregroundColor(Color.nestGray)
                        }
                        .listRowBackground(Color.clear).listRowSeparator(.hidden)
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Activity History")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Tasks View (Screen 31)
struct TasksView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false

    var pendingTasks: [FarmTask] { dataVM.tasks.filter { !$0.isCompleted } }
    var completedTasks: [FarmTask] { dataVM.tasks.filter { $0.isCompleted } }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        if !pendingTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Pending (\(pendingTasks.count))")
                                    .font(NestFont.headline(16)).foregroundColor(Color.nestDarkBrown)
                                    .padding(.horizontal, 16).padding(.top, 16)
                                ForEach(pendingTasks) { task in
                                    TaskRow(task: task)
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        if !completedTasks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Completed (\(completedTasks.count))")
                                    .font(NestFont.headline(16)).foregroundColor(Color.nestGray)
                                    .padding(.horizontal, 16).padding(.top, 20)
                                ForEach(completedTasks) { task in
                                    TaskRow(task: task)
                                        .padding(.horizontal, 16)
                                        .opacity(0.6)
                                }
                            }
                        }
                        if dataVM.tasks.isEmpty {
                            EmptyStateView(icon: "checkmark.circle", title: "No Tasks", message: "Add tasks to stay organised")
                        }
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill").font(.system(size: 22)).foregroundColor(Color.nestAmber)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddTaskView() }
        }
    }
}

struct TaskRow: View {
    let task: FarmTask
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showDelete = false

    var isOverdue: Bool { !task.isCompleted && task.dueDate < Date() }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { dataVM.toggleTask(task) } }) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(task.isCompleted ? Color.nestGreen : Color.nestGray.opacity(0.4))
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: task.isCompleted)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(NestFont.headline(14))
                    .foregroundColor(task.isCompleted ? Color.nestGray : Color.nestDarkBrown)
                    .strikethrough(task.isCompleted)
                HStack(spacing: 6) {
                    Image(systemName: task.category.icon).font(.system(size: 10))
                    Text(task.dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(NestFont.caption(12))
                }
                .foregroundColor(isOverdue ? Color.nestRed : Color.nestGray)
            }

            Spacer()

            // Priority badge
            Text(task.priority.rawValue)
                .font(NestFont.caption(10))
                .foregroundColor(Color(hex: task.priority.color))
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(Color(hex: task.priority.color).opacity(0.12))
                .cornerRadius(6)
        }
        .padding(12).background(Color.nestCardBg).cornerRadius(14).shadow(color: Color.nestShadow, radius: 4, y: 2)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) { dataVM.deleteTask(task) } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Add Task (Screen 32)
struct AddTaskView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var dueDate = Date().addingTimeInterval(3600)
    @State private var priority: FarmTask.Priority = .medium
    @State private var category: FarmTask.TaskCategory = .collect
    @State private var showValidation = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Task Title").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            TextField("e.g. Collect eggs from Layers A", text: $title).nestInput()
                            if showValidation && title.isEmpty {
                                Text("Title is required").font(NestFont.caption(12)).foregroundColor(Color.nestRed)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(FarmTask.TaskCategory.allCases, id: \.self) { cat in
                                        Button(action: { category = cat }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: cat.icon).font(.system(size: 12))
                                                Text(cat.rawValue).font(NestFont.caption(12))
                                            }
                                            .foregroundColor(category == cat ? .white : Color.nestDarkBrown)
                                            .padding(.horizontal, 12).padding(.vertical, 9)
                                            .background(category == cat ? AnyView(LinearGradient.nestAmberGradient) : AnyView(Color.nestLightGray))
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Priority").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            HStack(spacing: 10) {
                                ForEach(FarmTask.Priority.allCases, id: \.self) { p in
                                    Button(action: { priority = p }) {
                                        Text(p.rawValue).font(NestFont.caption(13))
                                            .foregroundColor(priority == p ? .white : Color(hex: p.color))
                                            .frame(maxWidth: .infinity).padding(.vertical, 10)
                                            .background(priority == p ? AnyView(Color(hex: p.color)) : AnyView(Color(hex: p.color).opacity(0.1)))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Due Date & Time").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                            DatePicker("", selection: $dueDate)
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(Color.nestLightGray).cornerRadius(14).accentColor(Color.nestAmber)
                        }

                        Button(action: saveTask) {
                            Text("Add Task")
                        }
                        .buttonStyle(NestPrimaryButton(gradient: .nestAmberGradient))
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                    .padding(20).padding(.top, 8)
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() }.foregroundColor(Color.nestGray))
        }
    }

    func saveTask() {
        showValidation = true
        guard !title.isEmpty else { return }
        dataVM.addTask(FarmTask(id: UUID().uuidString, title: title, dueDate: dueDate, isCompleted: false, priority: priority, category: category))
        dismiss()
    }
}
