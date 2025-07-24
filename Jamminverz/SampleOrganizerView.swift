//
//  SampleOrganizerView.swift
//  Jamminverz
//
//  Ultimate AI-powered sample organizer with advanced features
//

import SwiftUI
import AVFoundation
import Combine

// MARK: - Sample Data Models
struct Sample: Identifiable, Codable {
    let id: UUID
    let originalPath: String
    let fileName: String
    let fileSize: Int64
    let dateAdded: Date
    var analyzedData: SampleAnalysis?
    var suggestedName: String?
    var duplicates: [String] = []
    var similarSamples: [String] = []
    var tags: [String] = []
    var isSelected: Bool = false
    
    var displayName: String {
        suggestedName ?? fileName
    }
    
    var filePath: String {
        originalPath
    }
}

struct SampleAnalysis: Codable {
    let bpm: Int?
    let key: String?
    let instrument: InstrumentType
    let energy: Int // 1-10 scale
    let mood: MoodType
    let isLoop: Bool
    let quality: AudioQuality
    let duration: TimeInterval
    let hasVocals: Bool
    let confidence: Double // AI confidence 0-1
}

struct AudioQuality: Codable {
    let bitDepth: Int
    let sampleRate: Int
    let bitrate: Int?
    let format: String
}

enum InstrumentType: String, CaseIterable, Codable {
    case kick = "Kick"
    case snare = "Snare"
    case bass = "Bass"
    case melody = "Melody"
    case fx = "FX"
    case vocal = "Vocal"
    case percussion = "Percussion"
    case lead = "Lead"
    case pad = "Pad"
    case unknown = "Unknown"
    
    var emoji: String {
        switch self {
        case .kick: return "🥁"
        case .snare: return "🥁"
        case .bass: return "🎸"
        case .melody: return "🎵"
        case .fx: return "✨"
        case .vocal: return "🎤"
        case .percussion: return "🥁"
        case .lead: return "🎹"
        case .pad: return "🎼"
        case .unknown: return "❓"
        }
    }
}

enum MoodType: String, CaseIterable, Codable {
    case dark = "Dark"
    case bright = "Bright"
    case aggressive = "Aggressive"
    case chill = "Chill"
    case melodic = "Melodic"
    case energetic = "Energetic"
    case ambient = "Ambient"
    case emotional = "Emotional"
    
    var color: Color {
        switch self {
        case .dark: return Color.purple.opacity(0.8)
        case .bright: return Color.yellow.opacity(0.8)
        case .aggressive: return Color.red.opacity(0.8)
        case .chill: return Color.blue.opacity(0.8)
        case .melodic: return Color.green.opacity(0.8)
        case .energetic: return Color.orange.opacity(0.8)
        case .ambient: return Color.gray.opacity(0.8)
        case .emotional: return Color.pink.opacity(0.8)
        }
    }
}

// MARK: - Sample Organizer View Manager
@MainActor
class SampleOrganizerManager: ObservableObject {
    static let shared = SampleOrganizerManager()
    
    @Published var samples: [Sample] = []
    @Published var selectedSamples: [Sample] = []
    @Published var searchText: String = ""
    @Published var isAnalyzing: Bool = false
    @Published var analysisProgress: Double = 0.0
    @Published var currentlyPlaying: Sample?
    @Published var selectedInstrumentFilter: InstrumentType?
    @Published var selectedMoodFilter: MoodType?
    @Published var bpmRange: ClosedRange<Int> = 60...200
    @Published var energyRange: ClosedRange<Int> = 1...10
    
    // Analytics data
    @Published var analytics: SampleAnalytics = SampleAnalytics()
    
    private var audioEngine = AVAudioEngine()
    private var audioPlayer: AVAudioPlayer?
    
    private init() {
        loadSampleLibrary()
        setupAudioEngine()
    }
    
    // MARK: - Sample Library Management
    func loadSampleLibrary() {
        // Simulate loading existing samples from user's library
        _Concurrency.Task {
            await generateMockSamples()
            await MainActor.run {
                updateAnalytics()
            }
        }
    }
    
    func scanForNewSamples() {
        isAnalyzing = true
        analysisProgress = 0.0
        
        // Use Task for proper Swift concurrency
        _Concurrency.Task {
            // In real implementation, this would scan user directories
            let newSamples = await generateMockNewSamples()
            
            for (index, sample) in newSamples.enumerated() {
                // Analyze each sample
                do {
                    let analysis = try await AudioAnalysisEngine.shared.analyzeSample(at: URL(fileURLWithPath: sample.originalPath))
                    let suggestedName = await generateSmartName(sample, analysis: analysis)
                    let tags = await generateTags(from: analysis)
                    
                    let analyzedSample = Sample(
                        id: sample.id,
                        originalPath: sample.originalPath,
                        fileName: sample.fileName,
                        fileSize: sample.fileSize,
                        dateAdded: sample.dateAdded,
                        analyzedData: analysis,
                        suggestedName: suggestedName,
                        tags: tags
                    )
                    
                    await MainActor.run {
                        self.samples.append(analyzedSample)
                        self.analysisProgress = Double(index + 1) / Double(newSamples.count)
                    }
                } catch {
                    // Skip samples that fail to analyze
                    print("Failed to analyze sample \\(sample.fileName): \\(error)")
                }
                
                try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            await MainActor.run {
                self.isAnalyzing = false
                self.updateAnalytics()
                self.detectDuplicates()
                self.findSimilarSamples()
            }
        }
    }
    
    // MARK: - Audio Analysis & Intelligence
    func generateSmartName(_ sample: Sample, analysis: SampleAnalysis) async -> String {
        var parts: [String] = []
        
        // Add mood if confident
        if analysis.confidence > 0.7 {
            parts.append(analysis.mood.rawValue)
        }
        
        // Add genre hint based on BPM
        if let bpm = analysis.bpm {
            if bpm >= 130 && bpm <= 150 {
                parts.append("Trap")
            } else if bpm >= 120 && bpm <= 130 {
                parts.append("House")
            } else if bpm <= 90 {
                parts.append("Lofi")
            }
        }
        
        // Add instrument
        parts.append(analysis.instrument.rawValue)
        
        // Add BPM
        if let bpm = analysis.bpm {
            parts.append("\(bpm)BPM")
        }
        
        // Add key
        if let key = analysis.key {
            parts.append(key.replacingOccurrences(of: " ", with: ""))
        }
        
        let baseName = parts.joined(separator: "_")
        let fileExtension = URL(fileURLWithPath: sample.originalPath).pathExtension
        
        return "\(baseName).\(fileExtension)"
    }
    
    func generateTags(from analysis: SampleAnalysis) async -> [String] {
        var tags: [String] = []
        
        tags.append(analysis.instrument.rawValue.lowercased())
        tags.append(analysis.mood.rawValue.lowercased())
        
        if analysis.energy >= 8 {
            tags.append("high-energy")
        } else if analysis.energy <= 3 {
            tags.append("low-energy")
        }
        
        if analysis.isLoop {
            tags.append("loop")
        }
        
        if analysis.hasVocals {
            tags.append("vocal")
        }
        
        if let bpm = analysis.bpm {
            if bpm >= 140 {
                tags.append("fast")
            } else if bpm <= 80 {
                tags.append("slow")
            }
        }
        
        return tags
    }
    
    // MARK: - Duplicate & Similarity Detection
    func detectDuplicates() {
        var duplicateGroups: [[Sample]] = []
        var processed: Set<UUID> = []
        
        for sample in samples {
            if processed.contains(sample.id) { continue }
            
            var duplicates: [Sample] = [sample]
            
            for otherSample in samples {
                if sample.id == otherSample.id || processed.contains(otherSample.id) { continue }
                
                // Check for exact duplicates (same file size and similar names)
                if abs(sample.fileSize - otherSample.fileSize) < 1000 && 
                   areFilesSimilar(sample.fileName, otherSample.fileName) {
                    duplicates.append(otherSample)
                    processed.insert(otherSample.id)
                }
            }
            
            if duplicates.count > 1 {
                duplicateGroups.append(duplicates)
            }
            processed.insert(sample.id)
        }
        
        // Update samples with duplicate information
        for group in duplicateGroups {
            let duplicatePaths = group.map { $0.originalPath }
            for sample in group {
                if let index = samples.firstIndex(where: { $0.id == sample.id }) {
                    samples[index].duplicates = duplicatePaths.filter { $0 != sample.originalPath }
                }
            }
        }
        
        updateAnalytics()
    }
    
    func findSimilarSamples() {
        for (index, sample) in samples.enumerated() {
            guard let analysis = sample.analyzedData else { continue }
            
            var similarSamples: [String] = []
            
            for otherSample in samples {
                if sample.id == otherSample.id { continue }
                guard let otherAnalysis = otherSample.analyzedData else { continue }
                
                let similarity = calculateSimilarity(analysis, otherAnalysis)
                if similarity > 0.7 { // 70% similarity threshold
                    similarSamples.append(otherSample.originalPath)
                }
            }
            
            samples[index].similarSamples = similarSamples
        }
    }
    
    private func calculateSimilarity(_ analysis1: SampleAnalysis, _ analysis2: SampleAnalysis) -> Double {
        var similarityScore = 0.0
        var factors = 0
        
        // Instrument similarity
        if analysis1.instrument == analysis2.instrument {
            similarityScore += 0.3
        }
        factors += 1
        
        // BPM similarity
        if let bpm1 = analysis1.bpm, let bpm2 = analysis2.bpm {
            let bpmDiff = abs(bpm1 - bpm2)
            if bpmDiff <= 5 {
                similarityScore += 0.25
            } else if bpmDiff <= 10 {
                similarityScore += 0.15
            }
        }
        factors += 1
        
        // Energy similarity
        let energyDiff = abs(analysis1.energy - analysis2.energy)
        if energyDiff <= 1 {
            similarityScore += 0.2
        } else if energyDiff <= 2 {
            similarityScore += 0.1
        }
        factors += 1
        
        // Mood similarity
        if analysis1.mood == analysis2.mood {
            similarityScore += 0.25
        }
        factors += 1
        
        return similarityScore
    }
    
    private func areFilesSimilar(_ name1: String, _ name2: String) -> Bool {
        let clean1 = name1.lowercased().replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
        let clean2 = name2.lowercased().replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
        
        // Check if one name contains the other (accounting for version numbers, etc.)
        return clean1.contains(clean2.prefix(min(clean2.count, 10))) || 
               clean2.contains(clean1.prefix(min(clean1.count, 10)))
    }
    
    // MARK: - Audio Playback
    private func setupAudioEngine() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    func previewSample(_ sample: Sample) {
        // Stop current playback
        audioPlayer?.stop()
        
        // In real implementation, would load actual audio file
        currentlyPlaying = sample
        
        // Simulate playback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Would play actual audio here
            print("Playing sample: \(sample.displayName)")
        }
        
        // Auto-stop after duration
        if let duration = sample.analyzedData?.duration {
            DispatchQueue.main.asyncAfter(deadline: .now() + min(duration, 10.0)) {
                if self.currentlyPlaying?.id == sample.id {
                    self.stopPreview()
                }
            }
        }
    }
    
    func stopPreview() {
        audioPlayer?.stop()
        currentlyPlaying = nil
    }
    
    // MARK: - Filtering & Search
    var filteredSamples: [Sample] {
        var filtered = samples
        
        // Text search
        if !searchText.isEmpty {
            filtered = filtered.filter { sample in
                let searchTerms = searchText.lowercased().components(separatedBy: " ")
                return searchTerms.allSatisfy { term in
                    sample.displayName.lowercased().contains(term) ||
                    sample.tags.joined(separator: " ").lowercased().contains(term) ||
                    (sample.analyzedData?.key?.lowercased().contains(term) ?? false) ||
                    (sample.analyzedData?.bpm.map { "\($0)bpm" }.map { $0.contains(term) } ?? false)
                }
            }
        }
        
        // Instrument filter
        if let instrumentFilter = selectedInstrumentFilter {
            filtered = filtered.filter { $0.analyzedData?.instrument == instrumentFilter }
        }
        
        // Mood filter
        if let moodFilter = selectedMoodFilter {
            filtered = filtered.filter { $0.analyzedData?.mood == moodFilter }
        }
        
        // BPM range filter
        filtered = filtered.filter { sample in
            guard let bpm = sample.analyzedData?.bpm else { return true }
            return bpmRange.contains(bpm)
        }
        
        // Energy range filter
        filtered = filtered.filter { sample in
            let energy = sample.analyzedData?.energy ?? 5
            return energyRange.contains(energy)
        }
        
        return filtered
    }
    
    // MARK: - Analytics
    func updateAnalytics() {
        let totalSamples = samples.count
        let analyzedSamples = samples.filter { $0.analyzedData != nil }
        
        // Instrument breakdown
        var instrumentCounts: [InstrumentType: Int] = [:]
        for instrument in InstrumentType.allCases {
            instrumentCounts[instrument] = analyzedSamples.filter { $0.analyzedData?.instrument == instrument }.count
        }
        
        // BPM distribution
        let bpms = analyzedSamples.compactMap { $0.analyzedData?.bpm }
        let bpmRanges: [(range: String, count: Int)] = [
            ("60-80", bpms.filter { $0 >= 60 && $0 < 80 }.count),
            ("80-100", bpms.filter { $0 >= 80 && $0 < 100 }.count),
            ("100-120", bpms.filter { $0 >= 100 && $0 < 120 }.count),
            ("120-140", bpms.filter { $0 >= 120 && $0 < 140 }.count),
            ("140+", bpms.filter { $0 >= 140 }.count)
        ]
        
        // Duplicates
        let duplicateCount = samples.filter { !$0.duplicates.isEmpty }.count
        
        // Quality issues
        let qualityIssues = analyzedSamples.filter { sample in
            guard let quality = sample.analyzedData?.quality else { return false }
            return quality.sampleRate < 44100 || quality.bitDepth < 16
        }.count
        
        analytics = SampleAnalytics(
            totalSamples: totalSamples,
            analyzedSamples: analyzedSamples.count,
            instrumentCounts: instrumentCounts,
            bpmDistribution: bpmRanges,
            duplicateCount: duplicateCount,
            qualityIssues: qualityIssues,
            totalFileSize: samples.reduce(0) { $0 + $1.fileSize }
        )
    }
    
    // MARK: - Mock Data Generation
    private func generateMockSamples() async {
        let instruments: [InstrumentType] = [.kick, .snare, .bass, .melody, .fx, .vocal]
        let moods: [MoodType] = [.dark, .bright, .aggressive, .chill, .melodic, .energetic]
        
        let sampleNames = [
            "dark_trap_kick", "aggressive_snare", "melodic_bass_loop", "bright_melody",
            "atmospheric_fx", "vocal_chop", "deep_kick", "crisp_snare", "sub_bass",
            "lead_synth", "reverb_fx", "vocal_hook", "punchy_kick", "rim_shot",
            "wobble_bass", "arp_sequence", "sweep_fx", "vocal_texture"
        ]
        
        for i in 0..<50 {
            let instrument = instruments.randomElement()!
            let mood = moods.randomElement()!
            let bpm = Int.random(in: 70...150)
            let energy = Int.random(in: 1...10)
            
            let analysis = SampleAnalysis(
                bpm: bpm,
                key: ["C", "D", "E", "F", "G", "A", "B"].randomElement()! + (Bool.random() ? " major" : " minor"),
                instrument: instrument,
                energy: energy,
                mood: mood,
                isLoop: Bool.random(),
                quality: AudioQuality(bitDepth: [16, 24].randomElement()!, sampleRate: [44100, 48000].randomElement()!, bitrate: [320, 256, 192].randomElement(), format: "wav"),
                duration: Double.random(in: 1.0...30.0),
                hasVocals: instrument == .vocal,
                confidence: Double.random(in: 0.6...0.95)
            )
            
            let sample = Sample(
                id: UUID(),
                originalPath: "/samples/\(sampleNames.randomElement()!)_\(i).wav",
                fileName: "\(sampleNames.randomElement()!)_\(i).wav",
                fileSize: Int64.random(in: 100000...5000000),
                dateAdded: Date().addingTimeInterval(-Double.random(in: 0...86400*30)),
                analyzedData: analysis,
                tags: await generateTags(from: analysis)
            )
            
            samples.append(sample)
        }
        
        updateAnalytics()
    }
    
    private func generateMockNewSamples() async -> [Sample] {
        // Generate fewer samples for scanning simulation
        return Array(samples.prefix(10))
    }
}

// MARK: - Analytics Data Structure
struct SampleAnalytics {
    let totalSamples: Int
    let analyzedSamples: Int
    let instrumentCounts: [InstrumentType: Int]
    let bpmDistribution: [(range: String, count: Int)]
    let duplicateCount: Int
    let qualityIssues: Int
    let totalFileSize: Int64
    
    init() {
        self.totalSamples = 0
        self.analyzedSamples = 0
        self.instrumentCounts = [:]
        self.bpmDistribution = []
        self.duplicateCount = 0
        self.qualityIssues = 0
        self.totalFileSize = 0
    }
    
    init(totalSamples: Int, analyzedSamples: Int, instrumentCounts: [InstrumentType: Int], bpmDistribution: [(range: String, count: Int)], duplicateCount: Int, qualityIssues: Int, totalFileSize: Int64) {
        self.totalSamples = totalSamples
        self.analyzedSamples = analyzedSamples
        self.instrumentCounts = instrumentCounts
        self.bpmDistribution = bpmDistribution
        self.duplicateCount = duplicateCount
        self.qualityIssues = qualityIssues
        self.totalFileSize = totalFileSize
    }
    
    var fileSizeFormatted: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalFileSize)
    }
}

// MARK: - Sample Analyzer (AI Engine)
actor SampleAnalyzer {
    func analyzeSample(_ sample: Sample) -> SampleAnalysis {
        // In real implementation, this would use actual audio analysis
        // For now, we'll simulate based on filename patterns
        
        let fileName = sample.fileName.lowercased()
        
        // Detect instrument
        var instrument: InstrumentType = .unknown
        if fileName.contains("kick") || fileName.contains("bd") {
            instrument = .kick
        } else if fileName.contains("snare") || fileName.contains("sd") {
            instrument = .snare
        } else if fileName.contains("bass") || fileName.contains("sub") {
            instrument = .bass
        } else if fileName.contains("melody") || fileName.contains("lead") || fileName.contains("synth") {
            instrument = .melody
        } else if fileName.contains("fx") || fileName.contains("effect") || fileName.contains("sweep") {
            instrument = .fx
        } else if fileName.contains("vocal") || fileName.contains("vox") {
            instrument = .vocal
        }
        
        // Detect mood
        var mood: MoodType = .chill
        if fileName.contains("dark") || fileName.contains("deep") {
            mood = .dark
        } else if fileName.contains("bright") || fileName.contains("happy") {
            mood = .bright
        } else if fileName.contains("aggressive") || fileName.contains("hard") {
            mood = .aggressive
        } else if fileName.contains("melodic") || fileName.contains("sweet") {
            mood = .melodic
        } else if fileName.contains("energetic") || fileName.contains("pump") {
            mood = .energetic
        }
        
        // Generate realistic audio analysis
        let bpm = Int.random(in: 70...150)
        let energy = Int.random(in: 1...10)
        let isLoop = fileName.contains("loop") || fileName.contains("_lp")
        let hasVocals = instrument == .vocal
        
        return SampleAnalysis(
            bpm: bpm,
            key: ["C", "D", "E", "F", "G", "A", "B"].randomElement()! + (Bool.random() ? " major" : " minor"),
            instrument: instrument,
            energy: energy,
            mood: mood,
            isLoop: isLoop,
            quality: AudioQuality(
                bitDepth: [16, 24].randomElement()!,
                sampleRate: [44100, 48000].randomElement()!,
                bitrate: [192, 256, 320].randomElement(),
                format: URL(fileURLWithPath: sample.originalPath).pathExtension
            ),
            duration: Double.random(in: 1.0...30.0),
            hasVocals: hasVocals,
            confidence: Double.random(in: 0.7...0.95)
        )
    }
}

// MARK: - Main Sample Organizer View
struct SampleOrganizerView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @ObservedObject private var manager = SampleOrganizerManager.shared
    @State private var showAnalyticsDashboard = false
    @State private var draggedSample: Sample?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerView
                
                if manager.isAnalyzing {
                    analysisProgressView
                } else {
                    mainContentView
                }
            }
        }
        .sheet(isPresented: $showAnalyticsDashboard) {
            AnalyticsDashboardView(analytics: manager.analytics)
        }
        .onAppear {
            manager.loadSampleLibrary()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Navigation header
            HStack {
                Button(action: {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    currentTab = "organize"
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
                
                Text("SAMPLE ORGANIZER")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    showAnalyticsDashboard = true
                }) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Analytics summary
            analyticsHeaderView
            
            // Search bar
            searchBarView
            
            // Action buttons
            actionButtonsView
        }
        .padding(.bottom, 16)
    }
    
    private var analyticsHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("📊 Analytics")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("\(manager.analytics.totalSamples) samples | \(manager.analytics.instrumentCounts[.kick] ?? 0) kicks | \(manager.analytics.instrumentCounts[.snare] ?? 0) snares")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text(manager.analytics.fileSizeFormatted)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
    }
    
    private var searchBarView: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            
            TextField("Find dark trap kicks 85BPM", text: $manager.searchText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .textFieldStyle(PlainTextFieldStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 24)
    }
    
    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            ActionButton(title: "ORGANIZE", subtitle: "Auto-sort by\nAI detection", icon: "brain.head.profile") {
                manager.scanForNewSamples()
            }
            
            ActionButton(title: "ANALYZE", subtitle: "Find dupes\n& similar", icon: "arrow.triangle.2.circlepath") {
                manager.detectDuplicates()
                manager.findSimilarSamples()
            }
            
            ActionButton(title: "CLEAN", subtitle: "Fix names\n& metadata", icon: "doc.text") {
                // Implement batch cleaning
            }
            
            ActionButton(title: "EXPORT", subtitle: "Pack as\nZIP files", icon: "archivebox") {
                // Implement export functionality
            }
        }
        .padding(.horizontal, 24)
    }
    
    // MARK: - Main Content
    private var mainContentView: some View {
        VStack(spacing: 16) {
            // Genre buckets
            genreBucketsView
            
            // Sample grid
            sampleGridView
        }
    }
    
    private var genreBucketsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(InstrumentType.allCases, id: \.self) { instrument in
                    GenreBucketView(
                        instrument: instrument,
                        count: manager.analytics.instrumentCounts[instrument] ?? 0,
                        isSelected: manager.selectedInstrumentFilter == instrument
                    ) {
                        if manager.selectedInstrumentFilter == instrument {
                            manager.selectedInstrumentFilter = nil
                        } else {
                            manager.selectedInstrumentFilter = instrument
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var sampleGridView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(manager.filteredSamples) { sample in
                    SampleCardView(
                        sample: sample,
                        isPlaying: manager.currentlyPlaying?.id == sample.id,
                        onTap: {
                            manager.previewSample(sample)
                        },
                        onEdit: {
                            taskStore.selectedSampleForEdit = sample
                            currentTab = "edit"
                        },
                        onSelect: { isSelected in
                            if let index = manager.samples.firstIndex(where: { $0.id == sample.id }) {
                                manager.samples[index].isSelected = isSelected
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
    }
    
    private var analysisProgressView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 24) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 80, weight: .heavy))
                    .foregroundColor(Color(red: 0.373, green: 0.275, blue: 0.569))
                
                Text("ANALYZING SAMPLES")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
                
                VStack(spacing: 16) {
                    ProgressView(value: manager.analysisProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(height: 8)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                    
                    Text("Analyzing \(Int(manager.analysisProgress * 100))% complete...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views
struct ActionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GenreBucketView: View {
    let instrument: InstrumentType
    let count: Int
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 8) {
                Text(instrument.emoji)
                    .font(.system(size: 24))
                
                Text("\(count)")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundColor(.white)
                
                Text(instrument.rawValue.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("samples")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SampleCardView: View {
    let sample: Sample
    let isPlaying: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onSelect: (Bool) -> Void
    
    @State private var isSelected = false
    @State private var showEditMenu = false
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 8) {
                // Waveform placeholder
                HStack(spacing: 1) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.white.opacity(Double.random(in: 0.3...1.0)))
                            .frame(width: 2, height: CGFloat.random(in: 4...20))
                    }
                }
                .frame(height: 20)
                
                // Sample info
                VStack(spacing: 4) {
                    Text(sample.displayName)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    if let analysis = sample.analyzedData {
                        HStack(spacing: 4) {
                            Text(analysis.instrument.emoji)
                                .font(.system(size: 12))
                            
                            if let bpm = analysis.bpm {
                                Text("\(bpm)")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                    }
                }
                
                // Indicators
                HStack(spacing: 4) {
                    if !sample.duplicates.isEmpty {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 8))
                            .foregroundColor(.red)
                    }
                    
                    if !sample.similarSamples.isEmpty {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 8))
                            .foregroundColor(.orange)
                    }
                    
                    if sample.analyzedData?.isLoop == true {
                        Image(systemName: "repeat")
                            .font(.system(size: 8))
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                sample.analyzedData?.mood.color.opacity(0.2) ?? Color.white.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isPlaying ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            Button(action: {
                onEdit()
            }) {
                Label("Edit Sample", systemImage: "waveform")
            }
            
            Button(action: {
                isSelected.toggle()
                onSelect(isSelected)
            }) {
                Label(isSelected ? "Deselect" : "Select", systemImage: isSelected ? "checkmark.circle.fill" : "circle")
            }
        }
        .overlay(
            // Selection indicator
            isSelected ? 
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.white)
                .padding(4)
                .background(Color.green)
                .clipShape(Circle())
                .padding(4)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            : nil
        )
    }
}

struct AnalyticsDashboardView: View {
    let analytics: SampleAnalytics
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Overview stats
                        overviewStatsView
                        
                        // BPM distribution
                        bpmDistributionView
                        
                        // Instrument breakdown
                        instrumentBreakdownView
                        
                        // Quality analysis
                        qualityAnalysisView
                    }
                    .padding(24)
                }
            }
            .navigationTitle("Sample Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var overviewStatsView: some View {
        VStack(spacing: 16) {
            Text("YOUR SAMPLE LIBRARY STATS")
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(title: "Total Samples", value: "\(analytics.totalSamples)", icon: "music.note")
                StatCard(title: "File Size", value: analytics.fileSizeFormatted, icon: "internaldrive")
                StatCard(title: "Duplicates", value: "\(analytics.duplicateCount)", icon: "doc.on.doc")
                StatCard(title: "Quality Issues", value: "\(analytics.qualityIssues)", icon: "exclamationmark.triangle")
            }
        }
    }
    
    private var bpmDistributionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📈 BPM Distribution")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.white)
            
            ForEach(analytics.bpmDistribution, id: \.range) { data in
                HStack {
                    Text(data.range)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 60, alignment: .leading)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 20)
                            
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: geometry.size.width * CGFloat(data.count) / CGFloat(analytics.totalSamples), height: 20)
                        }
                    }
                    .frame(height: 20)
                    
                    Text("\(data.count)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
    }
    
    private var instrumentBreakdownView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎵 Instrument Breakdown")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.white)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(InstrumentType.allCases, id: \.self) { instrument in
                    let count = analytics.instrumentCounts[instrument] ?? 0
                    
                    VStack(spacing: 8) {
                        Text(instrument.emoji)
                            .font(.system(size: 24))
                        
                        Text("\(count)")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text(instrument.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
    
    private var qualityAnalysisView: some View {
        VStack(spacing: 16) {
            Text("🔄 Library Health")
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HealthIndicator(
                    title: "Duplicates Found",
                    value: "\(analytics.duplicateCount)",
                    subtitle: "Save space by removing",
                    color: analytics.duplicateCount > 0 ? .red : .green
                )
                
                HealthIndicator(
                    title: "Quality Issues",
                    value: "\(analytics.qualityIssues)",
                    subtitle: "Low-quality files detected",
                    color: analytics.qualityIssues > 0 ? .orange : .green
                )
                
                HealthIndicator(
                    title: "Organization",
                    value: "\(Int(Double(analytics.analyzedSamples) / Double(analytics.totalSamples) * 100))%",
                    subtitle: "Samples analyzed & tagged",
                    color: analytics.analyzedSamples == analytics.totalSamples ? .green : .orange
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
            
            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HealthIndicator: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.white)
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SampleOrganizerView(taskStore: TaskStore(), currentTab: .constant("sample-organizer"))
}