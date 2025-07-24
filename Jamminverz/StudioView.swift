//
//  StudioView.swift
//  Jamminverz
//
//  Loop-based beat builder with drag & drop from packs
//

import SwiftUI
import AVFoundation

struct StudioView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var studioEngine = StudioEngine()
    @State private var isPlaying = false
    @State private var currentStep = 0
    @State private var showSampleBrowser = false
    @State private var selectedTrackIndex: Int?
    @State private var projectName = "Untitled Project"
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Transport Controls
                transportControls
                
                // Pattern Grid
                ScrollView {
                    VStack(spacing: 16) {
                        patternGrid
                        
                        // Add Track Button
                        addTrackButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showSampleBrowser) {
            if let trackIndex = selectedTrackIndex {
                SampleBrowserSheet(
                    onSampleSelected: { sample in
                        studioEngine.loadSampleToTrack(sample, trackIndex: trackIndex)
                        showSampleBrowser = false
                    }
                )
            }
        }
        .onAppear {
            studioEngine.setup()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                TextField("Project Name", text: $projectName)
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundColor(.white)
                    .textFieldStyle(PlainTextFieldStyle())
                
                Text("Drag samples from packs to create beats")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Button(action: saveProject) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 24))
                    .foregroundColor(.teal)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var transportControls: some View {
        VStack(spacing: 16) {
            // BPM Control
            HStack {
                Text("BPM")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.gray)
                
                HStack(spacing: 0) {
                    Button(action: { studioEngine.bpm = max(60, studioEngine.bpm - 1) }) {
                        Image(systemName: "minus")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                    }
                    
                    Text("\(studioEngine.bpm)")
                        .font(.system(size: 20, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 60)
                    
                    Button(action: { studioEngine.bpm = min(200, studioEngine.bpm + 1) }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.1))
                    }
                }
                
                Spacer()
                
                // Pattern Length
                Text("BARS")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.gray)
                
                Picker("", selection: $studioEngine.patternLength) {
                    Text("1").tag(1)
                    Text("2").tag(2)
                    Text("4").tag(4)
                    Text("8").tag(8)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 150)
            }
            
            // Play Controls
            HStack(spacing: 20) {
                Button(action: {
                    studioEngine.stop()
                    isPlaying = false
                }) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Button(action: {
                    if isPlaying {
                        studioEngine.pause()
                    } else {
                        studioEngine.play()
                    }
                    isPlaying.toggle()
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                        .frame(width: 80, height: 80)
                        .background(Color.teal)
                        .clipShape(Circle())
                }
                
                Button(action: {
                    studioEngine.toggleRecording()
                }) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 24))
                        .foregroundColor(studioEngine.isRecording ? .white : .red)
                        .frame(width: 60, height: 60)
                        .background(studioEngine.isRecording ? Color.red : Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }
    
    private var patternGrid: some View {
        VStack(spacing: 12) {
            // Step numbers
            HStack(spacing: 2) {
                Text("TRACK")
                    .font(.system(size: 10, weight: .heavy))
                    .foregroundColor(.gray)
                    .frame(width: 100)
                
                ForEach(0..<16, id: \.self) { step in
                    Text("\(step + 1)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 30)
                }
            }
            
            // Tracks
            ForEach(Array(studioEngine.tracks.enumerated()), id: \.element.id) { index, track in
                TrackRow(
                    track: track,
                    trackIndex: index,
                    currentStep: $currentStep,
                    onSampleDrop: { studioEngine.loadSampleToTrack($0, trackIndex: index) },
                    onStepToggle: { step in studioEngine.toggleStep(trackIndex: index, step: step) },
                    onDelete: { studioEngine.removeTrack(at: index) },
                    onSelectSample: {
                        selectedTrackIndex = index
                        showSampleBrowser = true
                    }
                )
            }
        }
    }
    
    private var addTrackButton: some View {
        Button(action: {
            studioEngine.addTrack()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("ADD TRACK")
                    .font(.system(size: 14, weight: .heavy))
            }
            .foregroundColor(.teal)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.teal.opacity(0.2))
            .cornerRadius(12)
        }
    }
    
    private func saveProject() {
        // Save project logic
        print("Saving project: \(projectName)")
    }
}

// MARK: - Track Row
struct TrackRow: View {
    let track: StudioTrack
    let trackIndex: Int
    @Binding var currentStep: Int
    let onSampleDrop: (SampleReference) -> Void
    let onStepToggle: (Int) -> Void
    let onDelete: () -> Void
    let onSelectSample: () -> Void
    
    @State private var isDraggingOver = false
    
    var body: some View {
        HStack(spacing: 2) {
            // Track Info
            HStack(spacing: 8) {
                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.red.opacity(0.7))
                }
                
                // Sample selector
                Button(action: onSelectSample) {
                    Text(track.sampleName ?? "Empty")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(track.sample != nil ? .white : .gray)
                        .lineLimit(1)
                }
            }
            .frame(width: 100)
            .padding(.horizontal, 4)
            .frame(height: 40)
            .background(Color.white.opacity(isDraggingOver ? 0.2 : 0.05))
            .cornerRadius(8)
            .onDrop(of: ["public.text"], isTargeted: $isDraggingOver) { providers in
                // Handle sample drop
                return true
            }
            
            // Step buttons
            ForEach(0..<16, id: \.self) { step in
                StepButton(
                    isActive: track.pattern[step],
                    isCurrent: currentStep == step,
                    color: track.color,
                    action: { onStepToggle(step) }
                )
            }
        }
    }
}

// MARK: - Step Button
struct StepButton: View {
    let isActive: Bool
    let isCurrent: Bool
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Rectangle()
                .fill(isActive ? color : Color.white.opacity(0.1))
                .frame(width: 30, height: 40)
                .overlay(
                    Rectangle()
                        .stroke(isCurrent ? Color.white : Color.clear, lineWidth: 2)
                )
                .scaleEffect(isCurrent ? 1.1 : 1.0)
        }
        .animation(.easeInOut(duration: 0.1), value: isCurrent)
    }
}

// MARK: - Sample Browser Sheet
struct SampleBrowserSheet: View {
    let onSampleSelected: (SampleReference) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Text("Select a sample from your packs")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding()
                    
                    // Sample list would go here
                    Spacer()
                }
            }
            .navigationTitle("Select Sample")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Studio Engine
class StudioEngine: ObservableObject {
    @Published var tracks: [StudioTrack] = []
    @Published var bpm: Int = 120
    @Published var patternLength: Int = 4
    @Published var isRecording = false
    
    private var audioEngine: AVAudioEngine?
    private var sequencer: Timer?
    
    init() {
        // Initialize with 4 empty tracks
        for _ in 0..<4 {
            addTrack()
        }
    }
    
    func setup() {
        audioEngine = AVAudioEngine()
        // Setup audio engine
    }
    
    func addTrack() {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink]
        let newTrack = StudioTrack(
            name: "Track \(tracks.count + 1)",
            color: colors[tracks.count % colors.count]
        )
        tracks.append(newTrack)
    }
    
    func removeTrack(at index: Int) {
        guard tracks.count > 1 else { return }
        tracks.remove(at: index)
    }
    
    func loadSampleToTrack(_ sample: SampleReference, trackIndex: Int) {
        guard trackIndex < tracks.count else { return }
        tracks[trackIndex].sample = sample
        tracks[trackIndex].sampleName = sample.name
    }
    
    func toggleStep(trackIndex: Int, step: Int) {
        guard trackIndex < tracks.count, step < 16 else { return }
        tracks[trackIndex].pattern[step].toggle()
    }
    
    func play() {
        // Start playback
    }
    
    func pause() {
        // Pause playback
    }
    
    func stop() {
        // Stop playback
    }
    
    func toggleRecording() {
        isRecording.toggle()
    }
}

// MARK: - Models
struct StudioTrack: Identifiable {
    let id = UUID()
    var name: String
    var sample: SampleReference?
    var sampleName: String?
    var pattern: [Bool] = Array(repeating: false, count: 16)
    var volume: Float = 0.8
    var pan: Float = 0.0
    var color: Color
}

struct SampleReference {
    let id: String
    let name: String
    let url: URL
}

#Preview {
    StudioView(
        taskStore: TaskStore(),
        currentTab: .constant("studio")
    )
}