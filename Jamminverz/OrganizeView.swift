//
//  OrganizeView.swift
//  Jamminverz
//
//  Comprehensive music organization suite with AI-powered classification
//

import SwiftUI
import AVFoundation

// MARK: - Organization Mode Enum
enum OrganizationMode: String, CaseIterable {
    case samples = "SAMPLES"
    case albums = "ALBUMS" 
    case tracks = "TRACKS"
    case playlists = "PLAYLISTS"
    
    var icon: String {
        switch self {
        case .samples: return "waveform"
        case .albums: return "opticaldisc"
        case .tracks: return "music.note"
        case .playlists: return "music.note.list"
        }
    }
    
    var itemCount: Int {
        switch self {
        case .samples: return 2500
        case .albums: return 127
        case .tracks: return 8942
        case .playlists: return 23
        }
    }
    
    var description: String {
        switch self {
        case .samples: return "One-shots\n& loops"
        case .albums: return "Full albums\n& EPs"
        case .tracks: return "Individual\nsongs"
        case .playlists: return "Custom sets\n& mixes"
        }
    }
}

// MARK: - Organization Method Enum
enum OrganizationMethod: String, CaseIterable {
    case aiAssistant = "AI ASSISTANT"
    case genreThis = "GENRE THIS!"
    
    var icon: String {
        switch self {
        case .aiAssistant: return "brain.filled.head.profile"
        case .genreThis: return "gamecontroller.fill"
        }
    }
    
    var subtitle: String {
        switch self {
        case .aiAssistant: return "Smart Batch Sort\nLet AI organize"
        case .genreThis: return "Manual Game Mode\nSwipe to categorize"
        }
    }
    
    var actionText: String {
        switch self {
        case .aiAssistant: return "View AI suggestions"
        case .genreThis: return "Fun & detailed\nOne by one review"
        }
    }
}

// MARK: - Main Organize View
struct OrganizeView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @State private var selectedMode: OrganizationMode? = nil
    @State private var selectedMethod: OrganizationMethod? = nil
    @State private var showingAIAssistant = false
    @State private var showingGenreThis = false
    
    var backgroundColor: Color {
        Color.black // Match app theme
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                if selectedMode == nil {
                    // Step 1: Choose Organization Mode
                    modeSelectionView
                } else if selectedMethod == nil {
                    // Step 2: Choose View Method
                    methodSelectionView
                } else {
                    // Step 3: Show selected organization interface
                    organizationInterfaceView
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showingAIAssistant) {
            if let mode = selectedMode {
                AIAssistantView(mode: mode, onClose: {
                    showingAIAssistant = false
                })
            }
        }
        .sheet(isPresented: $showingGenreThis) {
            if let mode = selectedMode {
                GenreThisView(mode: mode, onClose: {
                    showingGenreThis = false
                })
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Button(action: {
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                if selectedMethod != nil {
                    // Go back to method selection
                    selectedMethod = nil
                } else if selectedMode != nil {
                    // Go back to mode selection
                    selectedMode = nil
                } else {
                    // Go back to main menu
                    currentTab = "menu"
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                    Text("BACK")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Text("ORGANIZE")
                .font(.system(size: 17, weight: .heavy))
                .foregroundColor(.white)
            
            Spacer()
            
            // Invisible spacer to balance the header
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.clear)
                Text("BACK")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.clear)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .padding(.bottom, 20)
    }
    
    private var modeSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("CHOOSE ORGANIZATION MODE")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Mode grid - 2x2 layout
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(OrganizationMode.allCases, id: \.self) { mode in
                        OrganizationModeCard(mode: mode) {
                            selectedMode = mode
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Text("Select the type of content you want to organize")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 20)
            }
            .padding(.bottom, 40)
        }
    }
    
    private var methodSelectionView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let mode = selectedMode {
                    Text("ORGANIZE \(mode.rawValue)")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("Choose your organization method")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    // Method selection cards
                    VStack(spacing: 16) {
                        ForEach(OrganizationMethod.allCases, id: \.self) { method in
                            OrganizationMethodCard(method: method, mode: mode) {
                                selectedMethod = method
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                // Show appropriate interface
                                if method == .aiAssistant {
                                    showingAIAssistant = true
                                } else {
                                    showingGenreThis = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 40)
        }
    }
    
    private var organizationInterfaceView: some View {
        VStack {
            if let mode = selectedMode, let method = selectedMethod {
                Text("\(method.rawValue) - \(mode.rawValue)")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                Text("Organization interface will appear here")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 10)
            }
        }
    }
}

// MARK: - Organization Mode Card
struct OrganizationModeCard: View {
    let mode: OrganizationMode
    let action: () -> Void
    
    var cardColor: Color {
        switch mode {
        case .samples:
            return Color(red: 0.8, green: 0.52, blue: 0.54) // #cc8589 as requested
        case .albums:
            return Color(red: 0.373, green: 0.275, blue: 0.569) // Purple
        case .tracks:
            return Color(red: 1.0, green: 0.7, blue: 0.8) // Pink hint
        case .playlists:
            return Color(red: 0.8, green: 0.8, blue: 0.8) // Light gray as requested
        }
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 0) {
                // Main content area
                ZStack {
                    Rectangle()
                        .fill(cardColor)
                    
                    VStack(spacing: 16) {
                        // Icon and count
                        VStack(spacing: 8) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 32, weight: .heavy))
                                .foregroundColor(.white)
                            
                            Text("\(mode.itemCount)")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(.white)
                        }
                        
                        // Mode title
                        Text(mode.rawValue)
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }
                .frame(height: 120)
                
                // Description area with darker background
                VStack(spacing: 4) {
                    Text(mode.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(
                    cardColor
                        .overlay(Color.black.opacity(0.2))
                )
            }
            .background(cardColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Organization Method Card
struct OrganizationMethodCard: View {
    let method: OrganizationMethod
    let mode: OrganizationMode
    let action: () -> Void
    
    var cardColor: Color {
        switch method {
        case .aiAssistant:
            return Color(red: 0.373, green: 0.275, blue: 0.569) // Purple for AI
        case .genreThis:
            return Color(red: 1.0, green: 0.5, blue: 0.0) // Orange for game mode
        }
    }
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            HStack(spacing: 0) {
                // Icon section
                ZStack {
                    Rectangle()
                        .fill(cardColor)
                        .frame(width: 80)
                    
                    Image(systemName: method.icon)
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.white)
                }
                
                // Content section
                VStack(alignment: .leading, spacing: 8) {
                    Text(method.rawValue)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text(method.subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                    
                    Text(method.actionText)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    cardColor
                        .overlay(Color.black.opacity(0.1))
                )
                
                Spacer()
            }
            .frame(height: 80)
            .background(cardColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AI Assistant View
struct AIAssistantView: View {
    let mode: OrganizationMode
    let onClose: () -> Void
    @State private var isAnalyzing = false
    @State private var progress: Double = 0.0
    @State private var showResults = false
    @StateObject private var aiManager = AIOrganizationManager.shared
    
    // Mock organized results
    @State private var confident: [MockTrack] = []
    @State private var needsReview: [MockTrack] = []
    @State private var unknown: [MockTrack] = []
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("CLOSE") {
                        onClose()
                    }
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("AI ASSISTANT > ORGANIZE \(mode.rawValue)")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("CLOSE")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if showResults {
                    // Results interface
                    ScrollView {
                        VStack(spacing: 24) {
                            Text("ORGANIZATION RESULTS")
                                .font(.system(size: 24, weight: .heavy))
                                .foregroundColor(.white)
                                .padding(.top, 20)
                            
                            // AI Confident section
                            AIResultsCard(
                                title: "AI CONFIDENT (\(confident.count) tracks)",
                                icon: "✅",
                                subtitle: "Ready to organize automatically",
                                color: Color.green.opacity(0.2),
                                borderColor: Color.green,
                                buttons: [
                                    ("Accept All", Color.green),
                                    ("Review", Color.blue),
                                    ("Skip", Color.gray)
                                ]
                            )
                            
                            // Needs Review section
                            AIResultsCard(
                                title: "NEEDS REVIEW (\(needsReview.count) tracks)",
                                icon: "⚠️",
                                subtitle: "AI is unsure - needs your input",
                                color: Color.orange.opacity(0.2),
                                borderColor: Color.orange,
                                buttons: [
                                    ("Review Now", Color.orange),
                                    ("Skip for Later", Color.gray)
                                ]
                            )
                            
                            // Unknown section
                            AIResultsCard(
                                title: "UNKNOWN (\(unknown.count) tracks)",
                                icon: "❓",
                                subtitle: "AI couldn't classify",
                                color: Color.red.opacity(0.2),
                                borderColor: Color.red,
                                buttons: [
                                    ("Manual Review", Color.red),
                                    ("Skip", Color.gray)
                                ]
                            )
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                } else if isAnalyzing {
                    // Analysis in progress
                    Spacer()
                    VStack(spacing: 32) {
                        Image(systemName: "brain.filled.head.profile")
                            .font(.system(size: 80, weight: .heavy))
                            .foregroundColor(Color(red: 0.373, green: 0.275, blue: 0.569))
                        
                        Text("ANALYZING \(mode.rawValue)")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 16) {
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .white))
                                .frame(height: 8)
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                            
                            Text("Analyzing \(Int(progress * Double(mode.itemCount))) of \(mode.itemCount) items...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    // Initial state
                    Spacer()
                    VStack(spacing: 32) {
                        Image(systemName: "brain.filled.head.profile")
                            .font(.system(size: 80, weight: .heavy))
                            .foregroundColor(Color(red: 0.373, green: 0.275, blue: 0.569))
                        
                        Text("AI ORGANIZING \(mode.rawValue)")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                        
                        VStack(spacing: 16) {
                            Text("Ready to organize \(mode.itemCount) \(mode.rawValue.lowercased())")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                            
                            Button(action: {
                                startAIAnalysis()
                            }) {
                                Text("START AI ANALYSIS")
                                    .font(.system(size: 18, weight: .heavy))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal, 40)
                        }
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            generateMockData()
        }
    }
    
    private func startAIAnalysis() {
        isAnalyzing = true
        
        // Simulate AI analysis progress
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            progress += 0.02
            
            if progress >= 1.0 {
                timer.invalidate()
                isAnalyzing = false
                progress = 0.0
                
                // Show results after analysis
                withAnimation(.easeInOut(duration: 0.5)) {
                    showResults = true
                }
            }
        }
    }
    
    private func generateMockData() {
        // Generate realistic distribution
        let total = mode.itemCount
        let confidentCount = Int(Double(total) * 0.7) // 70% confident
        let reviewCount = Int(Double(total) * 0.25)   // 25% needs review  
        let unknownCount = total - confidentCount - reviewCount // 5% unknown
        
        confident = Array(1...confidentCount).map { MockTrack(id: $0, name: "Confident Track \($0)") }
        needsReview = Array(1...reviewCount).map { MockTrack(id: $0, name: "Review Track \($0)") }
        unknown = Array(1...unknownCount).map { MockTrack(id: $0, name: "Unknown Track \($0)") }
    }
}

// MARK: - Genre This View
struct GenreThisView: View {
    let mode: OrganizationMode
    let onClose: () -> Void
    @State private var currentTrackIndex = 0
    @State private var streak = 0
    @State private var totalClassified = 0
    @State private var isPlaying = false
    @State private var showStartInterface = true
    
    // Mock tracks for the mode
    @State private var tracks: [MockTrack] = []
    
    // Genre options based on mode
    var genreOptions: [String] {
        switch mode {
        case .samples:
            return ["DRUMS", "BASS", "MELODY", "FX", "VOCALS", "LOOP", "OTHER", "SKIP"]
        case .tracks:
            return ["LOFI", "HIP HOP", "ELECTRONIC", "ROCK", "POP", "JAZZ", "CLASSICAL", "OTHER", "SKIP"]
        case .albums:
            return ["ROCK", "POP", "JAZZ", "ELECTRONIC", "CLASSICAL", "HIP HOP", "OTHER", "SKIP"]
        case .playlists:
            return ["WORKOUT", "CHILL", "PARTY", "STUDY", "DANCE", "AMBIENT", "OTHER", "SKIP"]
        }
    }
    
    var currentTrack: MockTrack? {
        guard currentTrackIndex < tracks.count else { return nil }
        return tracks[currentTrackIndex]
    }
    
    var progress: Double {
        guard !tracks.isEmpty else { return 0.0 }
        return Double(currentTrackIndex) / Double(tracks.count)
    }
    
    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.5, blue: 0.0).ignoresSafeArea() // Orange theme
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("CLOSE") {
                        onClose()
                    }
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    if showStartInterface {
                        Text("GENRE THIS!")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                    } else {
                        Text("GENRE THIS! > TRACK \(currentTrackIndex + 1) of \(tracks.count)")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("CLOSE")
                        .font(.system(size: 16, weight: .heavy))
                        .foregroundColor(.clear)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                if showStartInterface {
                    // Start Interface
                    Spacer()
                    VStack(spacing: 32) {
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 80, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text("MANUAL ORGANIZATION")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text("Classify your \(mode.rawValue.lowercased()) one by one\nwith detailed control")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            startOrganizing()
                        }) {
                            Text("START ORGANIZING")
                                .font(.system(size: 18, weight: .heavy))
                                .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    // Game Interface
                    VStack(spacing: 24) {
                        // Progress and streak
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Progress: \(Int(progress * 100))% complete")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                // Progress bar
                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.white.opacity(0.3))
                                            .frame(height: 8)
                                        
                                        Rectangle()
                                            .fill(Color.white)
                                            .frame(width: geometry.size.width * progress, height: 8)
                                    }
                                }
                                .frame(height: 8)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Streak: 🔥 \(streak) in a row!")
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        // Current track card
                        if let track = currentTrack {
                            VStack(spacing: 20) {
                                // Track info card
                                VStack(spacing: 16) {
                                    VStack(spacing: 8) {
                                        Text("🎵 \(track.name)")
                                            .font(.system(size: 24, weight: .heavy))
                                            .foregroundColor(.white)
                                            .multilineTextAlignment(.center)
                                        
                                        Text(track.artist)
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    // Play controls
                                    HStack(spacing: 20) {
                                        Button(action: {
                                            isPlaying.toggle()
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                            impactFeedback.impactOccurred()
                                        }) {
                                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                                .font(.system(size: 48, weight: .medium))
                                                .foregroundColor(.white)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Text(track.duration)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    
                                    // Waveform visualization (simulated)
                                    HStack(spacing: 2) {
                                        ForEach(0..<50, id: \.self) { _ in
                                            Rectangle()
                                                .fill(Color.white.opacity(Double.random(in: 0.3...1.0)))
                                                .frame(width: 3, height: CGFloat.random(in: 8...40))
                                        }
                                    }
                                    .frame(height: 40)
                                }
                                .padding(24)
                                .background(Color.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal, 24)
                                
                                // Genre selection buttons
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(genreOptions, id: \.self) { genre in
                                        Button(action: {
                                            classifyTrack(as: genre)
                                        }) {
                                            Text(genre)
                                                .font(.system(size: 16, weight: .heavy))
                                                .foregroundColor(Color(red: 1.0, green: 0.5, blue: 0.0))
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 44)
                                                .background(Color.white)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 24)
                            }
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            generateMockTracks()
        }
    }
    
    private func startOrganizing() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showStartInterface = false
        }
    }
    
    private func classifyTrack(as genre: String) {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Update streak
        if genre != "SKIP" {
            streak += 1
            totalClassified += 1
        } else {
            streak = 0
        }
        
        // Move to next track
        if currentTrackIndex < tracks.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentTrackIndex += 1
            }
        } else {
            // Finished all tracks
            // Could show completion screen here
            onClose()
        }
    }
    
    private func generateMockTracks() {
        let trackNames = [
            "Midnight Groove", "Summer Vibes", "Digital Dreams", "Acoustic Sunset",
            "Urban Nights", "Electric Storm", "Chill Waves", "Rock Anthem",
            "Jazz Fusion", "Pop Star", "Classical Beauty", "Hip Hop Beat",
            "Lofi Study", "Dance Floor", "Ambient Space", "Metal Core"
        ]
        
        let artists = [
            "The Midnight", "Synthwave Co.", "Digital Artists", "Acoustic Soul",
            "Urban Collective", "Electric Band", "Chill Masters", "Rock Legends",
            "Jazz Ensemble", "Pop Icons", "Orchestra", "Hip Hop Crew",
            "Lofi Producers", "Dance Artists", "Ambient Makers", "Metal Warriors"
        ]
        
        tracks = Array(0..<mode.itemCount).map { index in
            MockTrack(
                id: index,
                name: trackNames[index % trackNames.count],
                artist: artists[index % artists.count],
                duration: "\(Int.random(in: 2...5)):\(String(format: "%02d", Int.random(in: 10...59)))"
            )
        }
    }
}

// MARK: - Supporting Components

// Mock track data
struct MockTrack: Identifiable {
    let id: Int
    let name: String
    let artist: String
    let duration: String
    
    init(id: Int, name: String, artist: String = "Unknown Artist", duration: String = "3:24") {
        self.id = id
        self.name = name
        self.artist = artist
        self.duration = duration
    }
}

// AI Results Card Component
struct AIResultsCard: View {
    let title: String
    let icon: String
    let subtitle: String
    let color: Color
    let borderColor: Color
    let buttons: [(String, Color)]
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(icon)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
            
            // Action buttons
            HStack(spacing: 12) {
                ForEach(Array(buttons.enumerated()), id: \.offset) { index, button in
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        // Handle button action
                    }) {
                        Text(button.0)
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(button.1)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(color)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    OrganizeView(taskStore: TaskStore(), currentTab: .constant("organize"))
}