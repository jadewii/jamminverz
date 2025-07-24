//
//  CreateView.swift
//  Jamminverz
//
//  Drum machine and beat creation with integrated sample library
//

import SwiftUI
import AVFoundation

// MARK: - Create View (Drum Machine)
struct CreateView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var drumMachine = DrumMachineEngine()
    @StateObject private var sampleManager = SampleOrganizerManager.shared
    
    @State private var showSampleBrowser = false
    @State private var selectedPadIndex: Int?
    @State private var isRecording = false
    @State private var currentPattern = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Transport controls
                        transportSection
                        
                        // Drum pads
                        drumPadSection
                        
                        // Pattern sequencer
                        sequencerSection
                        
                        // Mixer section
                        mixerSection
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showSampleBrowser) {
            SampleBrowserView(
                selectedPadIndex: $selectedPadIndex,
                drumMachine: drumMachine,
                onSampleSelected: { sample in
                    if let padIndex = selectedPadIndex {
                        drumMachine.loadSampleToPad(sample, padIndex: padIndex)
                    }
                    showSampleBrowser = false
                }
            )
        }
        .onAppear {
            drumMachine.setupAudioEngine()
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: {
                currentTab = "organize"
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
                Text("CREATE")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundColor(.white)
                
                Text("Beat Machine")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Button(action: {
                // Export/save functionality
            }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Transport Section
    private var transportSection: some View {
        VStack(spacing: 16) {
            // BPM and time signature
            HStack(spacing: 24) {
                // BPM control
                VStack(alignment: .leading, spacing: 4) {
                    Text("BPM")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack {
                        Button(action: {
                            drumMachine.tempo = max(60, drumMachine.tempo - 1)
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                        
                        Text("\(Int(drumMachine.tempo))")
                            .font(.system(size: 24, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 60)
                        
                        Button(action: {
                            drumMachine.tempo = min(200, drumMachine.tempo + 1)
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                }
                
                Spacer()
                
                // Pattern selector
                VStack(alignment: .leading, spacing: 4) {
                    Text("PATTERN")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 8) {
                        ForEach(0..<4) { index in
                            Button(action: {
                                currentPattern = index
                                drumMachine.currentPattern = index
                            }) {
                                Text("\(index + 1)")
                                    .font(.system(size: 16, weight: .heavy))
                                    .foregroundColor(currentPattern == index ? .black : .white)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        currentPattern == index ?
                                        Color.white : Color.white.opacity(0.2)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
            }
            
            // Play controls
            HStack(spacing: 16) {
                Button(action: {
                    drumMachine.stop()
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    drumMachine.togglePlayback()
                }) {
                    Image(systemName: drumMachine.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 80, height: 80)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                
                Button(action: {
                    isRecording.toggle()
                    drumMachine.toggleRecording()
                }) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isRecording ? .white : .red)
                        .frame(width: 56, height: 56)
                        .background(isRecording ? Color.red : Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Drum Pad Section
    private var drumPadSection: some View {
        VStack(spacing: 16) {
            Text("DRUM PADS")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(0..<16) { index in
                    DrumPadView(
                        index: index,
                        drumMachine: drumMachine,
                        onTap: {
                            drumMachine.triggerPad(index)
                        },
                        onLongPress: {
                            selectedPadIndex = index
                            showSampleBrowser = true
                        }
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Sequencer Section
    private var sequencerSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("SEQUENCER")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("16 STEPS")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 8) {
                    ForEach(0..<16) { padIndex in
                        HStack(spacing: 4) {
                            // Pad label
                            Text(drumMachine.pads[padIndex].label)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 40)
                            
                            // Step buttons
                            ForEach(0..<16) { step in
                                SequencerStepButton(
                                    padIndex: padIndex,
                                    step: step,
                                    drumMachine: drumMachine
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
    
    // MARK: - Mixer Section
    private var mixerSection: some View {
        VStack(spacing: 16) {
            Text("MIXER")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<16) { index in
                        DrumChannelStrip(
                            padIndex: index,
                            drumMachine: drumMachine
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Drum Pad View
struct DrumPadView: View {
    let index: Int
    @ObservedObject var drumMachine: DrumMachineEngine
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    private var pad: DrumPad {
        drumMachine.pads[index]
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                if pad.sample != nil {
                    Image(systemName: "waveform")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Text(pad.label)
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.white)
            }
            .frame(height: 80)
            .frame(maxWidth: .infinity)
            .background(
                pad.sample != nil ?
                pad.color.opacity(drumMachine.padStates[index] ? 1.0 : 0.3) :
                Color.white.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(drumMachine.padStates[index] ? Color.white : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            onLongPress()
        }
    }
}

// MARK: - Sequencer Step Button
struct SequencerStepButton: View {
    let padIndex: Int
    let step: Int
    @ObservedObject var drumMachine: DrumMachineEngine
    
    private var isActive: Bool {
        drumMachine.patterns[drumMachine.currentPattern].steps[padIndex][step]
    }
    
    private var isCurrentStep: Bool {
        drumMachine.currentStep == step && drumMachine.isPlaying
    }
    
    var body: some View {
        Button(action: {
            drumMachine.toggleStep(padIndex: padIndex, step: step)
        }) {
            Rectangle()
                .fill(isActive ? drumMachine.pads[padIndex].color : Color.white.opacity(0.1))
                .frame(width: 24, height: 24)
                .overlay(
                    Rectangle()
                        .stroke(isCurrentStep ? Color.white : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Drum Channel Strip
struct DrumChannelStrip: View {
    let padIndex: Int
    @ObservedObject var drumMachine: DrumMachineEngine
    
    @State private var volume: Double = 0.8
    @State private var pan: Double = 0.5
    @State private var isMuted = false
    @State private var isSolo = false
    
    var body: some View {
        VStack(spacing: 8) {
            Text(drumMachine.pads[padIndex].label)
                .font(.system(size: 10, weight: .heavy))
                .foregroundColor(.white)
            
            // Volume slider
            VStack(spacing: 4) {
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 40, height: 120)
                    
                    Rectangle()
                        .fill(drumMachine.pads[padIndex].color)
                        .frame(width: 40, height: 120 * volume)
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newVolume = 1.0 - (value.location.y / 120)
                            volume = min(1.0, max(0.0, newVolume))
                            drumMachine.setVolume(for: padIndex, volume: Float(volume))
                        }
                )
                
                Text("\(Int(volume * 100))")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Pan knob
            CircularSlider(
                value: $pan,
                color: drumMachine.pads[padIndex].color
            )
            .frame(width: 32, height: 32)
            .onChange(of: pan) { _, newValue in
                drumMachine.setPan(for: padIndex, pan: Float((newValue - 0.5) * 2))
            }
            
            // Mute/Solo buttons
            HStack(spacing: 4) {
                Button(action: {
                    isMuted.toggle()
                    drumMachine.setMute(for: padIndex, muted: isMuted)
                }) {
                    Text("M")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(isMuted ? .black : .white)
                        .frame(width: 20, height: 20)
                        .background(isMuted ? Color.yellow : Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    isSolo.toggle()
                    drumMachine.setSolo(for: padIndex, solo: isSolo)
                }) {
                    Text("S")
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundColor(isSolo ? .black : .white)
                        .frame(width: 20, height: 20)
                        .background(isSolo ? Color.green : Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Circular Slider
struct CircularSlider: View {
    @Binding var value: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                
                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color, lineWidth: 3)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 8, height: 8)
                    .offset(y: -geometry.size.height / 2 + 4)
                    .rotationEffect(.degrees(value * 360 - 90))
            }
        }
    }
}

// MARK: - Sample Browser View
struct SampleBrowserView: View {
    @Binding var selectedPadIndex: Int?
    @ObservedObject var drumMachine: DrumMachineEngine
    let onSampleSelected: (Sample) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    @StateObject private var sampleManager = SampleOrganizerManager.shared
    @State private var selectedCategory: InstrumentType = .kick
    @State private var searchText = ""
    
    var filteredSamples: [Sample] {
        sampleManager.samples.filter { sample in
            guard let analysis = sample.analyzedData else { return false }
            
            let matchesCategory = analysis.instrument == selectedCategory
            let matchesSearch = searchText.isEmpty || 
                sample.displayName.localizedCaseInsensitiveContains(searchText)
            
            return matchesCategory && matchesSearch
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(InstrumentType.allCases, id: \.self) { type in
                                CategoryButton(
                                    type: type,
                                    isSelected: selectedCategory == type,
                                    onTap: { selectedCategory = type }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 16)
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.5))
                        
                        TextField("Search samples...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    
                    // Sample list
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(filteredSamples) { sample in
                                SampleTileView(
                                    sample: sample,
                                    onTap: {
                                        onSampleSelected(sample)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("SELECT SAMPLE")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(.white)
            )
        }
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let type: InstrumentType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(type.emoji)
                    .font(.system(size: 24))
                
                Text(type.rawValue.uppercased())
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(isSelected ? .black : .white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Sample Tile View
struct SampleTileView: View {
    let sample: Sample
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            VStack(spacing: 8) {
                // Waveform visualization
                HStack(spacing: 1) {
                    ForEach(0..<15, id: \.self) { _ in
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
                        .lineLimit(1)
                    
                    if let analysis = sample.analyzedData {
                        HStack(spacing: 4) {
                            if let bpm = analysis.bpm {
                                Text("\(bpm) BPM")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            if let key = analysis.key {
                                Text(key)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(sample.analyzedData?.mood.color.opacity(0.2) ?? Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    CreateView(
        taskStore: TaskStore(),
        currentTab: .constant("create")
    )
}