import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary warm farm palette
    static let nestCream       = Color(hex: "#FDF6E3")
    static let nestWarm        = Color(hex: "#F5E6C8")
    static let nestGold        = Color(hex: "#E8A020")
    static let nestAmber       = Color(hex: "#D4821A")
    static let nestBrown       = Color(hex: "#8B5E3C")
    static let nestDarkBrown   = Color(hex: "#4A2C17")
    static let nestGreen       = Color(hex: "#5C8A3C")
    static let nestSoftGreen   = Color(hex: "#8FB87A")
    static let nestRed         = Color(hex: "#C0392B")
    static let nestSoftRed     = Color(hex: "#E8735A")
    static let nestBlue        = Color(hex: "#4A7FA5")
    static let nestSky         = Color(hex: "#87CEEB")
    static let nestShadow      = Color(hex: "#2C1A0E").opacity(0.15)
    static let nestCardBg      = Color(hex: "#FFFBF2")
    static let nestGray        = Color(hex: "#8C7B6B")
    static let nestLightGray   = Color(hex: "#F0E8D8")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let nestHeroGradient = LinearGradient(
        colors: [Color(hex: "#FDF6E3"), Color(hex: "#F5E6C8")],
        startPoint: .top, endPoint: .bottom
    )
    static let nestGoldGradient = LinearGradient(
        colors: [Color(hex: "#F4C842"), Color(hex: "#E8A020")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let nestAmberGradient = LinearGradient(
        colors: [Color(hex: "#E8A020"), Color(hex: "#D4821A")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let nestGreenGradient = LinearGradient(
        colors: [Color(hex: "#6FAE4E"), Color(hex: "#4A8A2A")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let nestDarkGradient = LinearGradient(
        colors: [Color(hex: "#3D2010"), Color(hex: "#1A0C06")],
        startPoint: .top, endPoint: .bottom
    )
    static let nestCardGradient = LinearGradient(
        colors: [Color(hex: "#FFFBF2"), Color(hex: "#FFF5E0")],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// MARK: - Typography
struct NestFont {
    // Using system fonts with custom weights styled for farm aesthetic
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func headline(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .rounded)
    }
    static func caption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .rounded)
    }
    static func number(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .monospaced)
    }
}

// MARK: - Custom Button Styles
struct NestPrimaryButton: ButtonStyle {
    var gradient: LinearGradient = .nestGoldGradient
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NestFont.headline(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(gradient)
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .shadow(color: Color.nestGold.opacity(0.4), radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 2 : 4)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct NestSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(NestFont.headline(16))
            .foregroundColor(.nestAmber)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.nestWarm)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.nestGold, lineWidth: 1.5))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct NestIconButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Card Style
struct NestCard: ViewModifier {
    var padding: CGFloat = 16
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color.nestCardBg)
            .cornerRadius(20)
            .shadow(color: Color.nestShadow, radius: 8, x: 0, y: 4)
    }
}

extension View {
    func nestCard(padding: CGFloat = 16) -> some View {
        modifier(NestCard(padding: padding))
    }
}

// MARK: - Input Field Style
struct NestTextField: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.nestLightGray)
            .cornerRadius(14)
            .font(NestFont.body(16))
            .foregroundColor(Color.nestDarkBrown)
    }
}

extension View {
    func nestInput() -> some View {
        modifier(NestTextField())
    }
}
