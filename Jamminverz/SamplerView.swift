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
    @State private var showAllSequencersView = true // Default to all sequencers view
    @State private var selectedPadIndex: Int = 0 // Always start with pad 0 selected
    @State private var sequencerSteps = Array(repeating: Array(repeating: false, count: 16), count: 16) // 16 pads x 16 steps
    @State private var currentSequencerStep: Int = -1 // -1 means not playing
    @State private var sequencerTimer: Timer?
    @State private var padTimeSignatures = Array(repeating: 16, count: 16) // Time signature for each pad (default 16 steps)
    @State private var padSpeeds = Array(repeating: 1.0, count: 16) // Speed multiplier for each pad
    @State private var gridSize: Double = 12 // Number of columns/rows in the grid
    @State private var draggedPack: SamplePack? = nil
    @State private var draggedIndex: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var dropTargetIndex: Int? = nil
    
    // New sequencer control states
    @State private var padVolumes = Array(repeating: 0.8, count: 16) // Volume for each pad (0.0 to 1.0)
    @State private var padMuted = Array(repeating: false, count: 16) // Mute state for each pad
    @State private var padSolo = Array(repeating: false, count: 16) // Solo state for each pad
    @State private var padDirection = Array(repeating: "forward", count: 16) // Direction: forward, backward, pendulum, random
    @State private var padRetrigger = Array(repeating: 1, count: 16) // Retrigger count: 1-4
    @State private var padLength = Array(repeating: 16, count: 16) // Length of pattern for each pad
    @State private var padGhostNotes = Array(repeating: false, count: 16) // Ghost notes state for each pad
    
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
                    
                    // Main content
                    if showAllSequencersView {
                        // All sequencers view - fills entire space
                        allSequencersContent
                    } else {
                        // Normal sampler view
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
                    _ = samplesManager.createPack(name: pack.name, icon: pack.icon, color: pack.color)
                }
            }
        }
        .background(
            KeyboardHandlerView { key in
                handleKeyPress(key)
            }
        )
        // Removed sheet - view is now inline
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            // Back button
            Button(action: {
                currentTab = "menu"
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .heavy))
                    Text("BACK")
                        .font(.system(size: 16, weight: .heavy))
                }
                .foregroundColor(.white)
            }
            
            // Play/Stop buttons right after back button
            HStack(spacing: 12) {
                Button(action: startSequencer) {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )
                }
                
                Button(action: stopSequencer) {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Rectangle()
                                .fill(Color.white)
                                .frame(width: 12, height: 12)
                        )
                }
            }
            
            Spacer()
            
            Text("SAMPLER")
                .font(.system(size: 32, weight: .heavy))
                .foregroundColor(.white)
            
            Spacer()
            
            // View toggle buttons - styled like album grid with NO spacing
            HStack(spacing: 0) {
                // List view button
                Button(action: {
                    showSampleListView.toggle()
                }) {
                    Rectangle()
                        .fill(Color.white.opacity(showSampleListView ? 0.2 : 0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            VStack(spacing: 3) {
                                ForEach(0..<4) { _ in
                                    Rectangle()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: 22, height: 2)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Grid view toggle button
                Button(action: {
                    isGridView.toggle()
                }) {
                    Rectangle()
                        .fill(Color.white.opacity(isGridView ? 0.2 : 0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            LazyVGrid(columns: Array(repeating: GridItem(.fixed(6), spacing: 3), count: 4), spacing: 3) {
                                ForEach(0..<16) { _ in
                                    Rectangle()
                                        .fill(Color.white.opacity(isGridView ? 1.0 : 0.6))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // All sequencers view button
                Button(action: {
                    showAllSequencersView.toggle()
                }) {
                    Rectangle()
                        .fill(Color.white.opacity(showAllSequencersView ? 0.2 : 0.1))
                        .frame(width: 50, height: 50)
                        .overlay(
                            VStack(spacing: 3) {
                                ForEach(0..<3) { row in
                                    HStack(spacing: 3) {
                                        ForEach(0..<3) { col in
                                            Circle()
                                                .fill(Color.white.opacity(showAllSequencersView ? 1.0 : 0.6))
                                                .frame(width: 5, height: 5)
                                        }
                                    }
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Color picker button
                Button(action: {
                    showColorPicker.toggle()
                }) {
                    Rectangle()
                        .fill(
                            gridColorMode == "rainbow" ?
                            AnyShapeStyle(LinearGradient(
                                colors: [.red, .orange, .yellow, .green, .blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )) :
                            AnyShapeStyle(selectedGridColor)
                        )
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $showColorPicker) {
                    ColorPickerPopover(
                        gridColorMode: $gridColorMode,
                        selectedGridColor: $selectedGridColor
                    )
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
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
    
    // MARK: - All Sequencers Content
    private var allSequencersContent: some View {
        sequencerGrid
    }
    
    private var sequencerGrid: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(0..<16, id: \.self) { padIndex in
                        sequencerRow(for: padIndex)
                    }
                }
                .padding(.top, 80)
                .padding(.bottom, 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    @ViewBuilder
    private func sequencerRow(for padIndex: Int) -> some View {
        HStack(spacing: 12) {
            // Pad number
            padNumberView(padIndex)
            
            // Step buttons - 16 circles
            stepButtonsView(padIndex)
            
            // Control buttons in new order: M, S, L, F, R, G, C
            controlButtonsView(padIndex)
            
            // Volume slider at the end
            volumeSliderView(padIndex)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 10)
    }
    
    @ViewBuilder
    private func padNumberView(_ padIndex: Int) -> some View {
        ZStack {
            // Background for the entire button area
            RoundedRectangle(cornerRadius: 12)
                .fill(getColorForPad(padIndex).opacity(0.3))
                .frame(width: 100, height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(getColorForPad(padIndex).opacity(0.5), lineWidth: 2)
                )
            
            HStack(spacing: 0) {
                // Left arrow button
                Button(action: {
                    cycleToPreviousKit(for: padIndex)
                }) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 50, height: 52)
                        .overlay(
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(getColorForPad(padIndex).opacity(0.8))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Divider
                Rectangle()
                    .fill(getColorForPad(padIndex).opacity(0.5))
                    .frame(width: 1, height: 40)
                
                // Right arrow button
                Button(action: {
                    cycleToNextKit(for: padIndex)
                }) {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 49, height: 52)
                        .overlay(
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(getColorForPad(padIndex).opacity(0.8))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    @ViewBuilder
    private func stepButtonsView(_ padIndex: Int) -> some View {
        HStack(spacing: 12) {
            ForEach(0..<16) { step in
                stepButton(padIndex: padIndex, step: step)
            }
        }
    }
    
    @ViewBuilder
    private func stepButton(padIndex: Int, step: Int) -> some View {
        Button(action: {
            sequencerSteps[padIndex][step].toggle()
        }) {
            Circle()
                .fill(
                    sequencerSteps[padIndex][step] ? 
                    getColorForPad(padIndex) : 
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
                            lineWidth: step == currentSequencerStep ? 3 : 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 56, height: 56)
    }
    
    @ViewBuilder
    private func volumeSliderView(_ padIndex: Int) -> some View {
        Slider(
            value: Binding(
                get: { padVolumes[padIndex] },
                set: { padVolumes[padIndex] = $0 }
            ),
            in: 0...1
        )
        .frame(width: 150)
        .accentColor(getColorForPad(padIndex))
    }
    
    @ViewBuilder
    private func controlButtonsView(_ padIndex: Int) -> some View {
        HStack(spacing: 12) {
            // Mute button
            controlButton(
                title: "M",
                color: padMuted[padIndex] ? Color.red.opacity(0.6) : Color.white.opacity(0.2),
                action: { padMuted[padIndex].toggle() }
            )
            
            // Solo button
            controlButton(
                title: "S",
                color: padSolo[padIndex] ? Color.yellow.opacity(0.6) : Color.white.opacity(0.2),
                action: { padSolo[padIndex].toggle() }
            )
            
            // Length button
            controlButton(
                title: "L",
                color: Color.purple.opacity(0.2),
                action: {
                    let lengths = [1, 2, 4, 8, 16]
                    if let currentIndex = lengths.firstIndex(of: padLength[padIndex]) {
                        let nextIndex = (currentIndex + 1) % lengths.count
                        padLength[padIndex] = lengths[nextIndex]
                    }
                }
            )
            
            // Direction button
            controlButton(
                title: directionLetter(for: padDirection[padIndex]),
                color: directionColor(for: padDirection[padIndex]),
                action: {
                    let directions = ["forward", "backward", "pendulum", "random"]
                    if let currentIndex = directions.firstIndex(of: padDirection[padIndex]) {
                        let nextIndex = (currentIndex + 1) % directions.count
                        padDirection[padIndex] = directions[nextIndex]
                    }
                }
            )
            
            // Retrigger button
            controlButton(
                title: "R",
                color: padRetrigger[padIndex] > 1 ? Color.orange.opacity(0.3) : Color.white.opacity(0.2),
                action: {
                    // Cycle through: 1, 2, 3, 4
                    padRetrigger[padIndex] = padRetrigger[padIndex] % 4 + 1
                }
            )
            
            // Ghost notes button
            controlButton(
                title: "G",
                color: padGhostNotes[padIndex] ? Color.blue.opacity(0.3) : Color.white.opacity(0.2),
                action: { padGhostNotes[padIndex].toggle() }
            )
            
            // Clear button
            controlButton(
                title: "C",
                color: Color.red.opacity(0.2),
                action: {
                    for step in 0..<16 {
                        sequencerSteps[padIndex][step] = false
                    }
                }
            )
        }
    }
    
    @ViewBuilder
    private func controlButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 52, height: 52)
                .overlay(
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
    
    private var sequencerTransportBar: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Mute button
                Button(action: { /* TODO: Implement mute */ }) {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("M")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 50)
                
                // Solo button
                Button(action: { /* TODO: Implement solo */ }) {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Text("S")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 50)
                
                // 16 step indicators
                HStack(spacing: 0) {
                    ForEach(0..<16) { step in
                        Circle()
                            .fill(
                                step == currentSequencerStep ?
                                Color.white :
                                Color.white.opacity(0.2)
                            )
                            .frame(width: 35, height: 35)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Time signature controls
                HStack(spacing: 4) {
                    Button(action: {
                        if padTimeSignatures[selectedPadIndex] > 4 {
                            padTimeSignatures[selectedPadIndex] -= 1
                        }
                    }) {
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                    
                    Text("\(padTimeSignatures[selectedPadIndex])")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 30)
                    
                    Button(action: {
                        if padTimeSignatures[selectedPadIndex] < 16 {
                            padTimeSignatures[selectedPadIndex] += 1
                        }
                    }) {
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 20)
        }
        .frame(height: 80)
        .padding(.bottom, 20)
    }
    
    private func calculateGridSize(for size: CGSize) -> (circleSize: CGFloat, spacing: CGFloat) {
        let columns = 16
        let rows = 16
        let spacing: CGFloat = 4
        let circleSize = min(
            (size.width - (CGFloat(columns - 1) * spacing) - 40) / CGFloat(columns),
            (size.height - (CGFloat(rows - 1) * spacing) - 100) / CGFloat(rows)
        )
        return (circleSize, spacing)
    }
    
    // Helper function to get color for each pad
    private func getColorForPad(_ padIndex: Int) -> Color {
        let colors: [Color] = [.purple, .pink, .blue, .green, .orange, .red, .yellow, .cyan, .indigo, .mint, .teal, .brown]
        if let pack = selectedPack {
            return pack.color
        }
        return colors[padIndex % colors.count]
    }
    
    // Helper function to get color for direction button
    private func directionColor(for direction: String) -> Color {
        switch direction {
        case "forward":
            return Color.blue.opacity(0.2)
        case "backward":
            return Color.purple.opacity(0.2)
        case "pendulum":
            return Color.green.opacity(0.2)
        case "random":
            return Color.orange.opacity(0.2)
        default:
            return Color.white.opacity(0.2)
        }
    }
    
    // Helper function to get letter for direction button
    private func directionLetter(for direction: String) -> String {
        switch direction {
        case "forward":
            return "F"
        case "backward":
            return "B"
        case "pendulum":
            return "P"
        case "random":
            return "R"
        default:
            return "F"
        }
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
            samplerEngine: samplerEngine,
            gridSize: $gridSize,
            draggedPack: $draggedPack,
            draggedIndex: $draggedIndex,
            dragOffset: $dragOffset,
            dropTargetIndex: $dropTargetIndex,
            performPackSwap: performPackSwap
        )
    }
    
    // MARK: - Helper Methods
    private func loadMyPacks() {
        // Load packs from the samples manager
        myPacks = samplesManager.samplePacks
    }
    
    // MARK: - Drag and Drop Helper
    private func performPackSwap(targetIndex: Int) {
        guard let currentDraggedIndex = draggedIndex else { return }
        
        // Create a mutable copy of packs
        var updatedPacks = myPacks
        
        // If dropping on an empty slot
        if targetIndex >= updatedPacks.count {
            // Move the pack to the end
            let movedPack = updatedPacks.remove(at: currentDraggedIndex)
            updatedPacks.append(movedPack)
        } else if currentDraggedIndex != targetIndex {
            // Swap the packs
            let movedPack = updatedPacks.remove(at: currentDraggedIndex)
            if targetIndex > currentDraggedIndex {
                updatedPacks.insert(movedPack, at: targetIndex - 1)
            } else {
                updatedPacks.insert(movedPack, at: targetIndex)
            }
        }
        
        // Update the state
        myPacks = updatedPacks
        
        // Reset drag state
        draggedPack = nil
        draggedIndex = nil
        dropTargetIndex = nil
    }
    
    private func handleKeyPress(_ key: String) {
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
            // Always update selected pad index
            selectedPadIndex = padIndex
            
            // Only play sound if a sample pack is selected
            if selectedPack != nil {
                playPadSound(padIndex)
            }
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
    
    private func cycleToPreviousKit(for padIndex: Int) {
        guard let currentPack = selectedPack,
              let currentIndex = myPacks.firstIndex(where: { $0.id == currentPack.id }),
              currentIndex > 0 else { return }
        
        selectedPack = myPacks[currentIndex - 1]
        loadPackSounds(selectedPack!)
    }
    
    private func cycleToNextKit(for padIndex: Int) {
        guard let currentPack = selectedPack,
              let currentIndex = myPacks.firstIndex(where: { $0.id == currentPack.id }),
              currentIndex < myPacks.count - 1 else { return }
        
        selectedPack = myPacks[currentIndex + 1]
        loadPackSounds(selectedPack!)
    }
    
    private func playPadSound(_ padIndex: Int) {
        // Trigger the sound immediately
        samplerEngine.triggerPad(padIndex, velocity: 1.0)
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
            // Return a dimmed rainbow color based on a hash of current time
            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint, .teal]
            let randomIndex = Int.random(in: 0..<colors.count)
            return colors[randomIndex].opacity(0.3)
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
        let baseStepDuration = 60.0 / bpm / 4.0 // 16th notes
        
        sequencerTimer = Timer.scheduledTimer(withTimeInterval: baseStepDuration, repeats: true) { _ in
            // Play all pads based on their individual time signatures for polyrhythms
            for padIndex in 0..<16 {
                let padSteps = padTimeSignatures[padIndex]
                // padSpeed = padSpeeds[padIndex] // Reserved for future use
                
                // Calculate which step this pad should be on based on its time signature
                let effectiveStep = Int(Double(currentSequencerStep) * Double(padSteps) / 16.0) % padSteps
                
                // Check if this global step aligns with a step in this pad's pattern
                let stepInterval = 16.0 / Double(padSteps)
                if Double(currentSequencerStep).truncatingRemainder(dividingBy: stepInterval) < 0.01 {
                    if effectiveStep < padSteps && sequencerSteps[padIndex][effectiveStep] {
                        playPadSound(padIndex)
                    }
                }
            }
            
            // Move to next global step
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
                HStack(spacing: 12) {
                    // Play button
                    Button(action: {
                        startSequencer()
                    }) {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 52, height: 52)
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
                            .frame(width: 52, height: 52)
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
                    
                    // Step buttons - only show active steps based on time signature
                    ForEach(0..<16) { step in
                        if step < padTimeSignatures[padIndex] {
                            Button(action: {
                                sequencerSteps[padIndex][step].toggle()
                            }) {
                                Circle()
                                    .fill(
                                        sequencerSteps[padIndex][step] ? 
                                            (selectedPack?.color ?? .purple) : 
                                            Color.white.opacity(0.1)
                                    )
                                    .frame(width: 52, height: 52)
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
                    
                    // Time signature controls
                    HStack(spacing: 12) {
                        // Decrease time signature
                        Button(action: {
                            if padTimeSignatures[padIndex] > 4 {
                                padTimeSignatures[padIndex] -= 1
                            }
                        }) {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.purple.opacity(0.5), lineWidth: 2)
                                )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Current time signature display
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Text("\(padTimeSignatures[padIndex])")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.purple.opacity(0.5), lineWidth: 2)
                            )
                        
                        // Increase time signature
                        Button(action: {
                            if padTimeSignatures[padIndex] < 16 {
                                padTimeSignatures[padIndex] += 1
                            }
                        }) {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 52, height: 52)
                                .overlay(
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.purple.opacity(0.5), lineWidth: 2)
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
                                        // Always update selected pad index
                                        selectedPadIndex = index
                                        // Only play sound if pack is selected
                                        if selectedPack != nil {
                                            onPadTap(index)
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
    @Binding var gridSize: Double
    @Binding var draggedPack: SamplePack?
    @Binding var draggedIndex: Int?
    @Binding var dragOffset: CGSize
    @Binding var dropTargetIndex: Int?
    let performPackSwap: (Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with slider
            HStack(spacing: 12) {
                Text("JAM PACKS")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)
                
                // Grid size slider - only show when in grid view
                if isGridView {
                    HStack(spacing: 12) {
                        Text("GRID SIZE")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Slider(value: $gridSize, in: 10...50, step: 1)
                            .frame(width: 150)
                            .accentColor(.purple)
                        
                        Text("\(Int(gridSize))")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 25)
                    }
                }
                
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
            let columns = Int(gridSize)
            let totalSlots = columns * columns
            let spacing: CGFloat = 1
            let totalSpacing = spacing * CGFloat(columns - 1)
            let squareSize = (geo.size.width - totalSpacing) / CGFloat(columns)
            
            ZStack {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(squareSize), spacing: spacing), count: columns), spacing: spacing) {
                    ForEach(0..<totalSlots, id: \.self) { index in
                        GridSlotView(
                            index: index,
                            pack: index < myPacks.count ? myPacks[index] : nil,
                            squareSize: squareSize,
                            selectedPack: selectedPack,
                            draggedPack: draggedPack,
                            dropTargetIndex: dropTargetIndex,
                            onPackSelected: { pack in
                                selectedPack = pack
                                onPackSelected(pack)
                            },
                            onDragStart: { pack in
                                if let packIndex = myPacks.firstIndex(where: { $0.id == pack.id }) {
                                    draggedPack = pack
                                    draggedIndex = packIndex
                                }
                            },
                            onDrop: { targetIndex in
                                performPackSwap(targetIndex)
                            },
                            getPackColor: getPackColor,
                            getInactiveColor: getInactiveColor,
                            gridColorMode: gridColorMode,
                            selectedGridColor: selectedGridColor
                        )
                    }
                }
                
                // Remove the dragged pack overlay - SwiftUI handles it automatically
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
            // Return a dimmed rainbow color based on a hash of current time
            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint, .teal]
            let randomIndex = Int.random(in: 0..<colors.count)
            return colors[randomIndex].opacity(0.3)
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
    
    // Rainbow colors for inactive pads
    private var inactiveColor: Color {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint, .teal, .indigo, .brown]
        return colors[index % colors.count]
    }
    
    var body: some View {
        Button(action: onTap) {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    isActive ?
                    (isPressed ? Color.white : color.opacity(isSelected ? 1.0 : 0.8)) :
                    (isPressed ? Color.white : inactiveColor.opacity(isSelected ? 0.6 : 0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isActive ? (isSelected ? Color.white : color) : 
                            (isSelected ? Color.white : inactiveColor.opacity(0.5)),
                            lineWidth: isSelected ? 3 : 2
                        )
                )
                .overlay(
                    Text("\(index + 1)")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isActive || isSelected ? .white : .white.opacity(0.6))
                )
        }
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
            isAdded = true
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
        ("white", .white),
        ("black", .black),
        ("navy", Color(red: 0, green: 0, blue: 0.5)),
        ("forest", Color(red: 0.13, green: 0.37, blue: 0.13)),
        ("maroon", Color(red: 0.5, green: 0, blue: 0)),
        ("olive", Color(red: 0.5, green: 0.5, blue: 0)),
        ("lime", Color(red: 0.75, green: 1, blue: 0)),
        ("aqua", Color(red: 0, green: 1, blue: 1)),
        ("fuchsia", Color(red: 1, green: 0, blue: 1)),
        ("silver", Color(red: 0.75, green: 0.75, blue: 0.75)),
        ("coral", Color(red: 1, green: 0.5, blue: 0.31)),
        ("salmon", Color(red: 0.98, green: 0.5, blue: 0.45)),
        ("gold", Color(red: 1, green: 0.84, blue: 0)),
        ("plum", Color(red: 0.87, green: 0.63, blue: 0.87)),
        ("turquoise", Color(red: 0.25, green: 0.88, blue: 0.82)),
        ("violet", Color(red: 0.93, green: 0.51, blue: 0.93))
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            Text("GRID COLOR")
                .font(.system(size: 16, weight: .heavy))
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black)
            
            ScrollView {
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
            }
            .frame(maxHeight: 400)
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
                    if expandedPacks.contains(pack.id) {
                        expandedPacks.remove(pack.id)
                    } else {
                        expandedPacks.insert(pack.id)
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

// MARK: - Grid Slot View
struct GridSlotView: View {
    let index: Int
    let pack: SamplePack?
    let squareSize: CGFloat
    let selectedPack: SamplePack?
    let draggedPack: SamplePack?
    let dropTargetIndex: Int?
    let onPackSelected: (SamplePack) -> Void
    let onDragStart: (SamplePack) -> Void
    let onDrop: (Int) -> Void
    let getPackColor: (SamplePack) -> Color
    let getInactiveColor: () -> Color
    let gridColorMode: String
    let selectedGridColor: Color
    
    @State private var isDragOver = false
    
    private func getInactiveColorForIndex(_ index: Int) -> Color {
        if gridColorMode == "rainbow" {
            // Rainbow mode - generate a unique color for each index
            let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .cyan, .mint, .teal, .indigo, .brown]
            return colors[index % colors.count]
        } else {
            // Single color mode
            return selectedGridColor
        }
    }
    
    var body: some View {
        ZStack {
            if let pack = pack {
                Rectangle()
                    .fill(getPackColor(pack).opacity(selectedPack?.id == pack.id ? 1.0 : 0.8))
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        Rectangle()
                            .stroke(
                                selectedPack?.id == pack.id ? Color.white : Color.clear,
                                lineWidth: 1
                            )
                    )
                    .scaleEffect(draggedPack?.id == pack.id ? 0.8 : 1.0)
                    .opacity(draggedPack?.id == pack.id ? 0.5 : 1.0)
                    .onTapGesture {
                        onPackSelected(pack)
                    }
                    .onDrag {
                        onDragStart(pack)
                        return NSItemProvider(object: pack.id as NSString)
                    }
            } else {
                Rectangle()
                    .fill(getInactiveColorForIndex(index).opacity(0.2))
                    .aspectRatio(1, contentMode: .fit)
            }
            
            // Drop indicator
            if isDragOver {
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .background(Color.white.opacity(0.2))
            }
        }
        .onDrop(of: [.text], isTargeted: $isDragOver) { providers in
            // Only allow drop if we're dragging something
            if draggedPack != nil {
                onDrop(index)
                return true
            }
            return false
        }
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
                            if expandedPacks.contains(pack.id) {
                                expandedPacks.remove(pack.id)
                            } else {
                                expandedPacks.insert(pack.id)
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

// MARK: - Sequencer Row View
struct SequencerRowView: View {
    let padIndex: Int
    @Binding var sequencerSteps: [[Bool]]
    let currentStep: Int
    let circleSize: CGFloat
    let spacing: CGFloat
    let color: Color
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<16, id: \.self) { step in
                SamplerSequencerStepButton(
                    isActive: sequencerSteps[padIndex][step],
                    isCurrentStep: step == currentStep,
                    color: color,
                    size: circleSize,
                    action: {
                        sequencerSteps[padIndex][step].toggle()
                    }
                )
            }
        }
    }
}

// MARK: - Sampler Sequencer Step Button
struct SamplerSequencerStepButton: View {
    let isActive: Bool
    let isCurrentStep: Bool
    let color: Color
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(isActive ? color : Color.white.opacity(0.1))
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            isCurrentStep ? Color.white : Color.white.opacity(0.2),
                            lineWidth: isCurrentStep ? 2 : 1
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SamplerView(taskStore: TaskStore(), currentTab: .constant("sampler"))
}