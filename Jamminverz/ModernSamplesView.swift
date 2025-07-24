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
                        Text(selectedPack != nil ? selectedPack!.name.uppercased() : "ALL SAMPLES")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Text("\(selectedPack != nil ? selectedPackSamples.count : samplesManager.audioFiles.count) files")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Text("SAMPLE PACKS")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundColor(.white)
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
                
                // Content area - split view
                HStack(spacing: 24) {
                    // Left side - Sample list
                    VStack(spacing: 0) {
                        // List header
                        HStack {
                            Text("SAMPLES")
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(selectedPack != nil ? selectedPackSamples.count : samplesManager.audioFiles.count)")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.1))
                        
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(selectedPack != nil ? filteredPackSamples : filteredSamples) { file in
                                    SampleRow(
                                        file: file,
                                        isSelected: selectedSamples.contains(file.id),
                                        onToggle: { toggleSelection(file) },
                                        onDragStart: { startDragging([file]) }
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .scrollIndicators(.hidden)
                        
                        // Action buttons - Todomai style
                        HStack(spacing: 0) {
                            if selectedPack != nil {
                                Button(action: { 
                                    selectedPack = nil
                                    selectedPackSamples = []
                                }) {
                                    Text("SHOW ALL")
                                }
                                .buttonStyle(TodomaiButtonStyle(backgroundColor: Color.purple.opacity(0.3)))
                            } else {
                                Button(action: selectAll) {
                                    Text("SELECT ALL")
                                }
                                .buttonStyle(TodomaiButtonStyle(backgroundColor: Color.purple.opacity(0.3)))
                            }
                            
                            Button(action: { samplesManager.scanForAudioFiles() }) {
                                Text("REFRESH")
                            }
                            .buttonStyle(TodomaiButtonStyle(backgroundColor: Color.blue.opacity(0.3)))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.black.opacity(0.3))
                    
                    // Right side - Sample packs
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            // Packs header
                            HStack {
                                Text("PACKS")
                                    .font(.system(size: 20, weight: .heavy))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(samplesManager.samplePacks.count)")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.1))
                            
                            ScrollView {
                                LazyVGrid(columns: [
                                    GridItem(.fixed(110), spacing: 12),
                                    GridItem(.fixed(110), spacing: 12),
                                    GridItem(.fixed(110), spacing: 12),
                                    GridItem(.fixed(110), spacing: 12),
                                    GridItem(.fixed(110), spacing: 12)
                                ], spacing: 12) {
                                ForEach(samplesManager.samplePacks) { pack in
                                    SamplePackCard(
                                        pack: pack,
                                        isHovered: hoveredPack?.id == pack.id,
                                        isSelected: selectedPack?.id == pack.id,
                                        onTap: { 
                                            selectedPack = pack
                                            selectedPackSamples = samplesManager.getSamplesForPack(pack)
                                        },
                                        onDrop: { samples in
                                            samplesManager.addSamplesToPack(samples, pack: pack)
                                        }
                                    )
                                    .onHover { hovering in
                                        if hovering && isDragging {
                                            hoveredPack = pack
                                        } else if !hovering && hoveredPack?.id == pack.id {
                                            hoveredPack = nil
                                        }
                                    }
                                }
                                
                                // Add pack button
                                Button(action: { showCreatePackSheet = true }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 24, weight: .medium))
                                        Text("ADD\nPACK")
                                            .font(.system(size: 11, weight: .bold))
                                            .multilineTextAlignment(.center)
                                    }
                                    .foregroundColor(.white)
                                    .frame(width: 110, height: 110)
                                    .background(Color.white.opacity(0.2))
                                    .overlay(
                                        Rectangle() // Sharp corners
                                            .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    )
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }
                        .scrollIndicators(.hidden)
                        
                        // Pack action buttons - Todomai style
                        HStack(spacing: 0) {
                            Button(action: aiAutoPack) {
                                Text("AI AUTO-PACK")
                            }
                            .buttonStyle(TodomaiButtonStyle(backgroundColor: Color.purple))
                            
                            Button(action: { showCreatePackSheet = true }) {
                                Text("CREATE PACK")
                            }
                            .buttonStyle(TodomaiButtonStyle(backgroundColor: Color.green))
                            
                            Button(action: importPack) {
                                Text("IMPORT PACK")
                            }
                            .buttonStyle(TodomaiButtonStyle(backgroundColor: Color.orange))
                        }
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
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