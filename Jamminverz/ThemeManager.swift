//
//  ThemeManager.swift
//  Jamminverz
//
//  Manages app-wide theming with 4 unique styles
//

import SwiftUI

// MARK: - Theme Definition
struct Theme {
    let name: String
    let displayName: String
    
    // Colors
    let primaryBackground: Color
    let secondaryBackground: Color
    let tertiaryBackground: Color
    let primaryText: Color
    let secondaryText: Color
    let accentColor: Color
    let secondaryAccent: Color
    let buttonBackground: Color
    let cardBackground: Color
    let dividerColor: Color
    
    // Typography
    let headerFont: Font.Weight
    let bodyFont: Font.Weight
    let captionFont: Font.Weight
    
    // Styling
    let cornerRadius: CGFloat
    let buttonCornerRadius: CGFloat
    let cardCornerRadius: CGFloat
    let shadowRadius: CGFloat
    let buttonHeight: CGFloat
    let spacing: CGFloat
    
    // Special effects
    let hasGradients: Bool
    let hasGlassEffect: Bool
    let hasNeonEffect: Bool
    let hasAnimations: Bool
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: Theme {
        didSet {
            UserDefaults.standard.set(currentTheme.name, forKey: "selectedTheme")
        }
    }
    
    let themes: [Theme] = [
        // 1. TODOMAI CLASSIC - Dark with rich purple
        Theme(
            name: "todomai",
            displayName: "TODOMAI CLASSIC",
            primaryBackground: Color.black,
            secondaryBackground: Color(red: 0.1, green: 0.1, blue: 0.1),
            tertiaryBackground: Color(red: 0.15, green: 0.15, blue: 0.15),
            primaryText: .white,
            secondaryText: Color.gray,
            accentColor: Color(red: 0.373, green: 0.275, blue: 0.569), // Rich purple
            secondaryAccent: Color(red: 0.8, green: 0.6, blue: 1.0), // Light purple
            buttonBackground: Color(red: 0.373, green: 0.275, blue: 0.569),
            cardBackground: Color.white.opacity(0.05),
            dividerColor: Color.white.opacity(0.1),
            headerFont: .heavy,
            bodyFont: .heavy,
            captionFont: .medium,
            cornerRadius: 12,
            buttonCornerRadius: 30,
            cardCornerRadius: 16,
            shadowRadius: 0,
            buttonHeight: 60,
            spacing: 24,
            hasGradients: false,
            hasGlassEffect: false,
            hasNeonEffect: false,
            hasAnimations: true
        ),
        
        // 2. CYBERPUNK NEON - Dark with neon colors and glow effects
        Theme(
            name: "cyberpunk",
            displayName: "CYBERPUNK NEON",
            primaryBackground: Color(red: 0.05, green: 0.05, blue: 0.1),
            secondaryBackground: Color(red: 0.1, green: 0.1, blue: 0.15),
            tertiaryBackground: Color(red: 0.15, green: 0.15, blue: 0.2),
            primaryText: Color(red: 0.0, green: 1.0, blue: 0.8), // Cyan
            secondaryText: Color(red: 1.0, green: 0.0, blue: 0.5), // Hot pink
            accentColor: Color(red: 1.0, green: 0.0, blue: 0.5), // Hot pink
            secondaryAccent: Color(red: 0.0, green: 1.0, blue: 0.8), // Cyan
            buttonBackground: Color(red: 1.0, green: 0.0, blue: 0.5),
            cardBackground: Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.1),
            dividerColor: Color(red: 0.0, green: 1.0, blue: 0.8).opacity(0.3),
            headerFont: .black,
            bodyFont: .regular,
            captionFont: .light,
            cornerRadius: 0,
            buttonCornerRadius: 4,
            cardCornerRadius: 0,
            shadowRadius: 10,
            buttonHeight: 48,
            spacing: 16,
            hasGradients: true,
            hasGlassEffect: false,
            hasNeonEffect: true,
            hasAnimations: true
        ),
        
        // 3. GLASSMORPHISM - Light with frosted glass effects
        Theme(
            name: "glass",
            displayName: "GLASS AURORA",
            primaryBackground: Color(red: 0.95, green: 0.95, blue: 0.98),
            secondaryBackground: Color.white,
            tertiaryBackground: Color(red: 0.98, green: 0.98, blue: 1.0),
            primaryText: Color(red: 0.1, green: 0.1, blue: 0.2),
            secondaryText: Color(red: 0.4, green: 0.4, blue: 0.5),
            accentColor: Color(red: 0.4, green: 0.6, blue: 1.0), // Soft blue
            secondaryAccent: Color(red: 0.8, green: 0.4, blue: 0.8), // Soft purple
            buttonBackground: Color.white.opacity(0.8),
            cardBackground: Color.white.opacity(0.6),
            dividerColor: Color.black.opacity(0.05),
            headerFont: .semibold,
            bodyFont: .regular,
            captionFont: .light,
            cornerRadius: 20,
            buttonCornerRadius: 16,
            cardCornerRadius: 24,
            shadowRadius: 20,
            buttonHeight: 56,
            spacing: 20,
            hasGradients: true,
            hasGlassEffect: true,
            hasNeonEffect: false,
            hasAnimations: true
        ),
        
        // 4. RETRO WAVE - 80s inspired with warm colors
        Theme(
            name: "retrowave",
            displayName: "RETRO WAVE",
            primaryBackground: Color(red: 0.1, green: 0.05, blue: 0.15),
            secondaryBackground: Color(red: 0.15, green: 0.08, blue: 0.2),
            tertiaryBackground: Color(red: 0.2, green: 0.1, blue: 0.25),
            primaryText: Color(red: 1.0, green: 0.9, blue: 0.4), // Yellow
            secondaryText: Color(red: 1.0, green: 0.6, blue: 0.8), // Pink
            accentColor: Color(red: 1.0, green: 0.4, blue: 0.6), // Sunset pink
            secondaryAccent: Color(red: 0.4, green: 0.8, blue: 1.0), // Sky blue
            buttonBackground: Color(red: 1.0, green: 0.4, blue: 0.6), // Sunset pink
            cardBackground: Color(red: 1.0, green: 0.4, blue: 0.6).opacity(0.1),
            dividerColor: Color(red: 1.0, green: 0.9, blue: 0.4).opacity(0.2),
            headerFont: .bold,
            bodyFont: .medium,
            captionFont: .regular,
            cornerRadius: 8,
            buttonCornerRadius: 8,
            cardCornerRadius: 12,
            shadowRadius: 0,
            buttonHeight: 52,
            spacing: 18,
            hasGradients: true,
            hasGlassEffect: false,
            hasNeonEffect: false,
            hasAnimations: true
        )
    ]
    
    init() {
        // Load saved theme or default to TODOMAI
        let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme") ?? "todomai"
        currentTheme = themes.first { $0.name == savedTheme } ?? themes[0]
    }
    
    func setTheme(_ theme: Theme) {
        withAnimation(.spring()) {
            currentTheme = theme
        }
    }
}

// MARK: - View Extensions
extension View {
    func themed() -> some View {
        self.environmentObject(ThemeManager.shared)
    }
    
    func primaryBackground() -> some View {
        self.background(ThemeManager.shared.currentTheme.primaryBackground)
    }
    
    func cardStyle() -> some View {
        self
            .background(ThemeManager.shared.currentTheme.cardBackground)
            .cornerRadius(ThemeManager.shared.currentTheme.cardCornerRadius)
            .shadow(radius: ThemeManager.shared.currentTheme.shadowRadius)
    }
    
    func buttonStyle(theme: Theme) -> some View {
        self
            .frame(height: theme.buttonHeight)
            .background(
                Group {
                    if let gradient = theme.buttonGradient {
                        gradient
                    } else {
                        theme.buttonBackground
                    }
                }
            )
            .cornerRadius(theme.buttonCornerRadius)
    }
    
    func neonGlow(color: Color, isActive: Bool = true) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: ThemeManager.shared.currentTheme.cornerRadius)
                .stroke(color, lineWidth: 2)
                .blur(radius: isActive && ThemeManager.shared.currentTheme.hasNeonEffect ? 8 : 0)
                .opacity(isActive && ThemeManager.shared.currentTheme.hasNeonEffect ? 0.8 : 0)
        )
    }
    
    func glassEffect() -> some View {
        self.modifier(GlassEffectModifier())
    }
}

// MARK: - Glass Effect Modifier
struct GlassEffectModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        if themeManager.currentTheme.hasGlassEffect {
            content
                .background(
                    ZStack {
                        Color.white.opacity(0.1)
                        VisualEffectBlur(blurStyle: .systemUltraThinMaterial)
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        } else {
            content
        }
    }
}

// MARK: - Visual Effect Blur
struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: blurStyle)
    }
}

// MARK: - Gradient Extension for Theme Support
extension Theme {
    var buttonGradient: LinearGradient? {
        if name == "retrowave" {
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.4, blue: 0.6), Color(red: 1.0, green: 0.6, blue: 0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        return nil
    }
}