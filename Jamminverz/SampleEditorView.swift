//
//  SampleEditorView.swift
//  Jamminverz
//
//  Built-in sample editing studio with professional audio manipulation tools
//

import SwiftUI
import AVFoundation
import Accelerate

// MARK: - Sample Editor View
struct SampleEditorView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    let sample: Sample?
    
    @StateObject private var editorManager = SampleEditorManager()
    @State private var selectedTool: EditingTool = .basic
    @State private var showSaveOptions = false
    @State private var showPackBuilder = false
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var selection: ClosedRange<TimeInterval>?
    @State private var zoomLevel: Double = 1.0
    @State private var showEffectsPanel = false
    @State private var compareMode = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main editor area
                if editorManager.isLoading {
                    loadingView
                } else {
                    VStack(spacing: 16) {
                        // Waveform display
                        waveformView
                        
                        // Transport controls
                        transportControls
                        
                        // Tool panels
                        toolPanelView
                        
                        // Effects chain (if active)
                        if showEffectsPanel {
                            effectsChainView
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showSaveOptions) {
            SaveOptionsView(
                editorManager: editorManager,
                onSave: { option in
                    editorManager.saveWith(option: option)
                    showSaveOptions = false
                }
            )
        }
        .sheet(isPresented: $showPackBuilder) {
            SamplePackBuilderView(
                editorManager: editorManager,
                currentSample: editorManager.editedBuffer != nil ? createEditedSample() : nil
            )
        }
        .onAppear {
            if let sample = sample {
                editorManager.loadSample(sample)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .AVAudioEngineConfigurationChange)) { _ in
            editorManager.handleAudioSessionInterruption()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                currentTab = "samples"
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .heavy))
                    Text("BACK")
                        .font(.system(size: 17, weight: .heavy))
                }
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("SAMPLE EDITOR")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.white)
                
                if let sampleName = editorManager.currentSample?.displayName {
                    Text(sampleName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: {
                    showSaveOptions = true
                }) {
                    Text("SAVE")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(!editorManager.hasChanges)
                
                Button(action: {
                    showPackBuilder = true
                }) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Waveform View
    private var waveformView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                
                // Waveform
                if let waveform = editorManager.waveformData {
                    WaveformView(
                        waveformData: waveform,
                        selection: $selection,
                        currentTime: $currentTime,
                        duration: editorManager.duration,
                        zoomLevel: $zoomLevel,
                        isPlaying: isPlaying,
                        onSeek: { time in
                            editorManager.seek(to: time)
                        }
                    )
                    .padding(8)
                }
                
                // Timeline
                VStack {
                    Spacer()
                    TimelineView(duration: editorManager.duration, zoomLevel: zoomLevel)
                        .frame(height: 30)
                }
            }
        }
        .frame(height: 200)
        .overlay(
            // Zoom controls
            HStack {
                Spacer()
                VStack {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            zoomLevel = min(zoomLevel * 1.5, 10.0)
                        }
                    }) {
                        Image(systemName: "plus.magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            zoomLevel = max(zoomLevel / 1.5, 1.0)
                        }
                    }) {
                        Image(systemName: "minus.magnifyingglass")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(8)
            }
        )
    }
    
    // MARK: - Transport Controls
    private var transportControls: some View {
        HStack(spacing: 24) {
            // Play/Pause
            Button(action: {
                if isPlaying {
                    editorManager.pause()
                } else {
                    editorManager.play()
                }
                isPlaying.toggle()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Time display
            VStack(spacing: 4) {
                Text(formatTime(currentTime))
                    .font(.system(size: 18, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                
                Text("/ \(formatTime(editorManager.duration))")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Loop toggle
            Button(action: {
                editorManager.loopEnabled.toggle()
            }) {
                Image(systemName: "repeat")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(editorManager.loopEnabled ? .green : .white.opacity(0.5))
            }
            
            // A/B Compare
            Button(action: {
                compareMode.toggle()
                editorManager.toggleCompareMode()
            }) {
                Text("A/B")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(compareMode ? .blue : .white.opacity(0.5))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(compareMode ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                    )
            }
            
            // Undo/Redo
            HStack(spacing: 8) {
                Button(action: {
                    editorManager.undo()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(editorManager.canUndo ? .white : .white.opacity(0.3))
                }
                .disabled(!editorManager.canUndo)
                
                Button(action: {
                    editorManager.redo()
                }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(editorManager.canRedo ? .white : .white.opacity(0.3))
                }
                .disabled(!editorManager.canRedo)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Tool Panel View
    private var toolPanelView: some View {
        VStack(spacing: 16) {
            // Tool selector
            HStack(spacing: 12) {
                ForEach(EditingTool.allCases, id: \.self) { tool in
                    ToolSelectorButton(
                        tool: tool,
                        isSelected: selectedTool == tool,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedTool = tool
                            }
                        }
                    )
                }
            }
            
            // Tool specific controls
            Group {
                switch selectedTool {
                case .basic:
                    BasicEditPanel(editorManager: editorManager, selection: selection)
                case .effects:
                    EffectsPanel(editorManager: editorManager) {
                        showEffectsPanel.toggle()
                    }
                case .generate:
                    GeneratePanel(editorManager: editorManager)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
    
    // MARK: - Effects Chain View
    private var effectsChainView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EFFECTS CHAIN")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    editorManager.clearEffects()
                }) {
                    Text("CLEAR ALL")
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundColor(.red)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(editorManager.activeEffects) { effect in
                        EffectChainItem(effect: effect) {
                            editorManager.removeEffect(effect)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading sample...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d.%02d", minutes, seconds, milliseconds)
    }
    
    private func createEditedSample() -> Sample {
        var editedSample = editorManager.currentSample ?? Sample(
            id: UUID(),
            originalPath: "edited_sample.wav",
            fileName: "edited_sample.wav",
            fileSize: 0,
            dateAdded: Date()
        )
        
        editedSample.suggestedName = editorManager.suggestedFileName
        return editedSample
    }
}

// MARK: - Editing Tool Enum
enum EditingTool: String, CaseIterable {
    case basic = "BASIC EDIT"
    case effects = "EFFECTS"
    case generate = "GENERATE"
    
    var icon: String {
        switch self {
        case .basic: return "scissors"
        case .effects: return "wand.and.rays"
        case .generate: return "sparkles"
        }
    }
}

// MARK: - Tool Selector Button
struct ToolSelectorButton: View {
    let tool: EditingTool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: tool.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSelected ? .black : .white)
                
                Text(tool.rawValue)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(isSelected ? .black : .white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Basic Edit Panel
struct BasicEditPanel: View {
    @ObservedObject var editorManager: SampleEditorManager
    let selection: ClosedRange<TimeInterval>?
    
    @State private var pitchShift: Double = 0
    @State private var speedChange: Double = 100
    @State private var volumeChange: Double = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Trim controls
            HStack(spacing: 12) {
                EditButton(title: "✂️ Trim", subtitle: "To Selection") {
                    if let selection = selection {
                        editorManager.trim(to: selection)
                    }
                }
                .disabled(selection == nil)
                
                EditButton(title: "🔇 Silence", subtitle: "Remove") {
                    editorManager.removeSilence()
                }
                
                EditButton(title: "📐 Normalize", subtitle: "Volume") {
                    editorManager.normalize()
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Pitch control
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🎵 Pitch")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(pitchShift > 0 ? "+" : "")\(Int(pitchShift)) semitones")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Slider(value: $pitchShift, in: -12...12, step: 1)
                    .accentColor(.white)
                    .onChange(of: pitchShift) { _, newValue in
                        editorManager.setPitch(semitones: Int(newValue))
                    }
            }
            
            // Speed control
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("📏 Speed")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(Int(speedChange))%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Slider(value: $speedChange, in: 50...200, step: 5)
                    .accentColor(.white)
                    .onChange(of: speedChange) { _, newValue in
                        editorManager.setSpeed(percentage: newValue)
                    }
            }
            
            // Volume control
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🔊 Volume")
                        .font(.system(size: 14, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(volumeChange > 0 ? "+" : "")\(Int(volumeChange)) dB")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Slider(value: $volumeChange, in: -20...20, step: 1)
                    .accentColor(.white)
                    .onChange(of: volumeChange) { _, newValue in
                        editorManager.setVolume(decibels: newValue)
                    }
            }
            
            // Fade controls
            HStack(spacing: 12) {
                EditButton(title: "📈 Fade In", subtitle: "0.5s") {
                    editorManager.fadeIn(duration: 0.5)
                }
                
                EditButton(title: "📉 Fade Out", subtitle: "0.5s") {
                    editorManager.fadeOut(duration: 0.5)
                }
            }
        }
    }
}

// MARK: - Effects Panel
struct EffectsPanel: View {
    @ObservedObject var editorManager: SampleEditorManager
    let onToggleChain: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Effect buttons grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                EffectButton(title: "🎛️ Filter", effect: .filter) {
                    editorManager.addEffect(.filter)
                }
                
                EffectButton(title: "🌊 Reverb", effect: .reverb) {
                    editorManager.addEffect(.reverb)
                }
                
                EffectButton(title: "⏰ Delay", effect: .delay) {
                    editorManager.addEffect(.delay)
                }
                
                EffectButton(title: "⚡ Distort", effect: .distortion) {
                    editorManager.addEffect(.distortion)
                }
                
                EffectButton(title: "🌀 Chorus", effect: .chorus) {
                    editorManager.addEffect(.chorus)
                }
                
                EffectButton(title: "🎚️ EQ", effect: .eq) {
                    editorManager.addEffect(.eq)
                }
            }
            
            // Show effects chain toggle
            Button(action: onToggleChain) {
                HStack {
                    Image(systemName: "link")
                        .font(.system(size: 14, weight: .medium))
                    
                    Text("VIEW EFFECTS CHAIN")
                        .font(.system(size: 12, weight: .heavy))
                    
                    if !editorManager.activeEffects.isEmpty {
                        Text("(\(editorManager.activeEffects.count))")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                )
            }
        }
    }
}

// MARK: - Generate Panel
struct GeneratePanel: View {
    @ObservedObject var editorManager: SampleEditorManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                GenerateButton(title: "🔄 Reverse", subtitle: "Flip audio") {
                    editorManager.reverse()
                }
                
                GenerateButton(title: "🔁 Loop", subtitle: "Make seamless") {
                    editorManager.createLoop()
                }
                
                GenerateButton(title: "✨ Chop", subtitle: "Auto-slice") {
                    editorManager.autoChop()
                }
            }
            
            HStack(spacing: 12) {
                GenerateButton(title: "📐 Slice", subtitle: "Equal parts") {
                    editorManager.slice(count: 8)
                }
                
                GenerateButton(title: "🎯 Transients", subtitle: "Extract hits") {
                    editorManager.extractTransients()
                }
                
                GenerateButton(title: "🎨 Variations", subtitle: "Generate 4") {
                    editorManager.generateVariations(count: 4)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Advanced generation
            VStack(spacing: 12) {
                GenerateButton(title: "🔊 Harmonic Bass", subtitle: "Generate sub from kick") {
                    editorManager.generateHarmonicBass()
                }
                .frame(maxWidth: .infinity)
                
                GenerateButton(title: "🥁 Groove Extract", subtitle: "Pull rhythm pattern") {
                    editorManager.extractGroove()
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Supporting Views
struct EditButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EffectButton: View {
    let title: String
    let effect: AudioEffect
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(effect.color.opacity(0.3))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(effect.color, lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GenerateButton: View {
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.black)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.black.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.yellow)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EffectChainItem: View {
    let effect: ActiveEffect
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(effect.type.rawValue)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundColor(.white)
                
                if let paramText = effect.parameterText {
                    Text(paramText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(effect.type.color.opacity(0.3))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(effect.type.color, lineWidth: 1)
        )
    }
}

// MARK: - Waveform View
struct WaveformView: View {
    let waveformData: [Float]
    @Binding var selection: ClosedRange<TimeInterval>?
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    @Binding var zoomLevel: Double
    let isPlaying: Bool
    let onSeek: (TimeInterval) -> Void
    
    @State private var isDragging = false
    @State private var dragStartLocation: CGPoint = .zero
    @State private var dragCurrentLocation: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Waveform visualization
                WaveformShape(samples: downsampledData(for: geometry.size.width))
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.8), Color.white.opacity(0.4)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                
                // Selection overlay
                if let selection = selection {
                    let startX = timeToX(selection.lowerBound, width: geometry.size.width)
                    let endX = timeToX(selection.upperBound, width: geometry.size.width)
                    
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .frame(width: endX - startX)
                        .position(x: (startX + endX) / 2, y: geometry.size.height / 2)
                }
                
                // Playhead
                let playheadX = timeToX(currentTime, width: geometry.size.width)
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 2)
                    .position(x: playheadX, y: geometry.size.height / 2)
                    .animation(.linear(duration: 0.1), value: currentTime)
                
                // Drag selection visualization
                if isDragging {
                    let startX = min(dragStartLocation.x, dragCurrentLocation.x)
                    let endX = max(dragStartLocation.x, dragCurrentLocation.x)
                    
                    Rectangle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: endX - startX)
                        .position(x: (startX + endX) / 2, y: geometry.size.height / 2)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            dragStartLocation = value.location
                        }
                        dragCurrentLocation = value.location
                    }
                    .onEnded { value in
                        isDragging = false
                        
                        let startTime = xToTime(min(dragStartLocation.x, value.location.x), width: geometry.size.width)
                        let endTime = xToTime(max(dragStartLocation.x, value.location.x), width: geometry.size.width)
                        
                        if abs(endTime - startTime) > 0.1 {
                            selection = startTime...endTime
                        } else {
                            // Single tap - seek
                            onSeek(startTime)
                        }
                    }
            )
        }
    }
    
    private func downsampledData(for width: CGFloat) -> [Float] {
        let targetSamples = Int(width * zoomLevel)
        let skipFactor = max(1, waveformData.count / targetSamples)
        
        return stride(from: 0, to: waveformData.count, by: skipFactor).map { index in
            waveformData[index]
        }
    }
    
    private func timeToX(_ time: TimeInterval, width: CGFloat) -> CGFloat {
        CGFloat(time / duration) * width
    }
    
    private func xToTime(_ x: CGFloat, width: CGFloat) -> TimeInterval {
        Double(x / width) * duration
    }
}

// MARK: - Waveform Shape
struct WaveformShape: Shape {
    let samples: [Float]
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        guard !samples.isEmpty else { return path }
        
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        let sampleWidth = width / CGFloat(samples.count)
        
        for (index, sample) in samples.enumerated() {
            let x = CGFloat(index) * sampleWidth
            let sampleHeight = CGFloat(abs(sample)) * (height / 2)
            
            // Draw both positive and negative sides
            path.addRect(CGRect(
                x: x,
                y: midY - sampleHeight,
                width: max(1, sampleWidth - 1),
                height: sampleHeight * 2
            ))
        }
        
        return path
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    let duration: TimeInterval
    let zoomLevel: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Background
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                
                // Time markers
                ForEach(timeMarkers(for: geometry.size.width), id: \.self) { time in
                    let x = CGFloat(time / duration) * geometry.size.width
                    
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.white.opacity(0.5))
                            .frame(width: 1, height: 8)
                        
                        Text(formatTime(time))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .position(x: x, y: 15)
                }
            }
        }
    }
    
    private func timeMarkers(for width: CGFloat) -> [TimeInterval] {
        let markerInterval: TimeInterval = duration / (10 * zoomLevel)
        let markerCount = Int(duration / markerInterval)
        
        return (0...markerCount).map { index in
            TimeInterval(index) * markerInterval
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = Int(time)
        let milliseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d", seconds, milliseconds)
    }
}

// MARK: - Save Options View
struct SaveOptionsView: View {
    @ObservedObject var editorManager: SampleEditorManager
    let onSave: (SaveOption) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedOption: SaveOption = .saveAsNew
    @State private var newFileName: String = ""
    @State private var selectedFormat: AudioFormat = .wav
    @State private var selectedQuality: AudioQualityOption = .high
    @State private var addToPack = false
    @State private var selectedPack: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Save options
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SAVE OPTIONS")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundColor(.white)
                        
                        ForEach(SaveOption.allCases, id: \.self) { option in
                            SaveOptionRow(
                                option: option,
                                isSelected: selectedOption == option,
                                onTap: { selectedOption = option }
                            )
                        }
                    }
                    
                    // File name input
                    if selectedOption != .overwrite {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FILE NAME")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                            
                            TextField("Enter file name", text: $newFileName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                    }
                    
                    // Format selection
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("FORMAT")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                ForEach(AudioFormat.allCases, id: \.self) { format in
                                    FormatButton(
                                        format: format,
                                        isSelected: selectedFormat == format,
                                        onTap: { selectedFormat = format }
                                    )
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("QUALITY")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                            
                            HStack(spacing: 8) {
                                ForEach(AudioQualityOption.allCases, id: \.self) { quality in
                                    QualityButton(
                                        quality: quality,
                                        isSelected: selectedQuality == quality,
                                        onTap: { selectedQuality = quality }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Pack option
                    if selectedOption == .addToPack || selectedOption == .createNewPack {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle(isOn: $addToPack) {
                                Text("Add to sample pack")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: Color.green))
                            
                            if addToPack {
                                // Pack selector would go here
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("CANCEL")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        
                        Button(action: {
                            onSave(selectedOption)
                        }) {
                            Text("SAVE")
                                .font(.system(size: 16, weight: .heavy))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                        }
                        .disabled(selectedOption != .overwrite && newFileName.isEmpty)
                    }
                }
                .padding(24)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Save Option Enum
enum SaveOption: String, CaseIterable {
    case overwrite = "Overwrite Original"
    case saveAsNew = "Save as New Sample"
    case addToPack = "Add to Current Pack"
    case createNewPack = "Create New Pack"
    
    var icon: String {
        switch self {
        case .overwrite: return "arrow.triangle.2.circlepath"
        case .saveAsNew: return "doc.badge.plus"
        case .addToPack: return "folder.badge.plus"
        case .createNewPack: return "folder.badge.star"
        }
    }
}

// Extended save configuration
struct SaveConfiguration {
    var option: SaveOption
    var fileName: String?
    var format: AudioFormat?
    var quality: AudioQuality?
}

// MARK: - Audio Format & Quality Enums
enum AudioFormat: String, CaseIterable {
    case wav = "WAV"
    case mp3 = "MP3"
    case aiff = "AIFF"
    case m4a = "M4A"
}

enum AudioQualityOption: String, CaseIterable {
    case low = "16-bit"
    case high = "24-bit"
    case ultra = "32-bit"
}

// MARK: - Supporting Views for Save Options
struct SaveOptionRow: View {
    let option: SaveOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .green : .white.opacity(0.5))
                
                Image(systemName: option.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text(option.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FormatButton: View {
    let format: AudioFormat
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(format.rawValue)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct QualityButton: View {
    let quality: AudioQualityOption
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(quality.rawValue)
                .font(.system(size: 12, weight: .heavy))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.white : Color.white.opacity(0.2))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SampleEditorView(
        taskStore: TaskStore(),
        currentTab: .constant("editor"),
        sample: Sample(
            id: UUID(),
            originalPath: "/samples/kick_01.wav",
            fileName: "kick_01.wav",
            fileSize: 1024000,
            dateAdded: Date()
        )
    )
}