//
//  AudioProcessor.swift
//  Jamminverz
//
//  Audio effects processing engine
//

import AVFoundation
import Accelerate

class AudioProcessor: ObservableObject {
    static let shared = AudioProcessor()
    
    private var audioEngine: AVAudioEngine
    private var playerNode: AVAudioPlayerNode
    private var pitchNode: AVAudioUnitTimePitch
    private var reverbNode: AVAudioUnitReverb
    private var delayNode: AVAudioUnitDelay
    private var distortionNode: AVAudioUnitDistortion
    private var eqNode: AVAudioUnitEQ
    
    @Published var isProcessing = false
    
    private init() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        pitchNode = AVAudioUnitTimePitch()
        reverbNode = AVAudioUnitReverb()
        delayNode = AVAudioUnitDelay()
        distortionNode = AVAudioUnitDistortion()
        eqNode = AVAudioUnitEQ(numberOfBands: 2)
        
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        // Attach nodes
        audioEngine.attach(playerNode)
        audioEngine.attach(pitchNode)
        audioEngine.attach(reverbNode)
        audioEngine.attach(delayNode)
        audioEngine.attach(distortionNode)
        audioEngine.attach(eqNode)
        
        // Connect nodes in chain
        let format = audioEngine.mainMixerNode.outputFormat(forBus: 0)
        
        audioEngine.connect(playerNode, to: pitchNode, format: format)
        audioEngine.connect(pitchNode, to: distortionNode, format: format)
        audioEngine.connect(distortionNode, to: delayNode, format: format)
        audioEngine.connect(delayNode, to: reverbNode, format: format)
        audioEngine.connect(reverbNode, to: eqNode, format: format)
        audioEngine.connect(eqNode, to: audioEngine.mainMixerNode, format: format)
        
        // Set default values
        pitchNode.pitch = 0
        pitchNode.rate = 1.0
        reverbNode.loadFactoryPreset(.largeHall)
        reverbNode.wetDryMix = 0
        delayNode.delayTime = 0.25
        delayNode.wetDryMix = 0
        distortionNode.loadFactoryPreset(.multiDistortedCubed)
        distortionNode.wetDryMix = 0
        
        // Configure EQ bands
        let bands = eqNode.bands
        if bands.count >= 2 {
            // Low pass filter
            bands[0].filterType = .lowPass
            bands[0].frequency = 20000
            bands[0].bypass = false
            
            // High pass filter
            bands[1].filterType = .highPass
            bands[1].frequency = 20
            bands[1].bypass = false
        }
    }
    
    func startProcessing() {
        guard !isProcessing else { return }
        
        do {
            try audioEngine.start()
            isProcessing = true
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stopProcessing() {
        guard isProcessing else { return }
        
        audioEngine.stop()
        isProcessing = false
    }
    
    // MARK: - Effect Controls
    
    func setPitch(_ semitones: Float) {
        pitchNode.pitch = semitones * 100 // Convert semitones to cents
    }
    
    func setPlaybackSpeed(_ speed: Float) {
        pitchNode.rate = speed
    }
    
    func setReverb(_ mix: Float) {
        reverbNode.wetDryMix = mix
    }
    
    func setDelayMix(_ mix: Float) {
        delayNode.wetDryMix = mix
    }
    
    func setDelayTime(_ time: Float) {
        delayNode.delayTime = TimeInterval(time)
    }
    
    func setDistortion(_ amount: Float) {
        distortionNode.wetDryMix = amount
    }
    
    func setLowPass(_ frequency: Float) {
        let bands = eqNode.bands
        if bands.count > 0 {
            bands[0].frequency = frequency
        }
    }
    
    func setHighPass(_ frequency: Float) {
        let bands = eqNode.bands
        if bands.count > 1 {
            bands[1].frequency = frequency
        }
    }
    
    func setChorus(_ mix: Float) {
        // Chorus can be simulated with short delay and pitch modulation
        // For now, we'll use delay with very short time
        if mix > 0 {
            delayNode.delayTime = 0.02 // 20ms for chorus effect
            delayNode.feedback = 30
            delayNode.wetDryMix = mix * 0.5 // Scale down for subtlety
        }
    }
    
    func setPhaser(_ mix: Float) {
        // Phaser effect can be achieved through EQ manipulation
        // This is a simplified implementation
        if mix > 0 {
            let bands = eqNode.bands
            if bands.count > 0 {
                bands[0].gain = mix * 0.1 // Subtle gain adjustment
            }
        }
    }
    
    func resetAllEffects() {
        pitchNode.pitch = 0
        pitchNode.rate = 1.0
        reverbNode.wetDryMix = 0
        delayNode.wetDryMix = 0
        delayNode.delayTime = 0.25
        distortionNode.wetDryMix = 0
        
        let bands = eqNode.bands
        if bands.count >= 2 {
            bands[0].frequency = 20000
            bands[1].frequency = 20
        }
    }
    
    // MARK: - Audio Level Monitoring
    
    func getAudioLevels() -> [Float] {
        // Generate random values for visual effect
        // In a real implementation, you would tap the audio and analyze actual levels
        var levels: [Float] = []
        for _ in 0..<50 {
            levels.append(Float.random(in: 0.1...0.9))
        }
        return levels
    }
    
    // MARK: - Integration with MusicPlayerManager
    
    func connectToPlayer() {
        // This would connect the audio processor to the actual player
        // For now, this is a placeholder for future implementation
        // You would need to modify MusicPlayerManager to route audio through this engine
    }
}