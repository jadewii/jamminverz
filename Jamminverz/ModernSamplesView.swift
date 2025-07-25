//
//  ModernSamplesView.swift
//  Jamminverz
//
//  Beautiful klinmai-inspired samples management interface
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

// MARK: - Modern Samples View
struct ModernSamplesView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var samplesManager = ModernSamplesManager()
    @State private var selectedSamples = Set<String>()
    @State private var searchText = ""
    @State private var isDragging = false
    @State private var draggedSamples: [SampleFile] = []
    @State private var hoveredPack: SamplePack?
    @State private var showCreatePackSheet = false
    @State private var selectedPack: SamplePack?
    @State private var selectedPackSamples: [SampleFile] = []
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                colors: [
                    Color(hex: "E879F9"),
                    Color(hex: "D946EF"),
                    Color(hex: "C026D3")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("SAMPLES")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text("Organize your sample library")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.6))
                    
                    TextField("Search samples...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .accentColor(.white)
                }
                .padding(12)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Main content scroll
                ScrollView {
                    VStack(spacing: 48) {
                        // Create & Upload Pack section
                        VStack(spacing: 24) {
                            HStack(spacing: 24) {
                                // CREATE PACK
                                Button(action: { showCreatePackSheet = true }) {
                                    VStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 180)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                                )
                                            
                                            VStack(spacing: 12) {
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.system(size: 48, weight: .medium))
                                                    .foregroundColor(.white)
                                                Text("CREATE PACK")
                                                    .font(.system(size: 18, weight: .heavy))
                                                    .foregroundColor(.white)
                                                Text("Create a new sample pack")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // UPLOAD PACK
                                Button(action: { 
                                    uploadPack()
                                }) {
                                    VStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(Color.white.opacity(0.1))
                                                .frame(height: 180)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16)
                                                        .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                                                )
                                            
                                            VStack(spacing: 12) {
                                                Image(systemName: "folder.fill.badge.plus")
                                                    .font(.system(size: 48, weight: .medium))
                                                    .foregroundColor(.white)
                                                Text("UPLOAD PACK")
                                                    .font(.system(size: 18, weight: .heavy))
                                                    .foregroundColor(.white)
                                                Text("Import folder with samples")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.white.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // User's Packs section (will show uploaded packs)
                        if !samplesManager.samplePacks.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("MY PACKS")
                                        .font(.system(size: 20, weight: .heavy))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(samplesManager.samplePacks.count)")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 24)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        ForEach(samplesManager.samplePacks) { pack in
                                            FavoritePackCard(
                                                pack: pack,
                                                isSelected: selectedPack?.id == pack.id,
                                                isFavorite: samplesManager.isFavorite(pack.id),
                                                onTap: { 
                                                    selectedPack = pack
                                                    selectedPackSamples = samplesManager.getSamplesForPack(pack)
                                                },
                                                onToggleFavorite: {
                                                    samplesManager.toggleFavorite(pack.id)
                                                }
                                            )
                                            .frame(width: 280, height: 200)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                        
                        // Selected pack samples or all samples
                        if selectedPack != nil || !samplesManager.audioFiles.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text(selectedPack != nil ? "\(selectedPack!.name.uppercased()) SAMPLES" : "RECENT SAMPLES")
                                        .font(.system(size: 20, weight: .heavy))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if selectedPack != nil {
                                        Button(action: {
                                            selectedPack = nil
                                            selectedPackSamples = []
                                        }) {
                                            Text("SHOW ALL")
                                                .font(.system(size: 12, weight: .heavy))
                                                .foregroundColor(Color.purple)
                                        }
                                    }
                                }
                                .padding(.horizontal, 24)
                                
                                // Group samples by subfolder
                                if selectedPack != nil {
                                    let groupedSamples = Dictionary(grouping: filteredPackSamples) { $0.subfolder ?? "Root" }
                                    
                                    ForEach(groupedSamples.keys.sorted(), id: \.self) { subfolder in
                                        VStack(alignment: .leading, spacing: 8) {
                                            if subfolder != "Root" {
                                                Text(subfolder.uppercased())
                                                    .font(.system(size: 14, weight: .heavy))
                                                    .foregroundColor(.white.opacity(0.7))
                                                    .padding(.horizontal, 24)
                                                    .padding(.top, 8)
                                            }
                                            
                                            VStack(spacing: 8) {
                                                ForEach(groupedSamples[subfolder] ?? []) { file in
                                                    MinimalSampleRow(
                                                        file: file,
                                                        isSelected: selectedSamples.contains(file.id),
                                                        onToggle: { toggleSelection(file) },
                                                        onPlay: { playPreview(file) }
                                                    )
                                                }
                                            }
                                            .padding(.horizontal, 24)
                                        }
                                    }
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(filteredSamples.prefix(10)) { file in
                                            MinimalSampleRow(
                                                file: file,
                                                isSelected: selectedSamples.contains(file.id),
                                                onToggle: { toggleSelection(file) },
                                                onPlay: { playPreview(file) }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 24)
                    .padding(.bottom, 100)
                }
                
                // REMOVED OLD SPLIT VIEW
            }
        }
        .onAppear {
            samplesManager.scanForAudioFiles()
        }
        .sheet(isPresented: $showCreatePackSheet) {
            CreatePackSheet(samplesManager: samplesManager)
        }
        // Removed sheet for pack detail - we show samples in the left panel instead
    }
    
    
    // MARK: - Helper Methods
    private var filteredSamples: [SampleFile] {
        if searchText.isEmpty {
            return samplesManager.audioFiles
        }
        return samplesManager.audioFiles.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private var filteredPackSamples: [SampleFile] {
        if searchText.isEmpty {
            return selectedPackSamples
        }
        return selectedPackSamples.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func toggleSelection(_ file: SampleFile) {
        if selectedSamples.contains(file.id) {
            selectedSamples.remove(file.id)
        } else {
            selectedSamples.insert(file.id)
        }
    }
    
    private func selectAll() {
        if selectedSamples.count == filteredSamples.count {
            selectedSamples.removeAll()
        } else {
            selectedSamples = Set(filteredSamples.map { $0.id })
        }
    }
    
    private func startDragging(_ files: [SampleFile]) {
        draggedSamples = files
        isDragging = true
    }
    
    private func bulkActions() {
        // TODO: Show bulk actions menu
    }
    
    private func aiAutoPack() {
        samplesManager.createAutoPacksWithAI()
    }
    
    private func uploadPack() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Select a folder containing audio samples"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                processUploadedFolder(url)
            }
        }
        #endif
    }
    
    private func processUploadedFolder(_ folderURL: URL) {
        let folderName = folderURL.lastPathComponent
        
        // Create a new pack for this folder
        let newPack = samplesManager.createPack(
            name: folderName,
            icon: "📁",
            color: Color(hex: "E879F9")
        )
        
        // Scan for audio files in the folder and subfolders
        let fileManager = FileManager.default
        if let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            for case let fileURL as URL in enumerator {
                let pathComponents = fileURL.pathComponents
                let folderComponents = folderURL.pathComponents
                
                // Get the relative path components
                let relativeComponents = Array(pathComponents.dropFirst(folderComponents.count))
                
                // Check if it's an audio file
                let audioExtensions = ["wav", "mp3", "aiff", "m4a", "flac"]
                if audioExtensions.contains(fileURL.pathExtension.lowercased()) {
                    // Create sample file
                    let sample = SampleFile(
                        url: fileURL,
                        subfolder: relativeComponents.count > 1 ? relativeComponents[0] : nil
                    )
                    
                    // Add to manager
                    samplesManager.addSampleToPack(sample, pack: newPack)
                }
            }
        }
        
        // Refresh the view
        samplesManager.scanForAudioFiles()
    }
    
    private func importPack() {
        uploadPack()
    }
    
    private func playPreview(_ file: SampleFile) {
        // TODO: Implement preview playback
    }
}

// MARK: - Sample Row
struct SampleRow: View {
    let file: SampleFile
    let isSelected: Bool
    let onToggle: () -> Void
    let onDragStart: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                if let duration = file.duration {
                    Text(formatDuration(duration))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            // File size
            Text(formatFileSize(file.size))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.8))
            
            // BPM if available
            if let bpm = file.bpm {
                HStack(spacing: 4) {
                    Image(systemName: "music.note")
                        .font(.system(size: 12))
                    Text("\(Int(bpm))")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.white.opacity(0.8))
            }
            
            // Play button
            Button(action: { playPreview(file) }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
        )
        .draggable(file) {
            SampleDragPreview(file: file)
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func playPreview(_ file: SampleFile) {
        // TODO: Implement preview playback
    }
}

// MARK: - Pack Card
struct SamplePackCard: View {
    let pack: SamplePack
    let isHovered: Bool
    let isSelected: Bool
    let onTap: () -> Void
    let onDrop: ([SampleFile]) -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                // Icon or image
                ZStack {
                    Rectangle() // Sharp corners
                        .fill(pack.color.gradient)
                        .frame(height: 45)
                    
                    Text(pack.icon)
                        .font(.system(size: 24))
                }
                
                Text(pack.name.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text("\(pack.samples.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 110, height: 110)
            .background(
                Rectangle() // Sharp corners
                    .fill(Color.white.opacity(isSelected ? 0.3 : 0.15))
                    .overlay(
                        Rectangle()
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                            .stroke(Color.white.opacity(isHovered ? 0.5 : 0.2), lineWidth: 2)
                    )
            )
            .scaleEffect(isHovered ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onDrop(of: [.audio], isTargeted: .constant(false)) { providers in
            // Handle drop
            return true
        }
    }
}

// MARK: - Drag Preview
struct SampleDragPreview: View {
    let file: SampleFile
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "music.note")
            Text(file.name)
                .lineLimit(1)
        }
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(hex: "E879F9"))
        )
    }
}

// MARK: - Favorite Pack Card
struct FavoritePackCard: View {
    let pack: SamplePack
    let isSelected: Bool
    let isFavorite: Bool
    let onTap: () -> Void
    let onToggleFavorite: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Card Header with Gradient Background
                ZStack {
                    // Gradient background
                    LinearGradient(
                        colors: [
                            pack.color,
                            pack.color.opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Pattern overlay
                    GeometryReader { geo in
                        ZStack {
                            ForEach(0..<6) { row in
                                ForEach(0..<6) { col in
                                    Circle()
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 20, height: 20)
                                        .offset(
                                            x: CGFloat(col) * 30 - 10,
                                            y: CGFloat(row) * 30 - 10
                                        )
                                }
                            }
                        }
                        .clipped()
                    }
                    
                    // Content
                    VStack {
                        HStack {
                            Text(pack.icon)
                                .font(.system(size: 32))
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                            Spacer()
                            
                            // Favorite button
                            Button(action: {
                                onToggleFavorite()
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(isFavorite ? Color.pink : .white)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        Spacer()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pack.name.uppercased())
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                
                                Text("\(pack.samples.count) samples")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .frame(height: 140)
                
                // Card Footer
                HStack {
                    if isFavorite {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text("MY PACK")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.yellow)
                        }
                    } else {
                        Text("TAP TO VIEW")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.03))
            }
            .background(Color.black)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: pack.color.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Minimal Sample Row
struct MinimalSampleRow: View {
    let file: SampleFile
    let isSelected: Bool
    let onToggle: () -> Void
    let onPlay: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            // File info
            VStack(alignment: .leading, spacing: 2) {
                Text(file.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                HStack(spacing: 12) {
                    if let duration = file.duration {
                        Text(formatDuration(duration))
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    
                    if let bpm = file.bpm {
                        Label("\(Int(bpm)) BPM", systemImage: "metronome")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    
                    Text(formatFileSize(file.size))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Play button
            Button(action: onPlay) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.purple)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// TodomaiButtonStyle is imported from Styles.swift

// MARK: - Create Pack Sheet
struct CreatePackSheet: View {
    @ObservedObject var samplesManager: ModernSamplesManager
    @Environment(\.dismiss) var dismiss
    @State private var packName = ""
    @State private var selectedIcon = "🎵"
    @State private var selectedColor = Color(hex: "E879F9")
    
    let icons = ["🎵", "🥁", "🎹", "🎸", "🎤", "🎧", "🎛️", "🎺", "🎻", "🪕"]
    let colors = [
        Color(hex: "E879F9"),
        Color(hex: "F472B6"),
        Color(hex: "60A5FA"),
        Color(hex: "34D399"),
        Color(hex: "FBBF24"),
        Color(hex: "A78BFA")
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Pack name
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pack Name")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    TextField("Enter pack name", text: $packName)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // Icon selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Text(icon)
                                    .font(.system(size: 32))
                                    .frame(width: 60, height: 60)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedIcon == icon ? Color.white.opacity(0.3) : Color.white.opacity(0.1))
                                    )
                            }
                        }
                    }
                }
                
                // Color selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(color)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [selectedColor, selectedColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Create Pack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        _ = samplesManager.createPack(
                            name: packName.isEmpty ? "New Pack" : packName,
                            icon: selectedIcon,
                            color: selectedColor
                        )
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                }
            }
        }
    }
}

// MARK: - Pack Detail View
struct PackDetailView: View {
    let pack: SamplePack
    @ObservedObject var samplesManager: ModernSamplesManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Pack samples list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(pack.samples, id: \.self) { sampleId in
                            if let file = samplesManager.audioFiles.first(where: { $0.id == sampleId }) {
                                HStack {
                                    Text(file.name)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Button(action: { removeSample(sampleId) }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(pack.color.opacity(0.8))
            .navigationTitle(pack.name)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func removeSample(_ sampleId: String) {
        samplesManager.removeSampleFromPack(sampleId, pack: pack)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}