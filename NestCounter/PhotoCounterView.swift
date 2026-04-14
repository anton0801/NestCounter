import SwiftUI

// MARK: - Photo Counter View (Screens 9, 10, 11)
struct PhotoCounterView: View {
    @EnvironmentObject var dataVM: DataViewModel
    @State private var showImagePicker = false
    @State private var capturedImage: UIImage? = nil
    @State private var countResult: PhotoCountResult? = nil
    @State private var isAnalyzing = false
    @State private var showResult = false
    @State private var scanProgress: Double = 0
    @State private var scanLine: CGFloat = 0
    @State private var cameraActive = false
    @State private var flashRing = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("📷 Egg Counter")
                                .font(NestFont.display(26))
                                .foregroundColor(Color.nestDarkBrown)
                            Text("Take or select a photo of eggs\nto count them automatically")
                                .font(NestFont.body(14))
                                .foregroundColor(Color.nestGray)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 8)

                        // Camera viewfinder area
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.nestDarkBrown.opacity(0.05))
                                .frame(height: 280)

                            if let image = capturedImage {
                                // Show captured image
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 280)
                                    .clipped()
                                    .cornerRadius(24)

                                // Scan overlay
                                if isAnalyzing {
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.nestGold, lineWidth: 2)
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.clear, Color.nestGold.opacity(0.5), Color.clear],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: 4)
                                        .offset(y: scanLine - 140)
                                        .clipped()
                                }
                            } else {
                                // Empty state
                                VStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.nestWarm)
                                            .frame(width: 80, height: 80)
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 32, weight: .semibold))
                                            .foregroundColor(Color.nestAmber)
                                    }
                                    Text("Photo area")
                                        .font(NestFont.body(15))
                                        .foregroundColor(Color.nestGray)
                                    Text("Your eggs photo will appear here")
                                        .font(NestFont.caption(13))
                                        .foregroundColor(Color.nestGray.opacity(0.7))
                                }
                            }

                            // Corner guides
                            if capturedImage == nil {
                                ViewfinderCorners()
                            }
                        }
                        .padding(.horizontal, 20)

                        // Action buttons
                        VStack(spacing: 12) {
                            Button(action: {
                                showImagePicker = true
                                cameraActive = true
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Take Photo")
                                        .font(NestFont.headline(17))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 17)
                                .background(LinearGradient.nestAmberGradient)
                                .cornerRadius(16)
                                .shadow(color: Color.nestAmber.opacity(0.4), radius: 10, y: 4)
                            }

                            Button(action: {
                                showImagePicker = true
                                cameraActive = false
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "photo.on.rectangle")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Choose from Library")
                                        .font(NestFont.headline(17))
                                }
                                .foregroundColor(Color.nestAmber)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 17)
                                .background(Color.nestWarm)
                                .cornerRadius(16)
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.nestGold, lineWidth: 1.5))
                            }
                        }
                        .padding(.horizontal, 20)

                        // Demo count button
                        Button(action: {
                            simulatePhotoCount()
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "wand.and.sparkles")
                                    .font(.system(size: 16, weight: .bold))
                                Text("Demo: Simulate AI Count")
                                    .font(NestFont.headline(15))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LinearGradient.nestGreenGradient)
                            .cornerRadius(14)
                        }
                        .padding(.horizontal, 20)

                        // Instructions
                        VStack(alignment: .leading, spacing: 10) {
                            Text("📌 Tips for best results")
                                .font(NestFont.headline(15))
                                .foregroundColor(Color.nestDarkBrown)
                            ForEach([
                                "Ensure all eggs are visible",
                                "Use good lighting",
                                "Keep phone steady",
                                "Avoid overlapping eggs"
                            ], id: \.self) { tip in
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(Color.nestGold)
                                        .frame(width: 6, height: 6)
                                    Text(tip)
                                        .font(NestFont.body(14))
                                        .foregroundColor(Color.nestGray)
                                }
                            }
                        }
                        .padding(18)
                        .background(Color.nestCardBg)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)

                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showImagePicker) {
                NestImagePicker(image: $capturedImage, sourceType: cameraActive ? .camera : .photoLibrary) { img in
                    if img != nil {
                        startAnalysis()
                    }
                }
            }
            .sheet(item: $countResult) { result in
                PhotoResultView(result: result) {
                    countResult = nil
                    capturedImage = nil
                }
            }
        }
    }

    func simulatePhotoCount() {
        // Simulate with a placeholder egg image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 200))
        let img = renderer.image { ctx in
            UIColor(Color.nestWarm).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 300, height: 200))
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40),
            ]
            for i in 0..<6 {
                let x = CGFloat(20 + (i % 3) * 90)
                let y = CGFloat(30 + (i / 3) * 100)
                "🥚".draw(at: CGPoint(x: x, y: y), withAttributes: attrs)
            }
        }
        capturedImage = img
        startAnalysis()
    }

    func startAnalysis() {
        isAnalyzing = true
        scanProgress = 0
        scanLine = -140

        withAnimation(.linear(duration: 1.8).repeatCount(2, autoreverses: false)) {
            scanLine = 140
        }
        withAnimation(.linear(duration: 2.2)) {
            scanProgress = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            isAnalyzing = false
            let detected = Int.random(in: 4...18)
            let conf = Double.random(in: 0.85...0.97)
            countResult = PhotoCountResult(
                detectedCount: detected,
                confidence: conf,
                imageData: capturedImage?.jpegData(compressionQuality: 0.7)
            )
        }
    }
}

// MARK: - Viewfinder Corners
struct ViewfinderCorners: View {
    var body: some View {
        ZStack {
            ForEach([(false, false), (true, false), (false, true), (true, true)], id: \.0) { hFlip, vFlip in
                CornerShape()
                    .stroke(Color.nestGold, lineWidth: 3)
                    .frame(width: 28, height: 28)
                    .scaleEffect(x: hFlip ? -1 : 1, y: vFlip ? -1 : 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: hFlip ? (vFlip ? .bottomTrailing : .topTrailing) : (vFlip ? .bottomLeading : .topLeading))
                    .padding(16)
            }
        }
    }
}

struct CornerShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}

// MARK: - Photo Result View (Screen 10)
struct PhotoResultView: View {
    let result: PhotoCountResult
    var onDismiss: () -> Void
    @EnvironmentObject var dataVM: DataViewModel
    @State private var confirmedCount: Int
    @State private var showConfirm = false
    @State private var circleScale: CGFloat = 0.3
    @State private var numberOpacity: Double = 0

    init(result: PhotoCountResult, onDismiss: @escaping () -> Void) {
        self.result = result
        self.onDismiss = onDismiss
        _confirmedCount = State(initialValue: result.detectedCount)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            // Result header
                            VStack(spacing: 20) {
                                // Animated count circle
                                ZStack {
                                    Circle()
                                        .fill(LinearGradient.nestGoldGradient)
                                        .frame(width: 140, height: 140)
                                        .shadow(color: Color.nestGold.opacity(0.4), radius: 20, y: 10)
                                        .scaleEffect(circleScale)

                                    VStack(spacing: 2) {
                                        Text("\(result.detectedCount)")
                                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                            .opacity(numberOpacity)
                                        Text("eggs")
                                            .font(NestFont.caption(14))
                                            .foregroundColor(.white.opacity(0.85))
                                            .opacity(numberOpacity)
                                    }
                                }
                                .padding(.top, 24)

                                Text("Detection Complete!")
                                    .font(NestFont.display(22))
                                    .foregroundColor(Color.nestDarkBrown)
                            }

                            // Stats cards
                            HStack(spacing: 12) {
                                ResultStatCard(
                                    title: "Detected",
                                    value: "\(result.detectedCount)",
                                    icon: "eye.fill",
                                    color: Color.nestAmber
                                )
                                ResultStatCard(
                                    title: "Confidence",
                                    value: "\(Int(result.confidence * 100))%",
                                    icon: "checkmark.seal.fill",
                                    color: Color.nestGreen
                                )
                            }
                            .padding(.horizontal, 24)

                            // Adjust count
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Adjust Count")
                                    .font(NestFont.headline(16))
                                    .foregroundColor(Color.nestDarkBrown)

                                HStack(spacing: 20) {
                                    Button(action: {
                                        if confirmedCount > 0 {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                                confirmedCount -= 1
                                            }
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(Color.nestAmber)
                                    }

                                    Text("\(confirmedCount)")
                                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.nestDarkBrown)
                                        .frame(minWidth: 80)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: confirmedCount)

                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                            confirmedCount += 1
                                        }
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundColor(Color.nestAmber)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(20)
                            .background(Color.nestCardBg)
                            .cornerRadius(20)
                            .shadow(color: Color.nestShadow, radius: 8, y: 4)
                            .padding(.horizontal, 24)

                            Spacer(minLength: 20)
                        }
                    }

                    // Save button
                    VStack(spacing: 12) {
                        Button(action: { showConfirm = true }) {
                            Text("Save Record")
                        }
                        .buttonStyle(NestPrimaryButton(gradient: .nestGoldGradient))

                        Button(action: onDismiss) {
                            Text("Discard")
                                .font(NestFont.body(16))
                                .foregroundColor(Color.nestGray)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
            }
            .navigationTitle("Detection Result")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.nestDarkBrown)
            })
            .sheet(isPresented: $showConfirm) {
                ConfirmCountView(count: confirmedCount, confidence: result.confidence) {
                    showConfirm = false
                    onDismiss()
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.2)) {
                circleScale = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                numberOpacity = 1
            }
        }
    }
}

struct ResultStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .monospaced))
                .foregroundColor(Color.nestDarkBrown)
            Text(title)
                .font(NestFont.caption(12))
                .foregroundColor(Color.nestGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.nestCardBg)
        .cornerRadius(16)
        .shadow(color: Color.nestShadow, radius: 6, y: 3)
    }
}

// MARK: - Confirm Count View (Screen 11)
struct ConfirmCountView: View {
    let count: Int
    let confidence: Double
    var onSave: () -> Void
    @EnvironmentObject var dataVM: DataViewModel
    @State private var selectedGroupId: String = ""
    @State private var notes: String = ""
    @State private var date = Date()
    @State private var saved = false
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.nestCream.ignoresSafeArea()

                if showSuccess {
                    SuccessView(count: count) {
                        onSave()
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Summary
                            HStack(spacing: 16) {
                                VStack(spacing: 4) {
                                    Text("\(count)")
                                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.nestAmber)
                                    Text("Eggs")
                                        .font(NestFont.caption(13))
                                        .foregroundColor(Color.nestGray)
                                }
                                Divider().frame(height: 50)
                                VStack(spacing: 4) {
                                    Text("\(Int(confidence * 100))%")
                                        .font(.system(size: 42, weight: .bold, design: .monospaced))
                                        .foregroundColor(Color.nestGreen)
                                    Text("Confidence")
                                        .font(NestFont.caption(13))
                                        .foregroundColor(Color.nestGray)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(20)
                            .background(Color.nestCardBg)
                            .cornerRadius(20)
                            .shadow(color: Color.nestShadow, radius: 8, y: 4)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)

                            VStack(spacing: 16) {
                                // Bird group
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Bird Group")
                                        .font(NestFont.caption(13))
                                        .foregroundColor(Color.nestGray)
                                    Picker("Bird Group", selection: $selectedGroupId) {
                                        Text("Select group").tag("")
                                        ForEach(dataVM.birdGroups) { g in
                                            Text(g.name).tag(g.id)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .background(Color.nestLightGray)
                                    .cornerRadius(14)
                                    .accentColor(Color.nestAmber)
                                }

                                // Date
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Date")
                                        .font(NestFont.caption(13))
                                        .foregroundColor(Color.nestGray)
                                    DatePicker("", selection: $date, displayedComponents: .date)
                                        .datePickerStyle(CompactDatePickerStyle())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.nestLightGray)
                                        .cornerRadius(14)
                                        .accentColor(Color.nestAmber)
                                }

                                // Notes
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Notes (optional)")
                                        .font(NestFont.caption(13))
                                        .foregroundColor(Color.nestGray)
                                    TextField("Any observations...", text: $notes)
                                        .nestInput()
                                }
                            }
                            .padding(.horizontal, 24)

                            Button(action: saveRecord) {
                                Text("Confirm & Save")
                            }
                            .buttonStyle(NestPrimaryButton(gradient: .nestGoldGradient))
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                            Spacer(minLength: 40)
                        }
                    }
                }
            }
            .navigationTitle("Confirm Count")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if let first = dataVM.birdGroups.first {
                selectedGroupId = first.id
            }
        }
    }

    func saveRecord() {
        let groupName = dataVM.birdGroups.first { $0.id == selectedGroupId }?.name ?? "Unknown"
        let record = EggRecord(
            id: UUID().uuidString,
            birdGroupId: selectedGroupId,
            birdGroupName: groupName,
            count: count,
            date: date,
            notes: notes,
            photoCount: true,
            confidence: confidence
        )
        dataVM.addEggRecord(record)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showSuccess = true
        }
    }
}

// MARK: - Success Animation View
struct SuccessView: View {
    let count: Int
    var onContinue: () -> Void
    @State private var scale: CGFloat = 0.3
    @State private var checkOpacity: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient.nestGreenGradient)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.nestGreen.opacity(0.4), radius: 20, y: 10)
                    .scaleEffect(scale)
                Image(systemName: "checkmark")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(checkOpacity)
            }
            VStack(spacing: 8) {
                Text("Saved! 🎉")
                    .font(NestFont.display(28))
                    .foregroundColor(Color.nestDarkBrown)
                Text("\(count) eggs recorded successfully")
                    .font(NestFont.body(16))
                    .foregroundColor(Color.nestGray)
            }
            .opacity(checkOpacity)
            Spacer()
            Button(action: onContinue) {
                Text("Continue")
            }
            .buttonStyle(NestPrimaryButton(gradient: .nestGreenGradient))
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                checkOpacity = 1
            }
        }
    }
}

// MARK: - Image Picker Wrapper
struct NestImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    var onPick: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: NestImagePicker
        init(_ parent: NestImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let img = info[.originalImage] as? UIImage
            parent.image = img
            parent.onPick(img)
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
