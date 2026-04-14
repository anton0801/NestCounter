import SwiftUI

// MARK: - Bird Groups View (Screen 14)
struct BirdGroupsView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showAdd = false
    @State private var groupToEdit: BirdGroup? = nil

    var body: some View {
        ZStack {
            Color.nestCream.ignoresSafeArea()

            if dataVM.birdGroups.isEmpty {
                EmptyStateView(icon: "bird", title: "No Bird Groups", message: "Add your first bird group to start tracking")
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(dataVM.birdGroups) { group in
                            BirdGroupCard(group: group) {
                                groupToEdit = group
                            }
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Bird Groups")
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
            AddBirdGroupView()
        }
        .sheet(item: $groupToEdit) { group in
            EditBirdGroupView(group: group)
        }
    }
}

// MARK: - Bird Group Card
struct BirdGroupCard: View {
    let group: BirdGroup
    var onEdit: () -> Void
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showDeleteAlert = false

    var todayEggs: Int {
        let cal = Calendar.current
        return dataVM.eggRecords.filter {
            $0.birdGroupId == group.id && cal.isDateInToday($0.date)
        }.reduce(0) { $0 + $1.count }
    }

    var weekEggs: Int {
        let cal = Calendar.current
        let week = cal.date(byAdding: .day, value: -7, to: Date())!
        return dataVM.eggRecords.filter {
            $0.birdGroupId == group.id && $0.date >= week
        }.reduce(0) { $0 + $1.count }
    }

    var productivity: Int {
        let expected = group.expectedDailyEggs
        guard expected > 0 else { return 0 }
        return min(100, Int(Double(todayEggs) / Double(expected) * 100))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: group.color).opacity(0.18))
                        .frame(width: 58, height: 58)
                    Text(group.birdType.icon)
                        .font(.system(size: 30))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(NestFont.headline(17))
                        .foregroundColor(Color.nestDarkBrown)
                    HStack(spacing: 6) {
                        Text(group.birdType.rawValue)
                            .font(NestFont.caption(13))
                            .foregroundColor(Color.nestGray)
                        Text("•")
                            .foregroundColor(Color.nestGray)
                        Text("\(group.count) birds")
                            .font(NestFont.caption(13))
                            .foregroundColor(Color.nestGray)
                    }
                }

                Spacer()

                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: 20))
                        .foregroundColor(Color.nestGray)
                }
            }
            .padding(18)

            Divider()
                .background(Color.nestLightGray)

            // Stats
            HStack(spacing: 0) {
                GroupStatItem(label: "Today", value: "\(todayEggs) 🥚")
                Divider().frame(height: 40)
                GroupStatItem(label: "This Week", value: "\(weekEggs)")
                Divider().frame(height: 40)
                GroupStatItem(label: "Productivity", value: "\(productivity)%")
            }
            .padding(.vertical, 12)

            // Progress bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Expected: \(group.expectedDailyEggs)/day")
                        .font(NestFont.caption(12))
                        .foregroundColor(Color.nestGray)
                    Spacer()
                    Text("\(productivity)%")
                        .font(NestFont.caption(12))
                        .foregroundColor(productivity >= 80 ? Color.nestGreen : Color.nestAmber)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.nestLightGray)
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(productivity >= 80 ? LinearGradient.nestGreenGradient : LinearGradient.nestAmberGradient)
                            .frame(width: geo.size.width * CGFloat(productivity) / 100.0, height: 8)
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: productivity)
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 18)
        }
        .background(Color.nestCardBg)
        .cornerRadius(20)
        .shadow(color: Color.nestShadow, radius: 8, y: 4)
        .alert("Delete \(group.name)?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                dataVM.deleteBirdGroup(group)
            }
        } message: {
            Text("All records for this group will remain but won't be linked to this group.")
        }
    }
}

struct GroupStatItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(Color.nestDarkBrown)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(Color.nestGray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Add Bird Group (Screen 15)
struct AddBirdGroupView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var birdType: BirdGroup.BirdType = .chicken
    @State private var count: Int = 10
    @State private var selectedColor = "#E8A020"
    @State private var showValidation = false

    let colorOptions = ["#E8A020","#5C8A3C","#4A7FA5","#C0392B","#8B5E3C","#9B59B6"]

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Preview
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(hex: selectedColor).opacity(0.15))
                            HStack(spacing: 12) {
                                Text(birdType.icon)
                                    .font(.system(size: 40))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(name.isEmpty ? "Group Name" : name)
                                        .font(NestFont.headline(18))
                                        .foregroundColor(Color.nestDarkBrown)
                                    Text("\(count) \(birdType.rawValue)s")
                                        .font(NestFont.body(14))
                                        .foregroundColor(Color.nestGray)
                                }
                            }
                            .padding(20)
                        }
                        .frame(height: 90)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        VStack(spacing: 16) {
                            // Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Group Name")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                TextField("e.g. Layers A", text: $name)
                                    .nestInput()
                                if showValidation && name.isEmpty {
                                    Text("Name is required")
                                        .font(NestFont.caption(12))
                                        .foregroundColor(Color.nestRed)
                                }
                            }

                            // Bird type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bird Type")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(BirdGroup.BirdType.allCases, id: \.self) { type in
                                            Button(action: {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    birdType = type
                                                }
                                            }) {
                                                HStack(spacing: 6) {
                                                    Text(type.icon)
                                                    Text(type.rawValue)
                                                        .font(NestFont.caption(13))
                                                }
                                                .foregroundColor(birdType == type ? .white : Color.nestDarkBrown)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(birdType == type ? AnyView(LinearGradient.nestAmberGradient) : AnyView(Color.nestLightGray))
                                                .cornerRadius(12)
                                            }
                                        }
                                    }
                                }
                            }

                            // Count
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Number of Birds")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                HStack(spacing: 20) {
                                    Button(action: {
                                        if count > 1 { count -= 1 }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(count > 1 ? Color.nestAmber : Color.nestGray.opacity(0.3))
                                    }
                                    Text("\(count)")
                                        .font(.system(size: 38, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.nestDarkBrown)
                                        .frame(minWidth: 70)
                                    Button(action: { count += 1 }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color.nestAmber)
                                    }
                                }
                            }

                            // Color
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Color Tag")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                HStack(spacing: 12) {
                                    ForEach(colorOptions, id: \.self) { hex in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                selectedColor = hex
                                            }
                                        }) {
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.nestDarkBrown, lineWidth: selectedColor == hex ? 3 : 0)
                                                        .padding(2)
                                                )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        Button(action: saveGroup) {
                            Text("Add Bird Group")
                        }
                        .buttonStyle(NestPrimaryButton(gradient: .nestAmberGradient))
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Add Bird Group")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() }
                .foregroundColor(Color.nestGray))
        }
    }

    func saveGroup() {
        showValidation = true
        guard !name.isEmpty else { return }
        let group = BirdGroup(
            id: UUID().uuidString,
            name: name,
            birdType: birdType,
            count: count,
            color: selectedColor,
            addedAt: Date()
        )
        dataVM.addBirdGroup(group)
        dismiss()
    }
}

// MARK: - Edit Bird Group
struct EditBirdGroupView: View {
    let group: BirdGroup
    @EnvironmentObject var dataVM: DataViewModel
    @Environment(\.dismiss) var dismiss
    @State private var name: String
    @State private var birdType: BirdGroup.BirdType
    @State private var count: Int
    @State private var selectedColor: String

    let colorOptions = ["#E8A020","#5C8A3C","#4A7FA5","#C0392B","#8B5E3C","#9B59B6"]

    init(group: BirdGroup) {
        self.group = group
        _name = State(initialValue: group.name)
        _birdType = State(initialValue: group.birdType)
        _count = State(initialValue: group.count)
        _selectedColor = State(initialValue: group.color)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Group Name")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                TextField("Group name", text: $name)
                                    .nestInput()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Bird Type")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(BirdGroup.BirdType.allCases, id: \.self) { type in
                                            Button(action: { birdType = type }) {
                                                HStack(spacing: 6) {
                                                    Text(type.icon)
                                                    Text(type.rawValue).font(NestFont.caption(13))
                                                }
                                                .foregroundColor(birdType == type ? .white : Color.nestDarkBrown)
                                                .padding(.horizontal, 14).padding(.vertical, 10)
                                                .background(birdType == type ? AnyView(LinearGradient.nestAmberGradient) : AnyView(Color.nestLightGray))
                                                .cornerRadius(12)
                                            }
                                        }
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Number of Birds")
                                    .font(NestFont.caption(13))
                                    .foregroundColor(Color.nestGray)
                                HStack(spacing: 20) {
                                    Button(action: { if count > 1 { count -= 1 } }) {
                                        Image(systemName: "minus.circle.fill").font(.system(size: 30)).foregroundColor(Color.nestAmber)
                                    }
                                    Text("\(count)").font(.system(size: 34, weight: .bold, design: .monospaced)).foregroundColor(Color.nestDarkBrown).frame(minWidth: 60)
                                    Button(action: { count += 1 }) {
                                        Image(systemName: "plus.circle.fill").font(.system(size: 30)).foregroundColor(Color.nestAmber)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Color Tag").font(NestFont.caption(13)).foregroundColor(Color.nestGray)
                                HStack(spacing: 12) {
                                    ForEach(colorOptions, id: \.self) { hex in
                                        Button(action: { selectedColor = hex }) {
                                            Circle().fill(Color(hex: hex)).frame(width: 32, height: 32)
                                                .overlay(Circle().stroke(Color.nestDarkBrown, lineWidth: selectedColor == hex ? 3 : 0).padding(2))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        Button(action: saveEdit) {
                            Text("Save Changes")
                        }
                        .buttonStyle(NestPrimaryButton(gradient: .nestAmberGradient))
                        .padding(.horizontal, 20)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Cancel") { dismiss() }.foregroundColor(Color.nestGray))
        }
    }

    func saveEdit() {
        guard !name.isEmpty else { return }
        var updated = group
        updated.name = name
        updated.birdType = birdType
        updated.count = count
        updated.color = selectedColor
        dataVM.updateBirdGroup(updated)
        dismiss()
    }
}
