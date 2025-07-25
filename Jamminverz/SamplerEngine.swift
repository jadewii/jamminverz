//
//  SamplerEngine.swift
//  Jamminverz
//
//  Audio engine for MPC-style sampler with recording and effects
//

import Foundation
import AVFoundation
import SwiftUI

// MARK: - Sampler Pad Model
struct SamplerPad: Identifiable {
    let id = UUID()
    let index: Int
    var sampleURL: URL?
    var sampleName: String?
    var hasSample: Bool { sampleURL != nil }
    var volume: Float = 0.8
    var pitch: Float = 1.0
    var audioPlayer: AVAudioPlayer?
}

// MARK: - Pattern Step
struct PatternStep {
    let padIndex: Int
    let velocity: Float
    let timestamp: TimeInterval
}

// MARK: - Pattern
struct SamplerPattern {
    var steps: [PatternStep] = []
    var length: Int = 4 // bars
}

// MARK: - Sampler Engine
@MainActor
class SamplerEngine: ObservableObject {
    // Pads
    @Published var pads: [SamplerPad] = []
    
    // Patterns
    @Published var patterns: [SamplerPattern] = []
    @Published var currentPattern: Int = 0
    @Published var patternLength: Int = 4
    
    // Playback
    @Published var isPlaying = false
    @Published var isRecording = false
    @Published var bpm: Double = 120
    @Published var globalVelocity: Float = 0.8
    
    // Effects
    @Published var activeEffects: Set<String> = []
    @Published var metronomeEnabled = false
    @Published var quantizeEnabled = true
    
    // Audio engine
    private var audioEngine: AVAudioEngine?
    private var mixerNode: AVAudioMixerNode?
    private var playerNodes: [AVAudioPlayerNode] = []
    private var effectNodes: [String: AVAudioUnit] = [:]
    
    // Recording
    private var recordingStartTime: TimeInterval?
    private var recordedSteps: [PatternStep] = []
    
    // Playback timer
    private var playbackTimer: Timer?
    private var currentStep = 0
    private var stepsPerBar = 16
    
    // Metronome
    private var metronomePlayer: AVAudioPlayer?
    
    init() {
        // Initialize 16 pads
        for i in 0..<16 {
            pads.append(SamplerPad(index: i))
        }
        
        // Initialize 4 patterns
        for _ in 0..<4 {
            patterns.append(SamplerPattern())
        }
        
        setupAudioEngine()
        loadMetronomeSound()
    }
    
    // MARK: - Audio Engine Setup
    func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        mixerNode = AVAudioMixerNode()
        
        guard let audioEngine = audioEngine,
              let mixerNode = mixerNode else { return }
        
        audioEngine.attach(mixerNode)
        
        // Create player nodes for each pad
        for _ in 0..<16 {
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            playerNodes.append(playerNode)
            
            // Connect to mixer
            audioEngine.connect(playerNode, to: mixerNode, format: nil)
        }
        
        // Setup effects
        setupEffects()
        
        // Connect mixer to output
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: nil)
        
        // Start engine
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func setupEffects() {
        guard let audioEngine = audioEngine else { return }
        
        // Reverb
        let reverb = AVAudioUnitReverb()
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 0
        audioEngine.attach(reverb)
        effectNodes["Reverb"] = reverb
        
        // Delay
        let delay = AVAudioUnitDelay()
        delay.wetDryMix = 0
        delay.delayTime = 0.5
        delay.feedback = 30
        audioEngine.attach(delay)
        effectNodes["Delay"] = delay
        
        // Distortion
        let distortion = AVAudioUnitDistortion()
        distortion.loadFactoryPreset(.multiDecimated1)
        distortion.wetDryMix = 0
        audioEngine.attach(distortion)
        effectNodes["Distortion"] = distortion
    }
    
    // MARK: - Sample Loading
    func loadSample(_ url: URL, toPad padIndex: Int) {
        guard padIndex < pads.count else { return }
        
        pads[padIndex].sampleURL = url
        pads[padIndex].sampleName = url.lastPathComponent
            .replacingOccurrences(of: ".wav", with: "")
            .replacingOccurrences(of: ".mp3", with: "")
            .replacingOccurrences(of: ".aiff", with: "")
        
        // Preload audio player for quick playback
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            pads[padIndex].audioPlayer = player
        } catch {
            print("Failed to load sample: \(error)")
        }
    }
    
    func clearPad(_ padIndex: Int) {
        guard padIndex < pads.count else { return }
        
        pads[padIndex].sampleURL = nil
        pads[padIndex].sampleName = nil
        pads[padIndex].audioPlayer = nil
        
        // Stop any playing audio
        if padIndex < playerNodes.count {
            playerNodes[padIndex].stop()
        }
    }
    
    // MARK: - Pad Triggering
    func triggerPad(_ padIndex: Int, velocity: Float) {
        guard padIndex < pads.count,
              let sampleURL = pads[padIndex].sampleURL,
              audioEngine != nil,
              padIndex < playerNodes.count else { return }
        
        let playerNode = playerNodes[padIndex]
        
        do {
            let audioFile = try AVAudioFile(forReading: sampleURL)
            
            // Stop current playback
            playerNode.stop()
            
            // Schedule new playback
            playerNode.scheduleFile(audioFile, at: nil) {
                // Playback completed
            }
            
            // Apply volume and pitch
            playerNode.volume = pads[padIndex].volume * velocity
            
            if pads[padIndex].pitch != 1.0 {
                playerNode.rate = pads[padIndex].pitch
            }
            
            // Play
            playerNode.play()
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
        } catch {
            print("Failed to play sample: \(error)")
        }
    }
    
    // MARK: - Pattern Recording
    func startRecording() {
        isRecording = true
        recordingStartTime = Date().timeIntervalSince1970
        recordedSteps.removeAll()
        
        // Start playback if not already playing
        if !isPlaying {
            togglePlayback()
        }
    }
    
    func stopRecording() {
        isRecording = false
        
        // Add recorded steps to current pattern
        if !recordedSteps.isEmpty {
            patterns[currentPattern].steps.append(contentsOf: recordedSteps)
            
            // Quantize if enabled
            if quantizeEnabled {
                quantizePattern()
            }
        }
        
        recordedSteps.removeAll()
    }
    
    func recordPadHit(_ padIndex: Int) {
        guard isRecording,
              let startTime = recordingStartTime else { return }
        
        let currentTime = Date().timeIntervalSince1970
        let timestamp = currentTime - startTime
        
        let step = PatternStep(
            padIndex: padIndex,
            velocity: globalVelocity,
            timestamp: timestamp
        )
        
        recordedSteps.append(step)
    }
    
    // MARK: - Pattern Playback
    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            startPlayback()
        }
    }
    
    private func startPlayback() {
        isPlaying = true
        currentStep = 0
        
        let stepDuration = 60.0 / bpm / 4.0 // 16th notes
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { _ in
            DispatchQueue.main.async {
                self.playStep()
            }
        }
    }
    
    private func stopPlayback() {
        isPlaying = false
        playbackTimer?.invalidate()
        playbackTimer = nil
    }
    
    func stop() {
        stopPlayback()
        stopRecording()
        currentStep = 0
    }
    
    private func playStep() {
        let pattern = patterns[currentPattern]
        let patternDuration = Double(pattern.length) * 4.0 * 60.0 / bpm
        let currentTime = Double(currentStep) * 60.0 / bpm / 4.0
        
        // Play any steps at this time
        for step in pattern.steps {
            let stepTime = step.timestamp.truncatingRemainder(dividingBy: patternDuration)
            let timeDifference = abs(stepTime - currentTime)
            
            if timeDifference < 0.01 { // Within 10ms
                triggerPad(step.padIndex, velocity: step.velocity)
            }
        }
        
        // Play metronome
        if metronomeEnabled && currentStep % 4 == 0 {
            playMetronome()
        }
        
        // Advance step
        currentStep += 1
        if currentStep >= pattern.length * stepsPerBar {
            currentStep = 0
        }
    }
    
    // MARK: - Pattern Management
    func selectPattern(_ index: Int) {
        guard index < patterns.count else { return }
        currentPattern = index
    }
    
    func clearCurrentPattern() {
        patterns[currentPattern].steps.removeAll()
    }
    
    private func quantizePattern() {
        let stepDuration = 60.0 / bpm / 4.0
        
        for i in 0..<patterns[currentPattern].steps.count {
            let step = patterns[currentPattern].steps[i]
            let quantizedTime = round(step.timestamp / stepDuration) * stepDuration
            patterns[currentPattern].steps[i] = PatternStep(
                padIndex: step.padIndex,
                velocity: step.velocity,
                timestamp: quantizedTime
            )
        }
    }
    
    // MARK: - Effects
    func toggleEffect(_ effectName: String) {
        guard let effect = effectNodes[effectName] else { return }
        
        if activeEffects.contains(effectName) {
            activeEffects.remove(effectName)
            // Set wet/dry mix to 0 to bypass
            switch effectName {
            case "Reverb":
                (effect as? AVAudioUnitReverb)?.wetDryMix = 0
            case "Delay":
                (effect as? AVAudioUnitDelay)?.wetDryMix = 0
            case "Distortion":
                (effect as? AVAudioUnitDistortion)?.wetDryMix = 0
            default:
                break
            }
        } else {
            activeEffects.insert(effectName)
            // Apply wet/dry mix
            switch effectName {
            case "Reverb":
                (effect as? AVAudioUnitReverb)?.wetDryMix = 30
            case "Delay":
                (effect as? AVAudioUnitDelay)?.wetDryMix = 25
            case "Distortion":
                (effect as? AVAudioUnitDistortion)?.wetDryMix = 50
            default:
                break
            }
        }
    }
    
    // MARK: - Metronome
    func toggleMetronome() {
        metronomeEnabled.toggle()
    }
    
    private func loadMetronomeSound() {
        // Create a simple click sound
        let sampleRate = 44100.0
        let duration = 0.05
        let frequency = 1000.0
        
        var samples: [Float] = []
        for i in 0..<Int(sampleRate * duration) {
            let time = Double(i) / sampleRate
            let sample = Float(sin(2.0 * .pi * frequency * time))
            samples.append(sample * Float(1.0 - time / duration)) // Envelope
        }
        
        // Convert to audio data
        let audioFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = buffer.frameCapacity
        
        for i in 0..<samples.count {
            buffer.floatChannelData![0][i] = samples[i]
        }
        
        // Save to temp file and create player
        do {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("metronome.wav")
            let audioFile = try AVAudioFile(forWriting: tempURL, settings: audioFormat.settings)
            try audioFile.write(from: buffer)
            
            metronomePlayer = try AVAudioPlayer(contentsOf: tempURL)
            metronomePlayer?.prepareToPlay()
        } catch {
            print("Failed to create metronome sound: \(error)")
        }
    }
    
    private func playMetronome() {
        metronomePlayer?.play()
    }
    
    // MARK: - Quantize
    func toggleQuantize() {
        quantizeEnabled.toggle()
    }
    
    // MARK: - Pad Controls
    func setPadVolume(_ padIndex: Int, volume: Float) {
        guard padIndex < pads.count else { return }
        pads[padIndex].volume = volume
    }
    
    func setPadPitch(_ padIndex: Int, pitch: Float) {
        guard padIndex < pads.count else { return }
        pads[padIndex].pitch = pitch
    }
    
    // MARK: - Sequencer Control
    func startSequencer() {
        startPlayback()
    }
    
    func stopSequencer() {
        stopPlayback()
    }
}