//
//  RemixView.swift
//  Jamminverz
//
//  Audio remix interface with effects and visualizer
//

import SwiftUI
import AVFoundation

struct RemixView: View {
    @ObservedObject var taskStore: TaskStore
    @Binding var currentTab: String
    @StateObject private var playerManager = MusicPlayerManager.shared
    @StateObject private var audioProcessor = AudioProcessor.shared
    
    // Effect states
    @State private var pitchValue: Double = 0.0 // -12 to +12 semitones
    @State private var reverbMix: Double = 0.0 // 0 to 100%
    @State private var delayMix: Double = 0.0 // 0 to 100%
    @State private var delayTime: Double = 0.25 // 0.1 to 1.0 seconds
    @State private var distortionAmount: Double = 0.0 // 0 to 100%
    @State private var lowPassFrequency: Double = 20000.0 // 200 to 20000 Hz
    @State private var highPassFrequency: Double = 20.0 // 20 to 2000 Hz
    @State private var echoMix: Double = 0.0 // 0 to 100%
    @State private var chorusMix: Double = 0.0 // 0 to 100%
    @State private var phaserMix: Double = 0.0 // 0 to 100%
    @State private var playbackSpeed: Double = 1.0 // 0.5 to 2.0
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        currentTab = "radio"
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
                    
                    Text("REMIX STUDIO")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Reset button
                    Button(action: resetAllEffects) {
                        Text("RESET")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 30)
                
                // Current song info
                if let currentSong = playerManager.currentSong {
                    HStack {
                        Image(systemName: "music.note")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(formatSongName(currentSong.filename))
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
                }
                
                // Audio Visualizer
                AudioVisualizerView()
                    .frame(height: 120)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 30)
                
                // Effects controls
                ScrollView {
                    VStack(spacing: 30) {
                        // Pitch control
                        EffectSlider(
                            title: "PITCH",
                            value: $pitchValue,
                            range: -12...12,
                            unit: "semitones",
                            color: Color(red: 0.9, green: 0.3, blue: 0.6),
                            onChanged: { value in
                                audioProcessor.setPitch(Float(value))
                            }
                        )
                        
                        // Playback Speed
                        EffectSlider(
                            title: "SPEED",
                            value: $playbackSpeed,
                            range: 0.5...2.0,
                            unit: "x",
                            color: Color(red: 1.0, green: 0.7, blue: 0.3),
                            onChanged: { value in
                                audioProcessor.setPlaybackSpeed(Float(value))
                            }
                        )
                        
                        // Reverb
                        EffectSlider(
                            title: "REVERB",
                            value: $reverbMix,
                            range: 0...100,
                            unit: "%",
                            color: Color(red: 0.4, green: 0.6, blue: 1.0),
                            onChanged: { value in
                                audioProcessor.setReverb(Float(value))
                            }
                        )
                        
                        // Delay
                        VStack(spacing: 16) {
                            EffectSlider(
                                title: "DELAY MIX",
                                value: $delayMix,
                                range: 0...100,
                                unit: "%",
                                color: Color(red: 0.8, green: 0.4, blue: 0.9),
                                onChanged: { value in
                                    audioProcessor.setDelayMix(Float(value))
                                }
                            )
                            
                            EffectSlider(
                                title: "DELAY TIME",
                                value: $delayTime,
                                range: 0.1...1.0,
                                unit: "s",
                                color: Color(red: 0.8, green: 0.4, blue: 0.9).opacity(0.7),
                                onChanged: { value in
                                    audioProcessor.setDelayTime(Float(value))
                                }
                            )
                        }
                        
                        // Distortion
                        EffectSlider(
                            title: "DISTORTION",
                            value: $distortionAmount,
                            range: 0...100,
                            unit: "%",
                            color: Color(red: 1.0, green: 0.4, blue: 0.4),
                            onChanged: { value in
                                audioProcessor.setDistortion(Float(value))
                            }
                        )
                        
                        // Chorus
                        EffectSlider(
                            title: "CHORUS",
                            value: $chorusMix,
                            range: 0...100,
                            unit: "%",
                            color: Color(red: 0.4, green: 0.9, blue: 0.6),
                            onChanged: { value in
                                audioProcessor.setChorus(Float(value))
                            }
                        )
                        
                        // Phaser
                        EffectSlider(
                            title: "PHASER",
                            value: $phaserMix,
                            range: 0...100,
                            unit: "%",
                            color: Color(red: 0.9, green: 0.5, blue: 0.2),
                            onChanged: { value in
                                audioProcessor.setPhaser(Float(value))
                            }
                        )
                        
                        // Filters
                        VStack(spacing: 16) {
                            EffectSlider(
                                title: "LOW PASS",
                                value: $lowPassFrequency,
                                range: 200...20000,
                                unit: "Hz",
                                color: Color(red: 0.6, green: 0.8, blue: 0.4),
                                onChanged: { value in
                                    audioProcessor.setLowPass(Float(value))
                                }
                            )
                            
                            EffectSlider(
                                title: "HIGH PASS",
                                value: $highPassFrequency,
                                range: 20...2000,
                                unit: "Hz",
                                color: Color(red: 0.6, green: 0.8, blue: 0.4).opacity(0.7),
                                onChanged: { value in
                                    audioProcessor.setHighPass(Float(value))
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            audioProcessor.startProcessing()
        }
        .onDisappear {
            audioProcessor.stopProcessing()
        }
    }
    
    private func resetAllEffects() {
        withAnimation(.easeInOut(duration: 0.3)) {
            pitchValue = 0.0
            reverbMix = 0.0
            delayMix = 0.0
            delayTime = 0.25
            distortionAmount = 0.0
            lowPassFrequency = 20000.0
            highPassFrequency = 20.0
            echoMix = 0.0
            chorusMix = 0.0
            phaserMix = 0.0
            playbackSpeed = 1.0
        }
        
        audioProcessor.resetAllEffects()
    }
    
    private func formatSongName(_ filename: String) -> String {
        return filename
            .replacingOccurrences(of: ".mp3", with: "")
            .replacingOccurrences(of: ".m4a", with: "")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }
}

// MARK: - Audio Visualizer
struct AudioVisualizerView: View {
    @StateObject private var audioProcessor = AudioProcessor.shared
    @State private var amplitudes: [CGFloat] = Array(repeating: 0.0, count: 50)
    let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 2) {
                ForEach(0..<amplitudes.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.9, green: 0.3, blue: 0.6),
                                    Color(red: 0.4, green: 0.6, blue: 1.0)
                                ]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(width: (geometry.size.width - CGFloat(amplitudes.count - 1) * 2) / CGFloat(amplitudes.count))
                        .frame(height: max(4, amplitudes[index] * geometry.size.height))
                        .animation(.easeOut(duration: 0.1), value: amplitudes[index])
                }
            }
        }
        .onReceive(timer) { _ in
            updateAmplitudes()
        }
    }
    
    private func updateAmplitudes() {
        // Get audio levels from processor
        let levels = audioProcessor.getAudioLevels()
        
        // Update amplitudes with smooth animation
        for i in 0..<amplitudes.count {
            if i < levels.count {
                amplitudes[i] = CGFloat(levels[i])
            } else {
                // Generate some random movement for visual effect
                amplitudes[i] = CGFloat.random(in: 0.1...0.8)
            }
        }
    }
}

// MARK: - Effect Slider Component
struct EffectSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let color: Color
    let onChanged: (Double) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(String(format: "%.1f", value) + " " + unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 8)
                
                // Filled track
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * 280, height: 8)
                
                // Knob
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .shadow(color: color.opacity(0.5), radius: 4, x: 0, y: 2)
                    .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * 280 - 10)
            }
            .frame(width: 280)
            .gesture(
                DragGesture()
                    .onChanged { dragValue in
                        let progress = min(max(0, dragValue.location.x / 280), 1)
                        let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * Double(progress)
                        value = newValue
                        onChanged(newValue)
                    }
            )
        }
    }
}

#Preview {
    RemixView(taskStore: TaskStore(), currentTab: .constant("remix"))
}