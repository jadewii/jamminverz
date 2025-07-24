//
//  SampleEditorManager.swift
//  Jamminverz
//
//  Audio processing engine for the sample editor
//

import Foundation
import SwiftUI
import AVFoundation
import Accelerate

// MARK: - Sample Editor Manager
@MainActor
class SampleEditorManager: ObservableObject {
    @Published var currentSample: Sample?
    @Published var waveformData: [Float]?
    @Published var editedBuffer: AVAudioPCMBuffer?
    @Published var isLoading = false
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var loopEnabled = false
    @Published var hasChanges = false
    @Published var canUndo = false
    @Published var canRedo = false
    @Published var activeEffects: [ActiveEffect] = []
    @Published var suggestedFileName: String = ""
    
    // Audio engine components
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFile: AVAudioFile?
    private var originalBuffer: AVAudioPCMBuffer?
    private var compareBuffer: AVAudioPCMBuffer?
    
    // Playback timer
    private var playbackTimer: Timer?
    
    // Undo/Redo stacks
    private var undoStack: [EditAction] = []
    private var redoStack: [EditAction] = []
    
    // Effect nodes
    private var effectNodes: [AVAudioNode] = []
    
    init() {
        setupAudioEngine()
    }
    
    deinit {
        playerNode?.stop()
        audioEngine?.stop()
    }
    
    // MARK: - Audio Engine Setup
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let engine = audioEngine, let player = playerNode else { return }
        
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    // MARK: - Sample Loading
    func loadSample(_ sample: Sample) {
        isLoading = true
        currentSample = sample
        suggestedFileName = sample.displayName + "_edited"
        
        _Concurrency.Task { @MainActor in
            do {
                let url = URL(fileURLWithPath: sample.originalPath)
                audioFile = try AVAudioFile(forReading: url)
                
                guard let file = audioFile else { return }
                
                let format = file.processingFormat
                let frameCount = AVAudioFrameCount(file.length)
                
                originalBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
                guard let originalBuffer = originalBuffer else { return }
                
                try file.read(into: originalBuffer)
                
                // Create editable buffer copy
                editedBuffer = copyBuffer(originalBuffer)
                compareBuffer = copyBuffer(originalBuffer)
                
                // Update duration
                duration = Double(frameCount) / format.sampleRate
                
                // Generate waveform
                await self.generateWaveform(from: originalBuffer)
                
                isLoading = false
            } catch {
                print("Error loading sample: \(error)")
                isLoading = false
            }
        }
    }
    
    // MARK: - Waveform Generation
    private func generateWaveform(from buffer: AVAudioPCMBuffer) async {
        guard let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let downsampleFactor = max(1, frameLength / 1000) // Target ~1000 points
        
        var waveform: [Float] = []
        
        for i in stride(from: 0, to: frameLength, by: downsampleFactor) {
            var sum: Float = 0
            let end = min(i + downsampleFactor, frameLength)
            
            for j in i..<end {
                sum += abs(channelData[0][j])
                if buffer.format.channelCount > 1 {
                    sum += abs(channelData[1][j])
                    sum /= 2
                }
            }
            
            waveform.append(sum / Float(end - i))
        }
        
        await MainActor.run {
            self.waveformData = waveform
        }
    }
    
    // MARK: - Playback Control
    func play() {
        guard let player = playerNode,
              let buffer = editedBuffer else { return }
        
        if !isPlaying {
            player.scheduleBuffer(buffer, at: nil, options: loopEnabled ? .loops : []) {
                _Concurrency.Task { @MainActor in
                    if !self.loopEnabled {
                        self.stopPlayback()
                    }
                }
            }
            
            player.play()
            isPlaying = true
            startPlaybackTimer()
        }
    }
    
    func pause() {
        playerNode?.pause()
        isPlaying = false
        playbackTimer?.invalidate()
    }
    
    func stopPlayback() {
        playerNode?.stop()
        isPlaying = false
        currentTime = 0
        playbackTimer?.invalidate()
    }
    
    func seek(to time: TimeInterval) {
        currentTime = time
        
        if isPlaying {
            stopPlayback()
            play()
        }
    }
    
    func toggleCompareMode() {
        // Swap buffers
        let temp = editedBuffer
        editedBuffer = compareBuffer
        compareBuffer = temp
        
        if isPlaying {
            stopPlayback()
            play()
        }
    }
    
    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            _Concurrency.Task { @MainActor in
                if let nodeTime = self.playerNode?.lastRenderTime,
                   let playerTime = self.playerNode?.playerTime(forNodeTime: nodeTime) {
                    self.currentTime = Double(playerTime.sampleTime) / playerTime.sampleRate
                    
                    if self.currentTime >= self.duration && !self.loopEnabled {
                        self.stopPlayback()
                    }
                }
            }
        }
    }
    
    // MARK: - Basic Editing Functions
    func trim(to range: ClosedRange<TimeInterval>) {
        guard let buffer = editedBuffer else { return }
        
        let format = buffer.format
        let startFrame = AVAudioFramePosition(range.lowerBound * format.sampleRate)
        let endFrame = AVAudioFramePosition(range.upperBound * format.sampleRate)
        let frameCount = AVAudioFrameCount(endFrame - startFrame)
        
        if let trimmedBuffer = extractBuffer(from: buffer, startFrame: startFrame, frameCount: frameCount) {
            recordEdit(.trim(start: range.lowerBound, end: range.upperBound))
            editedBuffer = trimmedBuffer
            duration = Double(frameCount) / format.sampleRate
            hasChanges = true
            
            _Concurrency.Task { @MainActor in
                await self.generateWaveform(from: trimmedBuffer)
            }
        }
    }
    
    func removeSilence() {
        guard let buffer = editedBuffer else { return }
        
        // TODO: Implement silence detection and removal
        recordEdit(.removeSilence)
        hasChanges = true
    }
    
    func normalize() {
        guard let buffer = editedBuffer,
              let channelData = buffer.floatChannelData else { return }
        
        var maxSample: Float = 0
        let frameLength = Int(buffer.frameLength)
        
        // Find peak
        for channel in 0..<Int(buffer.format.channelCount) {
            for frame in 0..<frameLength {
                maxSample = max(maxSample, abs(channelData[channel][frame]))
            }
        }
        
        if maxSample > 0 && maxSample < 1.0 {
            let gain = 0.95 / maxSample // Normalize to -0.5dB
            
            for channel in 0..<Int(buffer.format.channelCount) {
                for frame in 0..<frameLength {
                    channelData[channel][frame] *= gain
                }
            }
            
            recordEdit(.normalize(gain: gain))
            hasChanges = true
            
            _Concurrency.Task { @MainActor in
                await self.generateWaveform(from: buffer)
            }
        }
    }
    
    func setPitch(semitones: Int) {
        recordEdit(.pitchShift(semitones: Float(semitones)))
        applyPitchShift(Float(semitones))
        hasChanges = true
    }
    
    func setSpeed(percentage: Double) {
        let factor = Float(percentage / 100.0)
        recordEdit(.timeStretch(factor: factor))
        applyTimeStretch(factor)
        hasChanges = true
    }
    
    func setVolume(decibels: Double) {
        let gain = pow(10, Float(decibels / 20.0))
        recordEdit(.volume(gain: gain))
        applyGain(gain)
        hasChanges = true
    }
    
    func fadeIn(duration: TimeInterval) {
        recordEdit(.fadeIn(duration: duration))
        applyFade(type: .fadeIn, duration: duration)
        hasChanges = true
    }
    
    func fadeOut(duration: TimeInterval) {
        recordEdit(.fadeOut(duration: duration))
        applyFade(type: .fadeOut, duration: duration)
        hasChanges = true
    }
    
    // MARK: - Effects
    func addEffect(_ type: AudioEffect) {
        let effect = ActiveEffect(type: type)
        activeEffects.append(effect)
        recordEdit(.addEffect(effect))
        rebuildEffectChain()
        hasChanges = true
    }
    
    func removeEffect(_ effect: ActiveEffect) {
        activeEffects.removeAll { $0.id == effect.id }
        recordEdit(.removeEffect(effect))
        rebuildEffectChain()
        hasChanges = true
    }
    
    func clearEffects() {
        activeEffects.removeAll()
        recordEdit(.clearEffects)
        rebuildEffectChain()
        hasChanges = true
    }
    
    private func rebuildEffectChain() {
        guard let engine = audioEngine, let player = playerNode else { return }
        
        // Remove existing effect nodes
        for node in effectNodes {
            engine.detach(node)
        }
        effectNodes.removeAll()
        
        // Rebuild chain
        var previousNode: AVAudioNode = player
        
        for effect in activeEffects {
            if let effectNode = createEffectNode(for: effect.type) {
                engine.attach(effectNode)
                engine.connect(previousNode, to: effectNode, format: nil)
                effectNodes.append(effectNode)
                previousNode = effectNode
            }
        }
        
        // Connect to output
        engine.connect(previousNode, to: engine.mainMixerNode, format: nil)
    }
    
    private func createEffectNode(for effect: AudioEffect) -> AVAudioNode? {
        switch effect {
        case .filter:
            let eq = AVAudioUnitEQ(numberOfBands: 1)
            eq.bands[0].filterType = .highPass
            eq.bands[0].frequency = 1000
            eq.bands[0].bypass = false
            return eq
            
        case .reverb:
            let reverb = AVAudioUnitReverb()
            reverb.loadFactoryPreset(.largeHall)
            reverb.wetDryMix = 30
            return reverb
            
        case .delay:
            let delay = AVAudioUnitDelay()
            delay.delayTime = 0.5
            delay.feedback = 50
            delay.wetDryMix = 30
            return delay
            
        case .distortion:
            let distortion = AVAudioUnitDistortion()
            distortion.loadFactoryPreset(.drumsBitBrush)
            distortion.wetDryMix = 50
            return distortion
            
        case .chorus:
            // Note: No built-in chorus, would need custom implementation
            return nil
            
        case .eq:
            let eq = AVAudioUnitEQ(numberOfBands: 5)
            // Configure bands
            return eq
        }
    }
    
    // MARK: - Advanced Tools
    func reverse() {
        guard let buffer = editedBuffer,
              let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        
        for channel in 0..<Int(buffer.format.channelCount) {
            var reversed = Array(UnsafeBufferPointer(start: channelData[channel], count: frameLength))
            reversed.reverse()
            
            for (index, sample) in reversed.enumerated() {
                channelData[channel][index] = sample
            }
        }
        
        recordEdit(.reverse)
        hasChanges = true
        
        _Concurrency.Task {
            await generateWaveform(from: buffer)
        }
    }
    
    func createLoop() {
        // TODO: Implement loop point detection
        recordEdit(.loop)
        hasChanges = true
    }
    
    func autoChop() {
        // TODO: Implement transient detection for auto-chop
        recordEdit(.autoChop)
        hasChanges = true
    }
    
    func slice(count: Int) {
        // TODO: Implement equal slicing
        recordEdit(.slice(count: count))
        hasChanges = true
    }
    
    func extractTransients() {
        // TODO: Implement transient extraction
        recordEdit(.extractTransients)
        hasChanges = true
    }
    
    func generateVariations(count: Int) {
        // TODO: Generate variations with different processing
        recordEdit(.generateVariations(count: count))
        hasChanges = true
    }
    
    func generateHarmonicBass() {
        // TODO: Generate sub-bass harmonics
        recordEdit(.generateHarmonicBass)
        hasChanges = true
    }
    
    func extractGroove() {
        // TODO: Extract rhythmic pattern
        recordEdit(.extractGroove)
        hasChanges = true
    }
    
    // MARK: - Undo/Redo
    func undo() {
        guard let action = undoStack.popLast() else { return }
        redoStack.append(action)
        // TODO: Implement action reversal
        updateUndoRedoState()
    }
    
    func redo() {
        guard let action = redoStack.popLast() else { return }
        undoStack.append(action)
        // TODO: Reapply action
        updateUndoRedoState()
    }
    
    private func recordEdit(_ action: EditAction) {
        undoStack.append(action)
        redoStack.removeAll()
        updateUndoRedoState()
    }
    
    private func updateUndoRedoState() {
        canUndo = !undoStack.isEmpty
        canRedo = !redoStack.isEmpty
    }
    
    // MARK: - Save Functions
    func saveWith(option: SaveOption) {
        // TODO: Implement save with different options
        hasChanges = false
    }
    
    func handleAudioSessionInterruption() {
        if isPlaying {
            pause()
        }
    }
    
    // MARK: - Helper Functions
    private func copyBuffer(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let newBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: buffer.frameCapacity) else { return nil }
        
        newBuffer.frameLength = buffer.frameLength
        
        if let srcData = buffer.floatChannelData, let dstData = newBuffer.floatChannelData {
            for channel in 0..<Int(buffer.format.channelCount) {
                memcpy(dstData[channel], srcData[channel], Int(buffer.frameLength) * MemoryLayout<Float>.size)
            }
        }
        
        return newBuffer
    }
    
    private func extractBuffer(from buffer: AVAudioPCMBuffer, startFrame: AVAudioFramePosition, frameCount: AVAudioFrameCount) -> AVAudioPCMBuffer? {
        guard let newBuffer = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: frameCount) else { return nil }
        
        newBuffer.frameLength = frameCount
        
        if let srcData = buffer.floatChannelData, let dstData = newBuffer.floatChannelData {
            for channel in 0..<Int(buffer.format.channelCount) {
                let src = srcData[channel].advanced(by: Int(startFrame))
                memcpy(dstData[channel], src, Int(frameCount) * MemoryLayout<Float>.size)
            }
        }
        
        return newBuffer
    }
    
    // MARK: - Audio Processing Helpers
    private func applyPitchShift(_ semitones: Float) {
        // TODO: Implement pitch shifting algorithm
        // This would require FFT-based processing or a library
    }
    
    private func applyTimeStretch(_ factor: Float) {
        // TODO: Implement time stretching algorithm
        // This would require phase vocoder or similar technique
    }
    
    private func applyGain(_ gain: Float) {
        guard let buffer = editedBuffer,
              let channelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        
        for channel in 0..<Int(buffer.format.channelCount) {
            var gainCopy = gain
            vDSP_vsmul(channelData[channel], 1, &gainCopy, channelData[channel], 1, vDSP_Length(frameLength))
        }
        
        _Concurrency.Task {
            await generateWaveform(from: buffer)
        }
    }
    
    private func applyFade(type: FadeType, duration: TimeInterval) {
        guard let buffer = editedBuffer,
              let channelData = buffer.floatChannelData else { return }
        
        let format = buffer.format
        let fadeSamples = Int(duration * format.sampleRate)
        let frameLength = Int(buffer.frameLength)
        
        for channel in 0..<Int(format.channelCount) {
            let channelPointer = channelData[channel]
            
            switch type {
            case .fadeIn:
                for i in 0..<min(fadeSamples, frameLength) {
                    let multiplier = Float(i) / Float(fadeSamples)
                    channelPointer[i] *= multiplier
                }
                
            case .fadeOut:
                let startIndex = max(0, frameLength - fadeSamples)
                for i in startIndex..<frameLength {
                    let multiplier = Float(frameLength - i) / Float(fadeSamples)
                    channelPointer[i] *= multiplier
                }
            }
        }
        
        _Concurrency.Task {
            await generateWaveform(from: buffer)
        }
    }
}

// MARK: - Supporting Types
enum EditAction {
    case trim(start: TimeInterval, end: TimeInterval)
    case removeSilence
    case normalize(gain: Float)
    case pitchShift(semitones: Float)
    case timeStretch(factor: Float)
    case volume(gain: Float)
    case fadeIn(duration: TimeInterval)
    case fadeOut(duration: TimeInterval)
    case addEffect(ActiveEffect)
    case removeEffect(ActiveEffect)
    case clearEffects
    case reverse
    case loop
    case autoChop
    case slice(count: Int)
    case extractTransients
    case generateVariations(count: Int)
    case generateHarmonicBass
    case extractGroove
}

enum FadeType {
    case fadeIn
    case fadeOut
}

enum AudioEffect: String, CaseIterable {
    case filter = "Filter"
    case reverb = "Reverb"
    case delay = "Delay"
    case distortion = "Distortion"
    case chorus = "Chorus"
    case eq = "EQ"
    
    var color: Color {
        switch self {
        case .filter: return .blue
        case .reverb: return .purple
        case .delay: return .green
        case .distortion: return .red
        case .chorus: return .orange
        case .eq: return .teal
        }
    }
}

struct ActiveEffect: Identifiable {
    let id = UUID()
    let type: AudioEffect
    var parameters: [String: Float] = [:]
    var isEnabled = true
    
    var parameterText: String? {
        switch type {
        case .filter:
            if let freq = parameters["frequency"] {
                return "\(Int(freq))Hz"
            }
        case .reverb:
            if let mix = parameters["mix"] {
                return "\(Int(mix))%"
            }
        case .delay:
            if let time = parameters["time"] {
                return "\(time)s"
            }
        case .distortion:
            if let amount = parameters["amount"] {
                return "\(Int(amount))%"
            }
        case .chorus:
            if let rate = parameters["rate"] {
                return "\(rate)Hz"
            }
        case .eq:
            return "5-band"
        }
        return nil
    }
}

// MARK: - Sample Pack Builder View
struct SamplePackBuilderView: View {
    @ObservedObject var editorManager: SampleEditorManager
    let currentSample: Sample?
    @Environment(\.presentationMode) var presentationMode
    
    @State private var packName = ""
    @State private var packDescription = ""
    @State private var selectedSamples: Set<String> = []
    @State private var generatedArtwork: UIImage?
    @State private var isGeneratingArtwork = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("CREATE SAMPLE PACK")
                            .font(.system(size: 24, weight: .heavy))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Pack details
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PACK NAME")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                            
                            TextField("Enter pack name", text: $packName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.1))
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DESCRIPTION")
                                .font(.system(size: 14, weight: .heavy))
                                .foregroundColor(.white)
                            
                            TextField("Pack description", text: $packDescription)
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
                    
                    // Artwork section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ARTWORK")
                            .font(.system(size: 14, weight: .heavy))
                            .foregroundColor(.white)
                        
                        if let artwork = generatedArtwork {
                            Image(uiImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Button(action: {
                                generateArtwork()
                            }) {
                                VStack(spacing: 12) {
                                    if isGeneratingArtwork {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 40))
                                            .foregroundColor(.white)
                                        
                                        Text("GENERATE ARTWORK")
                                            .font(.system(size: 14, weight: .heavy))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white.opacity(0.1))
                                )
                            }
                            .disabled(isGeneratingArtwork)
                        }
                    }
                    
                    Spacer()
                    
                    // Create button
                    Button(action: {
                        createPack()
                    }) {
                        Text("CREATE PACK")
                            .font(.system(size: 16, weight: .heavy))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                            )
                    }
                    .disabled(packName.isEmpty)
                }
                .padding(24)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func generateArtwork() {
        isGeneratingArtwork = true
        
        // TODO: Implement AI artwork generation
        // For now, create a placeholder
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            generatedArtwork = createPlaceholderArtwork()
            isGeneratingArtwork = false
        }
    }
    
    private func createPlaceholderArtwork() -> UIImage {
        let size = CGSize(width: 512, height: 512)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        // Create gradient background
        let context = UIGraphicsGetCurrentContext()!
        let colors = [UIColor.systemPurple.cgColor, UIColor.systemBlue.cgColor]
        let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil)!
        
        context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        
        // Add waveform visualization
        let waveformPath = UIBezierPath()
        waveformPath.move(to: CGPoint(x: 0, y: size.height / 2))
        
        for x in stride(from: 0, to: size.width, by: 4) {
            let y = size.height / 2 + sin(x * 0.02) * 50 * sin(x * 0.001)
            waveformPath.addLine(to: CGPoint(x: x, y: y))
        }
        
        UIColor.white.withAlphaComponent(0.8).setStroke()
        waveformPath.lineWidth = 3
        waveformPath.stroke()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func createPack() {
        // TODO: Implement pack creation logic
        presentationMode.wrappedValue.dismiss()
    }
}