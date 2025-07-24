//
//  DrumMachineEngine.swift
//  Jamminverz
//
//  Core drum machine audio engine with sample playback and sequencing
//

import Foundation
import AVFoundation
import SwiftUI

// MARK: - Drum Machine Engine
@MainActor
class DrumMachineEngine: ObservableObject {
    // Audio engine
    private var audioEngine: AVAudioEngine?
    private var mixer: AVAudioMixerNode?
    private var reverb: AVAudioUnitReverb?
    private var delay: AVAudioUnitDelay?
    
    // Sequencer
    private var sequencerTimer: Timer?
    @Published var currentStep = 0
    @Published var isPlaying = false
    @Published var isRecording = false
    @Published var tempo: Double = 120 {
        didSet { updateSequencerTiming() }
    }
    
    // Patterns
    @Published var currentPattern = 0
    @Published var patterns: [Pattern] = [
        Pattern(), Pattern(), Pattern(), Pattern()
    ]
    
    // Pads
    @Published var pads: [DrumPad] = []
    @Published var padStates: [Bool] = Array(repeating: false, count: 16)
    
    // Audio players
    private var players: [AVAudioPlayerNode] = []
    private var audioBuffers: [AVAudioPCMBuffer?] = Array(repeating: nil, count: 16)
    
    // Effects
    @Published var masterVolume: Float = 0.8
    @Published var reverbMix: Float = 0
    @Published var delayMix: Float = 0
    
    init() {
        setupPads()
        setupAudioEngine()
    }
    
    // MARK: - Setup
    private func setupPads() {
        let padConfigs: [(label: String, color: Color)] = [
            ("KICK", Color.red),
            ("SNARE", Color.orange),
            ("HAT", Color.yellow),
            ("OPEN", Color.green),
            ("CLAP", Color.blue),
            ("PERC 1", Color.purple),
            ("PERC 2", Color.pink),
            ("CRASH", Color.cyan),
            ("808", Color.red.opacity(0.8)),
            ("RIM", Color.orange.opacity(0.8)),
            ("SHAKER", Color.yellow.opacity(0.8)),
            ("RIDE", Color.green.opacity(0.8)),
            ("FX 1", Color.blue.opacity(0.8)),
            ("FX 2", Color.purple.opacity(0.8)),
            ("VOX", Color.pink.opacity(0.8)),
            ("FILL", Color.gray)
        ]
        
        pads = padConfigs.enumerated().map { index, config in
            DrumPad(
                id: index,
                label: config.label,
                color: config.color,
                volume: 0.8,
                pan: 0.0,
                pitch: 0.0
            )
        }
    }
    
    func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }
        
        mixer = engine.mainMixerNode
        
        // Setup reverb
        reverb = AVAudioUnitReverb()
        if let reverb = reverb {
            reverb.loadFactoryPreset(.largeHall)
            reverb.wetDryMix = 0
            engine.attach(reverb)
        }
        
        // Setup delay
        delay = AVAudioUnitDelay()
        if let delay = delay {
            delay.delayTime = 0.5
            delay.feedback = 50
            delay.wetDryMix = 0
            engine.attach(delay)
        }
        
        // Setup players
        for _ in 0..<16 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            players.append(player)
            
            // Connect player to mixer
            engine.connect(player, to: mixer!, format: nil)
        }
        
        // Connect effects
        if let mixer = mixer, let reverb = reverb, let delay = delay {
            engine.connect(mixer, to: reverb, format: nil)
            engine.connect(reverb, to: delay, format: nil)
            engine.connect(delay, to: engine.outputNode, format: nil)
        }
        
        // Start engine
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Sample Loading
    func loadSampleToPad(_ sample: Sample, padIndex: Int) {
        guard padIndex < pads.count else { return }
        
        pads[padIndex].sample = sample
        
        // Load audio buffer
        _Concurrency.Task {
            do {
                let url = URL(fileURLWithPath: sample.originalPath)
                let audioFile = try AVAudioFile(forReading: url)
                let format = audioFile.processingFormat
                let frameCount = AVAudioFrameCount(audioFile.length)
                
                let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
                guard let buffer = buffer else { return }
                
                try audioFile.read(into: buffer)
                audioBuffers[padIndex] = buffer
                
                // Auto-detect pad type from sample
                if let analysis = sample.analyzedData {
                    updatePadFromAnalysis(padIndex: padIndex, analysis: analysis)
                }
                
            } catch {
                print("Failed to load sample: \(error)")
            }
        }
    }
    
    private func updatePadFromAnalysis(padIndex: Int, analysis: SampleAnalysis) {
        // Update pad label based on instrument type
        switch analysis.instrument {
        case .kick:
            pads[padIndex].label = "KICK"
        case .snare:
            pads[padIndex].label = "SNARE"
        case .percussion:
            pads[padIndex].label = "PERC"
        case .bass:
            pads[padIndex].label = "BASS"
        case .vocal:
            pads[padIndex].label = "VOX"
        default:
            break
        }
        
        // Set suggested pitch adjustment if needed
        if analysis.key != nil {
            // Could implement key matching logic here
        }
    }
    
    // MARK: - Playback Control
    func togglePlayback() {
        if isPlaying {
            stop()
        } else {
            play()
        }
    }
    
    func play() {
        guard !isPlaying else { return }
        
        isPlaying = true
        currentStep = 0
        startSequencer()
    }
    
    func stop() {
        isPlaying = false
        isRecording = false
        currentStep = 0
        sequencerTimer?.invalidate()
        
        // Stop all playing sounds
        for player in players {
            player.stop()
        }
    }
    
    func toggleRecording() {
        isRecording.toggle()
        if isRecording && !isPlaying {
            play()
        }
    }
    
    // MARK: - Sequencer
    private func startSequencer() {
        let interval = 60.0 / tempo / 4.0 // 16th notes
        
        sequencerTimer?.invalidate()
        sequencerTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            _Concurrency.Task { @MainActor in
                self.processStep()
                self.currentStep = (self.currentStep + 1) % 16
            }
        }
    }
    
    private func updateSequencerTiming() {
        if isPlaying {
            startSequencer()
        }
    }
    
    private func processStep() {
        let pattern = patterns[currentPattern]
        
        for padIndex in 0..<16 {
            if pattern.steps[padIndex][currentStep] {
                triggerPad(padIndex)
            }
        }
    }
    
    // MARK: - Pad Triggering
    func triggerPad(_ index: Int) {
        guard index < pads.count,
              let buffer = audioBuffers[index],
              let player = players[safe: index] else { return }
        
        // Visual feedback
        padStates[index] = true
        _Concurrency.Task {
            try? await _Concurrency.Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                self.padStates[index] = false
            }
        }
        
        // Play sound
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: []) {
            // Completion handler
        }
        
        // Apply pad settings
        player.volume = pads[index].volume
        player.pan = pads[index].pan
        player.rate = pow(2.0, pads[index].pitch / 12.0) // Pitch in semitones
        
        player.play()
        
        // Record if in recording mode
        if isRecording {
            patterns[currentPattern].steps[index][currentStep] = true
        }
    }
    
    // MARK: - Pattern Management
    func toggleStep(padIndex: Int, step: Int) {
        guard padIndex < 16, step < 16 else { return }
        patterns[currentPattern].steps[padIndex][step].toggle()
    }
    
    func clearPattern() {
        patterns[currentPattern] = Pattern()
    }
    
    func copyPattern(from: Int, to: Int) {
        guard from < patterns.count, to < patterns.count else { return }
        patterns[to] = patterns[from]
    }
    
    // MARK: - Mixer Controls
    func setVolume(for padIndex: Int, volume: Float) {
        guard padIndex < pads.count else { return }
        pads[padIndex].volume = volume
    }
    
    func setPan(for padIndex: Int, pan: Float) {
        guard padIndex < pads.count else { return }
        pads[padIndex].pan = pan
    }
    
    func setPitch(for padIndex: Int, pitch: Float) {
        guard padIndex < pads.count else { return }
        pads[padIndex].pitch = pitch
    }
    
    func setMute(for padIndex: Int, muted: Bool) {
        guard padIndex < pads.count else { return }
        pads[padIndex].isMuted = muted
    }
    
    func setSolo(for padIndex: Int, solo: Bool) {
        guard padIndex < pads.count else { return }
        pads[padIndex].isSolo = solo
    }
    
    // MARK: - Effects
    func setReverbMix(_ value: Float) {
        reverbMix = value
        reverb?.wetDryMix = value * 100
    }
    
    func setDelayMix(_ value: Float) {
        delayMix = value
        delay?.wetDryMix = value * 100
    }
    
    // MARK: - Export
    func exportPattern() {
        // TODO: Implement pattern export to audio file
    }
}

// MARK: - Data Models
struct DrumPad: Identifiable {
    let id: Int
    var label: String
    var color: Color
    var sample: Sample?
    var volume: Float = 0.8
    var pan: Float = 0.0
    var pitch: Float = 0.0
    var isMuted: Bool = false
    var isSolo: Bool = false
}

struct Pattern: Identifiable, Codable {
    var id = UUID()
    var name: String = "Pattern"
    var steps: [[Bool]] = Array(repeating: Array(repeating: false, count: 16), count: 16)
    var length: Int = 16
}

// MARK: - Extensions
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}