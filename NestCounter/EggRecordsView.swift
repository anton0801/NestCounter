import SwiftUI

// MARK: - Egg Records View (Screen 12)
struct EggRecordsView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false
    @State private var searchText = ""
    @State private var selectedGroupFilter = "All"

    var filteredRecords: [EggRecord] {
        var records = dataVM.eggRecords
        if selectedGroupFilter != "All" {
            records = records.filter { $0.birdGroupName == selectedGroupFilter }
        }
        if !searchText.isEmpty {
            records = records.filter {
                $0.birdGroupName.localizedCaseInsensitiveContains(searchText) ||
                $0.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        return records
    }

    var groupNames: [String] {
        ["All"] + Array(Set(dataVM.eggRecords.map { $0.birdGroupName })).sorted()
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(groupNames, id: \.self) { name in
                                FilterChip(
                                    label: name,
                                    isSelected: selectedGroupFilter == name
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedGroupFilter = name
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }

                    if filteredRecords.isEmpty {
                        EmptyStateView(
                            icon: "list.clipboard",
                            title: "No Records",
                            message: "Add your first egg record"
                        )
                    } else {
                        List {
                            ForEach(filteredRecords) { record in
                                EggRecordDetailRow(record: record)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                            }
                            .onDelete { indexSet in
                                indexSet.forEach { i in
                                    dataVM.deleteEggRecord(filteredRecords[i])
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search records...")
            .navigationTitle("Egg Records")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showAdd = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(Color.nestAmber)
                    }
                }
            }
            .sheet(isPresented: $showAdd) {
                AddEggRecordView()
            }
        }
    }
}

struct EggRecordDetailRow: View {
    let record: EggRecord

    var body: some View {
        HStack(spacing: 14) {
            // Date column
            VStack(spacing: 2) {
                Text(dayString(from: record.date))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(Color.nestAmber)
                Text(monthString(from: record.date))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color.nestGray)
            }
            .frame(width: 40)

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(record.birdGroupName)
                        .font(NestFont.headline(14))
                        .foregroundColor(Color.nestDarkBrown)
                    if record.photoCount {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color.nestAmber)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.nestWarm)
                            .cornerRadius(6)
                    }
                }
                if !record.notes.isEmpty {
                    Text(record.notes)
                        .font(NestFont.body(12))
                        .foregroundColor(Color.nestGray)
                        .lineLimit(1)
                }
                if let conf = record.confidence, record.photoCount {
                    Text("AI: \(Int(conf * 100))% confidence")
                        .font(NestFont.caption(11))
                        .foregroundColor(Color.nestGreen)
                }
            }

            Spacer()

            Text("\(record.count)")
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(Color.nestDarkBrown)
                + Text(" 🥚")
                .font(.system(size: 16))
        }
        .padding(14)
        .background(Color.nestCardBg)
        .cornerRadius(16)
        .shadow(color: Color.nestShadow, radius: 6, y: 3)
    }

    func dayString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
    func monthString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date)
    }
}

// MARK: - Add Egg Record (Screen 13)
struct AddEggRecordView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedGroupId: String = ""
    @State private var count: Int = 0
    @State private var date = Date()
    @State private var notes = ""
    @State private var showValidation = false

    var selectedGroup: BirdGroup? {
        dataVM.birdGroups.first { $0.id == selectedGroupId }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Count selector
                        VStack(spacing: 16) {
                            Text("Egg Count")
                                .font(NestFont.display(18))
                                .foregroundColor(Color.nestDarkBrown)

                            HStack(spacing: 28) {
                                Button(action: {
                                    if count > 0 {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { count -= 1 }
                                    }
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 42))
                                        .foregroundColor(count > 0 ? Color.nestAmber : Color.nestGray.opacity(0.3))
                                }

                                Text("\(count)")
                                    .font(.system(size: 56, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color.nestDarkBrown)
                                    .frame(minWidth: 100)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: count)

                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { count += 1 }
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 42))
                                        .foregroundColor(Color.nestAmber)
                                }
                            }

                            // Quick add buttons
                            HStack(spacing: 8) {
                                ForEach([5, 10, 12, 24], id: \.self) { n in
                                    Button("+\(n)") {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            count += n
                                        }
                                    }
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestAmber)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 7)
                                    .background(Color.nestWarm)
                                    .cornerRadius(10)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(24)
                        .background(Color.nestCardBg)
                        .cornerRadius(20)
                        .shadow(color: Color.nestShadow, radius: 8, y: 4)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Bird group
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Bird Group")
                                .font(NestFont.headline(16))
                                .foregroundColor(Color.nestDarkBrown)

                            if dataVM.birdGroups.isEmpty {
                                Text("No bird groups. Please add one first.")
                                    .font(NestFont.body(14))
                                    .foregroundColor(Color.nestGray)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(dataVM.birdGroups) { group in
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    selectedGroupId = group.id
                                                }
                                            }) {
                                                HStack(spacing: 6) {
                                                    Text(group.birdType.icon)
                                                    Text(group.name)
                                                        .font(NestFont.caption(14))
                                                }
                                                .foregroundColor(selectedGroupId == group.id ? .white : Color.nestDarkBrown)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(
                                                    selectedGroupId == group.id
                                                    ? AnyView(LinearGradient.nestAmberGradient)
                                                    : AnyView(Color.nestLightGray)
                                                )
                                                .cornerRadius(12)
                                            }
                                        }
                                    }
                                }
                            }

                            if showValidation && selectedGroupId.isEmpty {
                                Text("Please select a bird group")
                                    .font(NestFont.caption(12))
                                    .foregroundColor(Color.nestRed)
                            }
                        }
                        .padding(.horizontal, 20)

                        // Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(NestFont.headline(16))
                                .foregroundColor(Color.nestDarkBrown)
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .datePickerStyle(CompactDatePickerStyle())
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color.nestLightGray)
                                .cornerRadius(14)
                                .accentColor(Color.nestAmber)
                        }
                        .padding(.horizontal, 20)

                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(NestFont.headline(16))
                                .foregroundColor(Color.nestDarkBrown)
                            TextField("Optional notes...", text: $notes)
                                .nestInput()
                        }
                        .padding(.horizontal, 20)

                        Button(action: saveRecord) {
                            Text("Save Record")
                        }
                        .buttonStyle(NestPrimaryButton(gradient: .nestGoldGradient))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Add Egg Record")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() }
                .foregroundColor(Color.nestGray)
            )
        }
        .onAppear {
            if let first = dataVM.birdGroups.first {
                selectedGroupId = first.id
            }
        }
    }

    func saveRecord() {
        showValidation = true
        guard !selectedGroupId.isEmpty, count > 0 else { return }
        let groupName = dataVM.birdGroups.first { $0.id == selectedGroupId }?.name ?? "Unknown"
        let record = EggRecord(
            id: UUID().uuidString,
            birdGroupId: selectedGroupId,
            birdGroupName: groupName,
            count: count,
            date: date,
            notes: notes,
            photoCount: false,
            confidence: nil
        )
        dataVM.addEggRecord(record)
        dismiss()
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : Color.nestDarkBrown)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? AnyView(LinearGradient.nestAmberGradient) : AnyView(Color.nestLightGray))
                .cornerRadius(20)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 52, weight: .light))
                .foregroundColor(Color.nestGray.opacity(0.4))
            Text(title)
                .font(NestFont.headline(20))
                .foregroundColor(Color.nestDarkBrown)
            Text(message)
                .font(NestFont.body(15))
                .foregroundColor(Color.nestGray)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(40)
    }
}
