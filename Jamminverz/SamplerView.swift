//
//  SamplerView.swift
//  Jamminverz
//
//  Sample pack browser with 4x4 drum pad grid
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

// MARK: - Sampler View
struct SamplerView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var samplerEngine = SamplerEngine()
    @StateObject private var samplesManager = ModernSamplesManager()
    @State private var selectedPack: SamplePack?
    @State private var myPacks: [SamplePack] = []
    @State private var isPressed = [Bool](repeating: false, count: 16)
    @State private var isGridView = false
    @State private var gridColorMode: String = "rainbow" // "rainbow" or color name
    @State private var selectedGridColor: Color = .blue
    @State private var showColorPicker = false
    @State private var showSampleListView = false
    @State private var selectedPadIndex: Int = 0 // Always start with pad 0 selected
    @State private var sequencerSteps = Array(repeating: Array(repeating: false, count: 16), count: 16) // 16 pads x 16 steps
    @State private var currentSequencerStep: Int = -1 // -1 means not playing
    @State private var sequencerTimer: Timer?
    
    // Sample packs from profiles (mock data for now)
    @State private var availablePacks: [SamplePack] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                Color(red: 0.05, green: 0.05, blue: 0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .frame(height: 50)
                    
                    // Main content with sequencer always visible
                    VStack(spacing: 20) {
                        // Two equal sized squares that fill available space
                        GeometryReader { innerGeo in
                            HStack(spacing: 20) {
                                let squareSize = min(innerGeo.size.width / 2 - 10, innerGeo.size.height)
                                
                                // Left side - Sample Pack Collection
                                samplePackGrid
                                    .frame(width: squareSize, height: squareSize)
                                
                                // Right side - 4x4 Drum Pads
                                drumPadGrid
                                    .frame(width: squareSize, height: squareSize)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                        .padding(.horizontal, 20)
                        
                        // Step Sequencer always visible at bottom
                        stepSequencerView(for: selectedPadIndex)
                            .frame(height: 100)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
        }
        .onAppear {
            samplerEngine.setupAudioEngine()
            loadMyPacks()
            
            // Create mock sample packs if none exist
            if samplesManager.samplePacks.isEmpty {
                // Create many packs to demonstrate the grid view
                let packNames = ["Trap", "House", "Lofi", "Drill", "R&B", "Techno", "Jazz", "Soul", "Funk", "Ambient", "DnB", "Dubstep", "Future", "Wave", "Phonk", "Garage", "Breaks", "Acid", "Trance", "Hardcore"]
                let colors: [Color] = [.purple, .pink, .blue, .green, .orange, .red, .yellow, .cyan, .indigo, .mint, .teal, .brown]
                let icons = ["🥁", "🎹", "🎸", "🎺", "🎷", "🎻", "🎤", "🎧", "🎵", "🎶", "🎼", "📻", "🔊", "🔈", "💿", "📀", "🎛️", "🎚️", "🎙️", "🥁"]
                
                for i in 1...100 {
                    let pack = SamplePack(
                        name: packNames[(i-1) % packNames.count] + " \(i)",
                        icon: icons[(i-1) % icons.count],
                        color: colors[(i-1) % colors.count]
                    )
                    samplesManager.createPack(name: pack.name, icon: pack.icon, color: pack.color)
                }
            }
        }
        .background(
            KeyboardHandlerView { key in
                handleKeyPress(key)
            }
        )
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                currentTab = "menu"
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .heavy))
                    Text("BACK")
                        .font(.system(size: 16, weight: .heavy))
                }
                .foregroundColor(.white)
            }
            
            Spacer()
            
            Text("SAMPLER")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(.white)
            
            Spacer()
            
            // View toggle and color picker buttons
            HStack(spacing: 2) {
                // List view button (4 rows icon)
                Button(action: {
                    showSampleListView.toggle()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(showSampleListView ? 0.2 : 0.1))
                            .frame(width: 40, height: 40)
                        
                        // 4 rows icon
                        VStack(spacing: 3) {
                            ForEach(0..<4) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(0.8))
                                    .frame(width: 20, height: 2)
                            }
                        }
                    }
                }
                
                // Grid view toggle button
                Button(action: {
                    isGridView.toggle()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(isGridView ? 0.2 : 0.1))
                            .frame(width: 40, height: 40)
                        
                        // 4x4 grid icon
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(6), spacing: 2), count: 4), spacing: 2) {
                            ForEach(0..<16) { _ in
                                Rectangle()
                                    .fill(Color.white.opacity(isGridView ? 1.0 : 0.6))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
                
                // Color picker button
                Button(action: {
                    showColorPicker.toggle()
                }) {
                    if gridColorMode == "rainbow" {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange, .yellow, .green, .blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedGridColor)
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                            )
                    }
                }
                .popover(isPresented: $showColorPicker) {
                    ColorPickerPopover(
                        gridColorMode: $gridColorMode,
                        selectedGridColor: $selectedGridColor
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }
    
    // MARK: - Drum Pad Grid
    private var drumPadGrid: some View {
        DrumPadGridView(
            selectedPack: selectedPack,
            isPressed: $isPressed,
            selectedPadIndex: $selectedPadIndex,
            onPadTap: playPadSound
        )
    }
    
    
    private func handleDrop(providers: [NSItemProvider], padIndex: Int) -> Bool {
        // This function is currently not used since drag and drop is disabled
        // Will implement proper drag and drop handling later
        return false
    }
    
    // MARK: - Sample Pack Grid
    private var samplePackGrid: some View {
        SamplePackGridView(
            myPacks: myPacks,
            selectedPack: $selectedPack,
            isGridView: isGridView,
            gridColorMode: gridColorMode,
            selectedGridColor: selectedGridColor,
            onPackSelected: loadPackSounds,
            showSampleListView: $showSampleListView,
            samplerEngine: samplerEngine
        )
    }
    
    // MARK: - Helper Methods
    private func loadMyPacks() {
        // Load packs from the samples manager
        myPacks = samplesManager.samplePacks
    }
    
    private func handleKeyPress(_ key: String) {
        // Only handle key presses if a sample pack is selected
        guard selectedPack != nil else { return }
        
        // Map keys to pad indices
        let keyMap: [String: Int] = [
            // Row 1: 1-4 for pads 1-4 (indices 0-3)
            "1": 0, "2": 1, "3": 2, "4": 3,
            // Row 2: Q-R for pads 5-8 (indices 4-7) 
            "q": 4, "w": 5, "e": 6, "r": 7,
            // Row 3: A-F for pads 9-12 (indices 8-11)
            "a": 8, "s": 9, "d": 10, "f": 11,
            // Row 4: Z-V for pads 13-16 (indices 12-15)
            "z": 12, "x": 13, "c": 14, "v": 15
        ]
        
        if let padIndex = keyMap[key.lowercased()] {
            playPadSound(padIndex)
            selectedPadIndex = padIndex
        }
    }
    
    private func loadPackSounds(_ pack: SamplePack) {
        // Load the 16 samples from the pack into the sampler engine
        // TODO: Implement loading samples into pads
        // for (index, sampleId) in pack.samples.enumerated() {
        //     if let sample = samplesManager.audioFiles.first(where: { $0.id == sampleId }) {
        //         samplerEngine.loadSample(sample.url, toPad: index)
        //     }
        // }
    }
    
    private func playPadSound(_ padIndex: Int) {
        isPressed[padIndex] = true
        
        // Trigger the sound
        samplerEngine.triggerPad(padIndex, velocity: 1.0)
        
        // Reset button state instantly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            isPressed[padIndex] = false
        }
    }
    
    private func getPackColor(for pack: SamplePack, at index: Int) -> Color {
        if gridColorMode == "rainbow" {
            return pack.color
        } else {
            return selectedGridColor
        }
    }
    
    private func getInactiveColor() -> Color {
        if gridColorMode == "rainbow" {
            return Color.gray
        } else {
            return selectedGridColor
        }
    }
    
    // MARK: - Sequencer Control
    private func startSequencer() {
        samplerEngine.startSequencer()
        currentSequencerStep = 0
        
        // Create timer for visual feedback
        sequencerTimer?.invalidate()
        let bpm = 120.0 // Default BPM
        let stepDuration = 60.0 / bpm / 4.0 // 16th notes
        
        sequencerTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { _ in
            // Play any active steps
            if sequencerSteps[selectedPadIndex][currentSequencerStep] {
                playPadSound(selectedPadIndex)
            }
            
            // Move to next step
            currentSequencerStep = (currentSequencerStep + 1) % 16
        }
    }
    
    private func stopSequencer() {
        samplerEngine.stopSequencer()
        sequencerTimer?.invalidate()
        sequencerTimer = nil
        currentSequencerStep = -1
    }
    
    // MARK: - Step Sequencer View
    @ViewBuilder
    private func stepSequencerView(for padIndex: Int) -> some View {
        VStack(spacing: 0) {
            // Sequencer content aligned with grids above
            GeometryReader { geo in
                HStack(spacing: 8) {
                    // Transport controls
                    HStack(spacing: 8) {
                        // Play button
                        Button(action: {
                            startSequencer()
                        }) {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Stop button
                        Button(action: {
                            stopSequencer()
                        }) {
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(width: 12, height: 12)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Spacer
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 20)
                    
                    // Step buttons
                    ForEach(0..<16) { step in
                        Button(action: {
                            sequencerSteps[padIndex][step].toggle()
                        }) {
                            Circle()
                                .fill(
                                    sequencerSteps[padIndex][step] ? 
                                        (selectedPack?.color ?? .green) : 
                                        Color.white.opacity(0.1)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(
                                            step == currentSequencerStep ?
                                            Color.white :
                                            (sequencerSteps[padIndex][step] ? 
                                            Color.white : 
                                            Color.white.opacity(0.2)),
                                            lineWidth: step == currentSequencerStep ? 3 : 2
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, 20)
            }
        }
    }
}

// MARK: - Drum Pad Grid View
struct DrumPadGridView: View {
    let selectedPack: SamplePack?
    @Binding var isPressed: [Bool]
    @Binding var selectedPadIndex: Int
    let onPadTap: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Selected pack name
            VStack(spacing: 10) {
                if let pack = selectedPack {
                    HStack {
                        Text(pack.name.uppercased())
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("BY JADE WII")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                } else {
                    Text("SELECT A SAMPLE PACK")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 40)
            .padding(.horizontal, 20)
            
            Spacer()
            
            // 4x4 Grid centered
            GeometryReader { geo in
                let padSpacing: CGFloat = 16
                let totalSpacing = padSpacing * 3
                let padSize = (geo.size.width - totalSpacing) / 4
                
                VStack(spacing: padSpacing) {
                    ForEach(0..<4) { row in
                        HStack(spacing: padSpacing) {
                            ForEach(0..<4) { col in
                                let index = row * 4 + col
                                DrumPadButton(
                                    index: index,
                                    isActive: selectedPack != nil,
                                    color: selectedPack?.color ?? .gray,
                                    isPressed: $isPressed[index],
                                    onTap: {
                                        if selectedPack != nil {
                                            onPadTap(index)
                                            selectedPadIndex = index
                                        }
                                    },
                                    isSelected: selectedPadIndex == index
                                )
                                .frame(width: padSize, height: padSize)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            
            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Sample Pack Grid View
struct SamplePackGridView: View {
    let myPacks: [SamplePack]
    @Binding var selectedPack: SamplePack?
    let isGridView: Bool
    let gridColorMode: String
    let selectedGridColor: Color
    let onPackSelected: (SamplePack) -> Void
    @Binding var showSampleListView: Bool
    let samplerEngine: SamplerEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text("JAM PACKS")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            if showSampleListView {
                // Show sample list in same area
                SampleListInlineView(samplerEngine: samplerEngine)
            } else if isGridView {
                condensedGridView
            } else {
                regularTileView
            }
        }
    }
    
    private var condensedGridView: some View {
        GeometryReader { geo in
            let columns = 30
            let totalSlots = columns * columns
            let spacing: CGFloat = 1
            let totalSpacing = spacing * CGFloat(columns - 1)
            let squareSize = (geo.size.width - totalSpacing) / CGFloat(columns)
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(squareSize), spacing: spacing), count: columns), spacing: spacing) {
                ForEach(0..<totalSlots, id: \.self) { index in
                    if index < myPacks.count {
                        let pack = myPacks[index]
                        Button(action: {
                            selectedPack = pack
                            onPackSelected(pack)
                        }) {
                            Rectangle()
                                .fill(getPackColor(for: pack).opacity(selectedPack?.id == pack.id ? 1.0 : 0.8))
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    Rectangle()
                                        .stroke(
                                            selectedPack?.id == pack.id ? Color.white : Color.clear,
                                            lineWidth: 1
                                        )
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Rectangle()
                            .fill(getInactiveColor().opacity(0.2))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }
    
    private var regularTileView: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 6), spacing: 16) {
                ForEach(myPacks) { pack in
                    SamplePackTile(
                        pack: pack,
                        isSelected: selectedPack?.id == pack.id,
                        onTap: {
                            selectedPack = pack
                            onPackSelected(pack)
                        }
                    )
                }
            }
        }
    }
    
    private func getPackColor(for pack: SamplePack) -> Color {
        if gridColorMode == "rainbow" {
            return pack.color
        } else {
            return selectedGridColor
        }
    }
    
    private func getInactiveColor() -> Color {
        if gridColorMode == "rainbow" {
            return Color.gray
        } else {
            return selectedGridColor
        }
    }
}

// MARK: - Drum Pad Button
struct DrumPadButton: View {
    let index: Int
    let isActive: Bool
    let color: Color
    @Binding var isPressed: Bool
    let onTap: () -> Void
    var isSelected: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isActive ?
                    (isPressed ? Color.white : color.opacity(isSelected ? 1.0 : 0.8)) :
                    Color.white.opacity(0.1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isActive ? (isSelected ? Color.white : color) : Color.white.opacity(0.2),
                            lineWidth: isSelected ? 3 : 2
                        )
                )
                .overlay(
                    Text("\(index + 1)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isActive ? .white : .white.opacity(0.3))
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .disabled(!isActive)
    }
}

// MARK: - Sample Pack Tile
struct SamplePackTile: View {
    let pack: SamplePack
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // 4x4 mini grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 1), count: 4), spacing: 1) {
                    ForEach(0..<16) { index in
                        Rectangle()
                            .fill(pack.color.opacity(0.7))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(8)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                // Pack name
                Text(pack.name)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
            }
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(isSelected ? 0.2 : 0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? pack.color : Color.white.opacity(0.2),
                        lineWidth: isSelected ? 3 : 1
                    )
            )
            .scaleEffect(isHovering ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isHovering)
        }
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

// MARK: - Add Pack Button (for Profile Views)
struct AddPackButton: View {
    let pack: SamplePack
    let onAdd: () -> Void
    @State private var isAdded = false
    
    var body: some View {
        Button(action: {
            onAdd()
            withAnimation {
                isAdded = true
            }
        }) {
            Image(systemName: isAdded ? "checkmark" : "heart")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(isAdded ? Color.green : Color.white.opacity(0.2))
                )
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .offset(x: 8, y: -8)
                        .opacity(isAdded ? 0 : 1)
                )
        }
        .disabled(isAdded)
    }
}

// MARK: - Color Picker Popover
struct ColorPickerPopover: View {
    @Binding var gridColorMode: String
    @Binding var selectedGridColor: Color
    @Environment(\.dismiss) var dismiss
    
    let colors: [(name: String, color: Color)] = [
        ("rainbow", Color.clear), // Special case
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("blue", .blue),
        ("purple", .purple),
        ("pink", .pink),
        ("mint", Color(red: 0.2, green: 0.9, blue: 0.6)),
        ("teal", .teal),
        ("cyan", .cyan),
        ("indigo", .indigo),
        ("brown", .brown),
        ("gray", .gray),
        ("white", .white)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("GRID COLOR")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(50), spacing: 10), count: 5), spacing: 10) {
                ForEach(colors, id: \.name) { item in
                    Button(action: {
                        gridColorMode = item.name
                        if item.name != "rainbow" {
                            selectedGridColor = item.color
                        }
                        dismiss()
                    }) {
                        if item.name == "rainbow" {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .orange, .yellow, .green, .blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(gridColorMode == "rainbow" ? Color.white : Color.clear, lineWidth: 3)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(item.color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(gridColorMode == item.name ? Color.white : Color.gray.opacity(0.3), lineWidth: 3)
                                )
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
            .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        }
        .frame(width: 300)
        .background(Color(red: 0.1, green: 0.1, blue: 0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Sample List View
struct SampleListView: View {
    @Binding var isPresented: Bool
    let onSampleDrop: (SampleFile, Int) -> Void
    @StateObject private var samplesManager = ModernSamplesManager()
    @State private var expandedPacks: Set<String> = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(samplesManager.samplePacks) { pack in
                    SamplePackSection(
                        pack: pack,
                        samplesManager: samplesManager,
                        expandedPacks: $expandedPacks,
                        onSampleDrop: onSampleDrop
                    )
                }
            }
            .listStyle(InsetGroupedListStyle())
            .background(Color(red: 0.05, green: 0.05, blue: 0.1))
            .navigationTitle("SAMPLE LIBRARY")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            samplesManager.scanForAudioFiles()
        }
    }
}

// MARK: - Sample Pack Section
struct SamplePackSection: View {
    let pack: SamplePack
    let samplesManager: ModernSamplesManager
    @Binding var expandedPacks: Set<String>
    let onSampleDrop: (SampleFile, Int) -> Void
    
    var body: some View {
        Section {
            if expandedPacks.contains(pack.id) {
                ForEach(samplesManager.getSamplesForPack(pack)) { sample in
                    SampleListRow(sample: sample, packColor: pack.color)
                }
            }
        } header: {
            SamplePackHeader(
                pack: pack,
                isExpanded: expandedPacks.contains(pack.id),
                onToggle: {
                    withAnimation {
                        if expandedPacks.contains(pack.id) {
                            expandedPacks.remove(pack.id)
                        } else {
                            expandedPacks.insert(pack.id)
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Sample Pack Header
struct SamplePackHeader: View {
    let pack: SamplePack
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                
                Text(pack.icon)
                    .font(.system(size: 20))
                
                Text(pack.name.uppercased())
                    .font(.system(size: 16, weight: .heavy))
                
                Spacer()
                
                Text("\(pack.samples.count) SAMPLES")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .foregroundColor(.white)
    }
}

// MARK: - Sample List Row
struct SampleListRow: View {
    let sample: SampleFile
    let packColor: Color
    
    var body: some View {
        HStack {
            Image(systemName: "waveform")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Text(sample.name)
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Spacer()
            
            if let duration = sample.duration {
                Text(formatDuration(duration))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Sample List Inline View
struct SampleListInlineView: View {
    let samplerEngine: SamplerEngine
    @StateObject private var samplesManager = ModernSamplesManager()
    @State private var expandedPacks: Set<String> = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(samplesManager.samplePacks) { pack in
                    VStack(alignment: .leading, spacing: 8) {
                        // Pack header
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if expandedPacks.contains(pack.id) {
                                    expandedPacks.remove(pack.id)
                                } else {
                                    expandedPacks.insert(pack.id)
                                }
                            }
                        }) {
                            HStack {
                                Image(systemName: expandedPacks.contains(pack.id) ? "chevron.down" : "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))
                                
                                Text(pack.icon)
                                    .font(.system(size: 16))
                                
                                Text(pack.name.uppercased())
                                    .font(.system(size: 14, weight: .heavy))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(pack.samples.count)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        
                        // Samples
                        if expandedPacks.contains(pack.id) {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(samplesManager.getSamplesForPack(pack)) { sample in
                                    HStack {
                                        Image(systemName: "waveform")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gray)
                                        
                                        Text(sample.name)
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 8)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(4)
                                }
                            }
                            .padding(.leading, 20)
                        }
                    }
                }
            }
        }
        .onAppear {
            samplesManager.scanForAudioFiles()
        }
    }
}

// MARK: - Keyboard Handler View
struct KeyboardHandlerView: UIViewRepresentable {
    let onKeyPress: (String) -> Void
    
    func makeUIView(context: Context) -> KeyboardHandlerUIView {
        let view = KeyboardHandlerUIView()
        view.onKeyPress = onKeyPress
        return view
    }
    
    func updateUIView(_ uiView: KeyboardHandlerUIView, context: Context) {}
}

class KeyboardHandlerUIView: UIView {
    var onKeyPress: ((String) -> Void)?
    
    override var canBecomeFirstResponder: Bool { true }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        DispatchQueue.main.async {
            self.becomeFirstResponder()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var keyCommands: [UIKeyCommand]? {
        let keys = ["1", "2", "3", "4", "q", "w", "e", "r", "a", "s", "d", "f", "z", "x", "c", "v"]
        return keys.map { key in
            UIKeyCommand(input: key, modifierFlags: [], action: #selector(keyPressed(_:)))
        }
    }
    
    @objc private func keyPressed(_ sender: UIKeyCommand) {
        if let key = sender.input {
            onKeyPress?(key)
        }
    }
}

#Preview {
    SamplerView(taskStore: TaskStore(), currentTab: .constant("sampler"))
}