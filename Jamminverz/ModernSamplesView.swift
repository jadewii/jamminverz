//
//  ModernSamplesView.swift
//  Jamminverz
//
//  Beautiful klinmai-inspired samples management interface
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

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
                    VStack(spacing: 32) {
                        // MY PACKS section
                        if !samplesManager.favoritePacks.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("MY PACKS")
                                        .font(.system(size: 20, weight: .heavy))
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text("\(samplesManager.favoritePacks.count)")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 24)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(samplesManager.favoritedPacks) { pack in
                                            FavoritePackCard(
                                                pack: pack,
                                                isSelected: selectedPack?.id == pack.id,
                                                isFavorite: true,
                                                onTap: { 
                                                    selectedPack = pack
                                                    selectedPackSamples = samplesManager.getSamplesForPack(pack)
                                                },
                                                onToggleFavorite: {
                                                    samplesManager.toggleFavorite(pack.id)
                                                }
                                            )
                                            .frame(width: 260)
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                }
                            }
                        }
                        
                        // ALL PACKS section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("ALL PACKS")
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(samplesManager.samplePacks.count)")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
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
                                        .frame(width: 260)
                                    }
                                    
                                    // Add pack button
                                    Button(action: { showCreatePackSheet = true }) {
                                        VStack(spacing: 8) {
                                            ZStack {
                                                Rectangle()
                                                    .fill(Color.white.opacity(0.1))
                                                    .frame(height: 120)
                                                    .overlay(
                                                        Rectangle()
                                                            .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                                    )
                                                
                                                VStack(spacing: 8) {
                                                    Image(systemName: "plus")
                                                        .font(.system(size: 32, weight: .medium))
                                                        .foregroundColor(.white)
                                                    Text("CREATE PACK")
                                                        .font(.system(size: 12, weight: .heavy))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                            
                                            Text("Add New")
                                                .font(.system(size: 14, weight: .heavy))
                                                .foregroundColor(.white)
                                            
                                            Text("Create custom pack")
                                                .font(.system(size: 11))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                        .frame(width: 260)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.horizontal, 24)
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
                                
                                VStack(spacing: 8) {
                                    ForEach(selectedPack != nil ? filteredPackSamples.prefix(10) : filteredSamples.prefix(10)) { file in
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
    
    private func importPack() {
        // TODO: Show file picker for pack import
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
            VStack(alignment: .leading, spacing: 12) {
                // Pack Preview Grid
                ZStack(alignment: .bottomTrailing) {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2),
                        GridItem(.flexible(), spacing: 2)
                    ], spacing: 2) {
                        ForEach(0..<16) { i in
                            Rectangle()
                                .fill(pack.color.opacity(Double.random(in: 0.3...0.8)))
                                .aspectRatio(1, contentMode: .fit)
                                .cornerRadius(2)
                        }
                    }
                    .padding(8)
                    .frame(height: 120)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                    )
                    
                    // Favorite button
                    Button(action: {
                        onToggleFavorite()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.7))
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(isFavorite ? Color.pink : .white)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 10, weight: .heavy))
                                        .foregroundColor(.white)
                                        .offset(x: 8, y: -8)
                                )
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .offset(x: -8, y: -8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(pack.icon)
                            .font(.system(size: 16))
                        Text(pack.name.uppercased())
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    HStack {
                        Label("\(pack.samples.count)", systemImage: "square.grid.2x2")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                        Spacer()
                        if isFavorite {
                            Label("MY PACK", systemImage: "star.fill")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .padding(12)
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
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
                        samplesManager.createPack(
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