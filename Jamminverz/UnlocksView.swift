//
//  UnlocksView.swift
//  Jamminverz
//
//  Gamification system with unlockable themes, stickers, and visualizers
//

import SwiftUI

struct UnlocksView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var selectedCategory = "all"
    @State private var userStats = UnlockUserStats()
    @State private var unlockedItems: Set<String> = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Stats Overview
                statsOverview
                
                // Category Filter
                categoryFilter
                
                // Unlockables Grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(filteredUnlockables) { unlockable in
                            UnlockableCard(
                                unlockable: unlockable,
                                isUnlocked: unlockedItems.contains(unlockable.id),
                                userStats: userStats
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            loadUserProgress()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("UNLOCKS")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text("Earn rewards by reaching milestones")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Level Badge
                VStack(spacing: 4) {
                    Text("LVL")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.gray)
                    Text("\(userStats.level)")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.purple)
                }
                .frame(width: 60, height: 60)
                .background(Color.purple.opacity(0.2))
                .clipShape(Circle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }
    
    private var statsOverview: some View {
        HStack(spacing: 12) {
            UnlockStatBox(
                title: "PROJECTS",
                value: "\(userStats.projectsCreated)",
                icon: "music.note",
                color: .blue
            )
            
            UnlockStatBox(
                title: "SAMPLES",
                value: "\(userStats.samplesCreated)",
                icon: "square.grid.2x2",
                color: .green
            )
            
            UnlockStatBox(
                title: "COLLABS",
                value: "\(userStats.collabsCompleted)",
                icon: "person.2",
                color: .pink
            )
            
            UnlockStatBox(
                title: "PLAYS",
                value: formatNumber(userStats.totalPlays),
                icon: "play.circle",
                color: .orange
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
    
    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(title: "ALL", isSelected: selectedCategory == "all") {
                    selectedCategory = "all"
                }
                FilterChip(title: "THEMES", isSelected: selectedCategory == "themes") {
                    selectedCategory = "themes"
                }
                FilterChip(title: "STICKERS", isSelected: selectedCategory == "stickers") {
                    selectedCategory = "stickers"
                }
                FilterChip(title: "VISUALIZERS", isSelected: selectedCategory == "visualizers") {
                    selectedCategory = "visualizers"
                }
                FilterChip(title: "BADGES", isSelected: selectedCategory == "badges") {
                    selectedCategory = "badges"
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }
    
    private var filteredUnlockables: [Unlockable] {
        let allUnlockables = generateUnlockables()
        
        switch selectedCategory {
        case "all":
            return allUnlockables
        case "themes":
            return allUnlockables.filter { $0.type == .theme }
        case "stickers":
            return allUnlockables.filter { $0.type == .sticker }
        case "visualizers":
            return allUnlockables.filter { $0.type == .visualizer }
        case "badges":
            return allUnlockables.filter { $0.type == .badge }
        default:
            return allUnlockables
        }
    }
    
    private func loadUserProgress() {
        // Load user stats and unlocked items
        userStats = UnlockUserStats(
            level: 12,
            projectsCreated: 45,
            samplesCreated: 320,
            collabsCompleted: 8,
            totalPlays: 12500
        )
        
        // Mock unlocked items
        unlockedItems = ["theme1", "sticker1", "sticker2", "badge1", "badge2", "badge3"]
    }
    
    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return "\(number / 1000)K"
        }
        return "\(number)"
    }
    
    private func generateUnlockables() -> [Unlockable] {
        return [
            // Themes
            Unlockable(
                id: "theme1",
                type: .theme,
                title: "Neon Dreams",
                description: "Vibrant neon profile theme",
                icon: "🌈",
                requirement: .projectCount(10),
                tier: .bronze
            ),
            Unlockable(
                id: "theme2",
                type: .theme,
                title: "Dark Mode Pro",
                description: "Premium dark theme with accents",
                icon: "🌙",
                requirement: .projectCount(25),
                tier: .silver
            ),
            Unlockable(
                id: "theme3",
                type: .theme,
                title: "Holographic",
                description: "Animated holographic theme",
                icon: "✨",
                requirement: .level(20),
                tier: .gold
            ),
            
            // Stickers
            Unlockable(
                id: "sticker1",
                type: .sticker,
                title: "Fire Producer",
                description: "Show off your heat",
                icon: "🔥",
                requirement: .sampleCount(100),
                tier: .bronze
            ),
            Unlockable(
                id: "sticker2",
                type: .sticker,
                title: "Beat Master",
                description: "Master of the beats",
                icon: "🥁",
                requirement: .sampleCount(250),
                tier: .silver
            ),
            Unlockable(
                id: "sticker3",
                type: .sticker,
                title: "Synth Wizard",
                description: "Synthesis expert",
                icon: "🎹",
                requirement: .projectCount(50),
                tier: .gold
            ),
            
            // Visualizers
            Unlockable(
                id: "viz1",
                type: .visualizer,
                title: "Wave Form",
                description: "Classic waveform visualizer",
                icon: "📊",
                requirement: .playCount(1000),
                tier: .bronze
            ),
            Unlockable(
                id: "viz2",
                type: .visualizer,
                title: "Particle Storm",
                description: "Reactive particle effects",
                icon: "🌟",
                requirement: .playCount(5000),
                tier: .silver
            ),
            Unlockable(
                id: "viz3",
                type: .visualizer,
                title: "3D Spectrum",
                description: "Advanced 3D visualization",
                icon: "🎆",
                requirement: .level(30),
                tier: .gold
            ),
            
            // Badges
            Unlockable(
                id: "badge1",
                type: .badge,
                title: "Early Adopter",
                description: "One of the first users",
                icon: "🏆",
                requirement: .special,
                tier: .gold
            ),
            Unlockable(
                id: "badge2",
                type: .badge,
                title: "Collab King",
                description: "Complete 5 collaborations",
                icon: "👑",
                requirement: .collabCount(5),
                tier: .silver
            ),
            Unlockable(
                id: "badge3",
                type: .badge,
                title: "Sample Collector",
                description: "Create 500 samples",
                icon: "💎",
                requirement: .sampleCount(500),
                tier: .platinum
            )
        ]
    }
}

// MARK: - Models
struct UnlockUserStats {
    var level: Int = 1
    var projectsCreated: Int = 0
    var samplesCreated: Int = 0
    var collabsCompleted: Int = 0
    var totalPlays: Int = 0
}

struct Unlockable: Identifiable {
    let id: String
    let type: UnlockableType
    let title: String
    let description: String
    let icon: String
    let requirement: UnlockRequirement
    let tier: UnlockTier
}

enum UnlockableType {
    case theme
    case sticker
    case visualizer
    case badge
}

enum UnlockRequirement {
    case projectCount(Int)
    case sampleCount(Int)
    case collabCount(Int)
    case playCount(Int)
    case level(Int)
    case special
    
    func isMetBy(_ stats: UnlockUserStats) -> Bool {
        switch self {
        case .projectCount(let count):
            return stats.projectsCreated >= count
        case .sampleCount(let count):
            return stats.samplesCreated >= count
        case .collabCount(let count):
            return stats.collabsCompleted >= count
        case .playCount(let count):
            return stats.totalPlays >= count
        case .level(let level):
            return stats.level >= level
        case .special:
            return false // Special unlocks handled separately
        }
    }
    
    var description: String {
        switch self {
        case .projectCount(let count):
            return "Create \(count) projects"
        case .sampleCount(let count):
            return "Create \(count) samples"
        case .collabCount(let count):
            return "Complete \(count) collabs"
        case .playCount(let count):
            return "Get \(count) plays"
        case .level(let level):
            return "Reach level \(level)"
        case .special:
            return "Special achievement"
        }
    }
}

enum UnlockTier {
    case bronze
    case silver
    case gold
    case platinum
    
    var color: Color {
        switch self {
        case .bronze: return Color(red: 0.8, green: 0.5, blue: 0.2)
        case .silver: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case .platinum: return Color(red: 0.9, green: 0.9, blue: 0.95)
        }
    }
}

// MARK: - Components
struct UnlockStatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.2))
        .cornerRadius(12)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.purple : Color.white.opacity(0.2))
                .cornerRadius(20)
        }
    }
}

struct UnlockableCard: View {
    let unlockable: Unlockable
    let isUnlocked: Bool
    let userStats: UnlockUserStats
    
    private var canUnlock: Bool {
        unlockable.requirement.isMetBy(userStats) && !isUnlocked
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Icon Section
            ZStack {
                Rectangle()
                    .fill(unlockable.tier.color.opacity(isUnlocked ? 0.3 : 0.1))
                    .frame(height: 100)
                
                Text(unlockable.icon)
                    .font(.system(size: 50))
                    .opacity(isUnlocked ? 1.0 : 0.3)
                
                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.5))
                        .offset(x: 30, y: -30)
                }
                
                // Tier indicator
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(unlockable.tier.color)
                            .frame(width: 8, height: 8)
                            .padding(6)
                    }
                    Spacer()
                }
            }
            
            // Info Section
            VStack(alignment: .leading, spacing: 8) {
                Text(unlockable.title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(isUnlocked ? .white : .gray)
                    .lineLimit(1)
                
                Text(unlockable.description)
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Progress or Status
                if isUnlocked {
                    Label("UNLOCKED", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.green)
                } else if canUnlock {
                    Button(action: {}) {
                        Text("CLAIM")
                            .font(.system(size: 12, weight: .heavy))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.purple)
                            .cornerRadius(8)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(unlockable.requirement.description)
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                        
                        // Progress bar for countable requirements
                        if case .projectCount(let required) = unlockable.requirement {
                            ProgressBar(current: userStats.projectsCreated, total: required)
                        } else if case .sampleCount(let required) = unlockable.requirement {
                            ProgressBar(current: userStats.samplesCreated, total: required)
                        } else if case .collabCount(let required) = unlockable.requirement {
                            ProgressBar(current: userStats.collabsCompleted, total: required)
                        } else if case .playCount(let required) = unlockable.requirement {
                            ProgressBar(current: userStats.totalPlays, total: required)
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(canUnlock ? Color.purple : Color.clear, lineWidth: 2)
        )
    }
}

struct ProgressBar: View {
    let current: Int
    let total: Int
    
    private var progress: Double {
        min(1.0, Double(current) / Double(total))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(current)/\(total)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.purple)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 4)
                    
                    Rectangle()
                        .fill(Color.purple)
                        .frame(width: geometry.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)
        }
    }
}

#Preview {
    UnlocksView(
        taskStore: TaskStore(),
        currentTab: .constant("unlocks")
    )
}