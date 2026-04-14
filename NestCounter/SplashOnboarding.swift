import SwiftUI

// MARK: - Splash Screen
struct SplashView: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var waveOffset: CGFloat = 0
    @State private var particleOpacity: Double = 0
    @State private var taglineOpacity: Double = 0
    @State private var logoRotation: Double = -15
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "#FDF6E3"), Color(hex: "#F0D9A8"), Color(hex: "#E8C87A")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Floating particles
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(Color.nestGold.opacity(0.15 + Double(i % 3) * 0.08))
                    .frame(width: CGFloat(8 + i * 4), height: CGFloat(8 + i * 4))
                    .offset(
                        x: CGFloat(cos(Double(i) * 0.52) * 120),
                        y: CGFloat(sin(Double(i) * 0.52) * 160)
                    )
                    .opacity(particleOpacity)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: waveOffset
                    )
            }

            VStack(spacing: 24) {
                // Logo
                ZStack {
                    Circle()
                        .fill(LinearGradient.nestGoldGradient)
                        .frame(width: 110, height: 110)
                        .shadow(color: Color.nestGold.opacity(0.5), radius: 20, y: 10)

                    VStack(spacing: -4) {
                        Text("🥚")
                            .font(.system(size: 40))
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .rotationEffect(.degrees(logoRotation))
                }
                .scaleEffect(scale)

                VStack(spacing: 6) {
                    Text("Nest Counter")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color.nestDarkBrown)

                    Text("Track egg production easily.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color.nestBrown)
                }
                .opacity(taglineOpacity)
            }

            // Bottom wave
            VStack {
                Spacer()
                WaveShape(offset: waveOffset)
                    .fill(Color.nestGold.opacity(0.2))
                    .frame(height: 100)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
                scale = 1.0
                logoRotation = 0
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                opacity = 1
                particleOpacity = 1
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                taglineOpacity = 1
            }
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: true).delay(0.5)) {
                waveOffset = 20
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                onFinish()
            }
        }
    }
}

// MARK: - Wave Shape
struct WaveShape: Shape {
    var offset: CGFloat
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.height * 0.5))
        for x in stride(from: 0, to: rect.width, by: 1) {
            let y = sin((x / rect.width * 2 * .pi) + offset * 0.1) * 20 + rect.height * 0.5
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0

    let pages: [OnboardingPage] = [
        OnboardingPage(
            index: 0,
            icon: "📷",
            title: "Count eggs\nwith camera",
            subtitle: "Snap a photo and let Nest Counter detect and count your eggs automatically using AI.",
            color1: Color(hex: "#E8A020"),
            color2: Color(hex: "#F4C842"),
            illustration: "camera.fill",
            illustrationBadge: "🥚"
        ),
        OnboardingPage(
            index: 1,
            icon: "📊",
            title: "Track daily\nproduction",
            subtitle: "Keep detailed records for every bird group. Never miss a day's collection.",
            color1: Color(hex: "#5C8A3C"),
            color2: Color(hex: "#8FB87A"),
            illustration: "chart.bar.fill",
            illustrationBadge: "📅"
        ),
        OnboardingPage(
            index: 2,
            icon: "🔬",
            title: "Analyze egg\nproductivity",
            subtitle: "Understand your flock's performance with charts, scores, and smart alerts.",
            color1: Color(hex: "#4A7FA5"),
            color2: Color(hex: "#87CEEB"),
            illustration: "chart.line.uptrend.xyaxis",
            illustrationBadge: "🌟"
        )
    ]

    var body: some View {
        ZStack {
            // Animated background
            LinearGradient(
                colors: [
                    pages[currentPage].color1.opacity(0.15),
                    pages[currentPage].color2.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .animation(.easeInOut(duration: 0.4), value: currentPage)
            .ignoresSafeArea()

            Color.nestCream.ignoresSafeArea()
            .opacity(0.85)

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        appState.completeOnboarding()
                    }
                    .font(NestFont.caption(15))
                    .foregroundColor(Color.nestGray)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                // Pages
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { i in
                        OnboardingPageView(page: pages[i])
                            .tag(i)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)

                // Dots + button
                VStack(spacing: 28) {
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { i in
                            Capsule()
                                .fill(i == currentPage ? pages[currentPage].color1 : Color.nestGray.opacity(0.3))
                                .frame(width: i == currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: currentPage)
                        }
                    }

                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                currentPage += 1
                            }
                        } else {
                            appState.completeOnboarding()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                .font(NestFont.headline(17))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [pages[currentPage].color1, pages[currentPage].color2],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(18)
                        .shadow(color: pages[currentPage].color1.opacity(0.4), radius: 12, y: 6)
                    }
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 44)
            }
        }
    }
}

struct OnboardingPage {
    let index: Int
    let icon: String
    let title: String
    let subtitle: String
    let color1: Color
    let color2: Color
    let illustration: String
    let illustrationBadge: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @State private var appeared = false
    @State private var iconBounce: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.color1.opacity(0.2), page.color2.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 220, height: 220)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.color1, page.color2],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: page.color1.opacity(0.4), radius: 20, y: 10)

                Image(systemName: page.illustration)
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundColor(.white)

                Text(page.illustrationBadge)
                    .font(.system(size: 28))
                    .offset(x: 52, y: -52)
                    .scaleEffect(iconBounce ? 1.2 : 1.0)
                    .animation(.spring(response: 0.5, dampingFraction: 0.5).repeatForever(autoreverses: true).delay(0.5), value: iconBounce)
            }
            .scaleEffect(appeared ? 1.0 : 0.6)
            .opacity(appeared ? 1 : 0)

            Spacer().frame(height: 48)

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(Color.nestDarkBrown)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(Color.nestBrown)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 36)
            .offset(y: appeared ? 0 : 30)
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                appeared = true
            }
            iconBounce = true
        }
        .onDisappear {
            appeared = false
        }
    }
}
