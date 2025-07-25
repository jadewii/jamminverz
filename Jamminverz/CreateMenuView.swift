//
//  CreateMenuView.swift
//  Jamminverz
//
//  Project type selection menu
//

import SwiftUI

struct CreateMenuView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var themeManager = ThemeManager.shared
    @State private var selectedProjectType: ProjectType?
    @State private var showCreateFlow = false
    
    enum ProjectType: String, CaseIterable {
        case samplePack = "SAMPLE PACK"
        case album = "ALBUM"
        case collab = "COLLAB"
        case beatTape = "BEAT TAPE"
        case single = "SINGLE"
        case remix = "REMIX"
        case loopKit = "LOOP KIT"
        case soundBank = "SOUND BANK"
        
        var description: String {
            switch self {
            case .samplePack: return "Organize samples into packs"
            case .album: return "Create full album releases"
            case .collab: return "Start collaborative projects"
            case .beatTape: return "Beat collections & mixtapes"
            case .single: return "Single track releases"
            case .remix: return "Remix existing tracks"
            case .loopKit: return "Loop collections for producers"
            case .soundBank: return "Preset & sound collections"
            }
        }
        
        var icon: String {
            switch self {
            case .samplePack: return "square.grid.2x2.fill"
            case .album: return "music.note.list"
            case .collab: return "person.2.fill"
            case .beatTape: return "metronome.fill"
            case .single: return "music.note"
            case .remix: return "arrow.triangle.2.circlepath"
            case .loopKit: return "repeat"
            case .soundBank: return "waveform"
            }
        }
        
        var color: Color {
            switch self {
            case .samplePack: return Color.purple
            case .album: return Color.blue
            case .collab: return Color.green
            case .beatTape: return Color.orange
            case .single: return Color.pink
            case .remix: return Color.red
            case .loopKit: return Color.yellow
            case .soundBank: return Color.cyan
            }
        }
    }
    
    var body: some View {
        ZStack {
            themeManager.currentTheme.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Title section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CREATE NEW PROJECT")
                                .font(.system(size: 34, weight: .heavy))
                                .foregroundColor(.white)
                            
                            Text("Choose a project type to get started")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        // Project type grid
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(ProjectType.allCases, id: \.self) { type in
                                    ProjectTypeCard(
                                        type: type,
                                        onTap: {
                                            selectedProjectType = type
                                            handleProjectTypeSelection(type)
                                        }
                                    )
                                    .frame(width: 260)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Recent projects section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("RECENT PROJECTS")
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {}) {
                                    Text("SEE ALL")
                                        .font(.system(size: 12, weight: .heavy))
                                        .foregroundColor(themeManager.currentTheme.accentColor)
                                }
                            }
                            
                            // Recent project cards would go here
                            Text("No recent projects")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 24)
                        
                        // Templates section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("TEMPLATES")
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    TemplateCard(title: "Hip Hop Beat", icon: "🎵")
                                    TemplateCard(title: "House Track", icon: "🎹")
                                    TemplateCard(title: "Trap Beat", icon: "🥁")
                                    TemplateCard(title: "Lo-Fi Session", icon: "🎧")
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(isPresented: $showCreateFlow) {
            if let type = selectedProjectType {
                switch type {
                case .album:
                    CreateAlbumView(taskStore: taskStore, albums: .constant([]))
                case .samplePack:
                    CreatePackSheet(samplesManager: ModernSamplesManager())
                default:
                    // For other types, show the drum machine for now
                    CreateView(taskStore: taskStore, currentTab: $currentTab)
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("CREATE")
                    .font(.system(size: 34, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("Start a new project")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private func handleProjectTypeSelection(_ type: ProjectType) {
        // Handle the selection based on type
        selectedProjectType = type
        
        // For now, show the create flow for album and sample pack
        // You can expand this to show specific creation flows for each type
        if type == .album || type == .samplePack {
            showCreateFlow = true
        } else {
            // For other types, navigate to the drum machine
            currentTab = "studio"
        }
    }
}

// MARK: - Project Type Card
struct ProjectTypeCard: View {
    let type: CreateMenuView.ProjectType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Visual representation (similar to sample pack grid)
                ZStack {
                    // Background pattern
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2)
                    ], spacing: 2) {
                        ForEach(0..<16) { i in
                            Rectangle()
                                .fill(type.color.opacity(Double.random(in: 0.3...0.8)))
                                .aspectRatio(1, contentMode: .fit)
                                .cornerRadius(2)
                        }
                    }
                    .padding(8)
                    .frame(height: 120)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                    
                    // Icon overlay
                    Image(systemName: type.icon)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white)
                        .padding(16)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Circle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.rawValue)
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text(type.description)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Template Card
struct TemplateCard: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 48))
                .frame(width: 100, height: 100)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            
            Text(title)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(.white)
        }
        .frame(width: 120)
    }
}

#Preview {
    CreateMenuView(
        taskStore: TaskStore(),
        currentTab: .constant("create")
    )
}