//
//  SamplerView.swift
//  Jamminverz
//
//  MPC-style sampler with 4x4 pad grid and keyboard mapping
//

import SwiftUI
import AVFoundation

// MARK: - Sampler View
struct SamplerView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var samplerEngine = SamplerEngine()
    @State private var recordingMode = false
    @State private var selectedPad: Int?
    @State private var showSamplePicker = false
    @State private var draggedSample: SampleFile?
    @State private var hoveredPad: Int?
    
    // Keyboard mapping
    let keyboardMap: [String: Int] = [
        "q": 0, "w": 1, "e": 2, "r": 3,
        "a": 4, "s": 5, "d": 6, "f": 7,
        "z": 8, "x": 9, "c": 10, "v": 11,
        "1": 12, "2": 13, "3": 14, "4": 15
    ]
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.3, blue: 0.5),
                    Color(red: 0.8, green: 0.2, blue: 0.4),
                    Color(red: 0.7, green: 0.1, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Main content
                HStack(spacing: 32) {
                    // Left side - Pad grid
                    padGridView
                        .frame(maxWidth: 600)
                    
                    // Right side - Controls
                    controlsView
                        .frame(width: 320)
                }
                .padding(.horizontal, 32)
                
                // Bottom bar
                bottomBarView
            }
            .padding(.vertical, 24)
        }
        .onAppear {
            samplerEngine.setupAudioEngine()
        }
        .focusable()
        .onKeyPress { press in
            handleKeyPress(press.key)
            return .handled
        }
        .sheet(isPresented: $showSamplePicker) {
            SamplePickerView(samplerEngine: samplerEngine, selectedPad: $selectedPad)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Text("SAMPLER")
                .font(.system(size: 42, weight: .heavy))
                .foregroundColor(.white)
            
            Spacer()
            
            // Recording indicator
            if recordingMode {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .opacity(0.5)
                                .scaleEffect(recordingMode ? 2 : 1)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: recordingMode)
                        )
                    
                    Text("RECORDING")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.3))
                .cornerRadius(20)
            }
            
            // Pattern selector
            HStack(spacing: 16) {
                ForEach(1...4, id: \.self) { pattern in
                    Button(action: { samplerEngine.selectPattern(pattern - 1) }) {
                        Text("\(pattern)")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(samplerEngine.currentPattern == pattern - 1 ? .black : .white)
                            .frame(width: 40, height: 40)
                            .background(
                                samplerEngine.currentPattern == pattern - 1 ?
                                Color.white : Color.white.opacity(0.2)
                            )
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Pad Grid View
    private var padGridView: some View {
        VStack(spacing: 16) {
            // Keyboard hints
            HStack {
                Text("KEYBOARD MAPPING")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                Text("Q-R, A-F, Z-V, 1-4")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            
            // 4x4 Pad grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 16) {
                ForEach(0..<16) { index in
                    PadButton(
                        index: index,
                        pad: samplerEngine.pads[index],
                        isSelected: selectedPad == index,
                        isHovered: hoveredPad == index,
                        keyLabel: getKeyLabel(for: index),
                        onTap: { triggerPad(index) },
                        onSelect: { selectedPad = index }
                    )
                    .onDrop(of: [.audio], isTargeted: .constant(false)) { providers in
                        _ = handleSampleDrop(providers, padIndex: index)
                        return true
                    }
                    .onHover { hovering in
                        hoveredPad = hovering ? index : nil
                    }
                }
            }
            
            // Velocity/Volume slider
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("VELOCITY")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(samplerEngine.globalVelocity * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Slider(value: $samplerEngine.globalVelocity, in: 0...1)
                    .accentColor(.white)
            }
            .padding(.horizontal, 8)
        }
    }
    
    // MARK: - Controls View
    private var controlsView: some View {
        VStack(spacing: 24) {
            // Selected pad info
            if let selectedPad = selectedPad {
                selectedPadInfo(pad: samplerEngine.pads[selectedPad])
            } else {
                emptyPadInfo
            }
            
            // Recording controls
            recordingControls
            
            // Effects section
            effectsSection
            
            Spacer()
        }
        .padding(24)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
    
    // MARK: - Selected Pad Info
    private func selectedPadInfo(pad: SamplerPad) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PAD \(pad.index + 1)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if pad.hasSample {
                    Button(action: { samplerEngine.clearPad(pad.index) }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            if let sampleName = pad.sampleName {
                VStack(alignment: .leading, spacing: 8) {
                    Text(sampleName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack {
                        Label("Volume", systemImage: "speaker.wave.2")
                            .font(.system(size: 12))
                        Slider(value: Binding(
                            get: { pad.volume },
                            set: { samplerEngine.setPadVolume(pad.index, volume: $0) }
                        ))
                    }
                    .foregroundColor(.white.opacity(0.8))
                    
                    HStack {
                        Label("Pitch", systemImage: "tuningfork")
                            .font(.system(size: 12))
                        Slider(
                            value: Binding(
                                get: { pad.pitch },
                                set: { samplerEngine.setPadPitch(pad.index, pitch: $0) }
                            ),
                            in: 0.5...2.0
                        )
                    }
                    .foregroundColor(.white.opacity(0.8))
                }
            } else {
                Button(action: { showSamplePicker = true }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Load Sample")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Empty Pad Info
    private var emptyPadInfo: some View {
        VStack(spacing: 12) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Select a pad")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    // MARK: - Recording Controls
    private var recordingControls: some View {
        VStack(spacing: 16) {
            Text("RECORDING")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                // Metronome
                Button(action: { samplerEngine.toggleMetronome() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "metronome")
                            .font(.system(size: 24))
                        Text("Metronome")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(samplerEngine.metronomeEnabled ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        samplerEngine.metronomeEnabled ?
                        Color.white.opacity(0.3) : Color.white.opacity(0.1)
                    )
                    .cornerRadius(8)
                }
                
                // Quantize
                Button(action: { samplerEngine.toggleQuantize() }) {
                    VStack(spacing: 4) {
                        Image(systemName: "square.grid.3x3")
                            .font(.system(size: 24))
                        Text("Quantize")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(samplerEngine.quantizeEnabled ? .white : .white.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        samplerEngine.quantizeEnabled ?
                        Color.white.opacity(0.3) : Color.white.opacity(0.1)
                    )
                    .cornerRadius(8)
                }
            }
            
            // Record button
            Button(action: toggleRecording) {
                HStack {
                    Image(systemName: recordingMode ? "stop.circle.fill" : "record.circle")
                        .font(.system(size: 20))
                    Text(recordingMode ? "Stop Recording" : "Start Recording")
                        .font(.system(size: 16, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(recordingMode ? Color.red : Color.red.opacity(0.8))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Effects Section
    private var effectsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EFFECTS")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            // Effect buttons
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(["Reverb", "Delay", "Filter", "Distortion"], id: \.self) { effect in
                    Button(action: { samplerEngine.toggleEffect(effect) }) {
                        Text(effect)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                samplerEngine.activeEffects.contains(effect) ?
                                Color.white.opacity(0.3) : Color.white.opacity(0.1)
                            )
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Bottom Bar View
    private var bottomBarView: some View {
        HStack(spacing: 24) {
            // Transport controls
            HStack(spacing: 16) {
                Button(action: { samplerEngine.stop() }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
                
                Button(action: { samplerEngine.togglePlayback() }) {
                    Image(systemName: samplerEngine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            // BPM control
            HStack(spacing: 8) {
                Text("BPM")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                TextField("120", value: $samplerEngine.bpm, format: .number)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 60)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // Pattern length
            HStack(spacing: 8) {
                Text("BARS")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                Picker("", selection: $samplerEngine.patternLength) {
                    ForEach([1, 2, 4, 8], id: \.self) { bars in
                        Text("\(bars)").tag(bars)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            
            // Clear pattern
            Button(action: { samplerEngine.clearCurrentPattern() }) {
                Text("Clear Pattern")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 32)
    }
    
    // MARK: - Helper Methods
    private func triggerPad(_ index: Int) {
        samplerEngine.triggerPad(index, velocity: samplerEngine.globalVelocity)
        
        if recordingMode {
            samplerEngine.recordPadHit(index)
        }
        
        // Visual feedback
        withAnimation(.easeOut(duration: 0.1)) {
            selectedPad = index
        }
    }
    
    private func toggleRecording() {
        recordingMode.toggle()
        if recordingMode {
            samplerEngine.startRecording()
        } else {
            samplerEngine.stopRecording()
        }
    }
    
    private func getKeyLabel(for index: Int) -> String {
        let keys = ["Q", "W", "E", "R", "A", "S", "D", "F", "Z", "X", "C", "V", "1", "2", "3", "4"]
        return keys[index]
    }
    
    private func handleKeyPress(_ key: KeyEquivalent) {
        let keyStr = String(key.character).lowercased()
        if let padIndex = keyboardMap[keyStr] {
            triggerPad(padIndex)
        }
    }
    
    private func handleSampleDrop(_ providers: [NSItemProvider], padIndex: Int) -> Bool {
        // Handle sample drop from SAMPLES view
        return true
    }
}

// MARK: - Pad Button
struct PadButton: View {
    let index: Int
    let pad: SamplerPad
    let isSelected: Bool
    let isHovered: Bool
    let keyLabel: String
    let onTap: () -> Void
    let onSelect: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            onTap()
            onSelect()
        }) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        pad.hasSample ?
                        (isPressed ? Color.white : padColor) :
                        Color.white.opacity(0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Color.white : Color.white.opacity(0.3),
                                lineWidth: isSelected ? 3 : 1
                            )
                    )
                
                // Content
                VStack(spacing: 8) {
                    // Pad number and key
                    HStack {
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .bold))
                        
                        Spacer()
                        
                        Text(keyLabel)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                    
                    // Sample name
                    if let sampleName = pad.sampleName {
                        Text(sampleName)
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(12)
                .foregroundColor(pad.hasSample ? .white : .white.opacity(0.5))
            }
            .frame(height: 120)
            .scaleEffect(isPressed ? 0.95 : (isHovered ? 1.05 : 1.0))
            .animation(.spring(response: 0.3), value: isPressed)
            .animation(.spring(response: 0.3), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity,
                            pressing: { pressing in
                                isPressed = pressing
                                if pressing { onTap() }
                            },
                            perform: {})
    }
    
    private var padColor: Color {
        let colors: [Color] = [
            .pink, .purple, .blue, .cyan,
            .green, .yellow, .orange, .red,
            .indigo, .mint, .teal, .brown,
            Color(red: 0.9, green: 0.3, blue: 0.5),
            Color(red: 0.5, green: 0.9, blue: 0.3),
            Color(red: 0.3, green: 0.5, blue: 0.9),
            Color(red: 0.9, green: 0.5, blue: 0.3)
        ]
        return colors[index % colors.count]
    }
}

// MARK: - Sample Picker View
struct SamplePickerView: View {
    @ObservedObject var samplerEngine: SamplerEngine
    @Binding var selectedPad: Int?
    @Environment(\.dismiss) var dismiss
    @StateObject private var samplesManager = ModernSamplesManager()
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search samples...", text: $searchText)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // Samples list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredSamples) { sample in
                            Button(action: { loadSample(sample) }) {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(sample.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        if let duration = sample.duration {
                                            Text(formatDuration(duration))
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if let bpm = sample.bpm {
                                        Text("\(Int(bpm)) BPM")
                                            .font(.system(size: 14))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color.gray.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Select Sample")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            samplesManager.scanForAudioFiles()
        }
    }
    
    private var filteredSamples: [SampleFile] {
        if searchText.isEmpty {
            return samplesManager.audioFiles
        }
        return samplesManager.audioFiles.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func loadSample(_ sample: SampleFile) {
        if let padIndex = selectedPad {
            samplerEngine.loadSample(sample.url, toPad: padIndex)
        }
        dismiss()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: duration) ?? "0:00"
    }
}